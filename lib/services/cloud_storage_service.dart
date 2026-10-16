import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../core/storage/r2_storage_config.dart';
import '../core/storage/r2_upload_service.dart';

enum CloudStorageFolder {
  homeBackgrounds('home/backgrounds'),
  homeSlides('home/slides'),
  studentProfileImages('students/profile_images'),
  executiveProfileImages('executive/profile_images'),
  committeeImages('committees/images'),
  eventPhotos('events/photos'),
  researchPapers('research/papers'),
  reportPdfs('reports/pdf'),
  reelVideos('reels/videos'),
  prdPosters('prd/posters');

  const CloudStorageFolder(this.path);
  final String path;
}

class CloudStorageUpload {
  const CloudStorageUpload({
    required this.url,
    required this.key,
    required this.contentType,
    required this.sizeBytes,
    required this.fileName,
  });

  final String url;
  final String key;
  final String contentType;
  final int sizeBytes;
  final String fileName;
}

class CloudStorageService {
  CloudStorageService({R2UploadService? uploadService, http.Client? httpClient})
    : _uploadService = uploadService ?? R2UploadService(),
      _httpClient = httpClient;

  final R2UploadService _uploadService;
  final http.Client? _httpClient;

  Future<CloudStorageUpload?> uploadImage({
    CloudStorageFolder folder = CloudStorageFolder.committeeImages,
    String? fileNamePrefix,
  }) {
    return uploadFile(
      folder: folder,
      fileNamePrefix: fileNamePrefix,
      type: FileType.image,
    );
  }

  Future<CloudStorageUpload?> uploadPdf({
    CloudStorageFolder folder = CloudStorageFolder.reportPdfs,
    String? fileNamePrefix,
  }) {
    return uploadFile(
      folder: folder,
      fileNamePrefix: fileNamePrefix,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      fallbackContentType: 'application/pdf',
    );
  }

  Future<CloudStorageUpload?> uploadVideo({
    CloudStorageFolder folder = CloudStorageFolder.reelVideos,
    String? fileNamePrefix,
  }) {
    return uploadFile(
      folder: folder,
      fileNamePrefix: fileNamePrefix,
      type: FileType.video,
      allowedExtensions: const ['mp4', 'mov', 'webm', 'm4v'],
    );
  }

  Future<CloudStorageUpload?> uploadFile({
    required CloudStorageFolder folder,
    String? fileNamePrefix,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    String? fallbackContentType,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? allowedExtensions : null,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;

    return uploadBytes(
      bytes: bytes,
      folder: folder,
      fileName: _buildFileName(file, fileNamePrefix),
      contentType:
          _contentType(file.extension, fallback: fallbackContentType) ??
          'application/octet-stream',
    );
  }

  Future<CloudStorageUpload> uploadBytes({
    required Uint8List bytes,
    required CloudStorageFolder folder,
    required String fileName,
    required String contentType,
  }) async {
    final result = await _uploadService.uploadBytes(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      folder: folder.path,
    );

    return CloudStorageUpload(
      url: result.url,
      key: result.key,
      contentType: result.contentType,
      sizeBytes: result.sizeBytes,
      fileName: fileName,
    );
  }

  Future<void> deleteFile({String? key, String? fileUrl}) async {
    if (!R2StorageConfig.canDelete) {
      if (key != null && key.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref().child(key).delete();
          return;
        } catch (e) {
          throw StateError('Firebase Storage delete failed: $e');
        }
      }
      return;
    }

    final client = _httpClient ?? http.Client();
    final ownsClient = _httpClient == null;

    try {
      final response = await client.post(
        Uri.parse(R2StorageConfig.deleteEndpoint),
        headers: await _jsonHeaders(),
        body: jsonEncode({'key': key, 'fileUrl': fileUrl}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Could not delete cloud file (${response.statusCode}): ${response.body}',
        );
      }
    } finally {
      if (ownsClient) client.close();
    }
  }

  String getPublicUrl(String urlOrKey) {
    return urlOrKey.trim();
  }

  Future<Map<String, String>> _jsonHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token =
        supabase.Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _buildFileName(PlatformFile file, String? prefix) {
    final rawName = file.name.trim().isNotEmpty
        ? file.name.trim()
        : 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final safePrefix = prefix
        ?.trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safePrefix == null || safePrefix.isEmpty) return rawName;
    return '${safePrefix}_$rawName';
  }

  String? _contentType(String? extension, {String? fallback}) {
    switch (extension?.toLowerCase().trim()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'm4v':
        return 'video/x-m4v';
      default:
        return fallback;
    }
  }
}
