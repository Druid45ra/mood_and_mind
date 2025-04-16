import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final database = await initDatabase();
  final settingsModel = SettingsModel(database);
  await settingsModel.loadSettings();
  await initializeNotifications(database, settingsModel);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsModel),
        ChangeNotifierProvider(create: (_) => AchievementsModel(database)),
      ],
      child: const MoodAndMindApp(),
    ),
  );
}

Future<Database> initDatabase() async {
  return openDatabase(
    p.join(await getDatabasesPath(), 'mood_mind.db'),
    onCreate: (db, version) async {
      print('Creating database...');
      await db.execute(
        'CREATE TABLE journal(id INTEGER PRIMARY KEY AUTOINCREMENT, mood TEXT, intensity INTEGER, note TEXT, timestamp TEXT)',
      );
      await db.execute(
        'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT, notification_time TEXT)',
      );
      await db.execute(
        'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
      );
      await db.execute(
        'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
      );
      await db.insert('settings', {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
        'language': 'ro',
      });
      print('Database created successfully.');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      print('Upgrading database from version $oldVersion to $newVersion...');
      if (oldVersion < 2) {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
        );
        if (tables.isEmpty) {
          await db.execute(
            'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
          );
          await db.insert('settings', {
            'id': 1,
            'notifications_enabled': 1,
            'dark_mode': 0,
            'language': 'ro',
          });
        }
      }
      if (oldVersion < 3) {
        final columns = await db.rawQuery("PRAGMA table_info(journal)");
        bool hasIntensity = columns.any((col) => col['name'] == 'intensity');
        if (!hasIntensity) {
          await db.execute('ALTER TABLE journal ADD COLUMN intensity INTEGER');
          print('Added intensity column to journal table.');
        }
      }
      if (oldVersion < 4) {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='habits'",
        );
        if (tables.isNotEmpty) {
          await db.execute(
            'CREATE TABLE habits_temp(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT)',
          );
          await db.execute(
            'INSERT INTO habits_temp(name, completed, date) SELECT name, completed, date FROM habits',
          );
          await db.execute('DROP TABLE habits');
          await db.execute('ALTER TABLE habits_temp RENAME TO habits');
          print('Updated habits table schema.');
        }
      }
      if (oldVersion < 5) {
        final columns = await db.rawQuery("PRAGMA table_info(habits)");
        bool hasNotificationTime =
            columns.any((col) => col['name'] == 'notification_time');
        if (!hasNotificationTime) {
          await db
              .execute('ALTER TABLE habits ADD COLUMN notification_time TEXT');
          print('Added notification_time column to habits table.');
        }
      }
      if (oldVersion < 6) {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'",
        );
        if (tables.isEmpty) {
          await db.execute(
            'CREATE TABLE achievements(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, earned INTEGER, timestamp TEXT)',
          );
          print('Created achievements table.');
        }
      }
      print('Database upgraded successfully.');
    },
    version: 6,
  );
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications(
    Database database, SettingsModel settingsModel) async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  try {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
    );
    if (tables.isEmpty) {
      await database.execute(
        'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER, language TEXT)',
      );
      await database.insert('settings', {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
        'language': 'ro',
      });
    }

    if (settingsModel.notificationsEnabled) {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        settingsModel.language == 'ro'
            ? 'Cum te simți astăzi?'
            : 'How do you feel today?',
        settingsModel.language == 'ro'
            ? 'Deschide Mood & Mind și înregistrează-ți starea!'
            : 'Open Mood & Mind and log your mood!',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification',
            'Daily Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('Daily notification scheduled successfully.');
      await settingsModel.scheduleHabitNotifications();
    }
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

class SettingsModel with ChangeNotifier {
  final Database _database;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _language = 'ro';

  SettingsModel(this._database);

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;
  String get language => _language;

