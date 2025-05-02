import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? selectedMood;
  int intensity = 5;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a mood before saving!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final journalModel = Provider.of<JournalModel>(context, listen: false);
      await journalModel.addEntry(
          selectedMood!, intensity, _noteController.text);
      _noteController.clear();
      setState(() {
        selectedMood = null;
        intensity = 5;
      });
      AppLogger.i(
          'Saved journal entry: $selectedMood (intensity: $intensity).');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood entry saved successfully!'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
    } catch (e) {
      AppLogger.e('Error saving journal entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to save your mood entry: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _saveEntry(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalModel>(
      builder: (context, journalModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Journal'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How do you feel today?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MoodEmoji(
                      emoji: '😢',
                      value: 'Sad',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val),
                    ),
                    MoodEmoji(
                      emoji: '😐',
                      value: 'Neutral',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val),
                    ),
                    MoodEmoji(
                      emoji: '😊',
                      value: 'Good',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val),
                    ),
                    MoodEmoji(
                      emoji: '😃',
                      value: 'Happy',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val),
                    ),
                    MoodEmoji(
                      emoji: '🥰',
                      value: 'Fulfilled',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Intensity: $intensity'),
                Slider(
                  value: intensity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: intensity.toString(),
                  onChanged: (value) =>
                      setState(() => intensity = value.round()),
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recent Entries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                journalModel.entries.isEmpty
                    ? const Text('No entries yet. Add one!')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: journalModel.entries.length,
                        itemBuilder: (context, index) {
                          final entry = journalModel.entries[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12.0),
                              leading: Text(
                                _getEmojiForMood(entry.mood),
                                style: const TextStyle(fontSize: 24),
                              ),
                              title:
                                  Text('${entry.mood} (${entry.intensity}/10)'),
                              subtitle: Text(
                                entry.note.isNotEmpty ? entry.note : 'No note',
                              ),
                              trailing: Text(
                                entry.timestamp.substring(0, 10),
                              ),
                            ),
                          );
                        },
                      ),
              ],
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
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
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
