import 'package:flutter/material.dart';
import 'package:mood_and_mind/models/settings_model.dart' as settings_model;
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<settings_model.SettingsModel>(
        builder: (context, settingsModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: settingsModel.notificationsEnabled,
                onChanged: (value) {
                  settingsModel.setNotificationsEnabled(value);
                  if (value) {
                    settingsModel.scheduleHabitNotifications();
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: settingsModel.darkMode,
                onChanged: (value) {
                  settingsModel.setDarkMode(value);
                },
              ),
              ListTile(
                title: const Text('Color Theme'),
                subtitle: Text(settingsModel.colorTheme),
                onTap: () async {
                  final selectedTheme = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Color Theme'),
                      children: ['Teal', 'Indigo']
                          .map((theme) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, theme),
                                child: Text(theme),
                              ))
                          .toList(),
                    ),
                  );
                  if (selectedTheme != null) {
                    settingsModel.setColorTheme(selectedTheme);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
