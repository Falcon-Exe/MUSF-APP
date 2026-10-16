import 'package:supabase_flutter/supabase_flutter.dart';
import 'library_repository.dart';

class SupabaseLibraryRepository implements LibraryRepository {
  final SupabaseClient _client;

  SupabaseLibraryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<List<Map<String, dynamic>>> getStudentsStream() {
    return _client
        .from('students')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> getHistoryStream(String studentID) {
    return _client
        .from('library_payments')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentID)
        .order('date', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> getBooksCatalogStream() {
    return _client
        .from('library_books')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Future<void> updateFine({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAdding,
    required int currentFine,
  }) async {
    if (amount <= 0) return;
    int newFine = isAdding
        ? (currentFine + amount)
        : (currentFine - amount).clamp(0, 999999);

    await _client.from('students').update({
      'library_fine': newFine,
      'library_status': newFine == 0 ? "Cleared" : "Pending",
    }).eq('id', docId);

    await _client.from('library_payments').insert({
      'student_id': studentID,
      'amount': amount,
      'type': isAdding ? 'Addition' : 'Deduction',
      'date': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteTransaction({
    required String transId,
    required String studentID,
    required int amount,
    required String type,
  }) async {
    await _client.from('library_payments').delete().eq('id', transId);

    final student = await _client
        .from('students')
        .select()
        .eq('student_id', studentID)
        .maybeSingle();

    if (student != null) {
      int currentFine =
          int.tryParse(student['library_fine']?.toString() ?? '0') ?? 0;

      int updatedFine = (type == 'Addition')
          ? (currentFine - amount).clamp(0, 999999)
          : (currentFine + amount);

      await _client.from('students').update({
        'library_fine': updatedFine,
        'library_status': updatedFine == 0 ? "Cleared" : "Pending",
      }).eq('id', student['id']);
    }
  }

  @override
  Future<void> addBook({
    required String title,
    required String author,
    String? imageUrl,
  }) async {
    await _client.from('library_books').insert({
      'title': title,
      'author': author,
      'image_url': imageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteBook(String docId) async {
    await _client.from('library_books').delete().eq('id', docId);
  }

  @override
  Future<void> sendNotice({
    required String studentID,
    required String message,
  }) async {
    await _client.from('notifications').insert({
      'student_id': studentID,
      'title': 'Library Notice',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'is_read': false,
      'type': 'library_notice',
    });
  }
}
