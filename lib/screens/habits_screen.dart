import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/services/database_service.dart';

class HabitsScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HabitsScreen({Key? key, required this.databaseHelper})
      : super(key: key);

  @override
  _HabitsScreenState createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  Future<void> _addHabit() async {
    if (_habitController.text.isEmpty) return;
    final habitsModel = Provider.of<HabitsModel>(context, listen: false);
    try {
      await habitsModel.addHabit(
        _habitController.text,
        DateTime.now().toIso8601String(),
        null,
      );
      _habitController.clear();
      if (mounted) setState(() {}); // Actualizăm UI-ul dacă e necesar
    } catch (e) {
      AppLogger.e('Error adding habit: $e');
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
          Expanded(
            child: Consumer<HabitsModel>(
              builder: (context, habitsModel, child) {
                return ListView.builder(
                  itemCount: habitsModel.habits.length,
                  itemBuilder: (context, index) {
                    final habit = habitsModel.habits[index];
                    return ListTile(
                      title: Text(habit.name),
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
