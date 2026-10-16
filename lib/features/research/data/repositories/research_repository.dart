// lib/features/research/data/repositories/research_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'dart:async';

abstract class ResearchRepository {
  Stream<List<Map<String, dynamic>>> getRequests();
  Stream<List<Map<String, dynamic>>> getMySubmissions();
  Future<void> submitPaper(Map<String, dynamic> data);
  Future<void> publishPaper(Map<String, dynamic> data);
  Future<void> approveRequest(String docId, Map<String, dynamic> data);
  Future<void> rejectRequest(String docId, Map<String, dynamic> data);
  Future<void> deleteRequest(String docId);
  Future<void> deletePublishedPaper(String docId);
  Future<void> toggleLike(String docId, bool isLiked);
  Future<void> archivePublication(String docId);
  Future<List<Map<String, dynamic>>> fetchResearchRecords({
    required String committeeName,
    required String statusGroup,
  });
}

class SupabaseResearchRepository implements ResearchRepository {
  final supabase.SupabaseClient _client;

  SupabaseResearchRepository({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getRequests() {
    // Returns drafts (pending requests) for admin
    return _client.from('research_works').stream(primaryKey: ['id']).map((
      list,
    ) {
      return list.where((item) => item['status'] == 'draft').toList();
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getMySubmissions() {
    final user = _client.auth.currentUser;
    final email = user?.email ?? '';

    // Stream all and filter by current student's email/ID or file_url locally
    return _client.from('research_works').stream(primaryKey: ['id']).asyncMap((
      list,
    ) async {
      // Find student ID associated with this auth email
      String studentId = '';
      if (email.isNotEmpty) {
        try {
          final studentRow = await _client
              .from('students')
              .select('student_id')
              .eq('auth_email', email)
              .maybeSingle();
          studentId = studentRow?['student_id']?.toString() ?? '';
        } catch (e) {
          // fallback
        }
      }
      return list.where((item) {
        final fileUrl = item['file_url']?.toString() ?? '';
        return fileUrl == studentId || item['author_name'] == email;
      }).toList();
    });
  }

  @override
  Future<void> submitPaper(Map<String, dynamic> data) async {
    final field = data['field']?.toString();
    final bodyText =
        data['description']?.toString() ?? data['abstract']?.toString() ?? '';
    final description = field == null || field.isEmpty
        ? bodyText
        : '[$field] $bodyText';
    final status = data['status']?.toString() ?? 'draft';
    final now = DateTime.now().toIso8601String();
    final insertData = <String, dynamic>{
      'title': data['title'],
      'author_name': data['author_name'] ?? data['author'],
      'description': description,
      'file_url':
          data['file_url'] ??
          data['pdf_url'] ??
          data['fileUrl'] ??
          data['studentID'],
      'pdf_url': data['pdf_url'] ?? data['file_url'] ?? data['fileUrl'],
      'status': status,
      'created_at': data['created_at'] ?? now,
      'updated_at': data['updated_at'] ?? now,
    };

    if (status == 'published' || status == 'archived') {
      insertData['published_at'] = data['published_at'] ?? now;
    }

    await _client.from('research_works').insert(insertData);
  }

  @override
  Future<void> publishPaper(Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('research_works').insert({
      'title': data['title'],
      'description': data['description'],
      'full_paper': data['full_paper'] ?? data['description'],
      'author_name': data['author_name'],
      'category': data['category'],
      'file_url': data['file_url'] ?? data['pdf_url'],
      'pdf_url': data['pdf_url'] ?? data['file_url'],
      'status': 'published',
      'published_at': now,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> approveRequest(String docId, Map<String, dynamic> data) async {
    await _client
        .from('research_works')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', docId);
  }

  @override
  Future<void> rejectRequest(String docId, Map<String, dynamic> data) async {
    // Rejection archives the record
    await _client
        .from('research_works')
        .update({
          'status': 'archived',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', docId);
  }

  @override
  Future<void> archivePublication(String docId) async {
    await _client
        .from('research_works')
        .update({
          'status': 'archived',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', docId);
  }

  @override
  Future<void> deleteRequest(String docId) async {
    await _client.from('research_works').delete().eq('id', docId);
  }

  @override
  Future<void> deletePublishedPaper(String docId) async {
    await _client.from('research_works').delete().eq('id', docId);
  }

  @override
  Future<void> toggleLike(String docId, bool isLiked) async {
    // research_works does not have likes_count in specified fields, so this is a no-op
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResearchRecords({
    required String committeeName,
    required String statusGroup,
  }) async {
    if (statusGroup == 'history') {
      final response = await _client
          .from('research_works')
          .select()
          .eq('status', 'published');
      return List<Map<String, dynamic>>.from(response);
    }

    // statusGroup: 'dashboard' (draft, published), or archive (published, archived)
    final response = await _client.from('research_works').select();

    final list = List<Map<String, dynamic>>.from(response);
    if (statusGroup == 'dashboard') {
      return list.where((item) {
        final status = item['status']?.toString() ?? 'draft';
        return status == 'draft' || status == 'published';
      }).toList();
    } else {
      return list.where((item) {
        final status = item['status']?.toString() ?? 'draft';
        return status == 'published' || status == 'archived';
      }).toList();
    }
  }
}
