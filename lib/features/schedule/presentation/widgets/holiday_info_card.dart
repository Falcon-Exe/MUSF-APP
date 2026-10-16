// lib/features/schedule/presentation/widgets/holiday_info_card.dart

import 'package:flutter/material.dart';

class HolidayInfoCard extends StatelessWidget {
  final String holidayName;

  const HolidayInfoCard({super.key, required this.holidayName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }
}
