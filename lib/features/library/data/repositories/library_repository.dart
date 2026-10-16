import 'package:cloud_firestore/cloud_firestore.dart';

abstract class LibraryRepository {
  Stream<QuerySnapshot> getStudentsStream();
  Stream<QuerySnapshot> getHistoryStream(String studentID);
  Stream<QuerySnapshot> getBooksCatalogStream();
  
  Future<void> updateFine({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAdding,
    required int currentFine,
  });

  Future<void> deleteTransaction({
    required String transId,
    required String studentID,
    required int amount,
    required String type,
  });

  Future<void> addBook({
    required String title,
    required String author,
    String? imageUrl,
  });

  Future<void> deleteBook(String docId);
  
  Future<void> sendNotice({
    required String studentID,
    required String message,
  });
}
