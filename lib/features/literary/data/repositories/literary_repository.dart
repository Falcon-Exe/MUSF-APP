abstract class LiteraryRepository {
  Stream<List<Map<String, dynamic>>> getRequestsStream();
  Stream<List<Map<String, dynamic>>> getStudentRequestsStream(String studentUid);

  Future<void> submitRequest({
    required String title,
    required String author,
    required String studentID,
    required String content,
    required String category,
    String? authorId,
  });

  Future<void> updateRequestStatus({
    required String docId,
    required String status,
  });

  Future<void> deleteRequest(String docId);
}
