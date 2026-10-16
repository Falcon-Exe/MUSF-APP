// lib/features/arts/data/repositories/supabase_arts_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'arts_repository.dart';

class SupabaseArtsRepository implements ArtsRepository {
  final SupabaseClient _client;

  SupabaseArtsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _client
        .from('arts_events')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(_normalizeEvent).toList());
  }

  Map<String, dynamic> _normalizeEvent(Map<String, dynamic> row) {
    return {
      ...row,
      'id': row['id']?.toString() ?? '',
      'title': row['title'] ?? '',
      'type': row['type'] ?? 'Stage',
      'resultsPublished': row['results_published'] ?? false,
      'firstPlaceId': row['first_place_id'] ?? '',
      'firstPlaceName': row['first_place_name'] ?? '',
      'secondPlaceId': row['second_place_id'] ?? '',
      'secondPlaceName': row['second_place_name'] ?? '',
      'thirdPlaceId': row['third_place_id'] ?? '',
      'thirdPlaceName': row['third_place_name'] ?? '',
      'createdAt': row['created_at'],
    };
  }

  @override
  Future<void> addEvent(String title, String type) async {
    await _client.from('arts_events').insert({
      'title': title.trim(),
      'type': type.trim(),
      'results_published': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateResults(String docId, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{};
    if (data.containsKey('firstPlaceId')) payload['first_place_id'] = data['firstPlaceId'];
    if (data.containsKey('firstPlaceName')) payload['first_place_name'] = data['firstPlaceName'];
    if (data.containsKey('secondPlaceId')) payload['second_place_id'] = data['secondPlaceId'];
    if (data.containsKey('secondPlaceName')) payload['second_place_name'] = data['secondPlaceName'];
    if (data.containsKey('thirdPlaceId')) payload['third_place_id'] = data['thirdPlaceId'];
    if (data.containsKey('thirdPlaceName')) payload['third_place_name'] = data['thirdPlaceName'];
    if (data.containsKey('resultsPublished')) payload['results_published'] = data['resultsPublished'];

    data.forEach((k, v) {
      if (!payload.containsKey(k) && !k.contains('Place') && k != 'resultsPublished') {
        payload[k] = v;
      }
    });

    await _client.from('arts_events').update(payload).eq('id', docId);
  }

  @override
  Future<void> deleteEvent(String docId) async {
    await _client.from('arts_events').delete().eq('id', docId);
  }
}
