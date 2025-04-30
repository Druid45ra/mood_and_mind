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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(database: widget.database),
      JournalScreen(database: widget.database),
      HabitsScreen(database: widget.database),
      CalendarScreen(database: widget.database),
      StatisticsScreen(database: widget.database),
      const SettingsScreen(), // Parametrul database a fost eliminat
      AchievementsScreen(database: widget.database),
    ];
    AppLogger.i('HomeScreen initialized with ${_screens.length} screens.');

    // Inițializăm animația
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _onItemTapped(int index) {
    AppLogger.i('Tapped on index: $index');
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.teal[50]!,
          color: Colors.teal[600]!,
          buttonBackgroundColor: Colors.teal[800]!,
          height: 70,
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
