// lib/features/sub_committees/presentation/pages/sub_committee_admin_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/universal_committee_dashboard.dart';

class SubCommitteeAdminPage extends StatelessWidget {
  final String committeeName;
  final Color accentColor;
  final IconData headerIcon;
  final VoidCallback? onBack;

  const SubCommitteeAdminPage({
    super.key,
    required this.committeeName,
    required this.accentColor,
    required this.headerIcon,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalCommitteeDashboard(
      committeeName: committeeName,
      displayTitle: "$committeeName Management",
      subtitle: "Management Console",
      onBack: () => onBack != null ? onBack!() : Navigator.pop(context),
      extraTabs: const [], // Generic committees use the default dashboard tools
    );
  }
}
