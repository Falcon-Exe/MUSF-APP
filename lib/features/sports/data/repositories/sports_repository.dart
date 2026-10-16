abstract class SportsRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream();
  Future<void> addEvent(String title, String category);
  Future<void> updateResults(String docId, Map<String, dynamic> data);
  Future<void> deleteEvent(String docId);
}
