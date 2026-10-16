import 'package:flutter/material.dart';

import 'features/finance/presentation/pages/finance_savings_page.dart';
import 'features/finance/presentation/pages/finance_collection_page.dart';
import 'features/finance/data/repositories/finance_repository.dart';
import 'features/library/presentation/pages/admin_library_page.dart';
import 'features/arts/presentation/pages/admin_arts_page.dart';
import 'features/sports/presentation/pages/admin_sports_page.dart';
import 'features/literary/presentation/pages/admin_literary_page.dart';
import 'features/research/presentation/pages/admin_research_page.dart';
import 'features/social_affairs/presentation/pages/admin_social_affairs_page.dart';
import 'features/prd/presentation/pages/prd_work_dashboard.dart';
import 'features/cuc/presentation/pages/admin_cuc_page.dart';
import 'features/leadership/presentation/pages/admin_leadership_page.dart';
import 'features/sub_committees/presentation/pages/sub_committee_admin_page.dart';
import 'admin/add_student_page.dart';
import 'admin/student_directory_page.dart';

class MenuPage extends StatelessWidget {
  final bool isAdmin;
  final String studentID;
  final Map<String, dynamic>? studentData;
  final Function(int)? onTabSwitch; // 🟢 Add this

  const MenuPage({
    super.key,
    this.isAdmin = false,
    this.studentID = "Unknown",
    this.studentData,
    this.onTabSwitch,
  });

  static const List<String> activeCommittees = [
    "CUC",
    "Treasurer",
    "Home Banner",
    "Bank",
    "Library",
    "Fine Arts",
    "Sports",
    "Literary",
    "Research",
    "Garden",
    "Medical",
    "Social Affairs",
    "PRD",
    "Store",
  ];

