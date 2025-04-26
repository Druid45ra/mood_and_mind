import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings_model.dart';
import '../generated/l10n.dart'; // Adaugă acest import

class SettingsScreen extends StatelessWidget {
  final Database database;

  const SettingsScreen({super.key, required this.database});

Future<void> _openDownloadsFolder(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context).downloadsErrorGeneric +
            ' ' +
            (AppLocalizations.of(context).language == 'ro'
                ? 'Te rugăm să accesezi manual folderul Descărcări.'
                : 'Please access the Downloads folder manually.'),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle),
        backgroundColor: Colors.teal[600], // Schimbă culoarea AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text(AppLocalizations.of(context).notifications),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              await settings.updateNotifications(value);
            },
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context).darkMode),
            value: settings.darkMode,
            onChanged: (value) async {
              await settings.updateDarkMode(value);
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).language),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: const [
                DropdownMenuItem(value: 'ro', child: Text('Română')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await settings.updateLanguage(value);
                }
              },
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).openDownloadsFolder),
            onTap: () => _openDownloadsFolder(context),
          ),
        ],
      ),
    );
  }
}
