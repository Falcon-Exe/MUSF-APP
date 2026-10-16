// lib/features/schedule/presentation/pages/schedule_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/schedule_calendar.dart';
import '../widgets/holiday_info_card.dart';
import '../widgets/event_list_item.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 🟢 Keep schedule state alive

  late final ScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 Required for KeepAlive

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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          String headerText = DateFormat('MMMM yyyy').format(_controller.focusedDate);
          String? holidayName = _controller.getHolidayName();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Calendar Header ---
              GestureDetector(
                onTap: () => _controller.pickYearMonth(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              ScheduleCalendar(controller: _controller),

              // --- Holiday Info Card ---
              if (holidayName != null)
                HolidayInfoCard(holidayName: holidayName),

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
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _controller.eventsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _controller.eventsMap.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      );
                    }

                    // Get events just for the currently selected date
                    final todaysEvents = _controller.getTodaysEvents();

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
                        return EventListItem(
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
}
