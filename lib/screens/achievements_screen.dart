import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:mood_and_mind/utils/logger.dart';

class AchievementsScreen extends StatefulWidget {
  final Future<Database> databaseFuture;

  const AchievementsScreen({super.key, required this.databaseFuture});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int completedHabits = 0;
  int journalEntries = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    AppLogger.i('Starting to load achievements data...');
    setState(() {
      isLoading = true;
    });

    try {
      final database = await widget.databaseFuture;
      final habitsResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM habits WHERE completed = 1',
      );
      final journalResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM journal_entries',
      );

      setState(() {
        completedHabits = habitsResult.first['count'] as int;
        journalEntries = journalResult.first['count'] as int;
        isLoading = false;
      });
      AppLogger.i(
          'Achievements loaded: $completedHabits habits completed, $journalEntries journal entries.');
    } catch (e) {
      AppLogger.e('Error loading achievements: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Achievements',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                            'Habits Completed: $completedHabits',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Journal Entries: $journalEntries',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          if (completedHabits >= 10)
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Habit Master: Completed 10 habits!'),
                              ],
                            ),
                          if (journalEntries >= 5)
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Journal Pro: Wrote 5 journal entries!'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
