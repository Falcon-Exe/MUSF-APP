// lib/features/schedule/data/repositories/supabase_schedule_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'schedule_repository.dart';

class SupabaseScheduleRepository implements ScheduleRepository {
  final SupabaseClient _client;

  SupabaseScheduleRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getEventsStream({String? committee}) {
    final stream = _client
        .from('union_schedule')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((rows) {
      var filtered = rows;
      if (committee != null && committee.isNotEmpty) {
        filtered = filtered
            .where((r) =>
                (r['committee']?.toString().toLowerCase() ?? '') ==
                committee.toLowerCase())
            .toList();
      }
      return filtered.map(_normalizeEvent).toList();
    });
  }

  Map<String, dynamic> _normalizeEvent(Map<String, dynamic> row) {
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : <String, dynamic>{};

    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'title': row['title'] ?? 'Untitled',
      'dateString': row['date_string'] ?? row['dateString'] ?? '',
      'timeString': row['time_string'] ?? row['timeString'] ?? '',
      'committee': row['committee'] ?? 'General',
      'image_url': row['image_url'] ?? metadata['image_url'] ?? '',
      'createdAt': row['created_at'],
    };
  }

  @override
  Future<void> addEvent({
    required String title,
    required String dateString,
    required String timeString,
    required String committee,
    String? imageUrl,
  }) async {
    await _client.from('union_schedule').insert({
      'title': title,
      'date_string': dateString,
      'time_string': timeString,
      'committee': committee,
      'metadata': {
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      },
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('union_schedule').delete().eq('id', id);
  }
}
