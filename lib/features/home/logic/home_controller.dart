// lib/features/home/logic/home_controller.dart

import 'package:flutter/foundation.dart';
import '../data/repositories/home_repository.dart';

class HomeController extends ChangeNotifier {
  final HomeRepository _repository;
  final String studentID;

  bool _isFlipped = false;
  late final Stream<List<Map<String, dynamic>>> unreadNotifStream;

  HomeController({required this.studentID, HomeRepository? repository})
      : _repository = repository ?? SupabaseHomeRepository() {
    unreadNotifStream = _repository.getUnreadNotifications(studentID);
  }

  bool get isFlipped => _isFlipped;

  void toggleFlip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    await _repository.markAsRead(notificationIds);
  }
}
