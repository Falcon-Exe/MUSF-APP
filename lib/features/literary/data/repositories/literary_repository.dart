import 'package:cloud_firestore/cloud_firestore.dart';

abstract class LiteraryRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> getRequestsStream();
  Stream<QuerySnapshot> getStudentRequestsStream(String studentUid);

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
