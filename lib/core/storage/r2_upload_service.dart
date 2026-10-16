import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'r2_storage_config.dart';

class R2UploadResult {
  const R2UploadResult({
    required this.url,
    required this.key,
    required this.contentType,
    required this.sizeBytes,
  });

  final String url;
  final String key;
  final String contentType;
  final int sizeBytes;
}

class R2UploadService {
  R2UploadService({http.Client? httpClient}) : _httpClient = httpClient;

  final http.Client? _httpClient;

  Future<R2UploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String folder,
  }) async {
    if (!R2StorageConfig.isConfigured) {
      try {
        final sanitizedKey = '${_sanitizeFolder(folder)}/${_sanitizeFileName(fileName)}';
        final storageRef = FirebaseStorage.instance.ref().child(sanitizedKey);
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
        final downloadUrl = await storageRef.getDownloadURL();
        return R2UploadResult(
          url: downloadUrl,
          key: sanitizedKey,
          contentType: contentType,
          sizeBytes: bytes.length,
        );
      } catch (e) {
        throw StateError('Firebase Storage upload failed: $e');
      }
    }

    final client = _httpClient ?? http.Client();
    final ownsClient = _httpClient == null;

    try {
      final signResponse = await client.post(
        Uri.parse(R2StorageConfig.signerEndpoint),
        headers: await _jsonHeaders(),
        body: jsonEncode({
          'fileName': _sanitizeFileName(fileName),
          'contentType': contentType,
          'folder': _sanitizeFolder(folder),
          'sizeBytes': bytes.length,
        }),
      );

      if (signResponse.statusCode < 200 || signResponse.statusCode >= 300) {
        throw StateError(
          'Could not create R2 upload URL (${signResponse.statusCode}): ${signResponse.body}',
        );
      }

      final payload = jsonDecode(signResponse.body) as Map<String, dynamic>;
      final uploadUrl = payload['uploadUrl']?.toString() ?? '';
      final fileUrl =
          payload['fileUrl']?.toString() ??
          payload['publicUrl']?.toString() ??
          payload['signedUrl']?.toString() ??
          payload['url']?.toString() ??
          '';
      final key = payload['key']?.toString() ?? '';

      if (uploadUrl.isEmpty || fileUrl.isEmpty || key.isEmpty) {
        throw StateError(
          'R2 signer response is missing uploadUrl, fileUrl, or key.',
        );
      }

      final uploadResponse = await client.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
        throw StateError(
          'R2 upload failed (${uploadResponse.statusCode}): ${uploadResponse.body}',
        );
      }

      return R2UploadResult(
        url: fileUrl,
        key: key,
        contentType: contentType,
        sizeBytes: bytes.length,
      );
    } finally {
      if (ownsClient) client.close();
    }
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

  String _sanitizeFileName(String value) {
    final name = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return name.isEmpty
        ? 'upload_${DateTime.now().millisecondsSinceEpoch}'
        : name;
  }

  String _sanitizeFolder(String value) {
    return value
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-'))
        .join('/');
  }
}
