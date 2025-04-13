import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await initDatabase();
  final settingsModel = SettingsModel(database);
  await settingsModel.loadSettings();
  await initializeNotifications(database, settingsModel);
  runApp(
    ChangeNotifierProvider(
      create: (_) => settingsModel,
      child: MoodAndMindApp(database: database),
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
        'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, completed INTEGER, date TEXT)',
      );
      await db.execute(
        'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER)',
      );
      await db.insert('settings', {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
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
            'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER)',
          );
          await db.insert('settings', {
            'id': 1,
            'notifications_enabled': 1,
            'dark_mode': 0,
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
      print('Database upgraded successfully.');
    },
    version: 4,
  );
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications(
  Database database,
  SettingsModel settingsModel,
) async {
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
        'CREATE TABLE settings(id INTEGER PRIMARY KEY AUTOINCREMENT, notifications_enabled INTEGER, dark_mode INTEGER)',
      );
      await database.insert('settings', {
        'id': 1,
        'notifications_enabled': 1,
        'dark_mode': 0,
      });
    }

    if (settingsModel.notificationsEnabled) {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        'Cum te simți astăzi?',
        'Deschide Mood & Mind și înregistrează-ți starea!',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification',
            'Notificări zilnice',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('Notifications scheduled successfully.');
    }
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

class SettingsModel with ChangeNotifier {
  final Database _database;
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  SettingsModel(this._database);

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;

  Future<void> loadSettings() async {
    try {
      final settings = await _database.query(
        'settings',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (settings.isNotEmpty) {
        _notificationsEnabled = settings[0]['notifications_enabled'] == 1;
        _darkMode = settings[0]['dark_mode'] == 1;
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
          'Cum te simți astăzi?',
          'Deschide Mood & Mind și înregistrează-ți starea!',
          RepeatInterval.daily,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_notification',
              'Notificări zilnice',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        await flutterLocalNotificationsPlugin.cancel(0);
      }
    } catch (e) {
      print('Error updating notifications: $e');
    }
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
}

class MoodAndMindApp extends StatelessWidget {
  final Database database;
  const MoodAndMindApp({Key? key, required this.database}) : super(key: key);

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
            appBarTheme: AppBarTheme(backgroundColor: Colors.teal[700]),
            useMaterial3: true,
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomeScreen(database: database),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Database database;
  const HomeScreen({Key? key, required this.database}) : super(key: key);

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
      SettingsScreen(database: widget.database),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Jurnal'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Obiceiuri',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setări'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[600],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  final Database database;
  const JournalScreen({Key? key, required this.database}) : super(key: key);

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
    } catch (e) {
      print('Error loading entries: $e');
    }
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te rog alege o stare de spirit!')),
      );
      return;
    }
    try {
      await widget.database.insert('journal', {
        'mood': selectedMood,
        'intensity': intensity,
        'note': _noteController.text,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _noteController.clear();
      setState(() {
        selectedMood = null;
        intensity = 5;
      });
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starea de spirit a fost salvată!')),
      );
    } catch (e) {
      print('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eroare la salvarea stării. Încearcă din nou.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal zilnic'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cum te simți astăzi?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodEmoji(
                  emoji: '😢',
                  value: 'Trist',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😐',
                  value: 'Neutru',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😊',
                  value: 'Bine',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '😃',
                  value: 'Fericit',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
                MoodEmoji(
                  emoji: '🥰',
                  value: 'Împlinit',
                  selected: selectedMood,
                  onTap: (val) => setState(() => selectedMood = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Intensitate: $intensity'),
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
              decoration: const InputDecoration(
                labelText: 'Notiță (opțional)',
                border: OutlineInputBorder(),
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
              child: const Text('Salvează'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Intrări recente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            journalEntries.isEmpty
                ? const Text('Nicio intrare încă. Adaugă una!')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: journalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = journalEntries[index];
                    return ListTile(
                      leading: Text(
                        _getEmojiForMood(entry['mood']),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        '${entry['mood']} (${entry['intensity'] ?? 'N/A'}/10)',
                      ),
                      subtitle: Text(
                        entry['note'].isNotEmpty
                            ? entry['note']
                            : 'Fără notiță',
                      ),
                      trailing: Text(entry['timestamp'].substring(0, 10)),
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
        return '😢';
      case 'Neutru':
        return '😐';
      case 'Bine':
        return '😊';
      case 'Fericit':
        return '😃';
      case 'Împlinit':
        return '🥰';
      default:
        return '😐';
    }
  }
}

class HabitsScreen extends StatefulWidget {
  final Database database;
  const HabitsScreen({Key? key, required this.database}) : super(key: key);

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
      final List<Map<String, dynamic>> loadedHabits = await widget.database
          .query('habits', where: 'date = ?', whereArgs: [today]);
      setState(() {
        habits = loadedHabits;
      });
    } catch (e) {
      print('Error loading habits: $e');
    }
  }

  Future<void> _addHabit() async {
    final name = _habitController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu un nume pentru obicei!')),
      );
      return;
    }
    try {
      await widget.database.insert('habits', {
        'name': name,
        'completed': 0,
        'date': today,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      _habitController.clear();
      await _loadHabits();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Obiceiul a fost adăugat!')));
    } catch (e) {
      print('Error adding habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la adăugarea obiceiului: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiceiuri zilnice'),
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
                    decoration: const InputDecoration(
                      labelText: 'Adaugă un obicei',
                      border: OutlineInputBorder(),
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
            const Text(
              'Obiceiurile tale de astăzi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  habits.isEmpty
                      ? const Center(
                        child: Text('Niciun obicei adăugat. Începe acum!'),
                      )
                      : ListView.builder(
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return CheckboxListTile(
                            title: Text(habit['name']),
                            value: habit['completed'] == 1,
                            activeColor: Colors.teal[600],
                            onChanged:
                                (value) =>
                                    _toggleHabit(habit['id'], value ?? false),
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
  const CalendarScreen({Key? key, required this.database}) : super(key: key);

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
    for (
      DateTime day = start;
      day.isBefore(end);
      day = day.add(const Duration(days: 1))
    ) {
      String dateStr = day.toIso8601String().substring(0, 10);
      bool hasData =
          _journalEntries.any(
            (entry) => entry['timestamp'].startsWith(dateStr),
          ) ||
          _habits.any((habit) => habit['date'] == dateStr);
      if (hasData) {
        events[DateTime(day.year, day.month, day.day)] = ['Data'];
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
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
              'Detalii pentru ${_selectedDay?.toIso8601String().substring(0, 10) ?? 'ziua selectată'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Stări de spirit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _journalEntries.isEmpty
                ? const Text('Nicio stare înregistrată.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _journalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _journalEntries[index];
                    return ListTile(
                      leading: Text(
                        _getEmojiForMood(entry['mood']),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        '${entry['mood']} (${entry['intensity']}/10)',
                      ),
                      subtitle: Text(
                        entry['note'].isNotEmpty
                            ? entry['note']
                            : 'Fără notiță',
                      ),
                    );
                  },
                ),
            const SizedBox(height: 20),
            const Text(
              'Obiceiuri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _habits.isEmpty
                ? const Text('Niciun obicei înregistrat.')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return ListTile(
                      title: Text(habit['name']),
                      trailing: Icon(
                        habit['completed'] == 1
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color:
                            habit['completed'] == 1
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
        return '😢';
      case 'Neutru':
        return '😐';
      case 'Bine':
        return '😊';
      case 'Fericit':
        return '😃';
      case 'Împlinit':
        return '🥰';
      default:
        return '😐';
    }
  }
}

class SettingsScreen extends StatelessWidget {
  final Database database;
  const SettingsScreen({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări'),
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalizează aplicația',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Notificări zilnice'),
              subtitle: const Text(
                'Primește un reminder zilnic pentru a-ți înregistra starea.',
              ),
              value: settings.notificationsEnabled,
              activeColor: Colors.teal[600],
              onChanged: (value) {
                settings.updateNotifications(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notificările au fost ${value ? 'activate' : 'dezactivate'}!',
                    ),
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Mod întunecat'),
              subtitle: const Text(
                'Comută între tema luminoasă și întunecată.',
              ),
              value: settings.darkMode,
              activeColor: Colors.teal[600],
              onChanged: (value) {
                settings.updateDarkMode(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Modul ${value ? 'întunecat' : 'luminos'} activat!',
                    ),
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

class MoodEmoji extends StatelessWidget {
  final String emoji;
  final String value;
  final String? selected;
  final Function(String) onTap;

  const MoodEmoji({
    Key? key,
    required this.emoji,
    required this.value,
    this.selected,
    required this.onTap,
  }) : super(key: key);

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
        child: Text(emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}
