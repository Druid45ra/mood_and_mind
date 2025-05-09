import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/journal_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class AchievementsModel extends ChangeNotifier {
  List<Map<String, dynamic>> _achievements = [];
  late Database _db;

  AchievementsModel(Database db) {
    _db = db;
    _initAchievements();
  }

  List<Map<String, dynamic>> get achievements => _achievements;

  Future<void> _initAchievements() async {
    _achievements = await _db.query('achievements');
    if (_achievements.isEmpty) {
      await _db.insert('achievements', {
        'name': 'First Entry',
        'description': 'Log your first journal entry',
        'achieved': 0,
      });
      await _db.insert('achievements', {
        'name': 'Consistency Star',
        'description': 'Log entries 5 days in a row',
        'achieved': 0,
      });
      await _db.insert('achievements', {
        'name': 'Habit Master',
        'description': 'Complete a habit 7 days in a row',
        'achieved': 0,
      });
      _achievements = await _db.query('achievements');
    }
    notifyListeners();
  }

  Future<void> loadAchievements() async {
    _achievements = await _db.query('achievements');
    notifyListeners();
  }

  Future<void> checkAchievements(BuildContext context) async {
    final journalModel = Provider.of<JournalModel>(context, listen: false);
    final entries = journalModel.entries;

    for (var achievement in _achievements) {
      if (achievement['achieved'] == 1) continue;

      if (achievement['name'] == 'First Entry' && entries.isNotEmpty) {
        await _db.update(
          'achievements',
          {'achieved': 1, 'timestamp': DateTime.now().toIso8601String()},
          where: 'name = ?',
          whereArgs: ['First Entry'],
        );
      }

      if (achievement['name'] == 'Consistency Star') {
        if (entries.length >= 5) {
          // Check for 5 consecutive days of entries
          bool hasConsecutiveDays = true;
          for (int i = 0; i < 5; i++) {
            final entryDate = DateTime.parse(entries[i].timestamp);
            final expectedDate = DateTime.now().subtract(Duration(days: 4 - i));
            if (entryDate.day != expectedDate.day ||
                entryDate.month != expectedDate.month ||
                entryDate.year != expectedDate.year) {
              hasConsecutiveDays = false;
              break;
            }
          }
          if (hasConsecutiveDays) {
            await _db.update(
              'achievements',
              {'achieved': 1, 'timestamp': DateTime.now().toIso8601String()},
              where: 'name = ?',
              whereArgs: ['Consistency Star'],
            );
          }
        }
      }

      if (achievement['name'] == 'Habit Master') {
        // This would require habit tracking logic to be implemented
      }
    }
    await loadAchievements();
  }
}
