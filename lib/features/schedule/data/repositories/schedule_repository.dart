// lib/features/schedule/data/repositories/schedule_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ScheduleRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream({String? committee});
  Future<void> addEvent({
    required String title,
    required String dateString,
    required String timeString,
    required String committee,
    String? imageUrl,
  });
  Future<void> deleteEvent(String id);
}

class FirestoreScheduleRepository implements ScheduleRepository {
  final FirebaseFirestore _firestore;

  FirestoreScheduleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _eventsRef => _firestore
      .collection('artifacts')
      .doc('union-hostel-app')
      .collection('public')
      .doc('data')
      .collection('union_schedule');

  @override
  Stream<List<Map<String, dynamic>>> getEventsStream({String? committee}) {
    Query query = _eventsRef.orderBy('createdAt', descending: true);
    if (committee != null && committee.isNotEmpty) {
      query = query.where('committee', isEqualTo: committee);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
        .toList());
  }

  @override
  Future<void> addEvent({
    required String title,
    required String dateString,
    required String timeString,
    required String committee,
    String? imageUrl,
  }) async {
    await _eventsRef.add({
      'title': title,
      'dateString': dateString,
      'timeString': timeString,
      'committee': committee,
      'image_url': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _eventsRef.doc(id).delete();
  }
}
