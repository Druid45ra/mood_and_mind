import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    initialScreen = _determineInitialScreen();
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
            : OnboardingScreen(databaseHelper: databaseHelper),
      );
    } catch (e, stackTrace) {
      print('Error determining initial screen: $e\n$stackTrace');
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error initializing app: $e')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}
