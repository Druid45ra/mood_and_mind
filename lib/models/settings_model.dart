import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/notification_service.dart';

class SettingsModel with ChangeNotifier {
  final Database _database;
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  SettingsModel(this._database);

  Database get database => _database;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;

  Future<void> loadSettings() async {
    try {
      final settings = await _database.query(
        'settings',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (settings.isNotEmpty) {
        _notificationsEnabled = settings[0]['notifications_enabled'] == 1;
        _darkMode = settings[0]['dark_mode'] == 1;
        notifyListeners();
      }
    } catch (e) {
      print(
          'Error loading settings: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  Future<void> updateNotifications(bool value) async {
    try {
      await _database.update(
        'settings',
        {'notifications_enabled': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );
      _notificationsEnabled = value;
      notifyListeners();
      if (value) {
        await NotificationService.scheduleDailyNotification();
        await scheduleHabitNotifications();
      } else {
        await NotificationService.cancelAllNotifications();
      }
    } catch (e) {
      print(
          'Error updating notifications: $e'); // TODO: Replace with a proper logging system
    }
  }

  Future<void> scheduleHabitNotifications() async {
    if (!_notificationsEnabled) return;
    try {
      final habits = await _database.query('habits');
      for (var habit in habits) {
        if (habit['notification_time'] != null) {
          final timeParts = (habit['notification_time'] as String).split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final id = habit['id'] as int;
          final name = habit['name'] as String;
          await NotificationService.scheduleHabitNotification(
            id: id,
            title: 'Time for $name!', // Text fix în engleză
            body: 'Complete your habit now.', // Text fix în engleză
            hour: hour,
            minute: minute,
          );
          print(
              'Scheduled notification for habit: $name at $hour:$minute'); // TODO: Replace with a proper logging system
        }
      }
    } catch (e) {
      print(
          'Error scheduling habit notifications: $e'); // TODO: Replace with a proper logging system
    }
  }

  Future<void> updateDarkMode(bool value) async {
    try {
      await _database.update(
        'settings',
        {'dark_mode': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );
      _darkMode = value;
      notifyListeners();
    } catch (e) {
      print(
          'Error updating dark mode: $e'); // TODO: Replace with a proper logging system
    }
  }
}
