import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/utils/logger.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  void _addHabit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!mounted) return; // Verificăm dacă widget-ul este încă montat
      final habitsModel = Provider.of<HabitsModel>(context, listen: false);
      final name = _habitController.text;
      final date = DateTime.now().toIso8601String().split('T')[0];
      habitsModel.addHabit(name, date, null).then((_) {
        _habitController.clear();
        AppLogger.i('Habit added: $name');
      }).catchError((e) {
        AppLogger.e('Error adding habit: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _habitController,
                decoration: const InputDecoration(labelText: 'New Habit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _addHabit,
                child: const Text('Add Habit'),
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
                            onChanged: (_) =>
                                habitsModel.toggleHabitCompletion(habit.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
