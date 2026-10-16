// lib/features/cuc/logic/cuc_controller.dart

import 'package:flutter/material.dart';
import '../data/repositories/cuc_repository.dart';
import '../data/repositories/supabase_cuc_repository.dart';

class CucController extends ChangeNotifier {
  final CucRepository _repository;

  CucController([CucRepository? repository])
      : _repository = repository ?? SupabaseCucRepository();

  Stream<List<Map<String, dynamic>>> getNoticesStream() => _repository.getNoticesStream();

  Future<void> postNotice({
    required String title,
    required String content,
    required String date,
  }) {
    return _repository.postNotice(title: title, content: content, date: date);
  }

  Future<void> deleteNotice(String docId) => _repository.deleteNotice(docId);
}
