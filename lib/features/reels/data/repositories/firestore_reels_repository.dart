import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../../../../services/cloud_storage_service.dart';
import 'reels_repository.dart';

class FirestoreReelsRepository implements ReelsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> getReelsStream(String committee) {
    return _firestore
        .collection('committee_reels')
        .where('committee', isEqualTo: committee)
        .snapshots();
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
    await _firestore.collection('committee_reels').add({
      'committee': committee,
      'imageUrl': imageUrl,
      'caption': caption.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteReel(String docId, String imageUrl) async {
    await _firestore.collection('committee_reels').doc(docId).delete();
    if (imageUrl.isNotEmpty) {
      try {
        await CloudStorageService().deleteFile(fileUrl: imageUrl);
      } catch (e) {
        // Storage deletion failed or file missing, proceed
      }
    }
  }
}
