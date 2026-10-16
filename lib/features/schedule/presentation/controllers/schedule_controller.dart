// lib/features/schedule/presentation/controllers/schedule_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/constants/holidays.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/supabase_schedule_repository.dart';

class ScheduleController extends ChangeNotifier {
  final ScheduleRepository _repository;

  DateTime _focusedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDate = DateTime.now();

  late ScrollController _scrollController;
  late final Stream<List<Map<String, dynamic>>> _eventsStream;
  
  // Cache for processed events to avoid re-processing on every build
  Map<String, List<Map<String, dynamic>>> _eventsMap = {};
  bool _isProcessing = false;

  ScheduleController({ScheduleRepository? repository})
      : _repository = repository ?? SupabaseScheduleRepository() {
    _eventsStream = _repository.getEventsStream();
    
    double initialOffset = (_selectedDate.day - 2.5) * 86.0;
    if (initialOffset < 0) initialOffset = 0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    
    // Listen to stream to process events and schedule notifications
    _eventsStream.listen(_processEvents);
  }

  DateTime get focusedDate => _focusedDate;
  DateTime get selectedDate => _selectedDate;
  ScrollController get scrollController => _scrollController;
  Stream<List<Map<String, dynamic>>> get eventsStream => _eventsStream;
  Map<String, List<Map<String, dynamic>>> get eventsMap => _eventsMap;

  void _processEvents(List<Map<String, dynamic>> events) {
    if (_isProcessing) return;
    _isProcessing = true;

    Map<String, List<Map<String, dynamic>>> newEventsMap = {};
    int eventIdCounter = 0;

    for (var data in events) {
      String rawDate = data['dateString'] ?? '';
      String title = data['title'] ?? 'Union Event';

      if (rawDate.isNotEmpty) {
        try {
          DateTime parsedDate = DateFormat('d/M/yyyy').parse(rawDate);
          String cleanDate = DateFormat('dd/MM/yyyy').format(parsedDate);
          newEventsMap.putIfAbsent(cleanDate, () => []).add(data);

          // 🟢 AUTOMATICALLY SCHEDULE NOTIFICATIONS! (mobile only)
          if (!kIsWeb) {
            NotificationService.scheduleEventReminder(
              eventIdCounter,
              "Reminder: $title is happening tomorrow!",
              parsedDate,
            );
          }
          eventIdCounter++;
        } catch (e) {
          newEventsMap.putIfAbsent(rawDate, () => []).add(data);
        }
      }
    }

    _eventsMap = newEventsMap;
    _isProcessing = false;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    double newOffset = (date.day - 2.5) * 86.0;
    _scrollController.animateTo(
      newOffset < 0 ? 0 : newOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    notifyListeners();
  }

  Future<void> pickYearMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _focusedDate = DateTime(picked.year, picked.month, 1);
      _selectedDate = picked;
      double newOffset = (picked.day - 2.5) * 86.0;
      _scrollController.animateTo(
        newOffset < 0 ? 0 : newOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getTodaysEvents() {
    String selectedEventKey = DateFormat('dd/MM/yyyy').format(_selectedDate);
    return _eventsMap[selectedEventKey] ?? [];
  }

  String? getHolidayName() {
    String selectedHolidayKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return ScheduleHolidays.indiaHolidays2026[selectedHolidayKey];
  }

  Future<void> addEvent({
    required String title,
    required String dateString,
    required String timeString,
    required String committee,
    String? imageUrl,
  }) {
    return _repository.addEvent(
      title: title,
      dateString: dateString,
      timeString: timeString,
      committee: committee,
      imageUrl: imageUrl,
    );
  }

  Future<void> deleteEvent(String id) {
    return _repository.deleteEvent(id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
