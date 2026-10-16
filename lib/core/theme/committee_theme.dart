import 'package:flutter/material.dart';

import 'app_colors.dart';

class CommitteeTheme {
  final Color headerColor;
  final Color accentColor;
  final Color lightColor;

  const CommitteeTheme({
    required this.headerColor,
    required this.accentColor,
    required this.lightColor,
  });

  static const Color pageBackground = AppColors.pageBackground;
  static const Color cardColor = AppColors.cardColor;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color borderColor = AppColors.borderColor;
}

const CommitteeTheme _defaultCommitteeTheme = CommitteeTheme(
  headerColor: AppColors.primaryGreen,
  accentColor: AppColors.accentTeal,
  lightColor: Color(0xFFE8F8EE),
);

const Map<String, CommitteeTheme> _committeeThemes = {
  'library': CommitteeTheme(
    headerColor: Color(0xFF4E342E),
    accentColor: Color(0xFF795548),
    lightColor: Color(0xFFF3E8E2),
  ),
  'literary': CommitteeTheme(
    headerColor: AppColors.primaryGreen,
    accentColor: AppColors.accentPurple,
    lightColor: Color(0xFFF3E8FF),
  ),
  'fine arts': CommitteeTheme(
    headerColor: Color(0xFF4A2C5F),
    accentColor: Color(0xFFA855F7),
    lightColor: Color(0xFFF5E8FF),
  ),
  'social affairs': CommitteeTheme(
    headerColor: Color(0xFF0F3D3E),
    accentColor: AppColors.accentTeal,
    lightColor: Color(0xFFE0F7F4),
  ),
  'bank': CommitteeTheme(
    headerColor: Color(0xFF1E3A5F),
    accentColor: Color(0xFF10B981),
    lightColor: Color(0xFFE3FCEF),
  ),
  'bank management': CommitteeTheme(
    headerColor: Color(0xFF1E3A5F),
    accentColor: Color(0xFF10B981),
    lightColor: Color(0xFFE3FCEF),
  ),
  'research': CommitteeTheme(
    headerColor: Color(0xFF164E63),
    accentColor: Color(0xFF06B6D4),
    lightColor: Color(0xFFE0F7FA),
  ),
  'prd': CommitteeTheme(
    headerColor: Color(0xFF5F370E),
    accentColor: AppColors.accentAmber,
    lightColor: Color(0xFFFFF3D6),
  ),
  'prd command center': CommitteeTheme(
    headerColor: Color(0xFF5F370E),
    accentColor: AppColors.accentAmber,
    lightColor: Color(0xFFFFF3D6),
  ),
  'garden': CommitteeTheme(
    headerColor: Color(0xFF2F4F2F),
    accentColor: Color(0xFF22C55E),
    lightColor: Color(0xFFE8F8EE),
  ),
  'medical': CommitteeTheme(
    headerColor: Color(0xFF7F1D1D),
    accentColor: AppColors.alertRed,
    lightColor: Color(0xFFFFE4E6),
  ),
  'sports': CommitteeTheme(
    headerColor: Color(0xFF064E3B),
    accentColor: Color(0xFF34D399),
    lightColor: Color(0xFFDFFBF0),
  ),
  'store': CommitteeTheme(
    headerColor: Color(0xFF374151),
    accentColor: Color(0xFF64748B),
    lightColor: Color(0xFFEFF3F6),
  ),
  'store collection': CommitteeTheme(
    headerColor: Color(0xFF374151),
    accentColor: Color(0xFF64748B),
    lightColor: Color(0xFFEFF3F6),
  ),
  'treasurer': CommitteeTheme(
    headerColor: AppColors.darkNavy,
    accentColor: Color(0xFF10B981),
    lightColor: Color(0xFFE3FCEF),
  ),
  'treasury': CommitteeTheme(
    headerColor: AppColors.darkNavy,
    accentColor: Color(0xFF10B981),
    lightColor: Color(0xFFE3FCEF),
  ),
  'cuc': CommitteeTheme(
    headerColor: Color(0xFF1E293B),
    accentColor: Color(0xFF3B82F6),
    lightColor: Color(0xFFEFF6FF),
  ),
};

CommitteeTheme getCommitteeTheme(String committeeName) {
  final normalized = committeeName.trim().toLowerCase();
  return _committeeThemes[normalized] ?? _defaultCommitteeTheme;
}
