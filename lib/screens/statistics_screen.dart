import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

class StatisticsScreen extends StatefulWidget {
  final Database database;
  const StatisticsScreen({super.key, required this.database});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class StatisticsData {
  final int habitCount;
  final int journalEntryCount;
  final Map<String, double> moodAverages;
  final double habitCompletionRate;

  StatisticsData({
    required this.habitCount,
    required this.journalEntryCount,
    required this.moodAverages,
    required this.habitCompletionRate,
  });
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _habitCount = 0;
  int _journalEntryCount = 0;
  Map<String, double> _moodAverages = {};
  double _habitCompletionRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<StatisticsData> _computeStatistics(Database database) async {
    try {
      final habits = await database.query('habits');
      final journalEntries = await database.query('journal');

      Map<String, double> moodAverages = {};
      if (journalEntries.isNotEmpty) {
        Map<String, List<int>> moodScores = {};
        for (var entry in journalEntries) {
          moodScores[entry['mood'] as String] =
              moodScores[entry['mood'] as String] ?? [];
          moodScores[entry['mood'] as String]!.add(entry['intensity'] as int);
        }
        moodScores.forEach((mood, intensities) {
          moodAverages[mood] =
              intensities.reduce((a, b) => a + b) / intensities.length;
        });
      }

      double habitCompletionRate = 0.0;
      if (habits.isNotEmpty) {
        int completedHabits =
            habits.where((habit) => habit['completed'] == 1).length;
        habitCompletionRate = (completedHabits / habits.length) * 100;
      }

      return StatisticsData(
        habitCount: habits.length,
        journalEntryCount: journalEntries.length,
        moodAverages: moodAverages,
        habitCompletionRate: habitCompletionRate,
      );
    } catch (e) {
      AppLogger.e('Error computing statistics: $e');
      return StatisticsData(
        habitCount: 0,
        journalEntryCount: 0,
        moodAverages: {},
        habitCompletionRate: 0.0,
      );
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await compute(_computeStatistics, widget.database);
      setState(() {
        _habitCount = stats.habitCount;
        _journalEntryCount = stats.journalEntryCount;
        _moodAverages = stats.moodAverages;
        _habitCompletionRate = stats.habitCompletionRate;
        _isLoading = false;
      });
      AppLogger.i(
          'Loaded statistics: $_habitCount habits, $_journalEntryCount journal entries.');
    } catch (e) {
      AppLogger.e('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habits: $_habitCount',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        'Habit Completion Rate: ${_habitCompletionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text('Journal Entries: $_journalEntryCount',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Mood Averages:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_moodAverages.isNotEmpty)
                      Column(
                        children: _moodAverages.entries
                            .map((entry) => Text(
                                '${entry.key}: ${entry.value.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 16)))
                            .toList(),
                      )
                    else
                      const Text('No mood data available.',
                          style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
    );
  }
}
