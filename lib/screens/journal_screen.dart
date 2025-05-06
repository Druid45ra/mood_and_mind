import 'package:flutter/material.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const JournalScreen({super.key, required this.databaseHelper});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _selectedMood;
  double _intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  String? _errorMessage;

  final List<String> _moods = [
    'Good 😊',
    'Sad 😢',
    'Angry 😠',
    'Excited 😄',
    'Tired 😴',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_selectedMood == null || _noteController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a mood and add a note.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final journalModel = Provider.of<JournalModel>(context, listen: false);
      await journalModel.addEntry(
        _selectedMood!,
        _intensity.toInt(),
        _noteController.text,
      );
      _noteController.clear();
      _selectedMood = null;
      _intensity = 5;
    } catch (e) {
      AppLogger.e('Error saving journal entry: $e');
      setState(() {
        _errorMessage = 'Failed to save entry: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedMood,
              hint: const Text('Select Mood'),
              isExpanded: true,
              items: _moods.map((mood) {
                return DropdownMenuItem<String>(
                  value: mood,
                  child: Text(mood),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMood = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Intensity: '),
                Expanded(
                  child: Slider(
                    value: _intensity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _intensity.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _intensity = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saveEntry,
            child: const Text('Save Entry'),
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
            child: Consumer<JournalModel>(
              builder: (context, journalModel, child) {
                if (journalModel.entries.isEmpty) {
                  return const Center(child: Text('No journal entries yet.'));
                }
                return ListView.builder(
                  itemCount: journalModel.entries.length,
                  itemBuilder: (context, index) {
                    final entry = journalModel.entries[index];
                    return ListTile(
                      title: Text('${entry.mood} (${entry.intensity}/10)'),
                      subtitle: Text(entry.note),
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
