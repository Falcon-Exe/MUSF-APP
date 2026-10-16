import 'package:flutter/material.dart';

class LibraryTheme {
  static const Color primary = Color(0xFF1E1B4B); // Midnight Indigo
  static const Color accent = Color(0xFFC5A059);  // Classic Gold
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color alert = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: border),
  );
}
