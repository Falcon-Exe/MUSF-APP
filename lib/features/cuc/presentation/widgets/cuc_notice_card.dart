import 'package:flutter/material.dart';

class CucNoticeCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final VoidCallback onDelete;

  const CucNoticeCard({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color redAdmin = Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_active, color: redAdmin),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(content, style: const TextStyle(color: Color(0xFF333333), fontSize: 13)),
              ),
            const SizedBox(height: 4),
            Text(
              "Last Date: $date",
              style: const TextStyle(color: redAdmin, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
