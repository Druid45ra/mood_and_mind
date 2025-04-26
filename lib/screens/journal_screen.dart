import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/settings_model.dart';
import '../models/achievements_model.dart';
import '../generated/l10n.dart';


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
      print('Error loading entries: $e');
    }
  }

  Future<void> _saveEntry() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Te rog alege o stare de spirit!'
                : 'Please choose a mood!',
          ),
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
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Starea de spirit a fost salvată!'
                : 'Mood has been saved!',
          ),
        ),
      );
    } catch (e) {
      print('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la salvarea stării. Încearcă din nou.'
                : 'Error saving mood. Try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(settings.language == 'ro' ? 'Jurnal zilnic' : 'Daily Journal'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.language == 'ro'
                  ? 'Cum te simți astăzi?'
                  : 'How do you feel today?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodEmoji(
                  emoji: '😢',
                  value: settings.language == 'ro' ? 'Trist' : 'Sad',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😐',
                  value: settings.language == 'ro' ? 'Neutru' : 'Neutral',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😊',
                  value: settings.language == 'ro' ? 'Bine' : 'Good',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😃',
                  value: settings.language == 'ro' ? 'Fericit' : 'Happy',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '🥰',
                  value: settings.language == 'ro' ? 'Împlinit' : 'Fulfilled',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
                '${settings.language == 'ro' ? 'Intensitate' : 'Intensity'}: $intensity'),
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
              decoration: InputDecoration(
                labelText: settings.language == 'ro'
                    ? 'Notiță (opțional)'
                    : 'Note (optional)',
                border: const OutlineInputBorder(),
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
              child: Text(settings.language == 'ro' ? 'Salvează' : 'Save'),
            ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro' ? 'Intrări recente' : 'Recent Entries',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? Text(settings.language == 'ro'
                    ? 'Nicio intrare încă. Adaugă una!'
                    : 'No entries yet. Add one!')
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
                              : (settings.language == 'ro'
                                  ? 'Fără notiță'
                                  : 'No note'),
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
      case 'Trist':
      case 'Sad':
        return '😢';
      case 'Neutru':
      case 'Neutral':
        return '😐';
      case 'Bine':
      case 'Good':
        return '😊';
      case 'Fericit':
      case 'Happy':
        return '😃';
      case 'Împlinit':
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
