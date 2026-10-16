// lib/features/arts/presentation/widgets/admin_arts_management_menu.dart

import 'package:flutter/material.dart';
import 'arts_sheets_import_dialog.dart';

import '../../../../admin/reel_upload_page.dart';
import '../../../../admin/event_management_page.dart';
import '../../../../admin/samajyam_admin_page.dart';
import '../../../../admin/admin_committee_prize.dart';
import '../../../../features/prd/presentation/pages/prd_request_desk_page.dart';

class AdminArtsManagementMenu extends StatelessWidget {
  final BuildContext parentContext;

  const AdminArtsManagementMenu({
    super.key,
    required this.parentContext,
  });

  static const Color primaryDark = Color(0xFF08233E);
  static const Color pageBg = Color(0xFFF6F8FB);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  void _openPage(BuildContext context, Widget destination) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 0, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _toolListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: danger ? const Color(0xFFFFF1F2) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: danger ? const Color(0xFFFECACA) : borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: danger ? color : textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: danger ? color.withValues(alpha: 0.4) : Colors.black12,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color reelColor = Color(0xFFFF5A6E);
    const Color eventColor = Color(0xFF38BDF8);
    const Color resultColor = Color(0xFF22C55E);
    const Color samajyamColor = Color(0xFF10B981);
    const Color prizeColor = Color(0xFF9333EA);
    const Color prdColor = Color(0xFFF59E0B);
    const Color exitColor = Color(0xFFEF4444);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: pageBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Management Console",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: primaryDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Manage arts tools and department actions",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                _sectionTitle("PRIMARY TOOLS"),
                _toolListTile(
                  context: context,
                  icon: Icons.event_available_rounded,
                  title: "Event Management",
                  subtitle: "Create and manage events",
                  color: eventColor,
                  onTap: () => _openPage(context, const EventManagementPage(initialCommittee: "Fine Arts")),
                ),
                _toolListTile(
                  context: context,
                  icon: Icons.video_collection_rounded,
                  title: "Reel Upload",
                  subtitle: "Upload reels and media",
                  color: reelColor,
                  onTap: () => _openPage(context, const ReelUploadPage(committeeName: "Fine Arts")),
                ),
                _toolListTile(
                  context: context,
                  icon: Icons.text_snippet_rounded,
                  title: "Import Results",
                  subtitle: "Import from Google Sheets",
                  color: resultColor,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => ArtsSheetsImportDialog(parentContext: parentContext),
                    );
                  },
                ),
                _toolListTile(
                  context: context,
                  icon: Icons.groups_rounded,
                  title: "Samajyam",
                  subtitle: "Manage Samajyam records",
                  color: samajyamColor,
                  onTap: () => _openPage(context, const SamajyamAdminPage()),
                ),

                _sectionTitle("DEPARTMENT TOOLS"),
                _toolListTile(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  title: "Prize Management",
                  subtitle: "Winners, scores and rankings",
                  color: prizeColor,
                  onTap: () => _openPage(context, const AdminCommitteeDashboard(initialCommittee: "Fine Arts")),
                ),
                _toolListTile(
                  context: context,
                  icon: Icons.design_services_rounded,
                  title: "PRD Dashboard",
                  subtitle: "Requests and design works",
                  color: prdColor,
                  onTap: () => _openPage(context, const PrdRequestDeskPage(initialCommittee: "Fine Arts")),
                ),

                _sectionTitle("SYSTEM"),
                _toolListTile(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: "Exit Management",
                  subtitle: "Return to previous screen",
                  color: exitColor,
                  danger: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
