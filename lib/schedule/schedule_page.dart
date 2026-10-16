import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 🟢 IMPORT YOUR NOTIFICATION SERVICE HERE
import '../core/services/notification_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 🟢 Keep schedule state alive
  DateTime _focusedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDate = DateTime.now();

  // 🟢 Scroll Controller to automatically scroll to Today's date
  late ScrollController _scrollController;
  late final Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();

    // 🟢 Cache the events stream so rebuilding calendar dates doesn't tear down the network
    _eventsStream = _eventsRef.snapshots();

    double initialOffset = (_selectedDate.day - 2.5) * 86.0;
    if (initialOffset < 0) initialOffset = 0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Your updated 2026 Holiday Map (Format: yyyy-MM-dd)
  final Map<String, String> _indiaHolidays2026 = {
    "2026-01-12": "National Youth Day",
    "2026-01-15": "Indian Army Day",
    "2026-01-26": "Republic Day",
    "2026-01-30": "Martyrs' Day",
    "2026-02-04": "World Cancer Day",
    "2026-02-28": "National Science Day",
    "2026-03-05": "Holi",
    "2026-03-08": "International Women's Day",
    "2026-03-19": "Eid al-Fitr",
    "2026-03-22": "World Water Day",
    "2026-04-07": "World Health Day",
    "2026-04-14": "Ambedkar Jayanti",
    "2026-04-22": "Earth Day",
    "2026-05-01": "Labour Day",
    "2026-05-11": "National Technology Day",
    "2026-05-27": "Bakrid",
    "2026-06-05": "World Environment Day",
    "2026-06-21": "International Yoga Day",
    "2026-07-01": "National Doctor's Day",
    "2026-07-26": "Kargil Vijay Diwas",
    "2026-08-15": "Independence Day",
    "2026-08-20": "World Mosquito Day",
    "2026-08-29": "National Sports Day",
    "2026-09-05": "Teachers' Day",
    "2026-09-15": "Engineer's Day",
    "2026-10-02": "Gandhi Jayanti",
    "2026-10-20": "Dussehra",
    "2026-11-08": "Diwali",
    "2026-11-14": "Children's Day",
    "2026-11-26": "Constitution Day",
    "2026-12-04": "Indian Navy Day",
    "2026-12-25": "Christmas Day",
  };

  final CollectionReference _eventsRef = FirebaseFirestore.instance
      .collection('artifacts')
      .doc('union-hostel-app')
      .collection('public')
      .doc('data')
      .collection('union_schedule');

  Future<void> _pickYearMonth(BuildContext context) async {
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
      setState(() {
        _focusedDate = DateTime(picked.year, picked.month, 1);
        _selectedDate = picked;
      });
      double newOffset = (picked.day - 2.5) * 86.0;
      _scrollController.animateTo(
        newOffset < 0 ? 0 : newOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 Required for KeepAlive
    int daysInMonth = DateUtils.getDaysInMonth(
      _focusedDate.year,
      _focusedDate.month,
    );
    String headerText = DateFormat('MMMM yyyy').format(_focusedDate);

    String selectedHolidayKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String? holidayName = _indiaHolidays2026[selectedHolidayKey];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Schedule",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          Map<String, List<Map<String, dynamic>>> eventsMap = {};

          if (snapshot.hasData) {
            int eventIdCounter = 0; // Unique ID for each notification

            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String rawDate = data['dateString'] ?? '';
              String title = data['title'] ?? 'Union Event';

              if (rawDate.isNotEmpty) {
                try {
                  DateTime parsedDate = DateFormat('d/M/yyyy').parse(rawDate);
                  String cleanDate = DateFormat(
                    'dd/MM/yyyy',
                  ).format(parsedDate);
                  eventsMap.putIfAbsent(cleanDate, () => []).add(data);

                  // 🟢 AUTOMATICALLY SCHEDULE NOTIFICATIONS!
                  // It will silently set an alarm for 5:00 PM the day before.
                  // If 5:00 PM on that day has already passed, the service safely ignores it.
                  NotificationService.scheduleEventReminder(
                    eventIdCounter,
                    "Reminder: $title is happening tomorrow!",
                    parsedDate,
                  );
                  eventIdCounter++; // Increment ID for the next event
                } catch (e) {
                  eventsMap.putIfAbsent(rawDate, () => []).add(data);
                }
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Calendar Header ---
              GestureDetector(
                onTap: () => _pickYearMonth(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Text(
                        headerText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ),

              // --- Horizontal Calendar List ---
              SizedBox(
                height: 110,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    DateTime date = DateTime(
                      _focusedDate.year,
                      _focusedDate.month,
                      index + 1,
                    );
                    bool isSelected =
                        date.day == _selectedDate.day &&
                        date.month == _selectedDate.month &&
                        date.year == _selectedDate.year;
                    bool isToday =
                        date.day == DateTime.now().day &&
                        date.month == DateTime.now().month &&
                        date.year == DateTime.now().year;

                    // Check for Holidays & Events
                    String holidayKey = DateFormat('yyyy-MM-dd').format(date);
                    bool isHoliday = _indiaHolidays2026.containsKey(holidayKey);

                    String eventKey = DateFormat('dd/MM/yyyy').format(date);
                    bool hasEvent = eventsMap.containsKey(eventKey);

                    // Determine Background Color Logic
                    Color? bgColor;
                    Gradient? bgGradient;
                    Color textColor = Colors.white;

                    if (isHoliday && hasEvent) {
                      bgGradient = const LinearGradient(
                        colors: [Colors.deepOrange, Colors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                    } else if (isHoliday) {
                      bgColor = Colors.deepOrange.withValues(alpha: 0.85);
                    } else if (hasEvent) {
                      bgColor = Colors.green.withValues(alpha: 0.85);
                    } else {
                      bgColor = isSelected
                          ? Colors.blueAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05);
                      textColor = isSelected
                          ? Colors.blueAccent
                          : Colors.white38;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        double newOffset = (date.day - 2.5) * 86.0;
                        _scrollController.animateTo(
                          newOffset < 0 ? 0 : newOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          gradient: bgGradient,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: Colors.blueAccent, width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isToday
                                  ? "TODAY"
                                  : DateFormat(
                                      'MMM',
                                    ).format(date).toUpperCase(),
                              style: TextStyle(
                                color: (isHoliday || hasEvent)
                                    ? Colors.white
                                    : textColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${date.day}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Holiday Info Card ---
              if (holidayName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepOrange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.deepOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Important: $holidayName",
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // --- Real-time Events List ---
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      );
                    }

                    // Get events just for the currently selected date
                    String selectedEventKey = DateFormat(
                      'dd/MM/yyyy',
                    ).format(_selectedDate);
                    List<Map<String, dynamic>> todaysEvents =
                        eventsMap[selectedEventKey] ?? [];

                    if (todaysEvents.isEmpty) {
                      return const Center(
                        child: Text(
                          "No events scheduled for this day.",
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: todaysEvents.length,
                      itemBuilder: (context, index) {
                        var event = todaysEvents[index];
                        return _buildEventItem(
                          title: event['title'] ?? 'Untitled Event',
                          time: event['timeString'] ?? '',
                          committee: event['committee'] ?? 'General',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String time,
    required String committee,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.event_note_rounded, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white54,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
          ),
          child: Text(
            committee,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
