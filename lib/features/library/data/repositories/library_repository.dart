abstract class LibraryRepository {
  Stream<List<Map<String, dynamic>>> getStudentsStream();
  Stream<List<Map<String, dynamic>>> getHistoryStream(String studentID);
  Stream<List<Map<String, dynamic>>> getBooksCatalogStream();

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
