// lib/features/home/logic/home_controller.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/home_repository.dart';

class HomeController extends ChangeNotifier {
  final HomeRepository _repository;
  final String studentID;

  bool _isFlipped = false;
  late final Stream<QuerySnapshot> unreadNotifStream;

  HomeController({required this.studentID, HomeRepository? repository})
    : _repository = repository ?? FirestoreHomeRepository() {
    // Isotope streams initially
    unreadNotifStream = _repository.getUnreadNotifications(studentID);
  }

  bool get isFlipped => _isFlipped;

  void toggleFlip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }
}
