// lib/features/arts/data/repositories/arts_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ArtsRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream();
  Future<void> addEvent(String title, String type);
  Future<void> updateResults(String docId, Map<String, dynamic> data);
  Future<void> deleteEvent(String docId);
}

class FirestoreArtsRepository implements ArtsRepository {
  final FirebaseFirestore _firestore;

  FirestoreArtsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _firestore
        .collection('arts_events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  @override
  Future<void> addEvent(String title, String type) async {
    await _firestore.collection('arts_events').add({
      'title': title,
      'type': type,
      'resultsPublished': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateResults(String docId, Map<String, dynamic> data) async {
    await _firestore.collection('arts_events').doc(docId).update(data);
  }

  @override
  Future<void> deleteEvent(String docId) async {
    await _firestore.collection('arts_events').doc(docId).delete();
  }
}
