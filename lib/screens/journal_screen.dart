import 'package:flutter/material.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/utils/logger.dart';

class JournalScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const JournalScreen({Key? key, required this.databaseHelper})
      : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _selectedMood;
  double _intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> _entries = [];

  final List<String> _moods = [
    'Good 😊',
    'Sad 😢',
    'Angry 😠',
    'Excited 😄',
    'Tired 😴',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    final db = await widget.databaseHelper.database;
    final entries = await db.query('journal_entries');
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedMood == null || _noteController.text.isEmpty) return;
    if (!mounted) return;
    try {
      final db = await widget.databaseHelper.database;
      await db.insert('journal_entries', {
        'mood': _selectedMood,
        'intensity': _intensity.toInt(),
        'note': _noteController.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _noteController.clear();
      _selectedMood = null;
      _intensity = 5;
      await _loadEntries();
    } catch (e) {
      AppLogger.e('Error saving journal entry: $e');
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
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  title: Text('${entry['mood']} (${entry['intensity']}/10)'),
                  subtitle: Text(entry['note']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
