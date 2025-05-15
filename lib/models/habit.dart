import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/achievements_model.dart';

class Habit {
  final int id;
  final String name;
  final bool isCompleted;
  final String date;
  final String? notificationTime;

  Habit({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.date,
    this.notificationTime,
  });
}

class HabitsModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  late Database _db;
  List<Habit> _habits = [];
  BuildContext? _context;

  HabitsModel(this._databaseHelper) {
    initialize();
  }

  Future<void> initialize() async {
    _db = await _databaseHelper.database;
    await _loadHabits();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> addHabit(
      String name, String date, String? notificationTime) async {
    // Setăm data curentă implicit dacă nu este furnizată
    final effectiveDate =
        date.isEmpty ? DateTime.now().toIso8601String().substring(0, 10) : date;
    try {
      final id = await _db.insert('habits', {
        'name': name,
        'completed': 0,
        'date': effectiveDate,
        'notification_time': notificationTime,
      });
      final newHabit = Habit(
        id: id,
        name: name,
        isCompleted: false,
        date: effectiveDate,
        notificationTime: notificationTime,
      );
      _habits.add(newHabit);
      notifyListeners();
      if (_context != null) {
        await DatabaseHelper().notifyDataChanged(_context!);
        final achievementsModel =
            Provider.of<AchievementsModel>(_context!, listen: false);
        await achievementsModel.checkAchievements(_context!);
      }
    } catch (e) {
      throw Exception('Error adding habit: $e');
    }
  }

  Future<void> toggleHabitCompletion(int id) async {
    final habitIndex = _habits.indexWhere((h) => h.id == id);
    if (habitIndex != -1) {
      final habit = _habits[habitIndex];
      final newCompleted = !habit.isCompleted;
      try {
        await _db.update(
          'habits',
          {'completed': newCompleted ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
        final updatedHabit = Habit(
          id: habit.id,
          name: habit.name,
          isCompleted: newCompleted,
          date: habit.date,
          notificationTime: habit.notificationTime,
        );
        _habits[habitIndex] = updatedHabit;
        notifyListeners();
        if (_context != null) {
          await DatabaseHelper().notifyDataChanged(_context!);
          final achievementsModel =
              Provider.of<AchievementsModel>(_context!, listen: false);
          await achievementsModel.checkAchievements(_context!);
        }
      } catch (e) {
        throw Exception('Error toggling habit: $e');
      }
    }
  }

  Future<void> _loadHabits() async {
    try {
      final maps = await _db.query('habits');
      _habits = maps
          .map((map) => Habit(
                id: map['id'] as int,
                name: map['name'] as String,
                isCompleted: (map['completed'] as int) == 1,
                date: map['date'] as String,
                notificationTime: map['notification_time'] as String?,
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Error loading habits: $e');
    }
  }

  Future<void> refresh() async {
    await _loadHabits();
  }

  @override
  void dispose() {
    _habits.clear();
    _context = null;
    super.dispose();
  }
}
