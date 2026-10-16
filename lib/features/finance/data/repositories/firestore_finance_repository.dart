// lib/features/finance/data/repositories/firestore_finance_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'finance_constants.dart';
import 'finance_exceptions.dart';

class FirestoreFinanceRepository implements FinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Security Helpers ---

  Future<void> _checkAuth() async {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) throw UnauthenticatedException();
  }

  Future<void> _checkAdminAccess() async {
    await _checkAuth();
    final user = supabase.Supabase.instance.client.auth.currentUser!;

    DocumentSnapshot doc = await _firestore
        .collection(FinanceConstants.studentsCollection)
        .doc(user.id)
        .get();

    Map<String, dynamic>? data;
    if (doc.exists) {
      data = doc.data() as Map<String, dynamic>?;
    } else {
      final email = user.email ?? '';
      final searchId = email.contains('@') ? email.split('@')[0] : email;
      final query = await _firestore
          .collection(FinanceConstants.studentsCollection)
          .where('studentID', isEqualTo: searchId.trim())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        data = query.docs.first.data();
      }
    }

    if (data == null) throw PermissionDeniedException();

    final String roleLower = (data['role']?.toString() ?? '').toLowerCase();
    final String designationLower = (data['designation']?.toString() ?? '')
        .toLowerCase();
    final String assignedRoleLower = (data['assignedRole']?.toString() ?? '')
        .toLowerCase();

    const List<String> adminDesignations = [
      'executive',
      'president',
      'secretary',
      'treasurer',
      'union director',
      'vice president',
      'joint secretary',
    ];

    final bool isAdmin =
        (data['isAdmin'] == true ||
            data['isAdmin']?.toString().toLowerCase() == 'true') ||
        (data['Admin'] == true ||
            data['Admin']?.toString().toLowerCase() == 'true') ||
        (data['admin'] == true ||
            data['admin']?.toString().toLowerCase() == 'true') ||
        roleLower == 'admin' ||
        adminDesignations.contains(designationLower) ||
        adminDesignations.contains(assignedRoleLower);

    if (!isAdmin) {
      throw PermissionDeniedException();
    }
  }

  Future<String> _getCurrentStudentId() async {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) return '';
    final email = user.email ?? '';
    return email.contains('@') ? email.split('@')[0] : email;
  }

  // --- Dues & Payments (Union / Store) ---

  @override
  Stream<QuerySnapshot> getStudentsStream() async* {
    await _checkAdminAccess();
    yield* _firestore
        .collection(FinanceConstants.studentsCollection)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getPaymentHistoryStream(
    String studentID,
    CollectionType type,
  ) async* {
    await _checkAuth();
    final currentId = await _getCurrentStudentId();
    if (studentID.trim() != currentId.trim()) {
      await _checkAdminAccess();
    }

    String collection = type == CollectionType.union
        ? FinanceConstants.unionPaymentsCollection
        : FinanceConstants.storePaymentsCollection;

    yield* _firestore
        .collection(collection)
        .where('studentID', isEqualTo: studentID.trim())
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Future<void> updateDuesBalance({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAddingDebt,
    required CollectionType type,
  }) async {
    await _checkAdminAccess();

    if (amount < 0) throw ValidationException('Amount cannot be negative');

    String balanceField = type == CollectionType.union
        ? 'unionBalance'
        : 'storeBalance';
    String totalPaidField = type == CollectionType.union
        ? 'unionTotalPaid'
        : 'storeTotalAdded';

    WriteBatch batch = _firestore.batch();
    DocumentReference studentRef = _firestore
        .collection(FinanceConstants.studentsCollection)
        .doc(docId);

    if (type == CollectionType.union) {
      if (isAddingDebt) return;
      batch.update(studentRef, {
        balanceField: FieldValue.increment(-amount),
        totalPaidField: FieldValue.increment(amount),
      });
    } else {
      if (isAddingDebt) {
        batch.set(studentRef, {
          balanceField: FieldValue.increment(amount),
          totalPaidField: FieldValue.increment(amount),
        }, SetOptions(merge: true));
      } else {
        batch.set(studentRef, {
          balanceField: FieldValue.increment(-amount),
        }, SetOptions(merge: true));
      }
    }

    String historyCollection = type == CollectionType.union
        ? FinanceConstants.unionPaymentsCollection
        : FinanceConstants.storePaymentsCollection;

    DocumentReference historyRef = _firestore
        .collection(historyCollection)
        .doc();
    batch.set(historyRef, {
      'studentID': studentID.trim(),
      'amount': amount,
      'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
      'date': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> deletePaymentRecord(
    String transId,
    String studentID,
    int amount,
    CollectionType type,
  ) async {
    await _checkAdminAccess();

    String collection = type == CollectionType.union
        ? FinanceConstants.unionPaymentsCollection
        : FinanceConstants.storePaymentsCollection;
    String balanceField = type == CollectionType.union
        ? 'unionBalance'
        : 'storeBalance';
    String totalPaidField = type == CollectionType.union
        ? 'unionTotalPaid'
        : 'storeTotalAdded';

    WriteBatch batch = _firestore.batch();
    batch.delete(_firestore.collection(collection).doc(transId));

    var studentQuery = await _firestore
        .collection(FinanceConstants.studentsCollection)
        .where('studentID', isEqualTo: studentID.trim())
        .limit(1)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      DocumentReference studentRef = studentQuery.docs.first.reference;
      if (type == CollectionType.union) {
        batch.update(studentRef, {
          balanceField: FieldValue.increment(amount),
          totalPaidField: FieldValue.increment(-amount),
        });
      } else {
        batch.update(studentRef, {
          balanceField: FieldValue.delete(),
          totalPaidField: FieldValue.delete(),
        });
      }
    }

    await batch.commit();
  }

  // --- Savings / Treasury ---

  @override
  Stream<QuerySnapshot> getTreasuryStream() async* {
    await _checkAdminAccess();
    yield* _firestore
        .collection(FinanceConstants.treasuryCollection)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getStudentSavingsHistory(String studentID) async* {
    await _checkAuth();
    final currentId = await _getCurrentStudentId();
    if (studentID.trim() != currentId.trim()) {
      await _checkAdminAccess();
    }

    yield* _firestore
        .collection(FinanceConstants.treasuryCollection)
        .where('studentID', isEqualTo: studentID.trim())
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Future<void> updateSavingsBalance(
    String studentID,
    int amount,
    bool isDeposit,
  ) async {
    await _checkAdminAccess();
    if (amount < 0) throw ValidationException('Amount cannot be negative');

    await _firestore.collection(FinanceConstants.treasuryCollection).add({
      'studentID': studentID.trim(),
      'amount': amount,
      'type': isDeposit ? 'income' : 'expense',
      'date': FieldValue.serverTimestamp(),
    });
  }

  // --- Account Ledger (Aero Ledger) ---

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getAeroLedgerStream() async* {
    await _checkAdminAccess();
    yield* _firestore
        .collection(FinanceConstants.aeroLedgerCollection)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Future<void> addLedgerEntry({
    required DateTime date,
    required String subcommittee,
    required String purpose,
    required String type,
    required int amount,
  }) async {
    await _checkAdminAccess();
    if (amount < 0) throw ValidationException('Amount cannot be negative');

    await _firestore.collection(FinanceConstants.aeroLedgerCollection).add({
      'date': Timestamp.fromDate(date),
      'subcommittee': subcommittee.trim(),
      'purpose': purpose.toUpperCase().trim(),
      'type': type.trim(),
      'amount': amount,
    });
  }

  @override
  Future<void> deleteLedgerEntry(String docId) async {
    await _checkAdminAccess();
    await _firestore
        .collection(FinanceConstants.aeroLedgerCollection)
        .doc(docId)
        .delete();
  }

  // --- Purchase Requests ---

  @override
  Stream<QuerySnapshot> getPurchaseRequestsStream(String status) async* {
    await _checkAuth();
    await _checkAdminAccess();

    if (status == 'all') {
      yield* _firestore
          .collection(FinanceConstants.purchaseRequestsCollection)
          .orderBy('submittedAt', descending: true)
          .snapshots();
    } else {
      yield* _firestore
          .collection(FinanceConstants.purchaseRequestsCollection)
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
          .snapshots();
    }
  }

  @override
  Future<void> approvePurchaseRequest(String docId) async {
    await _checkAdminAccess();
    await _firestore
        .collection(FinanceConstants.purchaseRequestsCollection)
        .doc(docId)
        .update({
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'rejectionReason': null,
        });
  }

  @override
  Future<void> rejectPurchaseRequest(String docId, String? reason) async {
    await _checkAdminAccess();
    await _firestore
        .collection(FinanceConstants.purchaseRequestsCollection)
        .doc(docId)
        .update({
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'rejectionReason': reason?.trim(),
        });
  }

  @override
  Future<void> deletePurchaseRequest(String docId) async {
    await _checkAdminAccess();
    await _firestore
        .collection(FinanceConstants.purchaseRequestsCollection)
        .doc(docId)
        .delete();
  }
}
