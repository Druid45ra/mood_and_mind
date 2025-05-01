import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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

  SettingsModel(Database db) {
    _db = db;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.query('settings', where: 'id = ?', whereArgs: [1]);
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
}
