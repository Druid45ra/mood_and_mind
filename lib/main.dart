import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_and_mind/models/journal_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHelper = DatabaseHelper();
  final prefs = await SharedPreferences.getInstance();
  final themeMode = prefs.getString('theme') ?? 'teal';
  final fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
  final backgroundImage = prefs.getString('backgroundImage');

  runApp(
    ChangeNotifierProvider(
      create: (_) => JournalModel(databaseHelper),
      child: MyApp(
        databaseHelper: databaseHelper,
        initialTheme: themeMode,
        initialFontFamily: fontFamily,
        initialBackgroundImage: backgroundImage,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final String initialTheme;
  final String initialFontFamily;
  final String? initialBackgroundImage;

  const MyApp({
    super.key,
    required this.databaseHelper,
    required this.initialTheme,
    required this.initialFontFamily,
    this.initialBackgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood & Mind',
      theme: ThemeData(
        primarySwatch: _getThemeColor(initialTheme),
        textTheme: GoogleFonts.getTextTheme(
          initialFontFamily,
          Theme.of(context).textTheme,
        ),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: _getThemeColor(initialTheme),
        textTheme: GoogleFonts.getTextTheme(
          initialFontFamily,
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(databaseHelper: databaseHelper),
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
