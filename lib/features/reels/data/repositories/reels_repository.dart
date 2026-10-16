import 'dart:typed_data';

abstract class ReelsRepository {
  Stream<List<Map<String, dynamic>>> getReelsStream(String committee);

  Future<String> uploadImage(Uint8List bytes, String fileName);

  Future<void> saveReel({
    required String committee,
    required String imageUrl,
    required String caption,
  });

  Future<void> deleteReel(String docId, String imageUrl);
}
