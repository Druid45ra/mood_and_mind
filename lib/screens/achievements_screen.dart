import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<AchievementsModel>(
        builder: (context, achievementsModel, child) {
          final achievements = achievementsModel.achievements;
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final isAchieved = achievement['achieved'] == 1;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isAchieved ? Icons.star : Icons.star_border,
                    color: isAchieved ? Colors.amber : Colors.grey,
                  ),
                  title: Text(
                    achievement['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAchieved ? Colors.teal : Colors.grey,
                    ),
                  ),
                  subtitle: Text(achievement['description']),
                  trailing: isAchieved
                      ? Text(
                          achievement['timestamp']?.substring(0, 10) ?? 'N/A',
                          style: const TextStyle(color: Colors.teal),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
