import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/splash_screen.dart';
import 'models/settings_model.dart';
import 'models/achievements_model.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final database = await DatabaseHelper().database;
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

  MaterialColor _getPrimarySwatch(String colorTheme) {
    switch (colorTheme) {
      case 'Indigo':
        return Colors.indigo;
      case 'Amber':
        return Colors.amber;
      case 'Teal':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        final primarySwatch = _getPrimarySwatch(settings.colorTheme);
        return MaterialApp(
          title: 'Mood & Mind',
          theme: ThemeData(
            primarySwatch: primarySwatch,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: primarySwatch[50],
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: primarySwatch,
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
            ),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: primarySwatch[700],
            ),
            useMaterial3: true,
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: SplashScreen(database: database),
        );
      },
    );
  }
}
