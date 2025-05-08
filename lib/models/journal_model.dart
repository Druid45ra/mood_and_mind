import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/achievements_model.dart';

class JournalModel extends ChangeNotifier {
  late Database _db;
  List<JournalEntry> _entries = [];
  bool _disposed = false;
  BuildContext? _context;

  List<JournalEntry> get entries => _entries;

  JournalModel(DatabaseHelper databaseHelper) {
    _init(databaseHelper);
  }

  Future<void> _init(DatabaseHelper databaseHelper) async {
    try {
      _db = await databaseHelper.database;
      await loadEntries();
    } catch (e) {
      debugPrint('Error initializing JournalModel: $e');
    }
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> loadEntries() async {
    try {
      final maps = await _db.query('journal_entries');
      _entries = maps.map((map) => JournalEntry.fromMap(map)).toList();
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
    }
  }

  Future<void> addEntry(String mood, int intensity, String note) async {
    try {
      await _db.insert('journal_entries', {
        'mood': mood,
        'intensity': intensity,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await loadEntries();
      if (!_disposed) notifyListeners();
      if (_context != null) {
        await DatabaseHelper().notifyDataChanged(_context!);
        final achievementsModel =
            Provider.of<AchievementsModel>(_context!, listen: false);
        await achievementsModel.checkAchievements(_context!);
      }
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await _db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
      await loadEntries();
      if (!_disposed) notifyListeners();
      if (_context != null) {
        await DatabaseHelper().notifyDataChanged(_context!);
        final achievementsModel =
            Provider.of<AchievementsModel>(_context!, listen: false);
        await achievementsModel.checkAchievements(_context!);
      }
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _context = null;
    super.dispose();
  }
}
