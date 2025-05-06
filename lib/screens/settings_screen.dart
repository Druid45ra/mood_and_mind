import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetAllData(BuildContext context) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/mood_and_mind.db');
    try {
      await db.delete('settings');
      await db.delete('habits');
      await db.delete('journal_entries');
      await db.delete('achievements');
      await db.close();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been reset successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      await db.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset data: ${e.toString()}. Try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _resetAllData(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsModel>(
          builder: (context, settings, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: settings.darkMode,
                    onChanged: (value) {
                      settings.setDarkMode(value);
                    },
                    activeColor: Colors.teal,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Database Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _resetAllData(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset All Data'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
