import 'package:flutter/material.dart';
import '../data/repositories/literary_repository.dart';

class LiteraryController extends ChangeNotifier {
  final LiteraryRepository _repository;

  LiteraryController(this._repository);

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getRequestsStream() =>
      _repository.getRequestsStream();
  Stream<List<Map<String, dynamic>>> getStudentRequestsStream(String studentUid) =>
      _repository.getStudentRequestsStream(studentUid);

  Future<void> submitRequest({
    required String title,
    required String author,
    required String studentID,
    required String content,
    required String category,
    String? authorId,
  }) {
    return _repository.submitRequest(
      title: title,
      author: author,
      studentID: studentID,
      content: content,
      category: category,
      authorId: authorId,
    );
  }

  Future<void> updateRequestStatus({
    required String docId,
    required String status,
  }) => _repository.updateRequestStatus(docId: docId, status: status);

  Future<void> deleteRequest(String docId) => _repository.deleteRequest(docId);
}
