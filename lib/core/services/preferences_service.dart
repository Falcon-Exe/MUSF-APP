import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Theme Mode ---
  static const String _themeModeKey = 'theme_mode';

  static ThemeMode getThemeMode() {
    try {
      final String? themeStr = _prefs.getString(_themeModeKey);
      if (themeStr == 'dark') return ThemeMode.dark;
      if (themeStr == 'light') return ThemeMode.light;
      return ThemeMode.system;
    } catch (e) {
      return ThemeMode.system; // Fallback if not initialized
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.dark) {
      await _prefs.setString(_themeModeKey, 'dark');
    } else if (mode == ThemeMode.light) {
      await _prefs.setString(_themeModeKey, 'light');
    } else {
      await _prefs.setString(_themeModeKey, 'system');
    }
  }

  // --- Notification Preferences ---
  static bool getGlobalNotifications() {
    try {
      return _prefs.getBool('notif_global') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setGlobalNotifications(bool v) async {
    try {
      await _prefs.setBool('notif_global', v);
    } catch (_) {
      // Ignore preference write errors
    }
  }

  static bool getEventReminders() {
    try {
      return _prefs.getBool('notif_events') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEventReminders(bool v) async {
    try {
      await _prefs.setBool('notif_events', v);
    } catch (_) {
      // Ignore preference write errors
    }
  }

  static bool getLibraryDueDates() {
    try {
      return _prefs.getBool('notif_library') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setLibraryDueDates(bool v) async {
    try {
      await _prefs.setBool('notif_library', v);
    } catch (_) {
      // Ignore preference write errors
    }
  }

  static bool getComplaintUpdates() {
    try {
      return _prefs.getBool('notif_complaints') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setComplaintUpdates(bool v) async {
    try {
      await _prefs.setBool('notif_complaints', v);
    } catch (_) {
      // Ignore preference write errors
    }
  }
}

// Global Notifier for the App Theme
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
