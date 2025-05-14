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
        _achievements.any((a) => a['name'] == name && a['achieved'] == 1);
    if (!existing) {
      await _database.insert(
        'achievements',
        {
          'name': name,
          'description': description,
          'achieved': 1,
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

  Future<int> _getJournalEntriesCount() async {
    final List<Map<String, dynamic>> entries = await _database.query('journal_entries');
    return entries.length;
  }

  Future<void> checkAchievements(BuildContext context) async {
    final journalEntriesCount = await _getJournalEntriesCount();
    final completedHabits = await _getCompletedHabitsCount();

    // First Entry
    if (journalEntriesCount >= 1) {
      await _addAchievement('First Entry', 'Log your first journal entry');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement Unlocked: First Entry!'),
          backgroundColor: Colors.teal,
        ),
      );
    }

    // Consistency Star (5 consecutive days of journal entries)
    final List<Map<String, dynamic>> entries =
        await _database.query('journal_entries', orderBy: 'timestamp DESC');
    if (entries.length >= 5) {
      bool hasConsecutiveDays = false;
      List<DateTime> dates = entries
          .map((e) => DateTime.parse(e['timestamp'] as String))
          .toList();
      dates.sort((a, b) => a.compareTo(b));

      for (int i = 0; i <= dates.length - 5; i++) {
        bool consecutive = true;
        for (int j = 0; j < 4; j++) {
          final currentDay = dates[i + j];
          final nextDay = dates[i + j + 1];
          if (nextDay.difference(currentDay).inDays != 1) {
            consecutive = false;
            break;
          }
        }
        if (consecutive) {
          hasConsecutiveDays = true;
          break;
        }
      }

      if (hasConsecutiveDays) {
        await _addAchievement('Consistency Star', 'Log entries 5 days in a row');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievement Unlocked: Consistency Star!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }

    // Habit Master (10 completed habits)
    if (completedHabits >= 10) {
      await _addAchievement('Habit Master', 'Completed 10 habits!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement Unlocked: Habit Master!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }
}
