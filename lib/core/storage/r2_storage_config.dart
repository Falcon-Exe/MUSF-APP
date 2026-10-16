import 'package:flutter_dotenv/flutter_dotenv.dart';

class R2StorageConfig {
  const R2StorageConfig._();

  static String get signerEndpoint =>
      dotenv.env['R2_SIGN_UPLOAD_ENDPOINT']?.trim() ?? '';

  static String get deleteEndpoint =>
      dotenv.env['R2_DELETE_FILE_ENDPOINT']?.trim() ?? '';

  static bool get isConfigured => signerEndpoint.isNotEmpty;

  static bool get canDelete => deleteEndpoint.isNotEmpty;
}
