import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart'; // Importăm sqflite pentru tipul Database
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/services/notification_service.dart';
import 'package:mood_and_mind/models/settings_model.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/screens/splash_screen.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final database = await DatabaseHelper().database;
  await NotificationService().initialize(); // Folosim metoda corectă
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  final Database database;

  MyApp({super.key, required this.database});

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsModel(database),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementsModel(database),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: SplashScreen(
          onFinish: () async {
            final seenOnboarding = await _checkOnboardingStatus();
            if (seenOnboarding) {
              return HomeScreen(database: database);
            } else {
              return OnboardingScreen(database: database);
            }
          },
        ),
      ),
    );
  }
}
