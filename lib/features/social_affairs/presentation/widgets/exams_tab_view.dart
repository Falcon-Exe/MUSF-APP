// lib/features/social_affairs/presentation/widgets/exams_tab_view.dart

import 'package:flutter/material.dart';
import 'exam_card.dart';

class ExamsTabView extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final Function(String) onDelete;
  final VoidCallback? onAdd;

  const ExamsTabView({
    super.key,
    required this.stream,
    required this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Add New"),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
          ],
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Could not load exams: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("No exams scheduled."));
            }

            return Column(
              children: docs.map((data) {
                DateTime date = DateTime.now();
                if (data['date'] is DateTime) {
                  date = data['date'] as DateTime;
                } else if (data['date'] != null) {
                  date = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
                }

                final docId = data['id']?.toString() ?? '';

                return ExamCard(
                  subject: data['subject'] ?? 'Unknown',
                  date: date,
                  location: data['location'] ?? 'TBD',
                  onDelete: () => _confirmDelete(
                    context,
                    docId,
                    data['subject'] ?? 'this exam',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Delete Exam?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("Are you sure you want to delete '$title'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              onDelete(docId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
