import 'package:flutter/material.dart';
import '../data/repositories/library_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryController extends ChangeNotifier {
  final LibraryRepository _repository;

  LibraryController(this._repository);

  String _selectedClass = "All";
  String _searchQuery = "";

  String get selectedClass => _selectedClass;
  String get searchQuery => _searchQuery;

  void setClass(String value) {
    _selectedClass = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> getStudentsStream() => _repository.getStudentsStream();
  Stream<QuerySnapshot> getHistoryStream(String studentID) => _repository.getHistoryStream(studentID);
  Stream<QuerySnapshot> getBooksCatalogStream() => _repository.getBooksCatalogStream();

  Future<void> updateFine({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAdding,
    required int currentFine,
  }) {
    return _repository.updateFine(
      docId: docId,
      studentID: studentID,
      amount: amount,
      isAdding: isAdding,
      currentFine: currentFine,
    );
  }

  Future<void> deleteTransaction({
    required String transId,
    required String studentID,
    required int amount,
    required String type,
  }) {
    return _repository.deleteTransaction(
      transId: transId,
      studentID: studentID,
      amount: amount,
      type: type,
    );
  }

  Future<void> addBook({
    required String title,
    required String author,
    String? imageUrl,
  }) {
    return _repository.addBook(title: title, author: author, imageUrl: imageUrl);
  }

  Future<void> deleteBook(String docId) => _repository.deleteBook(docId);

  Future<void> sendNotice({
    required String studentID,
    required String message,
  }) {
    return _repository.sendNotice(studentID: studentID, message: message);
  }
}
