// lib/features/finance/data/repositories/supabase_finance_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'finance_repository.dart';
import 'finance_exceptions.dart';

class SupabaseFinanceRepository implements FinanceRepository {
  final SupabaseClient _client;

  SupabaseFinanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // --- Security Helpers ---

  Future<void> _checkAuth() async {
    final user = _client.auth.currentUser;
    if (user == null) throw UnauthenticatedException();
  }

  Future<void> _checkAdminAccess() async {
    await _checkAuth();
    final user = _client.auth.currentUser!;
    final email = user.email?.trim().toLowerCase() ?? '';

    final studentRow = await _client
        .from('students')
        .select('role, is_admin, designation, assigned_role')
        .eq('auth_email', email)
        .maybeSingle();

    if (studentRow == null) throw PermissionDeniedException();

    final String roleLower = (studentRow['role']?.toString() ?? '').toLowerCase().trim();
    final String designationLower =
        (studentRow['designation']?.toString() ?? '').toLowerCase().trim();
    final String assignedRoleLower =
        (studentRow['assigned_role']?.toString() ?? '').toLowerCase().trim();

    const List<String> adminDesignations = [
      'executive',
      'president',
      'secretary',
      'treasurer',
      'union director',
      'vice president',
      'joint secretary',
      'chairman',
      'general secretary',
    ];

    final bool isAdmin = roleLower == 'admin' ||
        studentRow['is_admin'] == true ||
        studentRow['is_admin']?.toString().toLowerCase() == 'true' ||
        adminDesignations.contains(designationLower) ||
        adminDesignations.contains(assignedRoleLower);

    if (!isAdmin) {
      throw PermissionDeniedException();
    }
  }

  int _asInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  // --- Dues & Payments (Union / Store) ---

