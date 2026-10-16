// lib/features/social_affairs/data/repositories/supabase_social_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_repository.dart';

class SupabaseSocialRepository implements SocialRepository {
  final SupabaseClient _client;

  SupabaseSocialRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getCssWorksStream() {
    return _client
        .from('social_css_works')
        .stream(primaryKey: ['id'])
        .order('date_added', ascending: false)
        .map((rows) => rows.map(_normalizeCssWork).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getExamsStream() {
    return _client
        .from('social_exams')
        .stream(primaryKey: ['id'])
        .order('date')
        .map((rows) => rows.map(_normalizeExam).toList());
  }

  Map<String, dynamic> _normalizeCssWork(Map<String, dynamic> row) {
    DateTime? startDate;
    DateTime? endDate;
    if (row['start_date'] != null) {
      startDate = DateTime.tryParse(row['start_date'].toString());
    }
    if (row['end_date'] != null) {
      endDate = DateTime.tryParse(row['end_date'].toString());
    }

    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'title': row['title'] ?? '',
      'instruction': row['instruction'] ?? '',
      'startDate': startDate,
      'endDate': endDate,
      'dateAdded': row['date_added'],
    };
  }

  Map<String, dynamic> _normalizeExam(Map<String, dynamic> row) {
    DateTime date = DateTime.now();
    if (row['date'] != null) {
      date = DateTime.tryParse(row['date'].toString()) ?? DateTime.now();
    }

    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'subject': row['subject'] ?? '',
      'date': date,
      'location': row['location'] ?? 'TBD',
      'createdAt': row['created_at'],
    };
  }

  @override
  Future<void> addCssWork({
    required String title,
    required String instruction,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _client.from('social_css_works').insert({
      'title': title.trim(),
      'instruction': instruction.trim(),
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'date_added': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> addExam({
    required String subject,
    required DateTime date,
    required String location,
  }) async {
    await _client.from('social_exams').insert({
      'subject': subject.trim(),
      'date': date.toUtc().toIso8601String(),
      'location': location.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCssWork(String docId) async {
    await _client.from('social_css_works').delete().eq('id', docId);
  }

  @override
  Future<void> deleteExam(String docId) async {
    await _client.from('social_exams').delete().eq('id', docId);
  }
}
