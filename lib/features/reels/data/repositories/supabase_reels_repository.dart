import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/cloud_storage_service.dart';
import 'reels_repository.dart';

class SupabaseReelsRepository implements ReelsRepository {
  final SupabaseClient _client;

  SupabaseReelsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getReelsStream(String committee) {
    return _client
        .from('committee_reels')
        .stream(primaryKey: ['id'])
        .eq('committee', committee)
        .order('created_at', ascending: false);
  }

  @override
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final upload = await CloudStorageService().uploadBytes(
      bytes: bytes,
      folder: CloudStorageFolder.reelVideos,
      fileName: fileName,
      contentType: 'image/jpeg',
    );
    return upload.url;
  }

  @override
  Future<void> saveReel({
    required String committee,
    required String imageUrl,
    required String caption,
  }) async {
    await _client.from('committee_reels').insert({
      'committee': committee,
      'image_url': imageUrl,
      'caption': caption.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteReel(String docId, String imageUrl) async {
    await _client.from('committee_reels').delete().eq('id', docId);
    if (imageUrl.isNotEmpty) {
      try {
        await CloudStorageService().deleteFile(fileUrl: imageUrl);
      } catch (_) {
        // Storage deletion failed or file missing, proceed
      }
    }
  }
}
