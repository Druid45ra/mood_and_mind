import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/settings_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications(
      Database database, SettingsModel settingsModel) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
      );
      if (tables.isEmpty) {
        await database.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
        );
        await database.insert('settings', {
          'id': 1,
          'notifications_enabled': 1,
          'dark_mode': 0,
          'language': 'ro',
        });
      }

      if (settingsModel.notificationsEnabled) {
        await scheduleDailyNotification(settingsModel.language);
        await settingsModel.scheduleHabitNotifications();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static Future<void> scheduleDailyNotification(String language) async {
    await flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      language == 'ro' ? 'Cum te simți astăzi?' : 'How do you feel today?',
      language == 'ro'
          ? 'Deschide Mood & Mind și înregistrează-ți starea!'
          : 'Open Mood & Mind and log your mood!',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification',
          'Daily Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    print('Daily notification scheduled successfully.');
  }

  static Future<void> scheduleHabitNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_notification',
          'Habit Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
