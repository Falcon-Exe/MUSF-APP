// lib/features/social_affairs/data/repositories/social_repository.dart

abstract class SocialRepository {
  Stream<List<Map<String, dynamic>>> getCssWorksStream();
  Stream<List<Map<String, dynamic>>> getExamsStream();

  Future<void> addCssWork({
    required String title,
    required String instruction,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> addExam({
    required String subject,
    required DateTime date,
    required String location,
  });

  Future<void> deleteCssWork(String docId);
  Future<void> deleteExam(String docId);
}
