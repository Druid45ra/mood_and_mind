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
import 'package:mood_and_mind/screens/onboarding_screen.dart'; // Adăugat importul

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final databaseHelper = DatabaseHelper();
  Database? database;
  String? errorMessage;

  try {
    database = await databaseHelper.database;
    await NotificationService().initialize();
  } catch (e) {
    errorMessage = 'Eroare la inițializarea aplicației: $e';
  }

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  if (!seenOnboarding) {
    await prefs.setBool('seenOnboarding', true);
  }

  runApp(MyApp(
    databaseHelper: databaseHelper,
    database: database,
    errorMessage: errorMessage,
    seenOnboarding: seenOnboarding,
  ));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final Database? database;
  final String? errorMessage;
  final bool seenOnboarding;

  const MyApp({
    super.key,
    required this.databaseHelper,
    this.database,
    this.errorMessage,
    required this.seenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null || database == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              errorMessage ?? 'Eroare la inițializarea bazei de date.',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel(database!)),
        ChangeNotifierProvider(create: (_) => AchievementsModel(database!)),
        ChangeNotifierProvider(create: (_) => HabitsModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => JournalModel(databaseHelper)),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.teal,
              brightness:
                  settings.darkMode ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor:
                  settings.darkMode ? Colors.grey[900] : Colors.grey[100],
              textTheme: GoogleFonts.poppinsTextTheme().copyWith(
                bodyLarge: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black87),
                bodyMedium: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black87),
                titleLarge: GoogleFonts.poppins(
                    color: settings.darkMode ? Colors.white : Colors.black87),
                bodySmall: GoogleFonts.poppins(
                    color: settings.darkMode
                        ? Colors.grey[400]
                        : Colors.grey[600]),
                headlineMedium: GoogleFonts.poppins(
                  color: settings.darkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              cardTheme: CardTheme(
                color: settings.darkMode ? Colors.grey[800] : Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              dividerColor:
                  settings.darkMode ? Colors.grey[700] : Colors.grey[400],
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor:
                    settings.darkMode ? Colors.grey[800] : Colors.white,
                selectedItemColor: Colors.teal,
                unselectedItemColor:
                    settings.darkMode ? Colors.grey[400] : Colors.grey[600],
                selectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
            home: seenOnboarding
                ? HomeScreen(databaseHelper: databaseHelper)
                : OnboardingScreen(databaseHelper: databaseHelper),
          );
        },
      ),
    );
  }
}
