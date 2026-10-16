import 'dart:typed_data';

abstract class LeadershipRepository {
  Stream<List<Map<String, dynamic>>> getLeadersStream();
  Stream<List<Map<String, dynamic>>> getComplaintsStream();
  Future<List<Map<String, dynamic>>> getActiveLeaders();

  Future<void> saveLeader({
    String? docId,
    required String name,
    required String role,
    required int order,
    required String colorHex,
    required String iconName,
    String? imageUrl,
    Uint8List? imageBytes, // For new uploads
    String? backgroundImageUrl,
    bool isActive = true,
  });

  Future<void> deactivateLeader(String docId);
  Future<void> deleteLeader(String docId);
  Future<void> deleteComplaint(String docId);
}
