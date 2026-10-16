// lib/features/home/data/repositories/home_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HomeRepository {
  Stream<List<Map<String, dynamic>>> getUnreadNotifications(String studentID);
  Future<void> markAsRead(List<String> notificationIds);
}

class SupabaseHomeRepository implements HomeRepository {
  final SupabaseClient _client;

  SupabaseHomeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getUnreadNotifications(String studentID) {
    final lowerStudentID = studentID.toLowerCase().trim();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.where((row) {
              final sid = (row['student_id'] ?? '').toString().toLowerCase().trim();
              final isRead = row['is_read'] == true;
              return !isRead &&
                  (sid == lowerStudentID ||
                      sid == 'all' ||
                      sid == 'admin');
            }).toList());
  }

  @override
  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .filter('id', 'in', notificationIds);
  }
}
