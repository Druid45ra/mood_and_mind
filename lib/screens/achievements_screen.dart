import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart'; // Adaugat import

class AchievementsScreen extends StatelessWidget {
  final Database database;

  const AchievementsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final achievementsModel = Provider.of<AchievementsModel>(context);
    AppLogger.i(
        'AchievementsScreen loaded with ${achievementsModel.achievements.length} achievements.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.teal[600],
      ),
      body: achievementsModel.achievements.isEmpty
          ? const Center(
              child: Text(
                'No achievements yet.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: achievementsModel.achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievementsModel.achievements[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(achievement['name'] as String),
                    subtitle: Text(achievement['description'] as String),
                    trailing: Text(
                      (achievement['timestamp'] as String).substring(0, 10),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
