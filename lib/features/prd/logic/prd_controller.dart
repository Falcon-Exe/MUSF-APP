// lib/features/prd/logic/prd_controller.dart

import 'package:flutter/foundation.dart';
import '../data/repositories/prd_repository.dart';
import '../data/repositories/supabase_prd_repository.dart';

class PrdController extends ChangeNotifier {
  final PrdRepository _repository;

  int _selectedTabIndex = 0; // for WorkDashboard
  String _selectedClass = "All"; // for PrintRecords
  String _searchQuery = "";

  late final Stream<List<Map<String, dynamic>>> tasksStream;
  late final Stream<List<Map<String, dynamic>>> studentsStream;

  PrdController({PrdRepository? repository, String? committeeName})
      : _repository = repository ?? SupabasePrdRepository() {
    tasksStream = _repository.getTasks(committee: committeeName);
    studentsStream = _repository.getStudents();
  }

  int get selectedTabIndex => _selectedTabIndex;
  String get selectedClass => _selectedClass;
  String get searchQuery => _searchQuery;

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setClassFilter(String className) {
    _selectedClass = className;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> submitTask(Map<String, dynamic> data) async {
    await _repository.submitTask(data);
  }

  Future<void> updateTaskStatus(String docId, String status) async {
    await _repository.updateTaskStatus(docId, status);
  }

  Future<void> updateBalance(String docId, String studentID, int amount, bool isAddingDebt) async {
    await _repository.updateBalance(docId, studentID, amount, isAddingDebt);
  }

  Future<void> deleteRecord(String docId) async {
    await _repository.deleteRecord(docId);
  }

  Future<void> deleteTask(String docId) async {
    await _repository.deleteTask(docId);
  }
}
