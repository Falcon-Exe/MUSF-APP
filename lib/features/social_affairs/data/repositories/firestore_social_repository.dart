// lib/features/social_affairs/data/repositories/firestore_social_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'social_repository.dart';

class FirestoreSocialRepository implements SocialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Map<String, dynamic>>> getCssWorksStream() {
    return _firestore
        .collection('social_css_works')
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              DateTime? startDate;
              DateTime? endDate;
              if (data['startDate'] is Timestamp) {
                startDate = (data['startDate'] as Timestamp).toDate();
              }
              if (data['endDate'] is Timestamp) {
                endDate = (data['endDate'] as Timestamp).toDate();
              }
              return {
                ...data,
                'id': d.id,
                'startDate': startDate,
                'endDate': endDate,
              };
            }).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getExamsStream() {
    return _firestore
        .collection('social_exams')
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              DateTime date = DateTime.now();
              if (data['date'] is Timestamp) {
                date = (data['date'] as Timestamp).toDate();
              }
              return {
                ...data,
                'id': d.id,
                'date': date,
              };
            }).toList());
  }

  @override
  Future<void> addCssWork({
    required String title,
    required String instruction,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _firestore.collection('social_css_works').add({
      'title': title.trim(),
      'instruction': instruction.trim(),
      'startDate': startDate,
      'endDate': endDate,
      'dateAdded': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addExam({
    required String subject,
    required DateTime date,
    required String location,
  }) async {
    await _firestore.collection('social_exams').add({
      'subject': subject.trim(),
      'date': date,
      'location': location.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCssWork(String docId) async {
    await _firestore.collection('social_css_works').doc(docId).delete();
  }

  @override
  Future<void> deleteExam(String docId) async {
    await _firestore.collection('social_exams').doc(docId).delete();
  }
}
