import 'package:flutter_test/flutter_test.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Tests', () {
    late Database db;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY,
          notifications_enabled INTEGER NOT NULL,
          dark_mode INTEGER NOT NULL,
          color_theme TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE habits (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          completed INTEGER NOT NULL,
          date TEXT NOT NULL,
          notification_time TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE journal_entries (
          id INTEGER PRIMARY KEY,
          mood TEXT NOT NULL,
          intensity INTEGER NOT NULL,
          note TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE achievements (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          achieved INTEGER NOT NULL
        )
      ''');
      databaseHelper = DatabaseHelper(testDatabase: db);
      await databaseHelper._initializeSettings(db); // Specificăm db explicit
    });

    tearDown(() async {
      await db.close();
    });

    test('Database initialization creates tables', () async {
      final settings = await db.query('settings');
      expect(settings, isNotEmpty);

      final habits = await db.query('habits');
      expect(habits, isEmpty);

      final journalEntries = await db.query('journal_entries');
      expect(journalEntries, isEmpty);

      final achievements = await db.query('achievements');
      expect(achievements, isEmpty);
    });

    test('Database inserts initial settings', () async {
      final settings =
          await db.query('settings', where: 'id = ?', whereArgs: [1]);
      expect(settings.length, 1);
      expect(settings[0]['notifications_enabled'], 1);
      expect(settings[0]['dark_mode'], 0);
      expect(settings[0]['color_theme'], 'Teal');
    });
  });
}
