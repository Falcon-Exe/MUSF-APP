// lib/features/home/data/repositories/home_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class HomeRepository {
  Stream<QuerySnapshot> getUnreadNotifications(String studentID);
}

class FirestoreHomeRepository implements HomeRepository {
  final FirebaseFirestore _firestore;

  FirestoreHomeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<QuerySnapshot> getUnreadNotifications(String studentID) {
    return _firestore
        .collection('notifications')
        .where('studentID', whereIn: [studentID, 'all', 'admin'])
        .where('isRead', isEqualTo: false)
        .limit(20)
        .snapshots();
  }
}
