import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/settings_model.dart';
import '../models/achievements_model.dart';
import '../generated/l10n.dart'; // Adaugă acest import

class AchievementsScreen extends StatelessWidget {
  final Database database;

  const AchievementsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final achievementsModel = Provider.of<AchievementsModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).achievementsTitle),
        backgroundColor: Colors.teal[600], // Schimbă culoarea AppBar
      ),
      body: achievementsModel.achievements.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context).noAchievements,
                style: const TextStyle(fontSize: 18),
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