  @override
  Widget build(BuildContext context) {
    final String role = studentData?['role']?.toString().toLowerCase().trim() ?? '';
    final String assignedRole = studentData?['assigned_role']?.toString().toLowerCase().trim() ?? '';
    final String designation = studentData?['designation']?.toString().toLowerCase().trim() ?? '';
    final String fullRoleText = "$role $assignedRole $designation";

    final bool isSupabaseAdmin = role == 'admin' ||
        studentData?['is_admin'] == true ||
        studentData?['isAdmin'] == true ||
        fullRoleText.contains('admin') ||
        fullRoleText.contains('executive');
    final bool hasAssignedRole = (assignedRole.isNotEmpty && assignedRole != 'none') ||
        (designation.isNotEmpty && designation != 'none');
    final bool canOpenManagement = isAdmin || isSupabaseAdmin || hasAssignedRole;

    if (!canOpenManagement) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _buildDiagnosticUI(
          context,
          studentData ?? {},
          studentData != null
              ? "MATCH FOUND (via App State)!"
              : "NO DATA PASSED TO MENU",
        ),
      );
    }

    // Role-based filtering logic
    final List<String> userRoles = _managementAccessTokens(studentData);

    // Map departments to their required roles (lowercase for easy matching)
    final Map<String, List<String>> roleRequirements = {
      "Literary": ["literary coordinator", "literary"],
      "Fine Arts": ["fine arts coordinator", "fine arts"],
      "Social Affairs": ["social affairs officer", "social affairs"],
      "Bank": ["bank manager", "bank"],
      "Research": ["research coordinator", "research"],
      "PRD": ["public relations officer", "prd"],
      "Garden": ["garden supervisor", "garden"],
      "Medical": ["medical coordinator", "medical"],
      "Sports": ["sports coordinator", "sports"],
      "Store": ["store keeper", "store"],
      "Library": ["library coordinator", "library"],
      "CUC": ["cuc"],
      "Treasurer": ["treasurer", "finance"],
      "Home Banner": ["home banner"],
    };

    final String allRoleText = userRoles.join(' ').toLowerCase();

    final bool hasFullAccess =
        isSupabaseAdmin ||
        userRoles.contains('admin') ||
        userRoles.contains('executive') ||
        userRoles.contains('union director') ||
        userRoles.contains('treasurer') ||
        userRoles.contains('president') ||
        userRoles.contains('secretary') ||
        userRoles.contains('chairman') ||
        userRoles.contains('general secretary') ||
        userRoles.contains('vice president') ||
        userRoles.contains('joint secretary');

    final List<Map<String, dynamic>> allCommittees = [
      if (hasFullAccess)
        {
          "name": "Add Student",
          "subtitle": "Add manually or import from sheet",
          "icon": Icons.person_add_alt_1_rounded,
          "color": const Color(0xFF0F766E),
          "isExecutive": true,
        },
      {
        "name": "CUC",
        "icon": Icons.school_rounded,
        "color": const Color(0xFF1565C0),
        "isExecutive": true,
      },
      {
        "name": "Treasurer",
        "icon": Icons.account_balance_wallet_rounded,
        "color": const Color(0xFF00796B),
        "isExecutive": true,
      },
      {
        "name": "Home Banner",
        "subtitle": "Home background image",
        "icon": Icons.image_rounded,
        "color": const Color(0xFF0E7490),
        "isExecutive": true,
      },
      {
        "name": "Library",
        "icon": Icons.menu_book_rounded,
        "color": const Color(0xFF5D4037),
        "isExecutive": false,
      },
      {
        "name": "Literary",
        "icon": Icons.edit_note_rounded,
        "color": const Color(0xFF1E88E5),
        "isExecutive": false,
      },
      {
        "name": "Fine Arts",
        "icon": Icons.palette_rounded,
        "color": const Color(0xFF8E24AA),
        "isExecutive": false,
      },
      {
        "name": "Social Affairs",
        "icon": Icons.public_rounded,
        "color": const Color(0xFF00897B),
        "isExecutive": false,
      },
      {
        "name": "Bank",
        "icon": Icons.account_balance_rounded,
        "color": const Color(0xFF3949AB),
        "isExecutive": false,
      },
      {
        "name": "Research",
        "icon": Icons.science_rounded,
        "color": const Color(0xFF00ACC1),
        "isExecutive": false,
      },
      {
        "name": "PRD",
        "icon": Icons.campaign_rounded,
        "color": const Color(0xFFFB8C00),
        "isExecutive": false,
      },
      {
        "name": "Garden",
        "icon": Icons.local_florist_rounded,
        "color": const Color(0xFF43A047),
        "isExecutive": false,
      },
      {
        "name": "Medical",
        "icon": Icons.medical_services_rounded,
        "color": const Color(0xFFEF4444),
        "isExecutive": false,
      },
      {
        "name": "Sports",
        "icon": Icons.sports_soccer_rounded,
        "color": const Color(0xFFF4511E),
        "isExecutive": false,
      },
      {
        "name": "Store",
        "icon": Icons.shopping_cart_rounded,
        "color": const Color(0xFF546E7A),
        "isExecutive": false,
      },
    ];

    // Filter committees based on role text matching
    final List<Map<String, dynamic>> visibleModules = allCommittees.where((c) {
      if (hasFullAccess) return true;

      final reqRoles = roleRequirements[c['name']] ?? [];
      final String nameLower = c['name'].toString().toLowerCase();

      return reqRoles.any((r) => allRoleText.contains(r)) || allRoleText.contains(nameLower);
    }).toList();

    final execCommittees = visibleModules
        .where((c) => c['isExecutive'] == true)
        .toList();
    final subCommittees = visibleModules
        .where((c) => c['isExecutive'] != true)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildDashboardHeader(context),
          Expanded(
            child: visibleModules.isEmpty
                ? Center(
                    child: Text(
                      "You do not have access to any management modules.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    children: [
                      if (execCommittees.isNotEmpty) ...[
                        const Text(
                          "Executive Management",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: execCommittees.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 92,
                              ),
                          itemBuilder: (context, index) {
                            final item = execCommittees[index];
                            return _buildCompactCommitteeCard(
                              icon: item['icon'],
                              title: item['name'],
                              subtitle: item['subtitle'],
                              color: item['color'],
                              onTap: () =>
                                  _handleNavigation(context, item['name']),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (subCommittees.isNotEmpty) ...[
                        const Text(
                          "Sub Committees",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subCommittees.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 76,
                              ),
                          itemBuilder: (context, index) {
                            final item = subCommittees[index];
                            return _buildCompactCommitteeCard(
                              icon: item['icon'],
                              title: item['name'],
                              subtitle: item['subtitle'],
                              color: item['color'],
                              onTap: () =>
                                  _handleNavigation(context, item['name']),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  List<String> _managementAccessTokens(Map<String, dynamic>? data) {
    final tokens = <String>{};
    if (data == null) return tokens.toList();

    void addValue(dynamic raw) {
      if (raw == null) return;
      if (raw is Iterable) {
        for (final item in raw) {
          addValue(item);
        }
        return;
      }
      if (raw is Map) {
        for (final entry in raw.entries) {
          if (entry.value == true) addValue(entry.key);
          addValue(entry.value);
        }
        return;
      }

      for (final part
          in raw
              .toString()
              .split(RegExp(r'[,;/|]'))
              .map((value) => value.toLowerCase().trim())) {
        if (part.isNotEmpty) tokens.add(part);
      }
    }

    addValue(data['assignedRole']);
    addValue(data['assigned_role']);
    addValue(data['committee_access']);
    addValue(data['committeeAccess']);
    addValue(data['role']);
    addValue(data['designation']);

    return tokens.toList();
  }

  Widget _buildCompactCommitteeCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: subtitle == null ? 76 : 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECEA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                        height: 1.15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticUI(
    BuildContext context,
    Map<String, dynamic> data,
    String debugMsg,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 25),
      child: Column(
        children: [
          const Icon(
            Icons.lock_person_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            "Access Denied",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              if (onTabSwitch != null) {
                onTabSwitch!(0); // Switch to Home tab (index 0)
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF39544B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                "Management Console",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "Select a department to manage records",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    if (!Navigator.canPop(context)) {
      return const SizedBox.shrink(); // Hide if it's a tab
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
        label: const Text(
          "Exit Management",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String name) {
    Widget? destination;
    switch (name) {
      case "CUC":
        destination = const AdminCucPage();
        break;
      case "Students & Roles":
        destination = const StudentDirectoryPage();
        break;
      case "Add Student":
        showAddStudentOptionsSheet(context);
        return;
      case "Treasurer":
        destination = const FinanceCollectionPage(type: CollectionType.union);
        break;
      case "Home Banner":
        destination = HomeBackgroundAdminPage(
          onBack: () => Navigator.pop(context),
        );
        break;
      case "Bank":
        destination = const FinanceSavingsPage();
        break;
      case "Library":
        destination = const AdminLibraryPage();
        break;
      case "Fine Arts":
        destination = const AdminArtsPage();
        break;
      case "Sports":
        destination = const AdminSportsPage();
        break;
      case "Literary":
        destination = const AdminLiteraryPage();
        break;
      case "Research":
        destination = const AdminResearchPage();
        break;
      case "Garden":
        destination = const SubCommitteeAdminPage(
          committeeName: "Garden",
          accentColor: Color(0xFF4CAF50),
          headerIcon: Icons.eco_rounded,
        );
        break;
      case "Medical":
        destination = const SubCommitteeAdminPage(
          committeeName: "Medical",
          accentColor: Color(0xFFEF4444),
          headerIcon: Icons.medical_services_rounded,
        );
        break;
      case "Social Affairs":
        destination = const AdminSocialAffairsPage();
        break;
      case "PRD":
        destination = const PrdWorkDashboard();
        break;
      case "Store":
        destination = const FinanceCollectionPage(type: CollectionType.store);
        break;
    }
    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination!),
      );
    }
  }
}
