import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart'; // Adăugat importul
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/journal_model.dart';

class DatabaseHelper {
  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  factory DatabaseHelper() {
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mood_and_mind.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY,
        notifications_enabled INTEGER DEFAULT 1,
        dark_mode INTEGER DEFAULT 0,
        color_theme TEXT DEFAULT 'Teal'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id INTEGER PRIMARY KEY,
        name TEXT,
        completed INTEGER DEFAULT 0,
        notification_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_entries (
        id INTEGER PRIMARY KEY,
        mood TEXT,
        intensity INTEGER,
        note TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        achieved INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT
      )
    ''');
  }

  Future<void> notifyDataChanged(BuildContext context) async {
    final journalModel = Provider.of<JournalModel>(context, listen: false);
    await journalModel.loadEntries();

    final achievementsModel =
        Provider.of<AchievementsModel>(context, listen: false);
    await achievementsModel.loadAchievements();
  }
}
