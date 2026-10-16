// lib/features/arts/logic/arts_controller.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/arts_repository.dart';
import '../data/repositories/supabase_arts_repository.dart';

class ArtsController extends ChangeNotifier {
  final ArtsRepository _repository;

  String _selectedCategory = "On-Stage";
  bool _debugShowAll = false;
  String _searchQuery = "";

  late final Stream<List<Map<String, dynamic>>> eventsStream;

  ArtsController({ArtsRepository? repository})
      : _repository = repository ?? SupabaseArtsRepository() {
    eventsStream = _repository.getEventsStream();
  }

  String get selectedCategory => _selectedCategory;
  bool get debugShowAll => _debugShowAll;
  String get searchQuery => _searchQuery;

  void setCategory(String category) {
    _selectedCategory = normalizeCategory(category);
    notifyListeners();
  }

  static String normalizeCategory(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    final normalized = raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (normalized.contains('off')) return 'Off-Stage';
    if (normalized.contains('stage')) return 'On-Stage';
    return 'On-Stage';
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
      debugPrint("Error looking up student name in Supabase: $e");
    }
    return "Unknown Student ($cleanId)";
  }

  Future<void> addEvent(String title, String type) async {
    await _repository.addEvent(title, type);
  }

  Future<void> updateResults(String docId, Map<String, dynamic> data) async {
    await _repository.updateResults(docId, data);
  }

  Future<void> deleteEvent(String docId) async {
    await _repository.deleteEvent(docId);
  }
}
