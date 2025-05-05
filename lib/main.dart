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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final databaseHelper = DatabaseHelper();
  Database? database;
  String? errorMessage;

  try {
    print('Attempting to initialize database...');
    database = await databaseHelper.database;
    print('Database initialized successfully with database: $database');
    await NotificationService().initialize();
  } catch (e) {
    errorMessage = 'Eroare la inițializarea aplicației: $e';
    print(errorMessage);
  }

  // Resetează seenOnboarding pentru debug
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('seenOnboarding', false);
  print('SharedPreferences reset: seenOnboarding = false');

  runApp(MyApp(
      databaseHelper: databaseHelper,
      database: database,
      errorMessage: errorMessage));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final Database? database;
  final String? errorMessage;

  const MyApp(
      {super.key,
      required this.databaseHelper,
      this.database,
      this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null || database == null) {
      print(
          'Error condition met: errorMessage = $errorMessage, database = $database');
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

    print('Building MyApp with database: $database');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel(database!)),
        ChangeNotifierProvider(create: (_) => AchievementsModel(database!)),
        ChangeNotifierProvider(create: (_) => HabitsModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => JournalModel(databaseHelper)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme().copyWith(
            bodyLarge: GoogleFonts.poppins(color: Colors.black),
            bodyMedium: GoogleFonts.poppins(color: Colors.black),
            titleLarge: GoogleFonts.poppins(color: Colors.black),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.black,
            ),
          ),
          cardTheme: const CardTheme(
            color: Colors.white,
            surfaceTintColor: Colors.teal,
          ),
          dividerColor: Colors.grey[300],
        ),
        home: HomeScreen(databaseHelper: databaseHelper),
      ),
    );
  }
}
