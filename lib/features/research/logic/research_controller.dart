// lib/features/research/logic/research_controller.dart

import 'package:flutter/foundation.dart';
import '../data/repositories/research_repository.dart';

class ResearchController extends ChangeNotifier {
  final ResearchRepository _repository;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<String> _likedPapers = {};

  late final Stream<List<Map<String, dynamic>>> requestsStream;
  late final Stream<List<Map<String, dynamic>>> mySubmissionsStream;

  ResearchController({ResearchRepository? repository})
    : _repository = repository ?? SupabaseResearchRepository() {
    requestsStream = _repository.getRequests();
    mySubmissionsStream = _repository.getMySubmissions();
  }

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  Set<String> get likedPapers => _likedPapers;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool isLiked(String docId) => _likedPapers.contains(docId);

  Future<void> toggleLike(String docId, int currentLikes) async {
    final currentlyLiked = isLiked(docId);
    if (currentlyLiked) {
      _likedPapers.remove(docId);
    } else {
      _likedPapers.add(docId);
    }
    notifyListeners();

    try {
      await _repository.toggleLike(docId, currentlyLiked);
    } catch (e) {
      if (currentlyLiked) {
        _likedPapers.add(docId);
      } else {
        _likedPapers.remove(docId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> submitPaper(Map<String, dynamic> data) async {
    await _repository.submitPaper(data);
  }

  Future<void> publishPaper(Map<String, dynamic> data) async {
    await _repository.publishPaper(data);
  }

  Future<void> approveRequest(String docId, Map<String, dynamic> data) async {
    await _repository.approveRequest(docId, data);
  }

  Future<void> rejectRequest(String docId, Map<String, dynamic> data) async {
    await _repository.rejectRequest(docId, data);
  }

  Future<void> archivePublication(String docId) async {
    await _repository.archivePublication(docId);
  }

  Future<void> deleteRequest(String docId) async {
    await _repository.deleteRequest(docId);
  }

  Future<void> deletePublishedPaper(String docId) async {
    await _repository.deletePublishedPaper(docId);
  }

  Future<List<Map<String, dynamic>>> fetchResearchRecords({
    required String committeeName,
    required String statusGroup,
  }) async {
    return _repository.fetchResearchRecords(
      committeeName: committeeName,
      statusGroup: statusGroup,
    );
  }
}
