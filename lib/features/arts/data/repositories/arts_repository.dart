abstract class ArtsRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream();
  Future<void> addEvent(String title, String type);
  Future<void> updateResults(String docId, Map<String, dynamic> data);
  Future<void> deleteEvent(String docId);
}
