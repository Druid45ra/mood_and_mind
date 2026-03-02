import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:mood_and_mind/utils/logger.dart';

class DashboardScreen extends StatefulWidget {
  final Future<Database> databaseFuture;

  const DashboardScreen({super.key, required this.databaseFuture});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
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
    AppLogger.i('Starting to load dashboard data...');
    setState(() {
      isLoading = true;
    });

    try {
      final database = await widget.databaseFuture;
      final data = await Future.wait([
        _loadLastMood(database),
        _loadTodayHabits(database),
        _loadLast7DaysMoods(database),
      ]);

      setState(() {
        lastMood = data[0] as Map<String, dynamic>?;
        todayHabits = data[1] as List<Map<String, dynamic>>;
        last7DaysMoods = data[2] as List<Map<String, dynamic>>;
        isLoading = false;
      });
      AppLogger.i(
          'Dashboard data loaded successfully: ${todayHabits.length} habits, ${last7DaysMoods.length} moods.');
    } catch (e) {
      AppLogger.e('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadLastMood(Database db) async {
    try {
      final moods = await db.query(
        'journal_entries',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      AppLogger.d('Loaded last mood: ${moods.isNotEmpty ? moods.first : null}');
      return moods.isNotEmpty ? moods.first : null;
    } catch (e) {
      AppLogger.e('Error loading last mood: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadTodayHabits(Database db) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      AppLogger.d('Querying habits for today: $today');

      final habits = await db.query(
        'habits',
        where: 'date = ?',
        whereArgs: [today],
      );
      AppLogger.d('Loaded today\'s habits: ${habits.length} habits - $habits');

      if (habits.isEmpty) {
        AppLogger.d('No habits found for today, checking for recent habits...');
        final recentHabits = await db.query(
          'habits',
          orderBy: 'date DESC',
          limit: 10,
        );

        if (recentHabits.isNotEmpty) {
          AppLogger.d(
              'Found ${recentHabits.length} recent habits, copying unique ones to today...');
          final uniqueHabitNames = <String>{};
          for (var habit in recentHabits) {
            final name = habit['name'] as String;
            if (!uniqueHabitNames.contains(name)) {
              uniqueHabitNames.add(name);
              await db.insert('habits', {
                'name': name,
                'date': today,
                'completed': 0,
              });
            }
          }

          final updatedHabits = await db.query(
            'habits',
            where: 'date = ?',
            whereArgs: [today],
          );
          AppLogger.d(
              'Generated today\'s habits: ${updatedHabits.length} habits - $updatedHabits');
          return updatedHabits;
        }
      }

      return habits;
    } catch (e) {
      AppLogger.e('Error loading today\'s habits: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadLast7DaysMoods(Database db) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final moods = await db.query(
        'journal_entries',
        where: 'timestamp >= ?',
        whereArgs: [sevenDaysAgo.toIso8601String()],
        orderBy: 'timestamp ASC',
      );
      AppLogger.d('Loaded last 7 days moods: ${moods.length} entries - $moods');
      return moods;
    } catch (e) {
      AppLogger.e('Error loading last 7 days moods: $e');
      return [];
    }
  }

  Future<void> _toggleHabit(int id, int completed) async {
    try {
      final database = await widget.databaseFuture;
      await database.update(
        'habits',
        {'completed': completed == 1 ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.i(
          'Toggled habit id $id to ${completed == 1 ? 'incomplete' : 'complete'}.');
      await _loadData(); // Reîncarcă datele pentru a actualiza UI-ul
    } catch (e) {
      AppLogger.e('Error toggling habit id $id: $e');
    }
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
                  'Hello!',
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
                          'Your Last Mood',
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
                            : const Text('No mood recorded yet.'),
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
                          'Today\'s Habits',
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
                                      if (value != null) {
                                        _toggleHabit(
                                          habit['id'],
                                          habit['completed'],
                                        );
                                      }
                                    },
                                    activeColor:
                                        Theme.of(context).colorScheme.secondary,
                                  );
                                },
                              )
                            : const Text(
                                'No habits for today. Add some in the Habits section!'),
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
                          'Your Mood (Last 7 Days)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: last7DaysMoods.isNotEmpty
                              ? LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final dayIndex = value.toInt();
                                            if (dayIndex < 0 ||
                                                dayIndex >=
                                                    last7DaysMoods.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final date = DateTime.parse(
                                                last7DaysMoods[dayIndex]
                                                    ['timestamp']);
                                            return Text(
                                              '${date.day}/${date.month}',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: true, reservedSize: 40),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX:
                                        (last7DaysMoods.length - 1).toDouble(),
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
                                        dotData: const FlDotData(show: true),
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
                                  child: Text('No data available.'),
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
