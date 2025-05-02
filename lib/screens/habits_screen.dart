import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/settings_model.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();
  String today = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
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
      final habitsModel = Provider.of<HabitsModel>(context, listen: false);
      await habitsModel.addHabit(name, today, null);
      _habitController.clear();
      AppLogger.i('Added habit: $name for $today.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Habit added successfully!'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
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
        final habitsModel = Provider.of<HabitsModel>(context, listen: false);
        await habitsModel.addHabit(
            name, today, notificationTime); // Update notification time
        await settings.scheduleHabitNotifications();
        AppLogger.i('Set notification for habit $name at $notificationTime.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification set for $name at $notificationTime'),
            backgroundColor: Theme.of(context).primaryColor,
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
    return Consumer<HabitsModel>(
      builder: (context, habitsModel, child) {
        final todayHabits =
            habitsModel.habits.where((habit) => habit.date == today).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Habits'),
            centerTitle: true,
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
                  child: todayHabits.isEmpty
                      ? const Center(
                          child: Text('No habits added. Start now!'),
                        )
                      : ListView.builder(
                          itemCount: todayHabits.length,
                          itemBuilder: (context, index) {
                            final habit = todayHabits[index];
                            return HabitCard(
                              habit: habit,
                              onToggle: (value) async {
                                await habitsModel
                                    .toggleHabitCompletion(habit.id);
                              },
                              onSetNotification: () =>
                                  _setNotificationTime(habit.id, habit.name),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HabitCard extends StatefulWidget {
  final Habit habit;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.habit.isCompleted
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
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
        title: Text(widget.habit.name),
        subtitle: widget.habit.notificationTime != null
            ? Text('Notification: ${widget.habit.notificationTime}')
            : const Text('No notification'),
        value: widget.habit.isCompleted,
        activeColor: Theme.of(context).primaryColor,
        secondary: ScaleTransition(
          scale: _scaleAnimation,
          child: IconButton(
            icon: const Icon(Icons.alarm),
            color: widget.habit.notificationTime != null
                ? Theme.of(context).primaryColor
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
