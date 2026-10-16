// lib/features/cuc/data/repositories/firestore_cuc_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'cuc_repository.dart';

class FirestoreCucRepository implements CucRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getNoticesStream() {
    return _firestore
        .collection('cuc_notices')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  @override
  Future<void> postNotice({
    required String title,
    required String content,
    required String date,
  }) async {
    await _firestore.collection('cuc_notices').add({
      'title': title.trim(),
      'content': content.trim(),
      'date': date.trim(),
      'type': 'Custom',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNotice(String docId) async {
    await _firestore.collection('cuc_notices').doc(docId).delete();
  }
}
