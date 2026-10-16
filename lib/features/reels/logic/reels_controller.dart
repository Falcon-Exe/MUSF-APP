import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../data/repositories/reels_repository.dart';

class ReelsController extends ChangeNotifier {
  final ReelsRepository _repository;

  ReelsController(this._repository);

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  final TextEditingController captionController = TextEditingController();

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;

    if (bytes != null) {
      _imageBytes = bytes;
      notifyListeners();
    }
  }

  void clearSelection() {
    _imageBytes = null;
    captionController.clear();
    notifyListeners();
  }

  Future<bool> uploadReel(String committee) async {
    if (_imageBytes == null) return false;

    _isUploading = true;
    notifyListeners();

    try {
      String fileName =
          "${committee}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      String downloadUrl = await _repository.uploadImage(
        _imageBytes!,
        fileName,
      );
      await _repository.saveReel(
        committee: committee,
        imageUrl: downloadUrl,
        caption: captionController.text,
      );
      clearSelection();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Stream getReelsStream(String committee) =>
      _repository.getReelsStream(committee);
  Future<void> deleteReel(String docId, String imageUrl) =>
      _repository.deleteReel(docId, imageUrl);

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }
}
