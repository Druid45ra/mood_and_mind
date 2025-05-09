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
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseHelper databaseHelper = DatabaseHelper();
  late Future<Widget> initialScreen;
  String themeMode = 'teal';
  String fontFamily = 'Roboto';
  String? backgroundImage;

  @override
  void initState() {
    super.initState();
    initialScreen = _determineInitialScreen();
  }

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    themeMode = prefs.getString('theme') ?? 'teal';
    fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
    backgroundImage = prefs.getString('backgroundImage');

    // Inițializăm baza de date o dată
    final database = await databaseHelper.database;

    return seenOnboarding
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider(
                  create: (_) => JournalModel(databaseHelper)),
              ChangeNotifierProvider(
                  create: (_) => AchievementsModel(database)),
              ChangeNotifierProvider(
                  create: (_) => HabitsModel(databaseHelper)),
              ChangeNotifierProvider(create: (_) => SettingsModel(database)),
            ],
            child: HomeScreen(databaseHelper: databaseHelper),
          )
        : OnboardingScreen(databaseHelper: databaseHelper);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: SplashScreen(
              onFinish: () => Future.value(Container()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            ),
          );
        } else {
          return MaterialApp(
            title: 'Mood & Mind',
            theme: ThemeData(
              primarySwatch: _getThemeColor(themeMode),
              textTheme: GoogleFonts.getTextTheme(
                fontFamily,
                Theme.of(context).textTheme,
              ),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: _getThemeColor(themeMode),
              textTheme: GoogleFonts.getTextTheme(
                fontFamily,
                Theme.of(context).textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
              brightness: Brightness.dark,
            ),
            themeMode: ThemeMode.system,
            home: snapshot.data,
          );
        }
      },
    );
  }

  MaterialColor _getThemeColor(String theme) {
    switch (theme) {
      case 'teal':
        return Colors.teal;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      default:
        return Colors.teal;
    }
  }
}
