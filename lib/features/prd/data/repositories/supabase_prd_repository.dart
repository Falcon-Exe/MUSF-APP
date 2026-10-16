// lib/features/prd/data/repositories/supabase_prd_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'prd_repository.dart';

class SupabasePrdRepository implements PrdRepository {
  final SupabaseClient _client;

  SupabasePrdRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getTasks({String? status, String? committee}) {
    final stream = _client
        .from('prd_tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((rows) {
      var filtered = rows;
      if (committee != null && committee.isNotEmpty) {
        filtered = filtered.where((r) =>
            (r['committee_name'] ?? r['committeeName'])?.toString().toLowerCase() ==
            committee.toLowerCase()).toList();
      }
      if (status != null && status.isNotEmpty) {
        filtered = filtered.where((r) =>
            (r['status'] ?? 'Pending')?.toString().toLowerCase() ==
            status.toLowerCase()).toList();
      }
      return filtered.map(_normalizeTask).toList();
    });
  }

  Map<String, dynamic> _normalizeTask(Map<String, dynamic> row) {
    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'committeeName': row['committee_name'] ?? row['committeeName'] ?? 'General',
      'requestTitle': row['request_title'] ?? row['requestTitle'] ?? row['title'] ?? 'Untitled Request',
      'type': row['type'] ?? 'General',
      'status': row['status'] ?? 'Pending',
      'description': row['description'] ?? '',
      'deadline': row['deadline'] ?? '',
      'requestedBy': row['requested_by'] ?? row['requestedBy'] ?? '',
      'createdAt': row['created_at'],
    };
  }

  @override
  Stream<List<Map<String, dynamic>>> getStudents() {
    return _client
        .from('students')
        .stream(primaryKey: ['id'])
        .order('full_name')
        .map((rows) => rows.map(_normalizeStudent).toList());
  }

  Map<String, dynamic> _normalizeStudent(Map<String, dynamic> row) {
    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'fullName': row['full_name'] ?? row['fullName'] ?? row['name'] ?? 'Unknown',
      'studentID': row['student_id'] ?? row['studentID'] ?? '',
      'course': row['course'] ?? '',
      'prdPrintBalance': (row['prd_print_balance'] as num?)?.toInt() ?? 0,
      'prdPrintTotalAdded': (row['prd_print_total_added'] as num?)?.toInt() ?? 0,
    };
  }

  @override
  Future<void> submitTask(Map<String, dynamic> data) async {
    await _client.from('prd_tasks').insert({
      'committee_name': data['committeeName'] ?? data['committee_name'],
      'request_title': data['requestTitle'] ?? data['request_title'] ?? data['title'],
      'type': data['type'],
      'status': data['status'] ?? 'Pending',
      'description': data['description'],
      'deadline': data['deadline'],
      'requested_by': data['requestedBy'] ?? data['requested_by'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'metadata': data,
    });
  }

  @override
  Future<void> updateTaskStatus(String docId, String status) async {
    await _client.from('prd_tasks').update({
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', docId);
  }

  @override
  Future<void> updateBalance(String docId, String studentID, int amount, bool isAddingDebt) async {
    final student = await _client
        .from('students')
        .select('prd_print_balance, prd_print_total_added')
        .eq('id', docId)
        .maybeSingle();

    final currentBal = (student?['prd_print_balance'] as num?)?.toInt() ?? 0;
    final currentAdded = (student?['prd_print_total_added'] as num?)?.toInt() ?? 0;

    final newBal = isAddingDebt ? currentBal + amount : currentBal - amount;
    final newAdded = isAddingDebt ? currentAdded + amount : currentAdded;

    await _client.from('students').update({
      'prd_print_balance': newBal,
      if (isAddingDebt) 'prd_print_total_added': newAdded,
    }).eq('id', docId);

    await _client.from('prd_payments').insert({
      'student_id': studentID.trim(),
      'amount': amount,
      'type': isAddingDebt ? 'Debt Added' : 'Payment Collected',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteRecord(String docId) async {
    await _client.from('students').update({
      'prd_print_balance': 0,
      'prd_print_total_added': 0,
    }).eq('id', docId);
  }

  @override
  Future<void> deleteTask(String docId) async {
    await _client.from('prd_tasks').delete().eq('id', docId);
  }
}
