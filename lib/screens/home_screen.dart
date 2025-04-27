import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'habits_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import 'package:mood_and_mind/utils/logger.dart';

class HomeScreen extends StatefulWidget {
  final Database database;
  const HomeScreen({super.key, required this.database});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(database: widget.database),
      JournalScreen(database: widget.database),
      HabitsScreen(database: widget.database),
      CalendarScreen(database: widget.database),
      StatisticsScreen(database: widget.database),
      SettingsScreen(database: widget.database),
      AchievementsScreen(database: widget.database),
    ];
  }

  void _onItemTapped(int index) {
    AppLogger.e('Tapped on index: $index'); 
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true, // Asigurăm spațiu pentru bara de navigare a sistemului
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 40,
              ),
              const SizedBox(width: 8),
              const Text('Mood & Mind'),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.teal[600],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mental Wellness',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.teal[50]!,
          color: Colors.teal[600]!,
          buttonBackgroundColor: Colors.teal[800]!,
          height: 70, // Mărind înălțimea pentru o zonă interactivă mai mare
          index: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            Icon(Icons.dashboard, color: Colors.white),
            Icon(Icons.menu_book, color: Colors.white),
            Icon(Icons.check_circle, color: Colors.white),
            Icon(Icons.calendar_today, color: Colors.white),
            Icon(Icons.bar_chart, color: Colors.white),
            Icon(Icons.settings, color: Colors.white),
            Icon(Icons.star, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
