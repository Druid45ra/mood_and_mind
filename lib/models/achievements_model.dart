import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:mood_and_mind/services/database_service.dart';

class AchievementsModel extends ChangeNotifier {
  final Database _database;
  List<Map<String, dynamic>> _achievements = [];
  BuildContext? _context;

  AchievementsModel(this._database) {
    loadAchievements();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  List<Map<String, dynamic>> get achievements => _achievements;

  Future<void> loadAchievements() async {
    try {
      final List<Map<String, dynamic>> loadedAchievements =
          await _database.query('achievements');
      _achievements = loadedAchievements;
      notifyListeners();
      AppLogger.i('Loaded ${_achievements.length} achievements.');
    } catch (e) {
      AppLogger.e('Error loading achievements: $e');
    }
  }

  Future<void> _addAchievement(String name, String description) async {
    final existing =
        _achievements.any((a) => a['name'] == name && a['earned'] == 1);
    if (!existing) {
      await _database.insert(
        'achievements',
        {
          'name': name,
          'description': description,
          'earned': 1,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadAchievements();
      AppLogger.i('Achievement earned: $name');
      if (_context != null) {
        await DatabaseHelper().notifyDataChanged(_context!);
      }
    }
  }

  Future<int> _getCompletedHabitsCount() async {
    final List<Map<String, dynamic>> habits = await _database.query(
      'habits',
      where: 'completed = ?',
      whereArgs: [1],
    );
    return habits.length;
  }

  Future<void> checkAchievements(BuildContext context) async {
    // Verificăm realizarea pentru 10 obiceiuri completate
    final completedHabits = await _getCompletedHabitsCount();
    if (completedHabits >= 10) {
      await _addAchievement(
        'Habit Master',
        'Completed 10 habits!',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement Unlocked: Habit Master!'),
          backgroundColor: Colors.teal,
        ),
      );
    }

    // Alte verificări pentru realizări (ex. existente)
    final journalEntries = await _database.query('journal_entries');
    if (journalEntries.length >= 5) {
      await _addAchievement(
        'Journal Enthusiast',
        'Added 5 journal entries!',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement Unlocked: Journal Enthusiast!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }
}
