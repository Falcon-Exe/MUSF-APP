// lib/features/prd/data/repositories/prd_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PrdRepository {
  Stream<List<Map<String, dynamic>>> getTasks({String? status, String? committee});
  Stream<List<Map<String, dynamic>>> getStudents();
  Future<void> submitTask(Map<String, dynamic> data);
  Future<void> updateTaskStatus(String docId, String status);
  Future<void> updateBalance(String docId, String studentID, int amount, bool isAddingDebt);
  Future<void> deleteRecord(String docId);
  Future<void> deleteTask(String docId);
}

class FirestorePrdRepository implements PrdRepository {
  final FirebaseFirestore _firestore;

  FirestorePrdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getTasks({String? status, String? committee}) {
    Query query = _firestore.collection('prd_tasks');
    
    if (committee != null) {
      query = query.where('committeeName', isEqualTo: committee);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => {'id': d.id, ...((d.data() as Map<String, dynamic>?) ?? {})})
        .toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getStudents() {
    return _firestore.collection('students').snapshots().map((snap) => snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList());
  }

  @override
  Future<void> submitTask(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('prd_tasks').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify PRD Admins
    await _firestore.collection('notifications').add({
      'studentID': 'admin',
      'title': 'New PRD Request',
      'message': '${data['committeeName']} requested: ${data['requestTitle']}',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'prd_request',
      'referenceId': docRef.id,
    });
  }

  @override
  Future<void> updateTaskStatus(String docId, String status) async {
    await _firestore.collection('prd_tasks').doc(docId).update({'status': status});

    await _firestore.collection('notifications').add({
      'studentID': 'all',
      'title': 'PRD Task Updated',
      'message': 'Task status changed to $status',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'prd_update',
      'referenceId': docId,
    });
  }

  @override
  Future<void> updateBalance(String docId, String studentID, int amount, bool isAddingDebt) async {
    final batch = _firestore.batch();
    final studentRef = _firestore.collection('students').doc(docId);

    if (isAddingDebt) {
      batch.set(studentRef, {
        'prdPrintBalance': FieldValue.increment(amount),
        'prdPrintTotalAdded': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    } else {
      batch.set(studentRef, {
        'prdPrintBalance': FieldValue.increment(-amount),
      }, SetOptions(merge: true));
    }

    final logRef = _firestore.collection('prd_payments').doc();
    batch.set(logRef, {
      'studentID': studentID.trim(),
      'amount': amount,
      'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
      'date': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> deleteRecord(String docId) async {
    await _firestore.collection('students').doc(docId).update({
      'prdPrintBalance': FieldValue.delete(),
      'prdPrintTotalAdded': FieldValue.delete(),
    });
  }

  @override
  Future<void> deleteTask(String docId) async {
    await _firestore.collection('prd_tasks').doc(docId).delete();
  }
}
