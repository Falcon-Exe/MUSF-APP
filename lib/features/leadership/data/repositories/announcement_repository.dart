// lib/features/leadership/data/repositories/announcement_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'executive_announcements';

  Stream<QuerySnapshot> getAnnouncementsStream({String? committeeName}) {
    // If committeeName is provided, we fetch 'all' and specific committee
    if (committeeName != null) {
      return _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('targetType', whereIn: ['all', 'committee'])
          // Note: Firestore doesn't support complex OR filters easily with whereIn and other filters
          // So we might need to filter 'targetCommittee' in memory or use multiple streams
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendAnnouncement({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String targetType, // 'all', 'committee', 'students', 'admins'
    String? targetCommittee,
    required String priority, // 'normal', 'important'
  }) async {
    await _firestore.collection(_collection).add({
      'title': title,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'targetType': targetType,
      'targetCommittee': targetCommittee,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    // Mirror to notifications collection for the bell icon
    String targetID = 'all';
    if (targetType == 'committee' && targetCommittee != null) {
      // In a real app, we might send to all members of that committee
      // For now, let's use a convention like 'committee_Literary'
      targetID = 'committee_$targetCommittee';
    } else if (targetType == 'admins') {
      targetID = 'admin';
    }

    await _firestore.collection('notifications').add({
      'studentID': targetID,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'executive_announcement',
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection(_collection).doc(id).update({'isActive': false});
  }
}
