import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/models/habit.dart';

void main() {
  // Inițializăm sqflite_ffi pentru testare pe desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Tests', () {
    late Database db;

    setUp(() async {
      // Creăm o bază de date temporară în memorie pentru fiecare test
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // Creăm tabelele manual, așa cum face DatabaseHelper
      await db.execute('''
        CREATE TABLE journal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mood TEXT NOT NULL,
          intensity INTEGER NOT NULL,
          note TEXT,
          timestamp TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE habits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          completed INTEGER NOT NULL,
          date TEXT NOT NULL,
          notification_time TEXT
        )
      ''');
      await db.execute('CREATE INDEX idx_habits_date ON habits (date)');
    });

    tearDown(() async {
      // Închidem baza de date după fiecare test
      await db.close();
    });

    test('Save and retrieve a journal entry', () async {
      // Arrange: Pregătim o intrare în jurnal
      final entry = {
        'mood': 'Happy',
        'intensity': 8,
        'note': 'Feeling great today!',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Act: Salvăm intrarea
      await db.insert('journal', entry);

      // Act: Citim intrările
      final databaseHelper =
          DatabaseHelper.test(db); // Folosim o metodă auxiliară
      final entries = await databaseHelper.getJournalEntries();

      // Assert: Verificăm că intrarea a fost salvată și citită corect
      expect(entries.length, 1);
      expect(entries[0].mood, 'Happy');
      expect(entries[0].intensity, 8);
      expect(entries[0].note, 'Feeling great today!');
    });

    test('Save and retrieve a habit', () async {
      // Arrange: Pregătim un obicei
      final habit = {
        'name': 'Drink water',
        'completed': 0,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'notification_time': '08:00',
      };

      // Act: Salvăm obiceiul
      await db.insert('habits', habit);

      // Act: Citim obiceiurile
      final databaseHelper =
          DatabaseHelper.test(db); // Folosim o metodă auxiliară
      final habits = await databaseHelper.getHabits();

      // Assert: Verificăm că obiceiul a fost salvat și citit corect
      expect(habits.length, 1);
      expect(habits[0].name, 'Drink water');
      expect(habits[0].isCompleted, false);
      expect(habits[0].notificationTime, '08:00');
    });
  });
}
