import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class SettingsModel extends ChangeNotifier {
  late Database _db;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _colorTheme = 'Teal';
  MaterialColor _themeColor = Colors.teal;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  String get colorTheme => _colorTheme;
  MaterialColor get themeColor => _themeColor;

  SettingsModel(Database db, {bool initializeNotifications = true}) {
    _db = db;
    if (initializeNotifications) {
      _initializeNotifications();
    }
    loadSettings(); // Apelăm metoda publică
  }

  Future<void> loadSettings() async {
    final settings =
        await _db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (settings.isNotEmpty) {
      _notificationsEnabled = settings[0]['notifications_enabled'] == 1;
      _darkMode = settings[0]['dark_mode'] == 1;
      _colorTheme = settings[0]['color_theme'] as String;
      _themeColor = _getMaterialColor(_colorTheme);
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _db.update(
      'settings',
      {'notifications_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _darkMode = enabled;
    await _db.update(
      'settings',
      {'dark_mode': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
    notifyListeners();
  }

  Future<void> setColorTheme(String theme) async {
    _colorTheme = theme;
    _themeColor = _getMaterialColor(theme);
    await _db.update(
      'settings',
      {'color_theme': theme},
      where: 'id = ?',
      whereArgs: [1],
    );
    notifyListeners();
  }

  MaterialColor _getMaterialColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'indigo':
        return Colors.indigo;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.teal;
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
  }

  Future<void> scheduleHabitNotifications() async {
    final habits = await _db.query('habits');
    for (var habit in habits) {
      final id = habit['id'] as int;
      final name = habit['name'] as String;
      final timeString = habit['notification_time'] as String?;
      if (timeString != null && _notificationsEnabled) {
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;

          final scheduledDate = tz.TZDateTime(tz.local, DateTime.now().year,
              DateTime.now().month, DateTime.now().day, hour, minute);

          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            'Reminder: $name',
            'It’s time for your habit!',
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'habit_channel',
                'Habit Notifications',
                channelDescription: 'Notifications for your daily habits',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    }
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer<SettingsModel>(
        builder: (context, settingsModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: Text('Enable Notifications'),
                value: settingsModel.notificationsEnabled,
                onChanged: (value) {
                  settingsModel.setNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                title: Text('Dark Mode'),
                value: settingsModel.darkMode,
                onChanged: (value) {
                  settingsModel.setDarkMode(value);
                },
              ),
              ListTile(
                title: Text('Color Theme'),
                subtitle: Text(settingsModel.colorTheme),
                onTap: () {
                  // Logic to change color theme
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
