import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'leadership_repository.dart';

class SupabaseLeadershipRepository implements LeadershipRepository {
  SupabaseLeadershipRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> getLeadersStream() {
    return _client
        .from('leadership')
        .stream(primaryKey: ['id'])
        .order('display_order')
        .map((rows) => rows.map(_normalizeLeaderRow).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getComplaintsStream() {
    return _client
        .from('complaints')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => {
              ...r,
              'id': r['id']?.toString() ?? '',
              'studentID': r['student_id'] ?? r['studentID'] ?? '',
              'createdAt': r['created_at'],
            }).toList());
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveLeaders() async {
    final rows = await _client
        .from('leadership')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(
      rows.map((row) => _normalizeLeaderRow(Map<String, dynamic>.from(row))),
    );
  }

  @override
  Future<void> saveLeader({
    String? docId,
    required String name,
    required String role,
    required int order,
    required String colorHex,
    required String iconName,
    String? imageUrl,
    Uint8List? imageBytes,
    String? backgroundImageUrl,
    bool isActive = true,
  }) async {
    final finalImageUrl = imageUrl;

    final payload = {
      'name': name.trim(),
      'role': role.trim(),
      'image_url': finalImageUrl,
      'background_image_url': backgroundImageUrl?.trim().isEmpty == true
          ? null
          : backgroundImageUrl?.trim(),
      'display_order': order,
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'color_hex': colorHex.trim(),
      'icon_name': iconName,
      'metadata': {
        'full_name': name.trim(),
        'designation': role.trim(),
        'role_description': role.trim(),
        'profile_image_url': finalImageUrl,
      },
    };

    if (docId != null && docId.isNotEmpty) {
      await _client.from('leadership').update(payload).eq('id', docId);
    } else {
      await _client.from('leadership').insert({
        ...payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  @override
  Future<void> deactivateLeader(String docId) async {
    await _client
        .from('leadership')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', docId);
  }

  @override
  Future<void> deleteLeader(String docId) async {
    await _client.from('leadership').delete().eq('id', docId);
  }

  @override
  Future<void> deleteComplaint(String docId) async {
    await _client.from('complaints').delete().eq('id', docId);
  }

  Map<String, dynamic> _normalizeLeaderRow(Map<String, dynamic> row) {
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : <String, dynamic>{};

    return {
      ...row,
      'name': row['full_name'] ?? metadata['full_name'] ?? row['name'],
      'role': row['designation'] ?? metadata['designation'] ?? row['role'],
      'order': row['display_order'] ?? row['order'] ?? 99,
      'colorHex':
          row['color_hex'] ??
          metadata['colorHex'] ??
          row['colorHex'] ??
          '0xFF6366F1',
      'iconName':
          row['icon_name'] ??
          metadata['iconName'] ??
          row['iconName'] ??
          'person_rounded',
      'imageUrl':
          row['profile_image_url'] ??
          metadata['profile_image_url'] ??
          row['image_url'] ??
          row['imageUrl'],
      'backgroundImageUrl':
          row['background_image_url'] ?? row['backgroundImageUrl'],
      'isActive': row['is_active'] ?? row['isActive'] ?? true,
    };
  }
}
