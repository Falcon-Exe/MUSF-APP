import 'package:flutter/material.dart';
import '../features/library/presentation/pages/admin_library_page.dart';
import '../features/arts/presentation/pages/admin_arts_page.dart';
import '../features/sports/presentation/pages/admin_sports_page.dart';
import '../features/literary/presentation/pages/admin_literary_page.dart';
import '../features/research/presentation/pages/admin_research_page.dart';
import '../features/social_affairs/presentation/pages/admin_social_affairs_page.dart';
import '../features/prd/presentation/pages/prd_work_dashboard.dart';
import '../features/finance/presentation/pages/finance_collection_page.dart';
import '../features/finance/presentation/pages/finance_savings_page.dart';
import '../features/finance/data/repositories/finance_repository.dart';
import '../features/cuc/presentation/pages/admin_cuc_page.dart';
import '../features/leadership/presentation/pages/admin_leadership_page.dart';
import '../features/sub_committees/presentation/pages/sub_committee_admin_page.dart';

class AdminPageHelper {
  static const Map<String, List<String>> roleRequirements = {
    "Literary": ["literary coordinator"],
    "Fine Arts": ["fine arts coordinator"],
    "Social Affairs": ["social affairs officer"],
    "Finance": ["finance manager"],
    "Research": ["research coordinator"],
    "PRD": ["public relations officer"],
    "Garden": ["garden supervisor"],
    "Medical": ["medical coordinator"],
    "Sports": ["sports coordinator"],
    "Store Fund": ["store keeper"],
    "Library": ["library coordinator"],
  };

  static Widget? getPageByName(String name, {VoidCallback? onBack}) {
    switch (name) {
      case "CUC":
        return AdminCucPage(onBack: onBack);
      case "Admin":
        return HomeBackgroundAdminPage(onBack: onBack);
      case "Home Banner":
        return HomeBackgroundAdminPage(onBack: onBack);
      case "Union Fund":
        return const FinanceCollectionPage(type: CollectionType.union);
      case 'Numbered Ledger':
        return const FinanceSavingsPage();
      case "Library":
        return AdminLibraryPage(onBack: onBack);
      case "Fine Arts":
        return AdminArtsPage(onBack: onBack);
      case "Sports":
        return AdminSportsPage(onBack: onBack);
      case "Literary":
        return AdminLiteraryPage(onBack: onBack);
      case "Research":
        return AdminResearchPage(onBack: onBack);
      case "Garden":
        return SubCommitteeAdminPage(
          committeeName: "Garden",
          accentColor: const Color(0xFF4CAF50),
          headerIcon: Icons.eco_rounded,
          onBack: onBack,
        );
      case "Medical":
        return SubCommitteeAdminPage(
          committeeName: "Medical",
          accentColor: const Color(0xFFEF4444),
          headerIcon: Icons.medical_services_rounded,
          onBack: onBack,
        );
      case "Social Affairs":
        return AdminSocialAffairsPage(onBack: onBack);
      case "PRD":
        return PrdWorkDashboard(onBack: onBack);
      case 'Store Fund':
        return const FinanceCollectionPage(type: CollectionType.store);
      default:
        return null;
    }
  }

  static List<String> getAccessibleCommittees(
    Map<String, dynamic>? studentData,
  ) {
    if (studentData == null) return [];

    final String assignedRole = (studentData['assignedRole']?.toString() ?? '')
        .toLowerCase();
    final String baseRole = (studentData['role']?.toString() ?? '')
        .toLowerCase();
    final String designation = (studentData['designation']?.toString() ?? '')
        .toLowerCase();

    final List<String> userRoles = [assignedRole, baseRole, designation];

    final bool hasFullAccess =
        userRoles.contains('executive') ||
        userRoles.contains('union director') ||
        userRoles.contains('treasurer') ||
        userRoles.contains('president') ||
        userRoles.contains('secretary');

    if (hasFullAccess) {
      return [
        "CUC",
        "Home Banner",
        "Union Fund",
        "Library",
        "Fine Arts",
        "Social Affairs",
        "Bank",
        "Research",
        "PRD",
        "Garden",
        "Medical",
        "Sports",
        "Store",
      ];
    }

    List<String> accessible = [];
    roleRequirements.forEach((committee, roles) {
      if (roles.any((r) => userRoles.contains(r))) {
        accessible.add(committee);
      }
    });

    return accessible;
  }
}
