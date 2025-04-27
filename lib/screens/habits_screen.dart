import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/settings_model.dart';
import '../models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart';

class HabitsScreen extends StatefulWidget {
  final Database database;
  const HabitsScreen({super.key, required this.database});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();
  List<Map<String, dynamic>> habits = [];
  String today = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    try {
      final List<Map<String, dynamic>> loadedHabits =
          await widget.database.query(
        'habits',
        where: 'date = ?',
        whereArgs: [today],
      );
      setState(() {
        habits = loadedHabits;
      });
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
    } catch (e) {
      AppLogger.e(
          'Error loading habits: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  Future<void> _addHabit() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name for the habit!'), // Text fix în engleză
        ),
      );
      return;
    }
    try {
      await widget.database.insert(
        'habits',
        {
          'name': name,
          'completed': 0,
          'date': today,
          'notification_time': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      _habitController.clear();
      await _loadHabits();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit has been added!'), // Text fix în engleză
        ),
      );
    } catch (e) {
      AppLogger.e(
          'Error adding habit: $e'); // TODO: Replace with a proper logging system
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding habit: $e'), // Text fix în engleză
        ),
      );
    }
  }

  Future<void> _toggleHabit(int id, bool completed) async {
    try {
      await widget.database.update(
        'habits',
        {'completed': completed ? 1 : 0},
        where: 'id = ? AND date = ?',
        whereArgs: [id, today],
      );
      await _loadHabits();
    } catch (e) {
      AppLogger.e(
          'Error toggling habit: $e'); // TODO: Replace with a proper logging system
    }
  }

  Future<void> _setNotificationTime(int id, String name) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select time for $name', // Text fix în engleză
    );
    if (picked != null) {
      try {
        final notificationTime = '${picked.hour}:${picked.minute}';
        await widget.database.update(
          'habits',
          {'notification_time': notificationTime},
          where: 'id = ?',
          whereArgs: [id],
        );
        await settings.scheduleHabitNotifications();
        await _loadHabits();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification set for $name at $notificationTime'), // Text fix în engleză
          ),
        );
      } catch (e) {
        AppLogger.e(
            'Error setting notification time: $e'); // TODO: Replace with a proper logging system
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting notification.'), // Text fix în engleză
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habits'), // Text fix în engleză
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _habitController,
                    decoration: const InputDecoration(
                      labelText: 'Add a habit', // Text fix în engleză
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Your habits for today', // Text fix în engleză
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: habits.isEmpty
                  ? const Center(
                      child: Text(
                          'No habits added. Start now!'), // Text fix în engleză
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return CheckboxListTile(
                          title: Text(habit['name'] as String),
                          subtitle: habit['notification_time'] != null
                              ? Text(
                                  'Notification: ${habit['notification_time']}') // Text fix în engleză
                              : const Text(
                                  'No notification'), // Text fix în engleză
                          value: habit['completed'] == 1,
                          activeColor: Colors.teal[600],
                          secondary: IconButton(
                            icon: const Icon(Icons.alarm),
                            color: habit['notification_time'] != null
                                ? Colors.teal[600]
                                : Colors.grey,
                            onPressed: () => _setNotificationTime(
                                habit['id'], habit['name'] as String),
                          ),
                          onChanged: (value) =>
                              _toggleHabit(habit['id'], value ?? false),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
