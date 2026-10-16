// lib/features/social_affairs/presentation/widgets/css_tab_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'work_banner_card.dart';

class CssTabView extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final Function(String) onDelete;

  const CssTabView({super.key, required this.stream, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Could not load CSS works: ${snapshot.error}"),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("No CSS works scheduled."));
            }

            return Column(
              children: docs.map((data) {
                String startStr = 'TBD';
                String endStr = 'TBD';

                if (data['startDate'] is DateTime) {
                  startStr = DateFormat('MMM dd').format(data['startDate'] as DateTime);
                }
                if (data['endDate'] is DateTime) {
                  endStr = DateFormat('MMM dd').format(data['endDate'] as DateTime);
                }

                final docId = data['id']?.toString() ?? '';

                return WorkBannerCard(
                  eventName: data['title'] ?? 'Unnamed',
                  detail: data['instruction'] ?? 'No instructions',
                  dateSlot: "$startStr - $endStr",
                  onDelete: () => _confirmDelete(
                    context,
                    docId,
                    data['title'] ?? 'this program',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Work"),
        content: Text("Are you sure you want to remove $title?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              onDelete(id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
