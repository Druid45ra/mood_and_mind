import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/utils/logger.dart';

class SettingsModel extends ChangeNotifier {
  final Database _database;
  bool _darkMode = false;
  String _colorTheme = 'Teal'; // Tema implicită

  SettingsModel(this._database);

  bool get darkMode => _darkMode;
  String get colorTheme => _colorTheme;

  Future<void> loadSettings() async {
    try {
      final settings =
          await _database.query('settings', where: 'id = ?', whereArgs: [1]);
      if (settings.isNotEmpty) {
        _darkMode = settings.first['dark_mode'] == 1;
        _colorTheme = settings.first['color_theme']?.toString() ?? 'Teal';
      }
      notifyListeners();
      AppLogger.i(
          'Settings loaded: darkMode=$_darkMode, colorTheme=$_colorTheme');
    } catch (e) {
      AppLogger.e('Error loading settings: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _database.update(
      'settings',
      {'dark_mode': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
    notifyListeners();
    AppLogger.i('Dark mode set to $value');
  }

  Future<void> setColorTheme(String theme) async {
    _colorTheme = theme;
    await _database.update(
      'settings',
      {'color_theme': theme},
      where: 'id = ?',
      whereArgs: [1],
    );
    notifyListeners();
    AppLogger.i('Color theme set to $theme');
  }

  Future<void> scheduleHabitNotifications() async {
    // Logica existentă pentru notificări (dacă există)
  }
}
