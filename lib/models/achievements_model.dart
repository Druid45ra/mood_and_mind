import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AchievementsModel with ChangeNotifier {
  final Database _database;
  List<Map<String, dynamic>> _achievements = [];

  AchievementsModel(this._database) {
    _loadAchievements();
  }

  List<Map<String, dynamic>> get achievements => _achievements;

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _database.query('achievements');
      _achievements = achievements;
      notifyListeners();
    } catch (e) {
      print(
          'Error loading achievements: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  Future<void> unlockAchievement(
      String name, String description, BuildContext context) async {
    try {
      final existing = await _database.query(
        'achievements',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (existing.isEmpty) {
        await _database.insert(
          'achievements',
          {
            'name': name,
            'description': description,
            'earned': 1,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        await _loadAchievements();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Congratulations! You unlocked the badge: $name'), // Text fix în engleză
          ),
        );
      }
    } catch (e) {
      print(
          'Error unlocking achievement: $e'); // TODO: Replace with a proper logging system
    }
  }

  Future<void> checkAchievements(BuildContext context) async {
    final journalEntries = await _database.query('journal');
    final habits = await _database.query('habits');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // First journal entry
    if (journalEntries.isNotEmpty) {
      await unlockAchievement(
        'First Step', // Text fix în engleză
        'You logged your first mood!', // Text fix în engleză
        context,
      );
    }

    // All habits completed today
    final todayHabits = habits.where((h) => h['date'] == today).toList();
    if (todayHabits.isNotEmpty &&
        todayHabits.every((h) => h['completed'] == 1)) {
      await unlockAchievement(
        'Perfect Day', // Text fix în engleză
        'You completed all habits today!', // Text fix în engleză
        context,
      );
    }

    // 7 days consecutive journal
    int streak = 0;
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      String dateStr = currentDate
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      if (journalEntries.any((entry) =>
          (entry['timestamp'] as String?)?.startsWith(dateStr) ?? false)) {
        streak++;
      } else {
        break;
      }
    }
    if (streak >= 7) {
      await unlockAchievement(
        '7 Day Streak', // Text fix în engleză
        'You logged your mood for 7 days in a row!', // Text fix în engleză
        context,
      );
    }
  }
}
