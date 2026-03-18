import 'package:flutter/material.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_model.dart';
import 'package:mood_and_mind/models/settings_model.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  late Future<Widget> initialScreen;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    initialScreen = _determineInitialScreen();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  void _updateTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  Future<Widget> _determineInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      final database = await databaseHelper.database;

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => JournalModel(databaseHelper)),
          ChangeNotifierProvider(create: (_) => AchievementsModel(database)),
          ChangeNotifierProvider(create: (_) => HabitsModel(databaseHelper)),
          ChangeNotifierProvider(create: (_) => SettingsModel(database)),
        ],
        child: seenOnboarding
            ? HomeScreen(databaseHelper: databaseHelper)
            : OnboardingScreen(
                databaseHelper: databaseHelper, updateTheme: _updateTheme),
      );
    } catch (e, stackTrace) {
      print('Error determining initial screen: $e\n$stackTrace');
      return Scaffold(
        body: Center(child: Text('Error initializing app: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkTheme
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: FutureBuilder<Widget>(
        future: initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/app/app.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ProviderScope(child: CalorieTrackerApp()));
>>>>>>> origin/codex/generate-complete-calorie-tracking-app-in-flutter
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/app/app.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ProviderScope(child: CalorieTrackerApp()));
>>>>>>> b663892 (Rebuild app as clean architecture calorie tracker)
}
