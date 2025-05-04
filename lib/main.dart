import 'package:flutter/material.dart';
import 'package:mood_and_mind/screens/onboarding_screen.dart';
import 'package:mood_and_mind/screens/home_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHelper = DatabaseHelper();
  runApp(MyApp(databaseHelper: databaseHelper));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const MyApp({Key? key, required this.databaseHelper}) : super(key: key);

  Future<bool> checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        cardTheme: CardTheme(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        dividerColor: const Color.fromARGB(255, 45, 26, 26),
      ),
      home: SplashScreen(
        databaseHelper: databaseHelper,
        onFinish: () async {
          final seenOnboarding = await checkOnboardingStatus();
          return seenOnboarding
              ? HomeScreen(databaseHelper: databaseHelper)
              : OnboardingScreen(databaseHelper: databaseHelper);
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final Future<Widget> Function() onFinish;

  const SplashScreen(
      {Key? key, required this.databaseHelper, required this.onFinish})
      : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final nextScreen = await widget.onFinish();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
