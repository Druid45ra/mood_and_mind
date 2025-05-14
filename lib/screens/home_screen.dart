import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/screens/dashboard_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/statistics_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/models/settings_model.dart' as settings_model;
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  const HomeScreen({super.key, required this.databaseHelper});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsModel =
          Provider.of<settings_model.SettingsModel>(context, listen: false);
      final achievementsModel =
          Provider.of<AchievementsModel>(context, listen: false);
      achievementsModel.setContext(context);
      await settingsModel.loadSettings();
      final database = await widget.databaseHelper.database;
      setState(() {
        _screens = [
          CalendarScreen(database: database), // 0
          JournalScreen(databaseHelper: widget.databaseHelper), // 1
          HabitsScreen(databaseHelper: widget.databaseHelper), // 2
          DashboardScreen(database: database), // 3
          AchievementsScreen(), // 4
          StatisticsScreen(database: database), // 5
          SettingsScreen(), // 6
        ];
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, _screens.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<settings_model.SettingsModel>(
      builder: (context, settingsModel, child) {
        return Theme(
          data: settingsModel.darkMode
              ? ThemeData(
                  primarySwatch: settingsModel.themeColor ?? Colors.teal,
                  textTheme: GoogleFonts.getTextTheme(
                    'Roboto',
                    Theme.of(context).textTheme.apply(
                          bodyColor: Colors.white,
                          displayColor: Colors.white,
                        ),
                  ),
                  brightness: Brightness.dark,
                )
              : ThemeData(
                  primarySwatch: settingsModel.themeColor ?? Colors.teal,
                  textTheme: GoogleFonts.getTextTheme(
                    'Roboto',
                    Theme.of(context).textTheme,
                  ),
                  brightness: Brightness.light,
                ),
          child: Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Journal',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist),
                  label: 'Habits',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star),
                  label: 'Achievements',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Statistics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              backgroundColor: settingsModel.themeColor ?? Colors.teal,
              onTap: _onItemTapped,
              elevation: 8.0,
              type: BottomNavigationBarType.fixed,
            ),
          ),
        );
      },
    );
  }
}
