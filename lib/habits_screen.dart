import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

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
      print('Error loading habits: $e');
    }
  }

  Future<void> _addHabit() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Introdu un nume pentru obicei!'
                : 'Enter a name for the habit!',
          ),
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
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Obiceiul a fost adăugat!'
                : 'Habit has been added!',
          ),
        ),
      );
    } catch (e) {
      print('Error adding habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la adăugarea obiceiului: $e'
                : 'Error adding habit: $e',
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
      await _loadHabits();
    } catch (e) {
      print('Error toggling habit: $e');
    }
  }

  Future<void> _setNotificationTime(int id, String name) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: settings.language == 'ro'
          ? 'Selectează ora pentru $name'
          : 'Select time for $name',
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
        await Provider.of<SettingsModel>(context, listen: false)
            .scheduleHabitNotifications();
        await _loadHabits();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'ro'
                  ? 'Notificare setată pentru $name la $notificationTime'
                  : 'Notification set for $name at $notificationTime',
            ),
          ),
        );
      } catch (e) {
        print('Error setting notification time: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'ro'
                  ? 'Eroare la setarea notificării.'
                  : 'Error setting notification.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            settings.language == 'ro' ? 'Obiceiuri zilnice' : 'Daily Habits'),
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
                    decoration: InputDecoration(
                      labelText: settings.language == 'ro'
                          ? 'Adaugă un obicei'
                          : 'Add a habit',
                      border: const OutlineInputBorder(),
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
            Text(
              settings.language == 'ro'
                  ? 'Obiceiurile tale de astăzi'
                  : 'Your habits for today',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        settings.language == 'ro'
                            ? 'Niciun obicei adăugat. Începe acum!'
                            : 'No habits added. Start now!',
                      ),
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return CheckboxListTile(
                          title: Text(habit['name'] as String),
                          subtitle: habit['notification_time'] != null
                              ? Text(
                                  '${settings.language == 'ro' ? 'Notificare' : 'Notification'}: ${habit['notification_time']}')
                              : Text(settings.language == 'ro'
                                  ? 'Fără notificare'
                                  : 'No notification'),
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
