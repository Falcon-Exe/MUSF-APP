abstract class PrdRepository {
  Stream<List<Map<String, dynamic>>> getTasks({String? status, String? committee});
  Stream<List<Map<String, dynamic>>> getStudents();
  Future<void> submitTask(Map<String, dynamic> data);
  Future<void> updateTaskStatus(String docId, String status);
  Future<void> updateBalance(String docId, String studentID, int amount, bool isAddingDebt);
  Future<void> deleteRecord(String docId);
  Future<void> deleteTask(String docId);
}
