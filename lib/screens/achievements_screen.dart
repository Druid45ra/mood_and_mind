import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/utils/logger.dart';

class AchievementsScreen extends StatelessWidget {
  final Database database;

  const AchievementsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementsModel>(
      builder: (context, achievementsModel, child) {
        achievementsModel.loadAchievements(); // Încărcăm datele
        AppLogger.i(
            'AchievementsScreen loaded with ${achievementsModel.achievements.length} achievements.');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Achievements'),
            backgroundColor: Colors.teal,
            elevation: 4,
          ),
          body: achievementsModel.achievements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, color: Colors.grey, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'No achievements yet. Keep going!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: achievementsModel.achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievementsModel.achievements[index];
                    return Card(
                      elevation: 6,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.star,
                            color: Colors.amber, size: 30),
                        title: Text(
                          achievement['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(achievement['description'] as String),
                        trailing: Text(
                          (achievement['timestamp'] as String).substring(0, 10),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unlocked: ${achievement['name']}'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
