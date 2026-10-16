import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'r2_upload_service.dart';

class FileMetadataRepository {
  FileMetadataRepository({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  final supabase.SupabaseClient _client;

  Future<void> create({
    required String ownerTable,
    String? ownerId,
    required R2UploadResult upload,
    String? bucket,
    String visibility = 'public',
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('file_metadata').insert({
      'owner_table': ownerTable,
      'owner_id': ownerId,
      'r2_key': upload.key,
      'bucket': bucket,
      'file_url': upload.url,
      _urlColumnFor(upload.contentType): upload.url,
      'content_type': upload.contentType,
      'size_bytes': upload.sizeBytes,
      'uploaded_by': _client.auth.currentUser?.id,
      'visibility': visibility,
      'metadata': metadata ?? <String, dynamic>{},
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String _urlColumnFor(String contentType) {
    if (contentType.startsWith('image/')) return 'image_url';
    if (contentType.startsWith('video/')) return 'video_url';
    if (contentType == 'application/pdf') return 'pdf_url';
    return 'file_url';
  }
}
