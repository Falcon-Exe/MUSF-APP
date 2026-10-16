// lib/features/prd/presentation/widgets/prd_theme.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PrdTheme {
  static const Color primaryDark = AppColors.darkNavy;
  static const Color accentPrd = AppColors.accentTeal;
  static const Color background = AppColors.pageBackground;
  static const Color surface = AppColors.cardColor;
  static const Color cardBlue = AppColors.darkNavy;

  static const Color textMain = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color textLight = Colors.white70;

  static Color getStatusColor(String status) {
    if (status == 'In Progress' || status == 'Working') return AppColors.primaryGreen;
    if (status == 'Completed' || status == 'Done') return AppColors.accentTeal;
    return AppColors.accentAmber;
  }

  static IconData getStatusIcon(String status) {
    if (status == 'In Progress' || status == 'Working') return Icons.sync_rounded;
    if (status == 'Completed' || status == 'Done') return Icons.check_circle_rounded;
    return Icons.hourglass_top_rounded;
  }

  static IconData getTypeIcon(String? type) {
    if (type == 'Video/Reel') return Icons.play_circle_fill_rounded;
    if (type == 'Certificate') return Icons.workspace_premium_rounded;
    return Icons.image_rounded;
  }
}
