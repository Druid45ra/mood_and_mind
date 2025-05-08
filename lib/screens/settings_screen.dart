import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood_and_mind/utils/logger.dart';
import 'package:mood_and_mind/services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const SettingsScreen({super.key, required this.databaseHelper});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'teal';
  String _selectedFontFamily = 'Roboto';
  String? _backgroundImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme') ?? 'teal';
      _selectedFontFamily = prefs.getString('fontFamily') ?? 'Roboto';
      _backgroundImagePath = prefs.getString('backgroundImage');
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _selectedTheme);
    await prefs.setString('fontFamily', _selectedFontFamily);
    if (_backgroundImagePath != null) {
      await prefs.setString('backgroundImage', _backgroundImagePath!);
    }
    AppLogger.i(
        'Preferences saved: theme=$_selectedTheme, font=$_selectedFontFamily, background=$_backgroundImagePath');
    if (mounted) setState(() {});
  }

  Future<void> _pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImagePath = image.path;
      });
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTheme,
              decoration: const InputDecoration(labelText: 'Theme'),
              items: <String>['teal', 'purple', 'pink']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTheme = newValue!;
                });
                _savePreferences();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFontFamily,
              decoration: const InputDecoration(labelText: 'Font'),
              items: <String>['Roboto', 'Lato', 'Open Sans']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFontFamily = newValue!;
                });
                _savePreferences();
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Background Image'),
              subtitle: _backgroundImagePath != null
                  ? Text('Selected: $_backgroundImagePath')
                  : const Text('No image selected'),
              trailing: IconButton(
                icon: const Icon(Icons.photo),
                onPressed: _pickBackgroundImage,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Database Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                AppLogger.i('Reset All Data pressed');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset All Data',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
