import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mood_and_mind/models/settings_model.dart'; // Adăugăm importul

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SettingsModel Tests', () {
    late Database db;
    late SettingsModel settingsModel;

    setUp(() async {
      // Creăm o bază de date temporară în memorie
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY,
          notifications_enabled INTEGER NOT NULL,
          dark_mode INTEGER NOT NULL,
          color_theme TEXT NOT NULL
        )
      ''');
      await db.insert('settings', {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
        'color_theme': 'Teal',
      });

      // Inițializăm SettingsModel
      settingsModel = SettingsModel(db);
      await Future.delayed(
          const Duration(milliseconds: 100)); // Așteptăm încărcarea setărilor
    });

    tearDown(() async {
      await db.close();
    });

    test('Set notifications enabled', () async {
      // Act: Dezactivăm notificările
      await settingsModel.setNotificationsEnabled(false);

      // Assert: Verificăm că setarea a fost actualizată
      expect(settingsModel.notificationsEnabled, false);

      // Verificăm în baza de date
      final settings =
          await db.query('settings', where: 'id = ?', whereArgs: [1]);
      expect(settings[0]['notifications_enabled'], 0);
    });

    test('Set dark mode', () async {
      // Act: Activăm Dark Mode
      await settingsModel.setDarkMode(true);

      // Assert: Verificăm că setarea a fost actualizată
      expect(settingsModel.darkMode, true);

      // Verificăm în baza de date
      final settings =
          await db.query('settings', where: 'id = ?', whereArgs: [1]);
      expect(settings[0]['dark_mode'], 1);
    });

    test('Set color theme', () async {
      // Act: Schimbăm tema de culoare
      await settingsModel.setColorTheme('Indigo');

      // Assert: Verificăm că setarea a fost actualizată
      expect(settingsModel.colorTheme, 'Indigo');
      expect(settingsModel.themeColor, Colors.indigo);

      // Verificăm în baza de date
      final settings =
          await db.query('settings', where: 'id = ?', whereArgs: [1]);
      expect(settings[0]['color_theme'], 'Indigo');
    });
  });
}
