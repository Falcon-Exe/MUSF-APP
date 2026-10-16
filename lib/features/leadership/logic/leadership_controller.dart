import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../data/repositories/leadership_repository.dart';
import '../data/repositories/announcement_repository.dart';

class LeadershipController extends ChangeNotifier {
  final LeadershipRepository _repository;
  final AnnouncementRepository _announcementRepo = AnnouncementRepository();

  LeadershipController(this._repository);

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getLeadersStream() =>
      _repository.getLeadersStream();
  Stream<List<Map<String, dynamic>>> getComplaintsStream() =>
      _repository.getComplaintsStream();
  Future<List<Map<String, dynamic>>> getActiveLeaders() =>
      _repository.getActiveLeaders();

  Future<void> saveLeader({
    String? docId,
    required String name,
    required String role,
    required int order,
    required String colorHex,
    required String iconName,
    String? imageUrl,
    Uint8List? imageBytes,
    String? backgroundImageUrl,
    bool isActive = true,
  }) async {
    setUploading(true);
    try {
      await _repository.saveLeader(
        docId: docId,
        name: name,
        role: role,
        order: order,
        colorHex: colorHex,
        iconName: iconName,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        backgroundImageUrl: backgroundImageUrl,
        isActive: isActive,
      );
    } finally {
      setUploading(false);
    }
  }

  Future<void> deactivateLeader(String docId) =>
      _repository.deactivateLeader(docId);
  Future<void> deleteLeader(String docId) => _repository.deleteLeader(docId);
  Future<void> deleteComplaint(String docId) =>
      _repository.deleteComplaint(docId);

  // --- Announcements ---
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream({String? committeeName}) =>
      _announcementRepo.getAnnouncementsStream(committeeName: committeeName);

  Future<void> sendAnnouncement({
    required String title,
    required String message,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String targetType,
    String? targetCommittee,
    required String priority,
  }) async {
    await _announcementRepo.sendAnnouncement(
      title: title,
      message: message,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      targetType: targetType,
      targetCommittee: targetCommittee,
      priority: priority,
    );
  }
}
