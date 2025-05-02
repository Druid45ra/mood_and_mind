import 'package:flutter/material.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class JournalEntry {
  final int id;
  final String mood;
  final int intensity;
  final String note;
  final String timestamp;

  JournalEntry({
    required this.id,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.timestamp,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int,
      mood: map['mood'] as String,
      intensity: map['intensity'] as int,
      note: map['note'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'intensity': intensity,
      'note': note,
      'timestamp': timestamp,
    };
  }
}

class JournalModel extends ChangeNotifier {
  late Database _db;
  List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => _entries;

  JournalModel(DatabaseHelper databaseHelper) {
    _init(databaseHelper);
  }

  Future<void> _init(DatabaseHelper databaseHelper) async {
    _db = await databaseHelper.database;
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    final maps = await _db.query('journal_entries');
    _entries = maps.map((map) => JournalEntry.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addEntry(String mood, int intensity, String note) async {
    await _db.insert('journal_entries', {
      'mood': mood,
      'intensity': intensity,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    await _db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
    await _loadEntries();
  }
}
