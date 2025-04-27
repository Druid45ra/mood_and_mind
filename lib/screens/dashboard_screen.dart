import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  final Database database;
  const DashboardScreen({super.key, required this.database});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? lastMood;
  List<Map<String, dynamic>> todayHabits = [];
  List<Map<String, dynamic>> last7DaysMoods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Încarcă datele pe un thread separat
    final data = await Future.wait([
      _loadLastMood(),
      _loadTodayHabits(),
      _loadLast7DaysMoods(),
    ]);

    setState(() {
      lastMood = data[0] as Map<String, dynamic>?;
      todayHabits = data[1] as List<Map<String, dynamic>>;
      last7DaysMoods = data[2] as List<Map<String, dynamic>>;
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _loadLastMood() async {
    final moods = await widget.database.query(
      'journal',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return moods.isNotEmpty ? moods.first : null;
  }

  Future<List<Map<String, dynamic>>> _loadTodayHabits() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await widget.database.query(
      'habits',
      where: 'date = ?',
      whereArgs: [today],
    );
  }

  Future<List<Map<String, dynamic>>> _loadLast7DaysMoods() async {
    final sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    return await widget.database.query(
      'journal',
      where: 'timestamp >= ?',
      whereArgs: [sevenDaysAgo],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> _toggleHabit(int id, int completed) async {
    await widget.database.update(
      'habits',
      {'completed': completed == 1 ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!', // Text fix în engleză
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Last Mood', // Text fix în engleză
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        lastMood != null
                            ? Row(
                                children: [
                                  const Icon(Icons.mood,
                                      color: Colors.orange, size: 40),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${lastMood!['mood']} (${lastMood!['intensity']}/10)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        lastMood!['timestamp'].substring(0, 10),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const Text(
                                'No mood recorded yet.'), // Text fix în engleză
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Habits', // Text fix în engleză
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        todayHabits.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: todayHabits.length,
                                itemBuilder: (context, index) {
                                  final habit = todayHabits[index];
                                  return CheckboxListTile(
                                    title: Text(habit['name']),
                                    value: habit['completed'] == 1,
                                    onChanged: (value) {
                                      _toggleHabit(
                                          habit['id'], habit['completed']);
                                    },
                                    activeColor:
                                        Theme.of(context).colorScheme.secondary,
                                  );
                                },
                              )
                            : const Text(
                                'No habits for today.'), // Text fix în engleză
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Mood (Last 7 Days)', // Text fix în engleză
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: last7DaysMoods.isNotEmpty
                              ? LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: const FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: 6,
                                    minY: 1,
                                    maxY: 10,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: last7DaysMoods
                                            .asMap()
                                            .entries
                                            .map((e) => FlSpot(
                                                e.key.toDouble(),
                                                e.value['intensity']
                                                    .toDouble()))
                                            .toList(),
                                        isCurved: true,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                      'No data available.'), // Text fix în engleză
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
