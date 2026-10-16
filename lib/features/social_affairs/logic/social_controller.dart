// lib/features/social_affairs/logic/social_controller.dart

import 'package:flutter/material.dart';
import '../data/repositories/social_repository.dart';
import '../data/repositories/supabase_social_repository.dart';

class SocialController extends ChangeNotifier {
  final SocialRepository _repository;

  SocialController([SocialRepository? repository])
      : _repository = repository ?? SupabaseSocialRepository();

  String _activeTab = 'css'; // 'css' or 'exams'
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getCssWorksStream() => _repository.getCssWorksStream();
  Stream<List<Map<String, dynamic>>> getExamsStream() => _repository.getExamsStream();

  Future<void> addCssWork({
    required String title,
    required String instruction,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _repository.addCssWork(
      title: title,
      instruction: instruction,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> addExam({
    required String subject,
    required DateTime date,
    required String location,
  }) {
    return _repository.addExam(subject: subject, date: date, location: location);
  }

  Future<void> deleteCssWork(String docId) => _repository.deleteCssWork(docId);
  Future<void> deleteExam(String docId) => _repository.deleteExam(docId);
}
