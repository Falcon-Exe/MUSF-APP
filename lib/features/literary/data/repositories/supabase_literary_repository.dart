import 'package:supabase_flutter/supabase_flutter.dart';
import 'literary_repository.dart';

class SupabaseLiteraryRepository implements LiteraryRepository {
  final SupabaseClient _client;

  SupabaseLiteraryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getRequestsStream() {
    return _client
        .from('literary_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> getStudentRequestsStream(String studentUid) {
    return _client
        .from('literary_requests')
        .stream(primaryKey: ['id'])
        .eq('author_id', studentUid)
        .order('created_at', ascending: false);
  }

  @override
  Future<void> submitRequest({
    required String title,
    required String author,
    required String studentID,
    required String content,
    required String category,
    String? authorId,
  }) async {
    await _client.from('literary_requests').insert({
      'title': title,
      'author': author,
      'student_id': studentID,
      'content': content,
      'category': category,
      'author_id': authorId,
      'status': 'pending',
      'date': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateRequestStatus({
    required String docId,
    required String status,
  }) async {
    await _client
        .from('literary_requests')
        .update({'status': status})
        .eq('id', docId);
  }

  @override
  Future<void> deleteRequest(String docId) async {
    await _client.from('literary_requests').delete().eq('id', docId);
  }
}
