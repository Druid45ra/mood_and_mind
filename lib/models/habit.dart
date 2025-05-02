import 'package:flutter/material.dart';
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

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int,
      name: map['name'] as String,
      isCompleted: (map['completed'] as int) == 1,
      date: map['date'] as String,
      notificationTime: map['notification_time'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completed': isCompleted ? 1 : 0,
      'date': date,
      'notification_time': notificationTime,
    };
  }
}

class HabitsModel extends ChangeNotifier {
  late Database _db;
  List<Habit> _habits = [];

  List<Habit> get habits => _habits;

  HabitsModel(DatabaseHelper databaseHelper) {
    _init(databaseHelper);
  }

  Future<void> _init(DatabaseHelper databaseHelper) async {
    _db = await databaseHelper.database;
    await _loadHabits();
  }

  Future<void> _loadHabits() async {
    final maps = await _db.query('habits');
    _habits = maps.map((map) => Habit.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> addHabit(
      String name, String date, String? notificationTime) async {
    await _db.insert('habits', {
      'name': name,
      'completed': 0,
      'date': date,
      'notification_time': notificationTime,
    });
    await _loadHabits();
  }

  Future<void> deleteHabit(int id) async {
    await _db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await _loadHabits();
  }

  Future<void> toggleHabitCompletion(int id) async {
    final habit = _habits.firstWhere((h) => h.id == id);
    final newCompleted = !habit.isCompleted;
    await _db.update('habits', {'completed': newCompleted ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    await _loadHabits();
  }
}
