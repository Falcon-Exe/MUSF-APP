// lib/features/sports/presentation/widgets/admin_sports_event_card.dart

import 'package:flutter/material.dart';
import '../../logic/sports_controller.dart';
import 'sports_result_entry_dialog.dart';
import '../../../../core/widgets/student_name_widget.dart';

class AdminSportsEventCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final SportsController controller;

  const AdminSportsEventCard({
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
    final firstPlaceId = data['firstPlaceId'] ?? '';
    final secondPlaceId = data['secondPlaceId'] ?? '';
    final thirdPlaceId = data['thirdPlaceId'] ?? '';

    // Sports historically used firstPlaceName, but original code seems to mix ID lookup.
    // The AdminSportsPage uses StudentNameWidget for LOOKUP in preview row.
    // However, saving saves IDs. Let's keep it robust to show IDs or use StudentNameWidget if we want on-the-fly.
    // Arts saved names. Sports saved IDs. 
    // Wait, let's make sure it EXACTLY mirrors the admin_sports_page.dart behavior!
    // admin_sports_page.dart Line 538 uses `_winnerPreviewRow` with `StudentNameWidget`!
    // So it saves IDs, and converts on-the-fly!
    // I will use `StudentNameWidget` here for Sports!

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
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: const Icon(Icons.sports_mma_rounded, color: Colors.orange),
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
              _winnerPreviewRow("🥇 1st:", firstPlaceId, Colors.green),
              if (secondPlaceId.isNotEmpty) _winnerPreviewRow("🥈 2nd:", secondPlaceId, Colors.blueGrey),
              if (thirdPlaceId.isNotEmpty) _winnerPreviewRow("🥉 3rd:", thirdPlaceId, Colors.orange),
              const SizedBox(height: 8),
              const Text("Tap to edit scores • Long Press to Delete", style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
            ] else ...[
              const Text("Pending Results...", style: TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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
            builder: (c) => SportsResultEntryDialog(
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

  Widget _winnerPreviewRow(String label, String? id, [Color idColor = Colors.black87]) {
    if (id == null || id.isEmpty) return const SizedBox.shrink();
    final String targetId = id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(width: 5),
          // Using extracted widget from core
          StudentNameWidget(
            studentId: targetId,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: idColor),
          ),
        ],
      ),
    );
  }
}
