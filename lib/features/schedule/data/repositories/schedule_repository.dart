abstract class ScheduleRepository {
  Stream<List<Map<String, dynamic>>> getEventsStream({String? committee});
  Future<void> addEvent({
    required String title,
    required String dateString,
    required String timeString,
    required String committee,
    String? imageUrl,
  });
  Future<void> deleteEvent(String id);
}
