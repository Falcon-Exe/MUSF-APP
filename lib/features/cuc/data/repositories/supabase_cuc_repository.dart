// lib/features/cuc/data/repositories/supabase_cuc_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'cuc_repository.dart';

class SupabaseCucRepository implements CucRepository {
  final SupabaseClient _client;

  SupabaseCucRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getNoticesStream() {
    return _client
        .from('cuc_notices')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(_normalizeNotice).toList());
  }

  Map<String, dynamic> _normalizeNotice(Map<String, dynamic> row) {
    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'title': row['title'] ?? '',
      'content': row['content'] ?? '',
      'date': row['date'] ?? '',
      'type': row['type'] ?? 'Custom',
      'createdAt': row['created_at'],
    };
  }

  @override
  Future<void> postNotice({
    required String title,
    required String content,
    required String date,
  }) async {
    await _client.from('cuc_notices').insert({
      'title': title.trim(),
      'content': content.trim(),
      'date': date.trim(),
      'type': 'Custom',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteNotice(String docId) async {
    await _client.from('cuc_notices').delete().eq('id', docId);
  }
}
