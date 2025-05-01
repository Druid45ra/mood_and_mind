import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  // Constructor pentru testare, permite injectarea unei baze de date
  DatabaseHelper.test(this._database);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    AppLogger.i('Creating database...');
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mood_and_mind.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
        await db.execute('''
          CREATE TABLE achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            achieved INTEGER NOT NULL,
            date_achieved TEXT
          )
        ''');
        AppLogger.i('Database created successfully with indexes.');
      },
    );
  }

  Future<List<JournalEntry>> getJournalEntries(
      {int limit = 20, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'journal',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<List<Habit>> getHabits(
      {String? date, int limit = 20, int offset = 0}) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: date != null ? 'date = ?' : null,
      whereArgs: date != null ? [date] : null,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }
}
