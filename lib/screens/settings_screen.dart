import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mood_and_mind/utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) updateTheme;

  const SettingsScreen({super.key, required this.updateTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _isLoading = false;
    });
    AppLogger.i('Loaded settings: isDarkTheme=$_isDarkTheme');
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    widget.updateTheme(isDark); // Notifică aplicația despre schimbare
    AppLogger.i('Saved theme: isDarkTheme=$isDark');
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
    AppLogger.i('Notification permission: $_notificationsEnabled');
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
    AppLogger.i('Notification permission updated: $_notificationsEnabled');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: const Text('Dark Theme'),
                    value: _isDarkTheme,
                    onChanged: (value) {
                      setState(() {
                        _isDarkTheme = value;
                      });
                      _saveTheme(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListTile(
                    title: const Text('Enable Notifications'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) async {
                        if (value) {
                          await _requestNotificationPermission();
                        } else {
                          AppLogger.i('Disabling notifications not supported.');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
