// lib/features/leadership/data/repositories/announcement_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementRepository {
  final SupabaseClient _client;

  AnnouncementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getAnnouncementsStream({String? committeeName}) {
    return _client
        .from('executive_announcements')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false);
  }

  Future<void> sendAnnouncement({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String targetType, // 'all', 'committee', 'students', 'admins'
    String? targetCommittee,
    required String priority, // 'normal', 'important'
  }) async {
    await _client.from('executive_announcements').insert({
      'title': title,
      'message': message,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'target_type': targetType,
      'target_committee': targetCommittee,
      'priority': priority,
      'is_active': true,
    });

    // Mirror to notifications table for the bell icon
    String targetID = 'all';
    if (targetType == 'committee' && targetCommittee != null) {
      targetID = 'committee_$targetCommittee';
    } else if (targetType == 'admins') {
      targetID = 'admin';
    }

    await _client.from('notifications').insert({
      'student_id': targetID,
      'title': title,
      'message': message,
      'is_read': false,
      'type': 'executive_announcement',
      'priority': priority,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client
        .from('executive_announcements')
        .update({'is_active': false})
        .eq('id', id);
  }
}
