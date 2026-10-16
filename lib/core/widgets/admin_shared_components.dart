// lib/core/widgets/admin_shared_components.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminDashboardStyles {
  static const Color primaryDark = AppColors.primaryGreen;
  static const Color primaryDarkSecondary = AppColors.darkGreen;
  static const Color pageBg = AppColors.pageBackground;
  static const Color cardBg = AppColors.cardColor;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color borderColor = AppColors.borderColor;
  static const Color dangerRed = AppColors.alertRed;

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w900,
    color: textMuted,
    letterSpacing: 1.5,
  );
}

class AdminCommitteeHeader extends StatelessWidget {
  final String committeeName;
  final String subtitle;
  final VoidCallback onBack;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final Widget? searchField;
  final Widget tabToggles;
  final Widget? summaryRow;
  final Color headerColor;

  const AdminCommitteeHeader({
    super.key,
    required this.committeeName,
    required this.subtitle,
    required this.onBack,
    required this.searchHint,
    required this.tabToggles,
    this.searchController,
    this.onSearchChanged,
    this.searchField,
    this.summaryRow,
    this.headerColor = AdminDashboardStyles.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 5, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    committeeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (summaryRow != null) ...[
                    const SizedBox(height: 15),
                    summaryRow!,
                  ],
                  if (searchField != null) ...[
                    const SizedBox(height: 20),
                    searchField!,
                  ] else ...[
                    const SizedBox(height: 18),
                    CommitteeGlassSearchBar(
                      controller: searchController,
                      searchHint: searchHint,
                      onChanged: onSearchChanged,
                    ),
                  ],
                  const SizedBox(height: 20),
                  tabToggles,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommitteeGlassSearchBar extends StatelessWidget {
  final String searchHint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const CommitteeGlassSearchBar({
    super.key,
    required this.searchHint,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: Colors.white70),
          hintText: searchHint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const AdminSectionTitle({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AdminDashboardStyles.sectionTitleStyle.copyWith(color: color),
      ),
    );
  }
}

class AdminCoreToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color? iconBackgroundColor;
  final VoidCallback onTap;

  const AdminCoreToolCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.iconBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AdminDashboardStyles.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AdminDashboardStyles.borderColor,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AdminDashboardStyles.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AdminDashboardStyles.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSupportToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? iconBackgroundColor;
  final VoidCallback onTap;
  final bool danger;

  const AdminSupportToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.iconBackgroundColor,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFF1F2) : AdminDashboardStyles.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: danger
                ? const Color(0xFFFECACA)
                : AdminDashboardStyles.borderColor,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: danger
                          ? AdminDashboardStyles.dangerRed
                          : AdminDashboardStyles.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdminDashboardStyles.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: danger
                  ? AdminDashboardStyles.dangerRed.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.45),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
