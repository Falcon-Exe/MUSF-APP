// lib/features/cuc/data/repositories/cuc_repository.dart

abstract class CucRepository {
  Stream<List<Map<String, dynamic>>> getNoticesStream();
  Future<void> postNotice({
    required String title,
    required String content,
    required String date,
  });
  Future<void> deleteNotice(String docId);
}
