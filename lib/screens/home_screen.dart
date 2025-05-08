import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/dashboard_screen.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const HomeScreen({super.key, required this.databaseHelper});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _backgroundImagePath;
  late Database _database;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _loadBackgroundImage();
  }

  Future<void> _initializeDatabase() async {
    _database = await widget.databaseHelper.database;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backgroundImagePath = prefs.getString('backgroundImage');
    });
  }

  List<Widget> _getWidgetOptions() {
    return <Widget>[
      DashboardScreen(database: _database),
      JournalScreen(databaseHelper: widget.databaseHelper),
      HabitsScreen(
          databaseHelper: widget
              .databaseHelper), // Schimbat de la 'database' la 'databaseHelper'
      CalendarScreen(database: _database),
      SettingsScreen(databaseHelper: widget.databaseHelper),
      AchievementsScreen(database: _database),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: _backgroundImagePath != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(_backgroundImagePath!)),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.2),
                          BlendMode.dstATop,
                        ),
                      ),
                    )
                  : null,
              child: _getWidgetOptions().elementAt(_selectedIndex),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.book), label: 'Journal'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.favorite), label: 'Habits'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today), label: 'Calendar'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: 'Settings'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: 'Achievements'),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.teal,
              onTap: _onItemTapped,
            ),
    );
  }
}
