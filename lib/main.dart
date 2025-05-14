import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/screens/splash_screen.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/models/journal_model.dart';
import 'package:mood_and_mind/models/settings_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _buildApp() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    final databaseHelper = DatabaseHelper();
    final database = await databaseHelper.database;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JournalModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => AchievementsModel(database)),
        ChangeNotifierProvider(create: (_) => HabitsModel(databaseHelper)),
        ChangeNotifierProvider(create: (_) => SettingsModel(database)),
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, _) {
          final isDarkMode = settings.isDarkMode; // Asigură-te că ai getter-ul

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.indigo,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.indigo,
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: seenOnboarding
                ? HomeScreen(databaseHelper: databaseHelper)
                : OnboardingScreen(databaseHelper: databaseHelper),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: SplashScreen(
              onFinish: _dummyOnFinish,
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

  static Future<Widget> _dummyOnFinish() async {
    return const SizedBox.shrink();
  }
}
