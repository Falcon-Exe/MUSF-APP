// lib/features/home/presentation/widgets/side_drawer.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../menu_page.dart';
import '../../../../home/complaint_page.dart';
import '../../../../home/global_notification_inbox.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../admin/student_directory_page.dart';
import '../../../../core/theme/app_colors.dart';

class SideDrawer extends StatelessWidget {
  final bool isAdmin;
  final String studentID;
  final Map<String, dynamic>? studentData;
  final Function(int)? onTabSwitch;

  const SideDrawer({
    super.key,
    required this.isAdmin,
    required this.studentID,
    this.studentData,
    this.onTabSwitch,
  });

  @override
  Widget build(BuildContext context) {
    const Color drawerBg = AppColors.darkGreen;
    const Color drawerHeaderStart = AppColors.primaryGreen;
    const Color drawerHeaderEnd = AppColors.darkGreen;
    const Color itemColor = Color(0xFFEAF2EE);
    const Color mutedItemColor = Color(0xFFC6D4CE);
    const Color activeGreen = AppColors.accentTeal;
    const Color logoutColor = AppColors.alertRed;

    final String role = studentData?['role']?.toString().toLowerCase().trim() ?? '';
    final String assignedRole = (studentData?['assigned_role'] ?? studentData?['assignedRole'])?.toString().toLowerCase().trim() ?? '';
    final String designation = studentData?['designation']?.toString().toLowerCase().trim() ?? '';
    final String fullText = "$role $assignedRole $designation";

    final bool isSupabaseAdmin = role == 'admin' ||
        studentData?['is_admin'] == true ||
        studentData?['isAdmin'] == true ||
        fullText.contains('admin') ||
        fullText.contains('executive');
    final bool hasAssignedRole = (assignedRole.isNotEmpty && assignedRole != 'none') ||
        (designation.isNotEmpty && designation != 'none');

    final bool hasAdminPortalAccess = isAdmin || isSupabaseAdmin || hasAssignedRole;
    final bool hasStudentManagementAccess = isAdmin || isSupabaseAdmin;

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [drawerHeaderStart, drawerHeaderEnd],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/musf_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "MUSF PORTAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  if (isAdmin || isSupabaseAdmin) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            "GOD MODE",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Main actions
          if (hasAdminPortalAccess) ...[
            if (hasStudentManagementAccess)
              _drawerItem(
                Icons.manage_accounts_rounded,
                "Students & Roles",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentDirectoryPage(),
                    ),
                  );
                },
                color: activeGreen,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),

            _drawerItem(
              Icons.dashboard_customize_rounded,
              "Management Console",
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuPage(
                      isAdmin: true,
                      studentID: studentID,
                      studentData: studentData,
                    ),
                  ),
                );
              },
              color: activeGreen,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ],

          _drawerItem(Icons.feedback_rounded, "Complaint / Suggestion", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ComplaintPage()),
            );
          }, color: itemColor),

          _drawerItem(
            Icons.notifications_active_rounded,
            "Global Notifications",
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GlobalNotificationInbox(
                    studentID: studentID,
                    isAdmin: isAdmin,
                    studentData: studentData,
                  ),
                ),
              );
            },
            color: itemColor,
          ),

          const SizedBox(height: 10),

          const Divider(color: Colors.white12, indent: 24, endIndent: 24),

          // Secondary options
          _drawerItem(Icons.settings_rounded, "Settings", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(isAdmin: isAdmin),
              ),
            );
          }, color: mutedItemColor),

          _drawerItem(Icons.info_outline_rounded, "About Us", () {
            Navigator.pop(context);
          }, color: mutedItemColor),

          const Spacer(),

          const Divider(color: Colors.white12, indent: 24, endIndent: 24),

          _drawerItem(Icons.logout_rounded, "Log Out", () async {
            Navigator.pop(context);
            await supabase.Supabase.instance.client.auth.signOut();
          }, color: logoutColor),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.white70,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: backgroundColor,
        leading: Icon(icon, color: color, size: 23),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
