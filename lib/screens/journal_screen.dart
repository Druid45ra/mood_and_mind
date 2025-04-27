import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart';
class JournalScreen extends StatefulWidget {
  final Database database;
  const JournalScreen({super.key, required this.database});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? selectedMood;
  int intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> journalEntries = [];

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
    try {
      final List<Map<String, dynamic>> entries = await widget.database.query(
        'journal',
        orderBy: 'timestamp DESC',
      );
      setState(() {
        journalEntries = entries;
      });
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
    } catch (e) {
      AppLogger.e(
          'Error loading entries: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a mood!'), // Text fix în engleză
        ),
      );
      return;
    }
    try {
      await widget.database.insert(
        'journal',
        {
          'mood': selectedMood,
          'intensity': intensity,
          'note': _noteController.text,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _noteController.clear();
      setState(() {
        selectedMood = null;
        intensity = 5;
      });
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood has been saved!'), // Text fix în engleză
        ),
      );
    } catch (e) {
      AppLogger.e('Error saving entry: $e'); // TODO: Replace with a proper logging system
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving mood. Try again.'), // Text fix în engleză
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Journal'), // Text fix în engleză
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you feel today?', // Text fix în engleză
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodEmoji(
                  emoji: '😢',
                  value: 'Sad', // Text fix în engleză
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😐',
                  value: 'Neutral', // Text fix în engleză
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😊',
                  value: 'Good', // Text fix în engleză
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😃',
                  value: 'Happy', // Text fix în engleză
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '🥰',
                  value: 'Fulfilled', // Text fix în engleză
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Intensity: $intensity'), // Text fix în engleză
            Slider(
              value: intensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: intensity.toString(),
              onChanged: (value) => setState(() => intensity = value.round()),
              activeColor: Colors.teal[600],
              inactiveColor: Colors.teal[100],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Note (optional)', // Text fix în engleză
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'), // Text fix în engleză
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Entries', // Text fix în engleză
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? const Text('No entries yet. Add one!') // Text fix în engleză
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final entry = journalEntries[index];
                      return ListTile(
                        leading: Text(
                          _getEmojiForMood(entry['mood'] as String),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                            '${entry['mood']} (${entry['intensity'] ?? 'N/A'}/10)'),
                        subtitle: Text(
                          (entry['note'] as String?)?.isNotEmpty ?? false
                              ? entry['note'] as String
                              : 'No note', // Text fix în engleză
                        ),
                        trailing: Text(
                          (entry['timestamp'] as String).substring(0, 10),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
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

class MoodEmoji extends StatelessWidget {
  final String emoji;
  final String value;
  final String? selected;
  final Function(String) onTap;

  const MoodEmoji({
    super.key,
    required this.emoji,
    required this.value,
    this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
