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
  final int _pageSize = 20; // Numărul de obiceiuri pe pagină
  int _offset = 0; // Poziția de start pentru următoarea încărcare
  bool _hasMoreHabits = true; // Indică dacă mai sunt obiceiuri de încărcat

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

  Future<void> _loadHabits({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        _offset += _pageSize;
      });
    } else {
      setState(() {
        _offset = 0;
        habits.clear();
        _hasMoreHabits = true;
      });
    }

    try {
      final List<Map<String, dynamic>> loadedHabits =
          await widget.database.query(
        'habits',
        where: 'date = ?',
        whereArgs: [today],
        limit: _pageSize,
        offset: _offset,
      );
      setState(() {
        habits.addAll(loadedHabits);
        if (loadedHabits.length < _pageSize) {
          _hasMoreHabits = false;
        }
      });
      AppLogger.i(
          'Loaded ${loadedHabits.length} habits for $today (offset: $_offset).');
      if (!loadMore) {
        await Provider.of<AchievementsModel>(context, listen: false)
            .checkAchievements(context);
      }
    } catch (e) {
      AppLogger.e('Error loading habits: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load habits. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadHabits(loadMore: loadMore),
          ),
        ),
      );
    }
  }

  Future<void> _addHabit() async {
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the habit!'),
          backgroundColor: Colors.orange,
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
      await _loadHabits(); // Reîncarcăm de la început
      AppLogger.i('Added habit: $name for $today.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit added successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      AppLogger.e('Error adding habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to add habit: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _addHabit(),
          ),
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
      AppLogger.i(
          'Toggled habit id $id to ${completed ? 'complete' : 'incomplete'} on $today.');
      await _loadHabits(); // Reîncarcăm de la început
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Habit ${completed ? 'marked as completed' : 'marked as incomplete'}!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      AppLogger.e('Error toggling habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to update habit status: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _toggleHabit(id, completed),
          ),
        ),
      );
    }
  }

  Future<void> _setNotificationTime(int id, String name) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select time for $name',
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
        await _loadHabits(); // Reîncarcăm de la început
        AppLogger.i('Set notification for habit $name at $notificationTime.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification set for $name at $notificationTime'),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        AppLogger.e('Error setting notification time: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to set notification: ${e.toString()}. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _setNotificationTime(id, name),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habits'),
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
                      labelText: 'Add a habit',
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
              'Your habits for today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: habits.isEmpty
                  ? const Center(
                      child: Text('No habits added. Start now!'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: habits.length,
                            itemBuilder: (context, index) {
                              final habit = habits[index];
                              return HabitCard(
                                habit: habit,
                                onToggle: (value) =>
                                    _toggleHabit(habit['id'], value),
                                onSetNotification: () => _setNotificationTime(
                                    habit['id'], habit['name'] as String),
                              );
                            },
                          ),
                        ),
                        if (_hasMoreHabits)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: ElevatedButton(
                              onPressed: () => _loadHabits(loadMore: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[600],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Load More'),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitCard extends StatefulWidget {
  final Map<String, dynamic> habit;
  final Function(bool) onToggle;
  final VoidCallback onSetNotification;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onSetNotification,
  });

  @override
  State<HabitCard> createState() => _HabitsCardState();
}

class _HabitsCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.habit['completed'] == 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.teal[50] : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        title: Text(widget.habit['name'] as String),
        subtitle: widget.habit['notification_time'] != null
            ? Text('Notification: ${widget.habit['notification_time']}')
            : const Text('No notification'),
        value: isCompleted,
        activeColor: Colors.teal[600],
        secondary: ScaleTransition(
          scale: _scaleAnimation,
          child: IconButton(
            icon: const Icon(Icons.alarm),
            color: widget.habit['notification_time'] != null
                ? Colors.teal[600]
                : Colors.grey,
            onPressed: widget.onSetNotification,
          ),
        ),
        onChanged: (value) {
          if (value != null) {
            _controller.forward(from: 0);
            widget.onToggle(value);
          }
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
