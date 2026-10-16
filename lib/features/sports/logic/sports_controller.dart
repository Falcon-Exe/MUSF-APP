// lib/features/sports/logic/sports_controller.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/sports_repository.dart';
import '../data/repositories/supabase_sports_repository.dart';

class SportsController extends ChangeNotifier {
  final SportsRepository _repository;

  String _selectedCategory = "Outdoor"; // Outdoor or Indoor
  bool _debugShowAll = false;
  String _searchQuery = "";

  late final Stream<List<Map<String, dynamic>>> eventsStream;

  SportsController({SportsRepository? repository})
      : _repository = repository ?? SupabaseSportsRepository() {
    eventsStream = _repository.getEventsStream();
  }

  String get selectedCategory => _selectedCategory;
  bool get debugShowAll => _debugShowAll;
  String get searchQuery => _searchQuery;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleDebug() {
    _debugShowAll = !_debugShowAll;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool isMyId(dynamic databaseId, String studentId) {
    if (databaseId == null || databaseId.toString().isEmpty) return false;
    return databaseId.toString().trim() == studentId.trim();
  }

  Future<String> getStudentNameFromID(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return "";
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('full_name')
          .eq('student_id', cleanId)
          .maybeSingle();

      if (res != null && res['full_name'] != null) {
        return res['full_name'].toString();
      }
    } catch (e) {
      debugPrint("Error looking up name from Supabase: $e");
    }
    return "Unknown Student ($cleanId)";
  }

  Future<void> addEvent(String title, String category) async {
    await _repository.addEvent(title, category);
  }

  Future<void> updateResults(String docId, Map<String, dynamic> data) async {
    await _repository.updateResults(docId, data);
  }

  Future<void> deleteEvent(String docId) async {
    await _repository.deleteEvent(docId);
  }
}
