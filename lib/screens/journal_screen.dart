import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/utils/logger.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedMood = '😊'; // Valoare implicită
  int _moodIntensity = 5; // Valoare implicită
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!mounted) return; // Verificăm dacă widget-ul este încă montat
      final journalModel = Provider.of<JournalModel>(context, listen: false);
      journalModel
          .addEntry(_selectedMood, _moodIntensity, _noteController.text)
          .then((_) {
        _noteController.clear();
        AppLogger.i('Journal entry saved: ${_noteController.text}');
      }).catchError((e) {
        AppLogger.e('Error saving journal entry: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButton<String>(
                value: _selectedMood,
                items: const [
                  DropdownMenuItem(value: '😊', child: Text('Good')),
                  DropdownMenuItem(value: '😐', child: Text('Neutral')),
                  DropdownMenuItem(value: '☹️', child: Text('Bad')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMood = value!;
                    _moodIntensity =
                        {'😊': 5, '😐': 3, '☹️': 1}[_selectedMood]!;
                  });
                },
              ),
              Slider(
                value: _moodIntensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_moodIntensity/5',
                onChanged: (value) {
                  setState(() {
                    _moodIntensity = value.round();
                  });
                },
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a note';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _saveEntry,
                child: const Text('Save Entry'),
              ),
              Expanded(
                child: Consumer<JournalModel>(
                  builder: (context, journalModel, child) {
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
        ),
      ),
    );
  }
}
