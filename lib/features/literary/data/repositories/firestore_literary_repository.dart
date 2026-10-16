import 'package:cloud_firestore/cloud_firestore.dart';
import 'literary_repository.dart';

class FirestoreLiteraryRepository implements LiteraryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRequestsStream() {
    return _firestore
        .collection('literary_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getStudentRequestsStream(String studentUid) {
    return _firestore
        .collection('literary_requests')
        .where('authorId', isEqualTo: studentUid)
        .snapshots();
  }

  @override
  Future<void> submitRequest({
    required String title,
    required String author,
    required String studentID,
    required String content,
    required String category,
    String? authorId,
  }) async {
    await _firestore.collection('literary_requests').add({
      'title': title,
      'author': author,
      'studentID': studentID,
      'content': content,
      'category': category,
      'authorId': authorId,
      'status': 'pending',
      'date': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateRequestStatus({
    required String docId,
    required String status,
  }) async {
    await _firestore.collection('literary_requests').doc(docId).update({
      'status': status,
    });
  }

  @override
  Future<void> deleteRequest(String docId) async {
    await _firestore.collection('literary_requests').doc(docId).delete();
  }
}
