import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/services/notification_service.dart';
import 'package:mood_and_mind/models/settings_model.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/screens/splash_screen.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final databaseHelper = DatabaseHelper.instance;
  Database? database;
  String? errorMessage;

  try {
    database = await databaseHelper.database;
    await NotificationService().initialize();
  } catch (e) {
    errorMessage = 'Eroare la inițializarea aplicației: $e';
  }

  runApp(MyApp(databaseHelper: databaseHelper, errorMessage: errorMessage));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final String? errorMessage;

  const MyApp({super.key, required this.databaseHelper, this.errorMessage});

  Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('seenOnboarding') ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel(databaseHelper)),
        ChangeNotifierProvider(
            create: (_) => AchievementsModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => HabitsModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => JournalModel(databaseHelper)),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: settings.themeColor,
              brightness:
                  settings.darkMode ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor:
                  settings.darkMode ? Colors.grey[900] : Colors.white,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: settings.themeColor,
                brightness:
                    settings.darkMode ? Brightness.dark : Brightness.light,
                backgroundColor:
                    settings.darkMode ? Colors.grey[900] : Colors.white,
              ).copyWith(
                onBackground: settings.darkMode ? Colors.white : Colors.black,
                surface: settings.darkMode ? Colors.grey[800] : Colors.white,
                onSurface: settings.darkMode ? Colors.white : Colors.black,
              ),
              textTheme: GoogleFonts.poppinsTextTheme().copyWith(
                bodyLarge: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black),
                bodyMedium: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black),
                titleLarge: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: settings.themeColor,
                foregroundColor:
                    settings.darkMode ? Colors.white : Colors.black,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.themeColor,
                  foregroundColor:
                      settings.darkMode ? Colors.white : Colors.black,
                ),
              ),
              cardTheme: CardTheme(
                color: settings.darkMode ? Colors.grey[800] : Colors.white,
                surfaceTintColor: settings.themeColor,
              ),
              dividerColor:
                  settings.darkMode ? Colors.grey[600] : Colors.grey[300],
            ),
            home: SplashScreen(
              onFinish: () async {
                final seenOnboarding = await _checkOnboardingStatus();
                return seenOnboarding
                    ? HomeScreen(databaseHelper: databaseHelper)
                    : OnboardingScreen(databaseHelper: databaseHelper);
              },
            ),
          );
        },
      ),
    );
  }
}
