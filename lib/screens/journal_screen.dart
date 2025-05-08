import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/journal_model.dart'; // Corectat importul
import 'package:mood_and_mind/utils/logger.dart';
import 'package:mood_and_mind/services/database_service.dart';

class JournalScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const JournalScreen({super.key, required this.databaseHelper});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _formKey = GlobalKey<FormState>();
  String _mood = 'Neutral';
  int _intensity = 5;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submitJournalEntry() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final journalModel = Provider.of<JournalModel>(context, listen: false);
      journalModel.addEntry(_mood, _intensity, _noteController.text.trim());
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry added!')),
      );
      AppLogger.i(
          'Added journal entry: $_mood, $_intensity, ${_noteController.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalModel>(
      builder: (context, journalModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Journal'),
            backgroundColor: Colors.teal,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _mood,
                    decoration: InputDecoration(
                      labelText: 'Select Mood',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.white,
                    ),
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 16,
                    ),
                    items: <String>[
                      'Sad',
                      'Neutral',
                      'Good',
                      'Happy',
                      'Fulfilled'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _mood = newValue!;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a mood' : null,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _intensity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _intensity.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _intensity = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitJournalEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Add Entry',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Entries',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: journalModel
                        .entries.length, // Adăugat null check implicit
                    itemBuilder: (context, index) {
                      final entry = journalModel.entries[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Text(
                            _getEmojiForMood(entry.mood),
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text('${entry.mood} (${entry.intensity}/10)'),
                          subtitle: Text(
                              entry.note.isNotEmpty ? entry.note : 'No note'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => journalModel.deleteEntry(entry.id),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getEmojiForMood(String mood) {
    switch (mood) {
      case 'Sad':
        return '😢';
      case 'Neutral':
        return '😐';
      case 'Good':
        return '😊';
      case 'Happy':
        return '😃';
      case 'Fulfilled':
        return '🥰';
      default:
        return '😐';
    }
  }
}
