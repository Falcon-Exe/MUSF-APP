// lib/features/finance/presentation/widgets/finance_theme.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FinanceTheme {
  // Common Colors
  static const Color primaryDark = AppColors.darkNavy;
  static const Color cardBlue = AppColors.darkNavy;
  static const Color background = AppColors.pageBackground;
  
  static const Color incomeGreen = AppColors.accentTeal;
  static const Color expenseRed = AppColors.alertRed;
  static const Color primaryBlue = AppColors.primaryGreen;

  static const Color textMain = AppColors.textPrimary;
  static const Color textSub = AppColors.textMuted;

  // Status Colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return incomeGreen;
      case 'rejected':
        return expenseRed;
      default:
        return AppColors.accentAmber;
    }
  }

  // Common Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
