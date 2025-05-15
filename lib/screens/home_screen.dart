import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/dashboard_screen.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/screens/achievements_screen.dart';
import 'package:mood_and_mind/screens/calendar_screen.dart';
import 'package:mood_and_mind/screens/statistics_screen.dart';
import 'package:mood_and_mind/screens/settings_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const HomeScreen({super.key, required this.databaseHelper});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final List<String> _titles = [
    'Dashboard',
    'Journal',
    'Habits',
    'Achievements',
    'Calendar',
    'Statistics',
    'Settings',
  ];

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.book,
    Icons.checklist,
    Icons.star,
    Icons.calendar_today,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(databaseFuture: widget.databaseHelper.database),
      JournalScreen(databaseHelper: widget.databaseHelper),
      HabitsScreen(databaseHelper: widget.databaseHelper),
      AchievementsScreen(),
      CalendarScreen(databaseFuture: widget.databaseHelper.database),
      StatisticsScreen(databaseFuture: widget.databaseHelper.database),
      SettingsScreen(),
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
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _icons
            .asMap()
            .map((index, icon) => MapEntry(
                  index,
                  BottomNavigationBarItem(
                    icon: Icon(icon),
                    label: _titles[index],
                  ),
                ))
            .values
            .toList(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
