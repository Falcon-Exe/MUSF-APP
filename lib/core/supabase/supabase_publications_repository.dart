import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePublicationsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchPublications({
    required String committeeName,
  }) async {
    final response = await _client
        .from('publications')
        .select()
        .eq('committee_name', committeeName)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      response.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Stream<List<Map<String, dynamic>>> watchPublications({
    required String committeeName,
  }) {
    return _client
        .from('publications')
        .stream(primaryKey: ['id'])
        .eq('committee_name', committeeName)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows.map((row) => Map<String, dynamic>.from(row)).toList(),
        );
  }

  Future<void> createPublication({
    required String committeeName,
    required String title,
    required String content,
    required String category,
    required String authorName,
    String? imageUrl,
  }) async {
    await _client.from('publications').insert({
      'committee_name': committeeName,
      'title': title,
      'content': content,
      'category': category,
      'author_name': authorName,
      'image_url': imageUrl,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deletePublication(String id) async {
    await _client.from('publications').delete().eq('id', id);
  }

  Future<void> updatePublication({
    required String id,
    required String title,
    required String content,
    required String category,
    required String authorName,
    String? imageUrl,
  }) async {
    await _client
        .from('publications')
        .update({
          'title': title,
          'content': content,
          'category': category,
          'author_name': authorName,
          'image_url': imageUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> updateLikeCount({
    required String id,
    required int likesCount,
  }) async {
    await _client
        .from('publications')
        .update({
          'likes_count': likesCount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
