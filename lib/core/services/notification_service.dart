import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  static FlutterLocalNotificationsPlugin get _plugin {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();
    return _notificationsPlugin!;
  }

  static Future<void> init() async {
    if (kIsWeb) return; // Skip on web

    tz.initializeTimeZones();
    
    // 🟢 FORCES the S24 to show the app in the "Alarms & Reminders" list
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // Added this back: explicitly requests the exact alarms permission from the user
      await androidImplementation.requestExactAlarmsPermission();
    }
    
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings();
    
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings, 
    );

    // FIXED: Added required 'settings:' label to clear editor errors
    await _plugin.initialize(settings: initSettings);
  }

  static Future<void> scheduleEventReminder(int eventId, String title, DateTime eventDate) async {
    if (kIsWeb) return; // Skip on web

    // 🟢 Calculate 5:00 PM the previous day
    // E.g., if event is Oct 10th, reminder fires Oct 9th at 17:00 (5 PM)
    DateTime dayBeforeAt5PM = DateTime(
      eventDate.year, 
      eventDate.month, 
      eventDate.day - 1, 
      17, // 5 PM
      0
    );

    // Make sure we don't try to schedule a notification in the past
    if (dayBeforeAt5PM.isBefore(DateTime.now())) {
      return; 
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(dayBeforeAt5PM, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'union_events', 
      'Union Event Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(), 
    );

    await _plugin.zonedSchedule(
      id: eventId,
      title: 'Event Tomorrow! 🎉',
      body: title,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      // Reverted to exact to force the system to honor the alarm
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}