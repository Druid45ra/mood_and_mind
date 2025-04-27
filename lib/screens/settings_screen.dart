import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  final Database database;

  const SettingsScreen({super.key, required this.database});

  Future<void> _openDownloadsFolder(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open Downloads folder. Please access the Downloads folder manually.', // Text fix în engleză
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'), // Text fix în engleză
        backgroundColor: Colors.teal[600],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Notifications'), // Text fix în engleză
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              await settings.updateNotifications(value);
            },
          ),
          SwitchListTile(
            title: const Text('Dark Mode'), // Text fix în engleză
            value: settings.darkMode,
            onChanged: (value) async {
              await settings.updateDarkMode(value);
            },
          ),
          ListTile(
            title: const Text('Open Downloads Folder'), // Text fix în engleză
            onTap: () => _openDownloadsFolder(context),
          ),
        ],
      ),
    );
  }
}
