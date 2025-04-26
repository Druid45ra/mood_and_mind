import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/notification_service.dart';

class SettingsModel with ChangeNotifier {
  final Database _database;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _language = 'ro';

  SettingsModel(this._database);

  Database get database => _database; // Adaugă un getter public pentru database

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  String get language => _language;

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
        _language = (settings[0]['language'] as String?) ?? 'ro';
        print('Loaded language: $_language');
        notifyListeners();
      }
    } catch (e) {
      print('Error loading settings: $e');
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
        await NotificationService.scheduleDailyNotification(_language);
        await scheduleHabitNotifications();
      } else {
        await NotificationService.cancelAllNotifications();
      }
    } catch (e) {
      print('Error updating notifications: $e');
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
            title: _language == 'ro'
                ? 'E timpul pentru $name!'
                : 'Time for $name!',
            body: _language == 'ro'
                ? 'Completează-ți obiceiul acum.'
                : 'Complete your habit now.',
            hour: hour,
            minute: minute,
          );
          print('Scheduled notification for habit: $name at $hour:$minute');
        }
      }
    } catch (e) {
      print('Error scheduling habit notifications: $e');
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
      print('Error updating dark mode: $e');
    }
  }

  Future<void> updateLanguage(String value) async {
    try {
      print('Updating language to: $value');
      await _database.update(
        'settings',
        {'language': value},
        where: 'id = ?',
        whereArgs: [1],
      );
      _language = value;
      notifyListeners();
    } catch (e) {
      print('Error updating language: $e');
    }
  }
}
