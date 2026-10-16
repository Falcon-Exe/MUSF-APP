// lib/features/sports/data/repositories/sports_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SportsRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream();
  Future<void> addEvent(String title, String category);
  Future<void> updateResults(String docId, Map<String, dynamic> data);
  Future<void> deleteEvent(String docId);
}

class FirestoreSportsRepository implements SportsRepository {
  final FirebaseFirestore _firestore;

  FirestoreSportsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getEventsStream() {
    return _firestore
        .collection('sports_events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  @override
  Future<void> addEvent(String title, String category) async {
    await _firestore.collection('sports_events').add({
      'title': title,
      'category': category,
      'resultsPublished': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateResults(String docId, Map<String, dynamic> data) async {
    await _firestore.collection('sports_events').doc(docId).update(data);
  }

  @override
  Future<void> deleteEvent(String docId) async {
    await _firestore.collection('sports_events').doc(docId).delete();
  }
}
