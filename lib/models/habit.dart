import 'package:flutter/foundation.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

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

  HabitsModel(this._databaseHelper) {
    _initialize();
  }

  Future<void> _initialize() async {
    _db =
        await _databaseHelper.testDatabase; // Folosim testDatabase pentru teste
    _loadHabits();
  }

  List<Habit> get habits => List.unmodifiable(_habits);

  Future<void> addHabit(
      String name, String date, String? notificationTime) async {
    final id = await _db.insert('habits', {
      'name': name,
      'completed': 0,
      'date': date,
      'notification_time': notificationTime,
    });
    _habits.add(Habit(
      id: id,
      name: name,
      isCompleted: false,
      date: date,
      notificationTime: notificationTime,
    ));
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(int id) async {
    final habit = _habits.firstWhere((h) => h.id == id);
    final newCompleted = !habit.isCompleted;
    await _db.update(
      'habits',
      {'completed': newCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    habit.isCompleted = newCompleted;
    notifyListeners();
  }

  Future<void> _loadHabits() async {
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
  }

  void dispose() {
    _habits.clear();
    super.dispose();
  }
}
