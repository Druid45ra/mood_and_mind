import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/screens/splash_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_model.dart';
import 'package:mood_and_mind/models/settings_model.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp()); // Adăugat const
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
    print('MyApp: Initializing app...');
    initialScreen = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    try {
      print('MyApp: Determining initial screen...');
      final prefs = await SharedPreferences.getInstance();
      print('MyApp: SharedPreferences loaded.');
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      print('MyApp: seenOnboarding = $seenOnboarding');
      final database = await databaseHelper.database;
      print('MyApp: Database initialized.');

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
      print('MyApp: Error determining initial screen: $e\n$stackTrace');
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error initializing app: $e')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MyApp: Building widget tree...');
    return FutureBuilder<Widget>(
      future: initialScreen,
      builder: (context, snapshot) {
        print('MyApp: FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('MyApp: Showing SplashScreen...');
          return MaterialApp(
            home: Builder(
              builder: (context) => SplashScreen(
                onFinish: () async {
                  print('SplashScreen: onFinish called.');
                  await Future.delayed(const Duration(seconds: 2));
                  if (snapshot.data != null) {
                    print('SplashScreen: Returning snapshot.data.');
                    return snapshot.data!;
                  }
                  print(
                      'SplashScreen: Snapshot data is null, returning error screen.');
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(child: Text('Error: Unable to load app')),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (snapshot.hasError) {
          print('MyApp: FutureBuilder error: ${snapshot.error}');
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          print('MyApp: FutureBuilder completed, showing main app.');
          return snapshot.data!;
        }
      },
    );
  }
}
