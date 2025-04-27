import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/home_screen.dart';
import 'models/settings_model.dart';
import 'models/achievements_model.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Inițializează fusurile orare pentru notificări
  final database = await DatabaseService.initDatabase();
  final settingsModel = SettingsModel(database);
  await settingsModel.loadSettings();
  await NotificationService.initializeNotifications(database, settingsModel);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsModel),
        ChangeNotifierProvider(create: (_) => AchievementsModel(database)),
      ],
      child: MoodAndMindApp(database: database),
    ),
  );
}

class MoodAndMindApp extends StatelessWidget {
  final Database database;

  const MoodAndMindApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Mood & Mind',
          theme: ThemeData(
            primarySwatch: Colors.teal,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.teal[50],
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.teal,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
            ),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.teal[700],
            ),
            useMaterial3: true,
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(database: database),
        );
      },
    );
  }
}
