// lib/features/sports/presentation/widgets/admin_sports_management_menu.dart

import 'package:flutter/material.dart';
import 'sports_sheets_import_dialog.dart';

// Temporarily absolute imports mapped to current layout
import '../../../../features/reels/presentation/pages/reel_upload_page.dart';
import '../../../../admin/event_management_page.dart';
import '../../../../admin/admin_committee_prize.dart';
import '../../../../features/prd/presentation/pages/prd_request_desk_page.dart';

class AdminSportsManagementMenu extends StatelessWidget {
  final BuildContext parentContext;

  const AdminSportsManagementMenu({super.key, required this.parentContext});

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    Widget? destination, {
    bool isExit = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          Navigator.pop(context);
          if (isExit) {
            Navigator.pop(context);
          } else if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF08233E);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Tournament Console",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 30),
            _menuItem(
              context,
              Icons.video_collection_rounded,
              "Reel Upload Page",
              Colors.redAccent,
              const ReelUploadPage(committeeName: "Sports"),
            ),
            _menuItem(
              context,
              Icons.event_available_rounded,
              "Event Management Page",
              Colors.blue,
              const EventManagementPage(initialCommittee: "Sports"),
            ),
            _menuItem(
              context,
              Icons.emoji_events_rounded,
              "Committee Prize Admin",
              Colors.purple,
              const AdminCommitteeDashboard(initialCommittee: "Sports"),
            ),
            _menuItem(
              context,
              Icons.design_services_rounded,
              "PRD Admin Dashboard",
              Colors.orange,
              const PrdRequestDeskPage(initialCommittee: "Sports"),
            ),
            _menuItem(
              context,
              Icons.text_snippet_rounded,
              "Import Statistics (Sheets)",
              Colors.green,
              null,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => SportsSheetsImportDialog(parentContext: parentContext),
                );
              },
            ),
            const Divider(height: 40),
            _menuItem(
              context,
              Icons.logout_rounded,
              "Exit Tournament",
              Colors.black54,
              null,
              isExit: true,
            ),
          ],
        ),
      ),
    );
  }
}