  @override
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    return _client
        .from('students')
        .stream(primaryKey: ['id'])
        .order('full_name');
  }

  @override
  Stream<List<Map<String, dynamic>>> getPaymentHistoryStream(
    String studentID,
    CollectionType type,
  ) {
    final table = type == CollectionType.union
        ? 'union_payments'
        : 'store_payments';

    return _client
        .from(table)
        .stream(primaryKey: ['id'])
        .eq('student_id', studentID.trim())
        .order('date', ascending: false);
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

    final student = await _client
        .from('students')
        .select('union_total_paid, union_balance, store_balance, store_total_added')
        .eq('student_id', studentID.trim())
        .maybeSingle();

    if (type == CollectionType.union) {
      if (isAddingDebt) return;
      final currentPaid = _asInt(student?['union_total_paid']);
      final currentBalance = _asInt(student?['union_balance']);
      final newPaid = currentPaid + amount;
      final newBalance = (currentBalance - amount).clamp(0, currentBalance).toInt();

      await _client.from('students').update({
        'union_total_paid': newPaid,
        'union_balance': newBalance,
      }).eq('student_id', studentID.trim());

      await _client.from('union_payments').insert({
        'student_id': studentID.trim(),
        'amount': amount,
        'type': 'Payment Collected',
        'date': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      final currentBalance = _asInt(student?['store_balance']);
      final currentTotal = _asInt(student?['store_total_added']);
      final newBalance = isAddingDebt
          ? currentBalance + amount
          : (currentBalance - amount).clamp(0, currentBalance).toInt();
      final newTotal = isAddingDebt ? currentTotal + amount : currentTotal;

      await _client.from('students').update({
        'store_balance': newBalance,
        'store_total_added': newTotal,
      }).eq('student_id', studentID.trim());

      await _client.from('store_payments').insert({
        'student_id': studentID.trim(),
        'amount': amount,
        'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
        'date': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  @override
  Future<void> deletePaymentRecord(
    String transId,
    String studentID,
    int amount,
    CollectionType type,
  ) async {
    await _checkAdminAccess();
    final table = type == CollectionType.union
        ? 'union_payments'
        : 'store_payments';

    await _client.from(table).delete().eq('id', transId);

    final student = await _client
        .from('students')
        .select('union_total_paid, union_balance, store_balance, store_total_added')
        .eq('student_id', studentID.trim())
        .maybeSingle();

    if (student != null) {
      if (type == CollectionType.union) {
        final currentPaid = _asInt(student['union_total_paid']);
        final currentBalance = _asInt(student['union_balance']);
        await _client.from('students').update({
          'union_total_paid': (currentPaid - amount).clamp(0, currentPaid).toInt(),
          'union_balance': currentBalance + amount,
        }).eq('student_id', studentID.trim());
      } else {
        final currentBalance = _asInt(student['store_balance']);
        await _client.from('students').update({
          'store_balance': (currentBalance - amount).clamp(0, currentBalance).toInt(),
        }).eq('student_id', studentID.trim());
      }
    }
  }

  // --- Savings / Treasury (Numbered Ledger) ---

  @override
  Stream<List<Map<String, dynamic>>> getTreasuryStream() {
    return _client
        .from('treasury')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> getStudentSavingsHistory(String studentID) {
    return _client
        .from('treasury')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentID.trim())
        .order('date', ascending: false);
  }

  @override
  Future<void> updateSavingsBalance(
    String studentID,
    int amount,
    bool isDeposit,
  ) async {
    await _checkAdminAccess();
    if (amount < 0) throw ValidationException('Amount cannot be negative');

    await _client.from('treasury').insert({
      'student_id': studentID.trim(),
      'amount': amount,
      'type': isDeposit ? 'income' : 'expense',
      'date': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // --- Account Ledger (Aero Ledger) ---

  @override
  Stream<List<Map<String, dynamic>>> getAeroLedgerStream() {
    return _client
        .from('aero_ledger')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false);
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

    await _client.from('aero_ledger').insert({
      'date': date.toUtc().toIso8601String(),
      'subcommittee': subcommittee.trim(),
      'purpose': purpose.toUpperCase().trim(),
      'type': type.trim(),
      'amount': amount,
    });
  }

  @override
  Future<void> deleteLedgerEntry(String docId) async {
    await _checkAdminAccess();
    await _client.from('aero_ledger').delete().eq('id', docId);
  }

  // --- Purchase Requests ---

  @override
  Stream<List<Map<String, dynamic>>> getPurchaseRequestsStream(String status) {
    if (status == 'all') {
      return _client
          .from('purchase_requests')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    }
    return _client
        .from('purchase_requests')
        .stream(primaryKey: ['id'])
        .eq('status', status)
        .order('created_at', ascending: false);
  }

  @override
  Future<void> approvePurchaseRequest(String docId) async {
    await _checkAdminAccess();
    await _client.from('purchase_requests').update({
      'status': 'approved',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'rejection_reason': null,
    }).eq('id', docId);
  }

  @override
  Future<void> rejectPurchaseRequest(String docId, String? reason) async {
    await _checkAdminAccess();
    await _client.from('purchase_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'rejection_reason': reason?.trim(),
    }).eq('id', docId);
  }

  @override
  Future<void> deletePurchaseRequest(String docId) async {
    await _checkAdminAccess();
    await _client.from('purchase_requests').delete().eq('id', docId);
  }

  // --- Settings ---

  @override
  Stream<Map<String, dynamic>> getUnionSettingsStream() {
    return _client
        .from('app_settings')
        .stream(primaryKey: ['id'])
        .eq('setting_key', 'union_due_amount')
        .map((rows) {
          if (rows.isNotEmpty) {
            final val = int.tryParse(rows.first['setting_value']?.toString() ?? '1000') ?? 1000;
            return {'unionDueAmount': val};
          }
          return {'unionDueAmount': 1000};
        });
  }

  @override
  Future<void> updateUnionDueAmount(int amount) async {
    await _client.from('app_settings').upsert({
      'setting_key': 'union_due_amount',
      'setting_value': amount.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'setting_key');
  }
}