  Future<void> loadSettings() async {
    try {
      final settings = await _database.query(
        'settings',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (settings.isNotEmpty) {
        _notificationsEnabled =
            (settings[0]['notifications_enabled'] as int?) == 1;
        _darkMode = (settings[0]['dark_mode'] as int?) == 1;
        _language = (settings[0]['language'] as String?) ?? 'ro';
        notifyListeners();
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> updateNotifications(bool value) async {
    try {
      await _database.update(
        'settings',
        {'notifications_enabled': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );
      _notificationsEnabled = value;
      notifyListeners();
      if (value) {
        await flutterLocalNotificationsPlugin.periodicallyShow(
          0,
          _language == 'ro' ? 'Cum te simți astăzi?' : 'How do you feel today?',
          _language == 'ro'
              ? 'Deschide Mood & Mind și înregistrează-ți starea!'
              : 'Open Mood & Mind and log your mood!',
          RepeatInterval.daily,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_notification',
              'Daily Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        await scheduleHabitNotifications();
      } else {
        await flutterLocalNotificationsPlugin.cancelAll();
      }
    } catch (e) {
      print('Error updating notifications: $e');
    }
  }

  Future<void> scheduleHabitNotifications() async {
    if (!_notificationsEnabled) return;
    try {
      final habits = await _database.query('habits');
      for (var habit in habits) {
        if (habit['notification_time'] != null) {
          final timeParts = (habit['notification_time'] as String).split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final id = habit['id'] as int;
          final name = habit['name'] as String;
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id,
            _language == 'ro' ? 'E timpul pentru $name!' : 'Time for $name!',
            _language == 'ro'
                ? 'Completează-ți obiceiul acum.'
                : 'Complete your habit now.',
            _nextInstanceOfTime(hour, minute),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'habit_notification',
                'Habit Notifications',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          print('Scheduled notification for habit: $name at $hour:$minute');
        }
      }
    } catch (e) {
      print('Error scheduling habit notifications: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> updateDarkMode(bool value) async {
    try {
      await _database.update(
        'settings',
        {'dark_mode': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [1],
      );
      _darkMode = value;
      notifyListeners();
    } catch (e) {
      print('Error updating dark mode: $e');
    }
  }

  Future<void> updateLanguage(String value) async {
    try {
      await _database.update(
        'settings',
        {'language': value},
        where: 'id = ?',
        whereArgs: [1],
      );
      _language = value;
      notifyListeners();
      if (_notificationsEnabled) {
        await flutterLocalNotificationsPlugin.cancelAll();
        await flutterLocalNotificationsPlugin.periodicallyShow(
          0,
          _language == 'ro' ? 'Cum te simți astăzi?' : 'How do you feel today?',
          _language == 'ro'
              ? 'Deschide Mood & Mind și înregistrează-ți starea!'
              : 'Open Mood & Mind and log your mood!',
          RepeatInterval.daily,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_notification',
              'Daily Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        await scheduleHabitNotifications();
      }
    } catch (e) {
      print('Error updating language: $e');
    }
  }
}

class AchievementsModel with ChangeNotifier {
  final Database _database;
  List<Map<String, dynamic>> _achievements = [];

  AchievementsModel(this._database) {
    _loadAchievements();
  }

  List<Map<String, dynamic>> get achievements => _achievements;

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _database.query('achievements');
      _achievements = achievements;
      notifyListeners();
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  Future<void> unlockAchievement(
      String name, String description, BuildContext context) async {
    try {
      final existing = await _database.query(
        'achievements',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (existing.isEmpty) {
        await _database.insert(
          'achievements',
          {
            'name': name,
            'description': description,
            'earned': 1,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        await _loadAchievements();
        final settings = Provider.of<SettingsModel>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'ro'
                  ? 'Felicitări! Ai deblocat insigna: $name'
                  : 'Congratulations! You unlocked the badge: $name',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  Future<void> checkAchievements(BuildContext context) async {
    final journalEntries = await _database.query('journal');
    final habits = await _database.query('habits');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final settings = Provider.of<SettingsModel>(context, listen: false);

    // First journal entry
    if (journalEntries.isNotEmpty) {
      await unlockAchievement(
        settings.language == 'ro' ? 'Primul pas' : 'First Step',
        settings.language == 'ro'
            ? 'Ai înregistrat prima ta stare de spirit!'
            : 'You logged your first mood!',
        context,
      );
    }

    // All habits completed today
    final todayHabits = habits.where((h) => h['date'] == today).toList();
    if (todayHabits.isNotEmpty &&
        todayHabits.every((h) => h['completed'] == 1)) {
      await unlockAchievement(
        settings.language == 'ro' ? 'Zi perfectă' : 'Perfect Day',
        settings.language == 'ro'
            ? 'Ai completat toate obiceiurile astăzi!'
            : 'You completed all habits today!',
        context,
      );
    }

    // 7 days consecutive journal
    int streak = 0;
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      String dateStr = currentDate
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      if (journalEntries
          .any((entry) => (entry['timestamp'] as String).startsWith(dateStr))) {
        streak++;
      } else {
        break;
      }
    }
    if (streak >= 7) {
      await unlockAchievement(
        settings.language == 'ro' ? '7 zile consecutive' : '7 Day Streak',
        settings.language == 'ro'
            ? 'Ai înregistrat starea de spirit 7 zile la rând!'
            : 'You logged your mood for 7 days in a row!',
        context,
      );
    }
  }
}

class MoodAndMindApp extends StatelessWidget {
  const MoodAndMindApp({super.key});

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
          home: HomeScreen(database: settings._database),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Database database;
  const HomeScreen({super.key, required this.database});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      JournalScreen(database: widget.database),
      HabitsScreen(database: widget.database),
      CalendarScreen(database: widget.database),
      StatisticsScreen(database: widget.database),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal[300],
              ),
              child: Text(
                'Mood & Mind',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(
                  settings.language == 'ro' ? 'Realizări' : 'Achievements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AchievementsScreen(database: widget.database),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(settings.language == 'ro' ? 'Setări' : 'Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(database: widget.database),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: AnimatedScale(
              scale: _selectedIndex == 0 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.menu_book),
            ),
            label: settings.language == 'ro' ? 'Jurnal' : 'Journal',
            tooltip:
                settings.language == 'ro' ? 'Jurnal zilnic' : 'Daily Journal',
          ),
          BottomNavigationBarItem(
            icon: AnimatedScale(
              scale: _selectedIndex == 1 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.check_circle_outline),
            ),
            label: settings.language == 'ro' ? 'Obiceiuri' : 'Habits',
            tooltip: settings.language == 'ro'
                ? 'Obiceiuri zilnice'
                : 'Daily Habits',
          ),
          BottomNavigationBarItem(
            icon: AnimatedScale(
              scale: _selectedIndex == 2 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.calendar_month),
            ),
            label: settings.language == 'ro' ? 'Calendar' : 'Calendar',
            tooltip: settings.language == 'ro'
                ? 'Calendar activități'
                : 'Activity Calendar',
          ),
          BottomNavigationBarItem(
            icon: AnimatedScale(
              scale: _selectedIndex == 3 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.insert_chart_outlined),
            ),
            label: settings.language == 'ro' ? 'Statistici' : 'Statistics',
            tooltip: settings.language == 'ro'
                ? 'Statistici progres'
                : 'Progress Statistics',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[600],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedIconTheme: const IconThemeData(size: 30),
        unselectedIconTheme: const IconThemeData(size: 24),
        showUnselectedLabels: true,
        elevation: 8,
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  final Database database;
  const JournalScreen({super.key, required this.database});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? selectedMood;
  int intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> journalEntries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final List<Map<String, dynamic>> entries = await widget.database.query(
        'journal',
        orderBy: 'timestamp DESC',
      );
      setState(() {
        journalEntries = entries;
      });
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
    } catch (e) {
      print('Error loading entries: $e');
    }
  }

  Future<void> _saveEntry() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Te rog alege o stare de spirit!'
                : 'Please choose a mood!',
          ),
        ),
      );
      return;
    }
    try {
      await widget.database.insert(
        'journal',
        {
          'mood': selectedMood,
          'intensity': intensity,
          'note': _noteController.text,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _noteController.clear();
      setState(() {
        selectedMood = null;
        intensity = 5;
      });
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Starea de spirit a fost salvată!'
                : 'Mood has been saved!',
          ),
        ),
      );
    } catch (e) {
      print('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la salvarea stării. Încearcă din nou.'
                : 'Error saving mood. Try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(settings.language == 'ro' ? 'Jurnal zilnic' : 'Daily Journal'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.language == 'ro'
                  ? 'Cum te simți astăzi?'
                  : 'How do you feel today?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodEmoji(
                  emoji: '😢',
                  value: settings.language == 'ro' ? 'Trist' : 'Sad',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😐',
                  value: settings.language == 'ro' ? 'Neutru' : 'Neutral',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😊',
                  value: settings.language == 'ro' ? 'Bine' : 'Good',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😃',
                  value: settings.language == 'ro' ? 'Fericit' : 'Happy',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '🥰',
                  value: settings.language == 'ro' ? 'Împlinit' : 'Fulfilled',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
                '${settings.language == 'ro' ? 'Intensitate' : 'Intensity'}: $intensity'),
            Slider(
              value: intensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: intensity.toString(),
              onChanged: (value) => setState(() => intensity = value.round()),
              activeColor: Colors.teal[600],
              inactiveColor: Colors.teal[100],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: settings.language == 'ro'
                    ? 'Notiță (opțional)'
                    : 'Note (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEntry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
              ),
              child: Text(settings.language == 'ro' ? 'Salvează' : 'Save'),
            ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro' ? 'Intrări recente' : 'Recent Entries',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? Text(settings.language == 'ro'
                    ? 'Nicio intrare încă. Adaugă una!'
                    : 'No entries yet. Add one!')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: journalEntries.length,
                    itemBuilder: (context, index) {
                      final entry = journalEntries[index];
                      return ListTile(
                        leading: Text(
                          _getEmojiForMood(entry['mood'] as String),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                            '${entry['mood']} (${entry['intensity'] ?? 'N/A'}/10)'),
                        subtitle: Text(
                          (entry['note'] as String?)?.isNotEmpty == true
                              ? entry['note'] as String
                              : (settings.language == 'ro'
                                  ? 'Fără notiță'
                                  : 'No note'),
                        ),
                        trailing: Text(
                          (entry['timestamp'] as String).substring(0, 10),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  String _getEmojiForMood(String mood) {
    switch (mood) {
      case 'Trist':
      case 'Sad':
        return '😢';
      case 'Neutru':
      case 'Neutral':
        return '😐';
      case 'Bine':
      case 'Good':
        return '😊';
      case 'Fericit':
      case 'Happy':
        return '😃';
      case 'Împlinit':
      case 'Fulfilled':
        return '🥰';
      default:
        return '😐';
    }
  }
}

class HabitsScreen extends StatefulWidget {
  final Database database;
  const HabitsScreen({super.key, required this.database});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final TextEditingController _habitController = TextEditingController();
  List<Map<String, dynamic>> habits = [];
  String today = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final List<Map<String, dynamic>> loadedHabits =
          await widget.database.query(
        'habits',
        where: 'date = ?',
        whereArgs: [today],
      );
      setState(() {
        habits = loadedHabits;
      });
      await Provider.of<AchievementsModel>(context, listen: false)
          .checkAchievements(context);
    } catch (e) {
      print('Error loading habits: $e');
    }
  }

  Future<void> _addHabit() async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Introdu un nume pentru obicei!'
                : 'Enter a name for the habit!',
          ),
        ),
      );
      return;
    }
    try {
      await widget.database.insert(
        'habits',
        {
          'name': name,
          'completed': 0,
          'date': today,
          'notification_time': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      _habitController.clear();
      await _loadHabits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Obiceiul a fost adăugat!'
                : 'Habit has been added!',
          ),
        ),
      );
    } catch (e) {
      print('Error adding habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la adăugarea obiceiului: $e'
                : 'Error adding habit: $e',
          ),
        ),
      );
    }
  }

  Future<void> _toggleHabit(int id, bool completed) async {
    try {
      await widget.database.update(
        'habits',
        {'completed': completed ? 1 : 0},
        where: 'id = ? AND date = ?',
        whereArgs: [id, today],
      );
      await _loadHabits();
    } catch (e) {
      print('Error toggling habit: $e');
    }
  }

  Future<void> _setNotificationTime(int id, String name) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: settings.language == 'ro'
          ? 'Selectează ora pentru $name'
          : 'Select time for $name',
    );
    if (picked != null) {
      try {
        final notificationTime = '${picked.hour}:${picked.minute}';
        await widget.database.update(
          'habits',
          {'notification_time': notificationTime},
          where: 'id = ?',
          whereArgs: [id],
        );
        await Provider.of<SettingsModel>(context, listen: false)
            .scheduleHabitNotifications();
        await _loadHabits();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'ro'
                  ? 'Notificare setată pentru $name la $notificationTime'
                  : 'Notification set for $name at $notificationTime',
            ),
          ),
        );
      } catch (e) {
        print('Error setting notification time: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.language == 'ro'
                  ? 'Eroare la setarea notificării.'
                  : 'Error setting notification.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            settings.language == 'ro' ? 'Obiceiuri zilnice' : 'Daily Habits'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _habitController,
                    decoration: InputDecoration(
                      labelText: settings.language == 'ro'
                          ? 'Adaugă un obicei'
                          : 'Add a habit',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro'
                  ? 'Obiceiurile tale de astăzi'
                  : 'Your habits for today',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        settings.language == 'ro'
                            ? 'Niciun obicei adăugat. Începe acum!'
                            : 'No habits added. Start now!',
                      ),
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return CheckboxListTile(
                          title: Text(habit['name'] as String),
                          subtitle: habit['notification_time'] != null
                              ? Text(
                                  '${settings.language == 'ro' ? 'Notificare' : 'Notification'}: ${habit['notification_time']}')
                              : Text(settings.language == 'ro'
                                  ? 'Fără notificare'
                                  : 'No notification'),
                          value: habit['completed'] == 1,
                          activeColor: Colors.teal[600],
                          secondary: IconButton(
                            icon: const Icon(Icons.alarm),
                            color: habit['notification_time'] != null
                                ? Colors.teal[600]
                                : Colors.grey,
                            onPressed: () => _setNotificationTime(
                                habit['id'] as int, habit['name'] as String),
                          ),
                          onChanged: (value) =>
                              _toggleHabit(habit['id'] as int, value ?? false),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final Database database;
  const CalendarScreen({super.key, required this.database});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _habits = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadDataForDay(_selectedDay!);
  }

  Future<void> _loadDataForDay(DateTime day) async {
    final dateStr = day.toIso8601String().substring(0, 10);
    try {
      final journalEntries = await widget.database.query(
        'journal',
        where: 'timestamp LIKE ?',
        whereArgs: ['$dateStr%'],
      );
      final habits = await widget.database.query(
        'habits',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      setState(() {
        _journalEntries = journalEntries;
        _habits = habits;
      });
    } catch (e) {
      print('Error loading data for day: $e');
    }
  }

  Map<DateTime, List<dynamic>> _getEventsForDays() {
    Map<DateTime, List<dynamic>> events = {};
    DateTime start = DateTime.now().subtract(const Duration(days: 365));
    DateTime end = DateTime.now().add(const Duration(days: 365));
    for (DateTime day = start;
        day.isBefore(end);
        day = day.add(const Duration(days: 1))) {
      String dateStr = day.toIso8601String().substring(0, 10);
      bool hasData = _journalEntries.any(
              (entry) => (entry['timestamp'] as String).startsWith(dateStr)) ||
          _habits.any((habit) => (habit['date'] as String) == dateStr);
      if (hasData) {
        events[DateTime(day.year, day.month, day.day)] = ['Data'];
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.language == 'ro' ? 'Calendar' : 'Calendar'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadDataForDay(selectedDay);
              },
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) => _getEventsForDays()[day] ?? [],
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal[200],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.teal[600],
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.teal[400],
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${settings.language == 'ro' ? 'Detalii pentru' : 'Details for'} ${_selectedDay?.toIso8601String().substring(0, 10) ?? (settings.language == 'ro' ? 'ziua selectată' : 'selected day')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              settings.language == 'ro' ? 'Stări de spirit' : 'Moods',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _journalEntries.isEmpty
                ? Text(settings.language == 'ro'
                    ? 'Nicio stare înregistrată.'
                    : 'No moods recorded.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _journalEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _journalEntries[index];
                      return ListTile(
                        leading: Text(
                          _getEmojiForMood(entry['mood'] as String),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title:
                            Text('${entry['mood']} (${entry['intensity']}/10)'),
                        subtitle: Text(
                          (entry['note'] as String?)?.isNotEmpty == true
                              ? entry['note'] as String
                              : (settings.language == 'ro'
                                  ? 'Fără notiță'
                                  : 'No note'),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro' ? 'Obiceiuri' : 'Habits',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _habits.isEmpty
                ? Text(settings.language == 'ro'
                    ? 'Niciun obicei înregistrat.'
                    : 'No habits recorded.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
                      return ListTile(
                        title: Text(habit['name'] as String),
                        trailing: Icon(
                          habit['completed'] == 1
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: habit['completed'] == 1
                              ? Colors.teal[600]
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  String _getEmojiForMood(String mood) {
    switch (mood) {
      case 'Trist':
      case 'Sad':
        return '😢';
      case 'Neutru':
      case 'Neutral':
        return '😐';
      case 'Bine':
      case 'Good':
        return '😊';
      case 'Fericit':
      case 'Happy':
        return '😃';
      case 'Împlinit':
      case 'Fulfilled':
        return '🥰';
      default:
        return '😐';
    }
  }
}

class SettingsScreen extends StatelessWidget {
  final Database database;
  const SettingsScreen({super.key, required this.database});

  Future<void> _launchGooglePlay(BuildContext context) async {
    const url =
        'https://play.google.com/store/apps/details?id=com.example.mood_and_mind';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Play.')),
      );
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final uri =
        Uri.parse('mailto:your.email@example.com?subject=Feedback Mood & Mind');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  Future<void> _exportJournal(BuildContext context) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    try {
      final entries = await database.query('journal');
      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/journal_export.csv');
      String csv = 'ID,Mood,Intensity,Note,Timestamp\n';
      for (var entry in entries) {
        final note = (entry['note'] as String?)?.replaceAll(',', '') ?? '';
        csv +=
            '${entry['id']},${entry['mood']},${entry['intensity'] ?? ''},$note,${entry['timestamp']}\n';
      }
      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Jurnalul a fost exportat în ${file.path}'
                : 'Journal exported to ${file.path}',
          ),
        ),
      );
    } catch (e) {
      print('Error exporting journal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la exportarea jurnalului.'
                : 'Error exporting journal.',
          ),
        ),
      );
    }
  }

  Future<void> _exportHabits(BuildContext context) async {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    try {
      final habits = await database.query('habits');
      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/habits_export.csv');
      String csv = 'ID,Name,Completed,Date,Notification Time\n';
      for (var habit in habits) {
        final name = (habit['name'] as String?)?.replaceAll(',', '') ?? '';
        csv +=
            '${habit['id']},$name,${habit['completed']},${habit['date']},${habit['notification_time'] ?? ''}\n';
      }
      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Obiceiurile au fost exportate în ${file.path}'
                : 'Habits exported to ${file.path}',
          ),
        ),
      );
    } catch (e) {
      print('Error exporting habits: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.language == 'ro'
                ? 'Eroare la exportarea obiceiurilor.'
                : 'Error exporting habits.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.language == 'ro' ? 'Setări' : 'Settings'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            settings.language == 'ro'
                ? 'Personalizează aplicația'
                : 'Customize App',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(
                settings.language == 'ro' ? 'Notificări' : 'Notifications'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Activează notificările zilnice și pentru obiceiuri'
                  : 'Enable daily and habit notifications',
            ),
            value: settings.notificationsEnabled,
            activeColor: Colors.teal[600],
            secondary: const Icon(Icons.notifications),
            onChanged: (value) {
              settings.updateNotifications(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    settings.language == 'ro'
                        ? 'Notificările au fost ${value ? 'activate' : 'dezactivate'}!'
                        : 'Notifications have been ${value ? 'enabled' : 'disabled'}!',
                  ),
                ),
              );
            },
          ),
          SwitchListTile(
            title:
                Text(settings.language == 'ro' ? 'Mod întunecat' : 'Dark Mode'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Comută între tema luminoasă și întunecată'
                  : 'Switch between light and dark theme',
            ),
            value: settings.darkMode,
            activeColor: Colors.teal[600],
            secondary: const Icon(Icons.dark_mode),
            onChanged: (value) {
              settings.updateDarkMode(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    settings.language == 'ro'
                        ? 'Modul ${value ? 'întunecat' : 'luminos'} activat!'
                        : '${value ? 'Dark' : 'Light'} mode enabled!',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(settings.language == 'ro' ? 'Limbă' : 'Language'),
            subtitle: Text(settings.language == 'ro' ? 'Română' : 'English'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(settings.language == 'ro'
                      ? 'Alege limba'
                      : 'Choose Language'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Română'),
                        onTap: () {
                          settings.updateLanguage('ro');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () {
                          settings.updateLanguage('en');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(settings.language == 'ro'
                ? 'Exportă jurnalul'
                : 'Export Journal'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Salvează jurnalul ca fișier CSV'
                  : 'Save journal as CSV file',
            ),
            onTap: () => _exportJournal(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(settings.language == 'ro'
                ? 'Exportă obiceiurile'
                : 'Export Habits'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Salvează obiceiurile ca fișier CSV'
                  : 'Save habits as CSV file',
            ),
            onTap: () => _exportHabits(context),
          ),
          const Divider(height: 30),
          Text(
            settings.language == 'ro' ? 'Despre aplicație' : 'About App',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(
                settings.language == 'ro' ? 'Evaluează aplicația' : 'Rate App'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Lasă o recenzie pe Google Play'
                  : 'Leave a review on Google Play',
            ),
            onTap: () => _launchGooglePlay(context),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(settings.language == 'ro'
                ? 'Trimite feedback'
                : 'Send Feedback'),
            subtitle: Text(
              settings.language == 'ro'
                  ? 'Spune-ne părerea ta prin e-mail'
                  : 'Tell us your thoughts via email',
            ),
            onTap: () => _sendFeedback(context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(settings.language == 'ro'
                ? 'Despre Mood & Mind'
                : 'About Mood & Mind'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mood & Mind',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.favorite, color: Colors.teal),
                children: [
                  Text(
                    settings.language == 'ro'
                        ? 'Mood & Mind te ajută să-ți monitorizezi starea de spirit și să-ți formezi obiceiuri sănătoase. Construim această aplicație pentru a-ți susține bunăstarea mentală!'
                        : 'Mood & Mind helps you track your mood and build healthy habits. We’re building this app to support your mental well-being!',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  final Database database;
  const AchievementsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final achievements = Provider.of<AchievementsModel>(context).achievements;
    return Scaffold(
      appBar: AppBar(
        title: Text(settings.language == 'ro' ? 'Realizări' : 'Achievements'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.language == 'ro' ? 'Insignele tale' : 'Your Badges',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            achievements.isEmpty
                ? Center(
                    child: Text(
                      settings.language == 'ro'
                          ? 'Nicio insignă deblocată încă. Continuă să explorezi!'
                          : 'No badges unlocked yet. Keep exploring!',
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return Card(
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: (achievement['earned'] as int?) == 1
                                  ? 1.0
                                  : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.star,
                                size: 50,
                                color: (achievement['earned'] as int?) == 1
                                    ? Colors.teal[600]
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              achievement['name'] as String,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              achievement['description'] as String,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class StatisticsScreen extends StatefulWidget {
  final Database database;
  const StatisticsScreen({super.key, required this.database});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> journalEntries = [];
  Map<String, int> moodDistribution = {};
  double avgIntensity7Days = 0;
  double avgIntensity30Days = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final habitData = await widget.database.query('habits');
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final journalData = await widget.database.query(
        'journal',
        where: 'timestamp >= ?',
        whereArgs: [thirtyDaysAgo],
      );

      Map<String, int> tempMoodDist = {
        'Trist': 0,
        'Sad': 0,
        'Neutru': 0,
        'Neutral': 0,
        'Bine': 0,
        'Good': 0,
        'Fericit': 0,
        'Happy': 0,
        'Împlinit': 0,
        'Fulfilled': 0,
      };
      double intensitySum7 = 0;
      double intensitySum30 = 0;
      int intensityCount7 = 0;
      int intensityCount30 = 0;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      for (var entry in journalData) {
        final mood = entry['mood'] as String;
        tempMoodDist[mood] = (tempMoodDist[mood] ?? 0) + 1;
        final entryDate = DateTime.parse(entry['timestamp'] as String);
        if (entry['intensity'] != null) {
          final intensity = (entry['intensity'] as num).toDouble();
          intensitySum30 += intensity;
          intensityCount30++;
          if (entryDate.isAfter(sevenDaysAgo)) {
            intensitySum7 += intensity;
            intensityCount7++;
          }
        }
      }

      setState(() {
        habits = habitData;
        journalEntries = journalData;
        moodDistribution = tempMoodDist;
        avgIntensity7Days =
            intensityCount7 > 0 ? intensitySum7 / intensityCount7 : 0;
        avgIntensity30Days =
            intensityCount30 > 0 ? intensitySum30 / intensityCount30 : 0;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  int _calculateStreak(String habitName) {
    int streak = 0;
    DateTime currentDate = DateTime.now();
    while (true) {
      String dateStr = currentDate.toIso8601String().substring(0, 10);
      bool completed = habits.any(
        (habit) =>
            (habit['name'] as String) == habitName &&
            (habit['date'] as String) == dateStr &&
            habit['completed'] == 1,
      );
      if (!completed) break;
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _calculateCompletionPercentage(String habitName, int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    int completedDays = 0;
    for (int i = 0; i < days; i++) {
      String dateStr =
          startDate.add(Duration(days: i)).toIso8601String().substring(0, 10);
      if (habits.any(
        (habit) =>
            (habit['name'] as String) == habitName &&
            (habit['date'] as String) == dateStr &&
            habit['completed'] == 1,
      )) {
        completedDays++;
      }
    }
    return days > 0 ? (completedDays / days * 100) : 0;
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Trist':
      case 'Sad':
        return Colors.red[400]!;
      case 'Neutru':
      case 'Neutral':
        return Colors.yellow[600]!;
      case 'Bine':
      case 'Good':
        return Colors.green[300]!;
      case 'Fericit':
      case 'Happy':
        return Colors.green[600]!;
      case 'Împlinit':
      case 'Fulfilled':
        return Colors.blue[400]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final uniqueHabits = habits.map((h) => h['name'] as String).toSet().toList();
    final moods = settings.language == 'ro'
        ? ['Trist', 'Neutru', 'Bine', 'Fericit', 'Împlinit']
        : ['Sad', 'Neutral', 'Good', 'Happy', 'Fulfilled'];

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.language == 'ro' ? 'Statistici' : 'Statistics'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.language == 'ro' ? 'Progresul tău' : 'Your Progress',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro' ? 'Obiceiuri' : 'Habits',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            uniqueHabits.isEmpty
                ? Text(settings.language == 'ro' ? 'Niciun obicei înregistrat.' : 'No habits recorded.')
                : Column(
                    children: uniqueHabits.map((habitName) {
                      final streak = _calculateStreak(habitName);
                      final completion7Days = _calculateCompletionPercentage(habitName, 7);
                      final completion30Days = _calculateCompletionPercentage(habitName, 30);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habitName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                settings.language == 'ro'
                                    ? 'Streak: $streak zile'
                                    : 'Streak: $streak days',
                              ),
                              Text(
                                settings.language == 'ro'
                                    ? 'Completat: ${completion7Days.toStringAsFixed(1)}% în ultimele 7 zile'
                                    : 'Completed: ${completion7Days.toStringAsFixed(1)}% in the last 7 days',
                              ),
                              Text(
                                settings.language == 'ro'
                                    ? 'Completat: ${completion30Days.toStringAsFixed(1)}% în ultimele 30 de zile'
                                    : 'Completed: ${completion30Days.toStringAsFixed(1)}% in the last 30 days',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro'
                  ? 'Stări de spirit (ultimele 30 de zile)'
                  : 'Moods (last 30 days)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? Text(settings.language == 'ro' ? 'Nicio stare înregistrată.' : 'No moods recorded.')
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < moods.length) {
                                      return Text(
                                        moods[index],
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: moods.asMap().entries.map((e) {
                              int index = e.key;
                              String mood = e.value;
                              int count = moodDistribution[mood] ?? 0;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: count.toDouble(),
                                    color: _getMoodColor(mood),
                                    width: 12,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moods.map((mood) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: _getMoodColor(mood),
                              ),
                              const SizedBox(width: 4),
                              Text(mood),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            Text(
              settings.language == 'ro'
                  ? 'Intensitate stare (ultimele 30 de zile)'
                  : 'Mood Intensity (last 30 days)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              settings.language == 'ro'
                  ? 'Medie ultimele 7 zile: ${avgIntensity7Days.toStringAsFixed(1)}/10'
                  : 'Average last 7 days: ${avgIntensity7Days.toStringAsFixed(1)}/10',
            ),
            Text(
              settings.language == 'ro'
                  ? 'Medie ultimele 30 zile: ${avgIntensity30Days.toStringAsFixed(1)}/10'
                  : 'Average last 30 days: ${avgIntensity30Days.toStringAsFixed(1)}/10',
            ),
          ],
        ),
      ),
    );
  }
}

class MoodEmoji extends StatelessWidget {
  final String emoji;
  final String value;
  final String? selected;
  final Function(String) onTap;

  const MoodEmoji({
    super.key,
    required this.emoji,
    required this.value,
    this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
