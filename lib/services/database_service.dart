import 'package:mood_and_mind/utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper({Database? testDatabase}) {
    if (testDatabase != null) {
      _database = testDatabase;
    }
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mood_and_mind.db');
    AppLogger.i('Creating database...');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            completed INTEGER NOT NULL,
            date TEXT NOT NULL,
            notification_time TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE journal_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT NOT NULL,
            intensity INTEGER NOT NULL,
            note TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            achieved INTEGER NOT NULL
          )
        ''');
        await db.insert('settings', {
          'id': 1,
          'notifications_enabled': 1,
          'dark_mode': 0,
          'color_theme': 'Teal',
        });
      },
    );
  }
}
