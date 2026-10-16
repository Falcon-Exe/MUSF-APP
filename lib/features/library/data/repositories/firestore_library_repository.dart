import 'package:cloud_firestore/cloud_firestore.dart';
import 'library_repository.dart';

class FirestoreLibraryRepository implements LibraryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> getStudentsStream() {
    return _firestore.collection('students').snapshots();
  }

  @override
  Stream<QuerySnapshot> getHistoryStream(String studentID) {
    return _firestore
        .collection('library_payments')
        .where('studentID', isEqualTo: studentID)
        .orderBy('date', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getBooksCatalogStream() {
    return _firestore
        .collection('library_books')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Future<void> updateFine({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAdding,
    required int currentFine,
  }) async {
    if (amount <= 0) return;
    int newFine = isAdding
        ? (currentFine + amount)
        : (currentFine - amount).clamp(0, 999999);

    await _firestore.collection('students').doc(docId).update({
      'libraryFine': newFine,
      'libraryStatus': newFine == 0 ? "Cleared" : "Pending",
    });

    await _firestore.collection('library_payments').add({
      'studentID': studentID,
      'amount': amount,
      'type': isAdding ? 'Addition' : 'Deduction',
      'date': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTransaction({
    required String transId,
    required String studentID,
    required int amount,
    required String type,
  }) async {
    await _firestore.collection('library_payments').doc(transId).delete();

    var studentQuery = await _firestore
        .collection('students')
        .where('studentID', isEqualTo: studentID)
        .limit(1)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      var doc = studentQuery.docs.first;
      int currentFine = int.tryParse(doc['libraryFine']?.toString() ?? '0') ?? 0;

      int updatedFine = (type == 'Addition')
          ? (currentFine - amount).clamp(0, 999999)
          : (currentFine + amount);

      await doc.reference.update({
        'libraryFine': updatedFine,
        'libraryStatus': updatedFine == 0 ? "Cleared" : "Pending",
      });
    }
  }

  @override
  Future<void> addBook({
    required String title,
    required String author,
    String? imageUrl,
  }) async {
    await _firestore.collection('library_books').add({
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteBook(String docId) async {
    await _firestore.collection('library_books').doc(docId).delete();
  }

  @override
  Future<void> sendNotice({
    required String studentID,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'studentID': studentID,
      'title': 'Library Notice',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'library_notice',
    });
  }
}
