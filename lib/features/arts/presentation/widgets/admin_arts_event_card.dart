// lib/features/arts/presentation/widgets/admin_arts_event_card.dart

import 'package:flutter/material.dart';
import '../../logic/arts_controller.dart';
import 'arts_result_entry_dialog.dart';

class AdminArtsEventCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ArtsController controller;

  const AdminArtsEventCard({
    super.key,
    required this.docId,
    required this.data,
    required this.controller,
  });

  void _confirmDelete(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete $title?"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await controller.deleteEvent(docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Unnamed Event';
    final hasResults = data['resultsPublished'] == true;
    final firstPlaceName = data['firstPlaceName'] ?? '';
    final secondPlaceName = data['secondPlaceName'] ?? '';
    final thirdPlaceName = data['thirdPlaceName'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.palette_rounded, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (hasResults) ...[
              Text("🥇 1st: $firstPlaceName", style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
              if (secondPlaceName.isNotEmpty) Text("🥈 2nd: $secondPlaceName", style: const TextStyle(fontSize: 12)),
              if (thirdPlaceName.isNotEmpty) Text("🥉 3rd: $thirdPlaceName", style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text("Tap to edit scores • Long Press to Delete", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
            ] else ...[
              const Text("Pending Results...", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Tap to assign winners • Long Press to Delete", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (c) => ArtsResultEntryDialog(
              docId: docId,
              eventName: title,
              data: data,
              controller: controller,
            ),
          );
        },
        onLongPress: () => _confirmDelete(context, title),
      ),
    );
  }
}
