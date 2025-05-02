import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:mood_and_mind/models/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/mood_mind.db');
      final backupPath =
          '${directory.path}/mood_mind_backup_${DateTime.now().toIso8601String()}.db';
      await dbFile.copy(backupPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved successfully to $backupPath'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to create backup: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _backupDatabase(context),
          ),
        ),
      );
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);
        final dbPath = await getDatabasesPath();
        final dbFile = File('$dbPath/mood_mind.db');
        await dbFile.delete();
        await backupFile.copy(dbFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Database restored successfully! Please restart the app.'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup file selected.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to restore database: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _restoreDatabase(context),
          ),
        ),
      );
    }
  }

  Future<void> _clearOldData(BuildContext context) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/mood_mind.db');
    final cutoffDate =
        DateTime.now().subtract(const Duration(days: 180)); // 6 luni
    try {
      final journalDeleted = await db.delete(
        'journal',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      final habitsDeleted = await db.delete(
        'habits',
        where: 'date < ?',
        whereArgs: [cutoffDate.toIso8601String().substring(0, 10)],
      );
      await db.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cleared $journalDeleted journal entries and $habitsDeleted habits older than 6 months.'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      await db.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to clear old data: ${e.toString()}. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _clearOldData(context),
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
        backgroundColor: Colors.teal[300],
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
                    activeColor: Colors.teal[600],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Color Theme',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: settings.colorTheme,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Teal', child: Text('Teal')),
                      DropdownMenuItem(value: 'Indigo', child: Text('Indigo')),
                      DropdownMenuItem(value: 'Amber', child: Text('Amber')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setColorTheme(value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Backup & Restore',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _backupDatabase(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Backup Data'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _restoreDatabase(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restore Data'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Database Maintenance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _clearOldData(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Data Older Than 6 Months'),
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
