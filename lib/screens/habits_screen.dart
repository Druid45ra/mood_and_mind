import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/services/database_service.dart';

class HabitsScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HabitsScreen({super.key, required this.databaseHelper});

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _addHabit() async {
    if (_habitController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a habit.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final habitsModel = Provider.of<HabitsModel>(context, listen: false);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await habitsModel.addHabit(
        _habitController.text,
        today, // Setăm data curentă explicit
        null,
      );
      _habitController.clear();
    } catch (e) {
      AppLogger.e('Error adding habit: $e');
      setState(() {
        _errorMessage = 'Failed to add habit: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _habitController,
                    decoration: const InputDecoration(
                      labelText: 'New Habit',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addHabit,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: Consumer<HabitsModel>(
              builder: (context, habitsModel, child) {
                if (habitsModel.habits.isEmpty) {
                  return const Center(child: Text('No habits yet.'));
                }
                return ListView.builder(
                  itemCount: habitsModel.habits.length,
                  itemBuilder: (context, index) {
                    final habit = habitsModel.habits[index];
                    return ListTile(
                      title: Text(habit.name),
                      subtitle: Text('Date: ${habit.date}'),
                      trailing: Checkbox(
                        value: habit.isCompleted,
                        onChanged: (value) {
                          if (value != null) {
                            habitsModel.toggleHabitCompletion(habit.id);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
