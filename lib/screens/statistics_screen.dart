import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';

class StatisticsScreen extends StatefulWidget {
  final Database database;
  const StatisticsScreen({super.key, required this.database});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> journalEntries = [];
  Map<String, int> moodDistribution = {};
  double avgIntensity7Days = 0;
  double avgIntensity30Days = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final habitData = await widget.database.query('habits');
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final journalData = await widget.database.query(
        'journal',
        where: 'timestamp >= ?',
        whereArgs: [thirtyDaysAgo],
      );

      Map<String, int> tempMoodDist = {
        'Sad': 0,
        'Neutral': 0,
        'Good': 0,
        'Happy': 0,
        'Fulfilled': 0,
      };
      double intensitySum7 = 0;
      double intensitySum30 = 0;
      int intensityCount7 = 0;
      int intensityCount30 = 0;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      for (var entry in journalData) {
        final mood = entry['mood'] as String;
        if (tempMoodDist.containsKey(mood)) {
          tempMoodDist[mood] = (tempMoodDist[mood] ?? 0) + 1;
        }
        final entryDate = DateTime.parse(entry['timestamp'] as String);
        if (entry['intensity'] != null) {
          final intensity = (entry['intensity'] as num).toDouble();
          intensitySum30 += intensity;
          intensityCount30++;
          if (entryDate.isAfter(sevenDaysAgo)) {
            intensitySum7 += intensity;
            intensityCount7++;
          }
        }
      }

      setState(() {
        habits = habitData;
        journalEntries = journalData;
        moodDistribution = tempMoodDist;
        avgIntensity7Days =
            intensityCount7 > 0 ? intensitySum7 / intensityCount7 : 0;
        avgIntensity30Days =
            intensityCount30 > 0 ? intensitySum30 / intensityCount30 : 0;
      });
    } catch (e) {
      print(
          'Error loading statistics: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  int _calculateStreak(String habitName) {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    while (true) {
      String dateStr = currentDate.toIso8601String().substring(0, 10);
      bool completed = habits.any(
        (habit) =>
            habit['name'] == habitName &&
            habit['date'] == dateStr &&
            habit['completed'] == 1,
      );
      if (!completed) break;
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _calculateCompletionPercentage(String habitName, int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    int completedDays = 0;
    for (int i = 0; i < days; i++) {
      String dateStr =
          startDate.add(Duration(days: i)).toIso8601String().substring(0, 10);
      if (habits.any(
        (habit) =>
            habit['name'] == habitName &&
            habit['date'] == dateStr &&
            habit['completed'] == 1,
      )) {
        completedDays++;
      }
    }
    return days > 0 ? (completedDays / days * 100) : 0;
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Sad':
        return Colors.red[400]!;
      case 'Neutral':
        return Colors.yellow[600]!;
      case 'Good':
        return Colors.green[300]!;
      case 'Happy':
        return Colors.green[600]!;
      case 'Fulfilled':
        return Colors.blue[400]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueHabits =
        habits.map((h) => h['name'] as String).toSet().toList();
    const moods = ['Sad', 'Neutral', 'Good', 'Happy', 'Fulfilled'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'), // Text fix în engleză
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress', // Text fix în engleză
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Habits', // Text fix în engleză
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            uniqueHabits.isEmpty
                ? const Text('No habits recorded.') // Text fix în engleză
                : Column(
                    children: uniqueHabits.map((habitName) {
                      final streak = _calculateStreak(habitName);
                      final completion7Days =
                          _calculateCompletionPercentage(habitName, 7);
                      final completion30Days =
                          _calculateCompletionPercentage(habitName, 30);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habitName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Streak: $streak days'), // Text fix în engleză
                              Text(
                                  'Completed: ${completion7Days.toStringAsFixed(1)}% in the last 7 days'), // Text fix în engleză
                              Text(
                                  'Completed: ${completion30Days.toStringAsFixed(1)}% in the last 30 days'), // Text fix în engleză
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
            const Text(
              'Moods (last 30 days)', // Text fix în engleză
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? const Text('No moods recorded.') // Text fix în engleză
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < moods.length) {
                                      return Text(
                                        moods[index],
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: moods.asMap().entries.map((e) {
                              int index = e.key;
                              String mood = e.value;
                              int count = moodDistribution[mood] ?? 0;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: count.toDouble(),
                                    color: _getMoodColor(mood),
                                    width: 12,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moods.map((mood) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: _getMoodColor(mood),
                              ),
                              const SizedBox(width: 4),
                              Text(mood),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            const Text(
              'Mood Intensity (last 30 days)', // Text fix în engleză
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
                'Average last 7 days: ${avgIntensity7Days.toStringAsFixed(1)}/10'), // Text fix în engleză
            Text(
                'Average last 30 days: ${avgIntensity30Days.toStringAsFixed(1)}/10'), // Text fix în engleză
          ],
        ),
      ),
    );
  }
}
