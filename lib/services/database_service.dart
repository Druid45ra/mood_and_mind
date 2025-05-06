import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  Database? _testDatabase;

  factory DatabaseHelper({Database? testDatabase}) {
    _instance._testDatabase = testDatabase;
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    print('Initializing database...');
    _database = await _initDatabase();
    print('Database initialized successfully');
    return _database!;
  }

  Future<Database> get testDatabase async {
    if (_testDatabase != null) return _testDatabase!;
    _testDatabase = await _initDatabase();
    return _testDatabase!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'mood_and_mind.db');

    return await openDatabase(dbPath, version: 1,
        onCreate: (db, version) async {
      print('Creating tables...');
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
          earned INTEGER NOT NULL,
          timestamp TEXT
        )
      ''');
      await initializeSettings(db);
      print('Tables created successfully');
    });
  }

  Future<void> initializeSettings(Database db) async {
    await db.insert(
      'settings',
      {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
        'color_theme': 'Teal',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> notifyDataChanged(BuildContext context) async {
    final habitsModel = Provider.of<HabitsModel>(context, listen: false);
    final journalModel = Provider.of<JournalModel>(context, listen: false);
    final achievementsModel =
        Provider.of<AchievementsModel>(context, listen: false);

    await habitsModel.refresh();
    await journalModel.loadEntries();
    await achievementsModel.loadAchievements();
  }
}
