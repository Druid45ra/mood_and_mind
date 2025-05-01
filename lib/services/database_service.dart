import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  DatabaseHelper.withDatabase(this._database);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      p.join(await getDatabasesPath(), 'mood_mind.db'),
      onCreate: (db, version) async {
        AppLogger.i('Creating database...');
        await db.execute(
          'CREATE TABLE journal(id INTEGER PRIMARY KEY AUTOINCREMENT, mood TEXT, intensity INTEGER, note TEXT, timestamp TEXT)',
        );
        await db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT, notification_time TEXT)',
        );
        await db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, color_theme TEXT)',
        );
        await db.execute(
          'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
        );
        await db.insert('settings', {
          'id': 1,
          'notifications_enabled': 1,
          'dark_mode': 0,
          'color_theme': 'Teal',
        });
        // Creăm indecși pentru coloanele des folosite
        await db.execute(
            'CREATE INDEX idx_journal_timestamp ON journal(timestamp)');
        await db.execute('CREATE INDEX idx_habits_date ON habits(date)');
        AppLogger.i('Database created successfully with indexes.');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.i(
            'Upgrading database from version $oldVersion to $newVersion...');
        if (oldVersion < 2) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
          );
          if (tables.isEmpty) {
            await db.execute(
              'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, color_theme TEXT)',
            );
            await db.insert('settings', {
              'id': 1,
              'notifications_enabled': 1,
              'dark_mode': 0,
              'color_theme': 'Teal',
            });
          }
        }
        if (oldVersion < 3) {
          final columns = await db.rawQuery("PRAGMA table_info(journal)");
          bool hasIntensity = columns.any((col) => col['name'] == 'intensity');
          if (!hasIntensity) {
            await db
                .execute('ALTER TABLE journal ADD COLUMN intensity INTEGER');
            AppLogger.i('Added intensity column to journal table.');
          }
        }
        if (oldVersion < 4) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='habits'",
          );
          if (tables.isNotEmpty) {
            await db.execute(
              'CREATE TABLE habits_temp(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT)',
            );
            await db.execute(
              'INSERT INTO habits_temp(name, completed, date) SELECT name, completed, date FROM habits',
            );
            await db.execute('DROP TABLE habits');
            await db.execute('ALTER TABLE habits_temp RENAME TO habits');
            AppLogger.i('Updated habits table schema.');
          }
        }
        if (oldVersion < 5) {
          final columns = await db.rawQuery("PRAGMA table_info(habits)");
          bool hasNotificationTime =
              columns.any((col) => col['name'] == 'notification_time');
          if (!hasNotificationTime) {
            await db.execute(
                'ALTER TABLE habits ADD COLUMN notification_time TEXT');
            AppLogger.i('Added notification_time column to habits table.');
          }
        }
        if (oldVersion < 6) {
          final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'",
          );
          if (tables.isEmpty) {
            await db.execute(
              'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
            );
            AppLogger.i('Created achievements table.');
          }
        }
        if (oldVersion < 7) {
          final columns = await db.rawQuery("PRAGMA table_info(settings)");
          bool hasLanguage = columns.any((col) => col['name'] == 'language');
          if (hasLanguage) {
            await db.execute('ALTER TABLE settings RENAME TO settings_temp');
            await db.execute(
              'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, color_theme TEXT)',
            );
            await db.execute(
              'INSERT INTO settings(id, notifications_enabled, dark_mode) SELECT id, notifications_enabled, dark_mode FROM settings_temp',
            );
            await db.execute('DROP TABLE settings_temp');
            AppLogger.i('Removed language column from settings table.');
          }
        }
        if (oldVersion < 8) {
          final columns = await db.rawQuery("PRAGMA table_info(settings)");
          bool hasColorTheme =
              columns.any((col) => col['name'] == 'color_theme');
          if (!hasColorTheme) {
            await db
                .execute('ALTER TABLE settings ADD COLUMN color_theme TEXT');
            await db.update(
              'settings',
              {'color_theme': 'Teal'},
              where: 'id = ?',
              whereArgs: [1],
            );
            AppLogger.i('Added color_theme column to settings table.');
          }
        }
        if (oldVersion < 9) {
          // Adăugăm indecșii pentru utilizatorii existenți
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_journal_timestamp ON journal(timestamp)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_habits_date ON habits(date)');
          AppLogger.i('Added indexes for journal(timestamp) and habits(date).');
        }
        AppLogger.i('Database upgraded successfully.');
      },
      version:
          9, // Incrementăm versiunea pentru a reflecta adăugarea indecșilor
    );
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('journal');
    return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
  }
}
