import 'package:flutter/material.dart';

class WorkBannerCard extends StatelessWidget {
  final String eventName;
  final String detail;
  final String dateSlot;
  final VoidCallback onDelete;

  const WorkBannerCard({
    super.key,
    required this.eventName,
    required this.detail,
    required this.dateSlot,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: color),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateSlot, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
