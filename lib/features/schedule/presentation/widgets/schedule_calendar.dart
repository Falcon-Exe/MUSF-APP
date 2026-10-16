// lib/features/schedule/presentation/widgets/schedule_calendar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/constants/holidays.dart';
import '../controllers/schedule_controller.dart';

class ScheduleCalendar extends StatelessWidget {
  final ScheduleController controller;

  const ScheduleCalendar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(
      controller.focusedDate.year,
      controller.focusedDate.month,
    );

    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: controller.scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          DateTime date = DateTime(
            controller.focusedDate.year,
            controller.focusedDate.month,
            index + 1,
          );
          bool isSelected =
              date.day == controller.selectedDate.day &&
              date.month == controller.selectedDate.month &&
              date.year == controller.selectedDate.year;
          bool isToday =
              date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          // Check for Holidays & Events
          String holidayKey = DateFormat('yyyy-MM-dd').format(date);
          bool isHoliday = ScheduleHolidays.indiaHolidays2026.containsKey(holidayKey);

          String eventKey = DateFormat('dd/MM/yyyy').format(date);
          bool hasEvent = controller.eventsMap.containsKey(eventKey);

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
            textColor = isSelected ? Colors.blueAccent : Colors.white38;
          }

          return GestureDetector(
            onTap: () => controller.selectDate(date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
                        : DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(
                      color: (isHoliday || hasEvent) ? Colors.white : textColor,
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
    );
  }
}
