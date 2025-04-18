// Conținutul din main_part1.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// Clasa HabitContext pentru gestionarea obiceiurilor
class HabitContext extends ChangeNotifier {
  List<Map<String, dynamic>> _habits = [];

  List<Map<String, dynamic>> get habits => _habits;

  void toggleHabit(int id, bool completed) {
    _habits = _habits.map((habit) {
      if (habit['id'] == id) {
        return {...habit, 'completed': completed ? 1 : 0};
      }
      return habit;
    }).toList();
    notifyListeners();
  }

  void addHabit(String name) {
    _habits.add({
      'id': _habits.length + 1,
      'name': name,
      'completed': 0,
      'notification_time': null,
    });
    notifyListeners();
  }
}

// Clasa AchievementsModel pentru gestionarea realizărilor
class AchievementsModel extends ChangeNotifier {
  List<Map<String, dynamic>> _achievements = [];

  List<Map<String, dynamic>> get achievements => _achievements;

  void unlockAchievement(
      BuildContext context, String name, String description) {
    _achievements.add({
      'name': name,
      'description': description,
      'unlocked': true,
    });
    notifyListeners();
    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.achievementUnlocked(name)),
      ),
    );
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitContext()),
        ChangeNotifierProvider(create: (_) => AchievementsModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood & Mind',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.welcomeMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: 'ro',
              items: [
                DropdownMenuItem(
                  value: 'ro',
                  child: Text(localizations.chooseLanguage),
                ),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                // Logica pentru schimbarea limbii va fi implementată mai târziu
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: Text(localizations.start),
            ),
          ],
        ),
      ),
    );
  }
}

// Conținutul din main_part2.dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    JournalScreen(),
    HabitsScreen(),
    CalendarScreen(),
    StatisticsScreen(),
    SettingsScreen(),
    AchievementsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: localizations.dailyJournal,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.check_circle),
            label: localizations.dailyHabits,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: localizations.calendar,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: localizations.statistics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: localizations.settings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.star),
            label: localizations.achievements,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _selectedMood;
  double _intensity = 5.0;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMood() {
    final localizations = AppLocalizations.of(context)!;
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseChooseMood)),
      );
      return;
    }
    // Logica pentru salvarea stării (de exemplu, în baza de date)
    Provider.of<AchievementsModel>(context, listen: false).unlockAchievement(
      context,
      localizations.firstStep,
      localizations.firstStepDescription,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.moodSaved)),
    );
    _noteController.clear();
    setState(() {
      _selectedMood = null;
      _intensity = 5.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.howDoYouFeel,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _selectedMood,
            hint: Text(localizations.pleaseChooseMood),
            items: [
              localizations.sad,
              localizations.neutral,
              localizations.good,
              localizations.happy,
              localizations.fulfilled,
            ].map((String mood) {
              return DropdownMenuItem<String>(
                value: mood,
                child: Text(mood),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMood = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Text('${localizations.intensity}: ${_intensity.toInt()}'),
          Slider(
            value: _intensity,
            min: 1,
            max: 10,
            divisions: 9,
            label: _intensity.toInt().toString(),
            onChanged: (value) {
              setState(() {
                _intensity = value;
              });
            },
          ),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: localizations.noteOptional,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saveMood,
                child: Text(localizations.save),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  _noteController.clear();
                  setState(() {
                    _selectedMood = null;
                    _intensity = 5.0;
                  });
                },
                child: Text(localizations.cancel),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            localizations.recentEntries,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Logica pentru afișarea intrărilor recente va fi adăugată ulterior
          const Text('Intrări recente placeholder'),
        ],
      ),
    );
  }
}

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _habitController = TextEditingController();

  @override
  void dispose() {
    _habitController.dispose();
    super.dispose();
  }

  void _addHabit() {
    final localizations = AppLocalizations.of(context)!;
    if (_habitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.enterHabitName)),
      );
      return;
    }
    Provider.of<HabitContext>(context, listen: false)
        .addHabit(_habitController.text);
    _habitController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.habitAdded)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final habits = Provider.of<HabitContext>(context).habits;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _habitController,
            decoration: InputDecoration(
              labelText: localizations.addHabit,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addHabit,
            child: Text(localizations.addHabit),
          ),
          const SizedBox(height: 20),
          Text(
            localizations.yourHabitsToday,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          habits.isEmpty
              ? Text(localizations.noHabits)
              : Expanded(
                  child: ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return ListTile(
                        title: Text(habit['name']),
                        subtitle: Text(
                          habit['notification_time'] != null
                              ? '${localizations.notification}: ${habit['notification_time']}'
                              : localizations.noNotification,
                        ),
                        trailing: Checkbox(
                          value: habit['completed'] == 1,
                          onChanged: (value) {
                            Provider.of<HabitContext>(context, listen: false)
                                .toggleHabit(habit['id'], value ?? false);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Text(localizations.calendar),
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Text(localizations.statistics),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.customizeApp,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text(localizations.notifications),
            subtitle: Text(localizations.notificationsSubtitle),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Logica pentru notificări va fi adăugată ulterior
              },
            ),
          ),
          ListTile(
            title: Text(localizations.darkMode),
            subtitle: Text(localizations.darkModeSubtitle),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Logica pentru mod întunecat va fi adăugată ulterior
              },
            ),
          ),
          ListTile(
            title: Text(localizations.language),
            subtitle: Text(localizations.chooseLanguage),
            onTap: () {
              // Logica pentru schimbarea limbii va fi adăugată ulterior
            },
          ),
        ],
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final achievements = Provider.of<AchievementsModel>(context).achievements;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.yourBadges,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          achievements.isEmpty
              ? Text(localizations.noBadges)
              : Expanded(
                  child: ListView.builder(
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return ListTile(
                        title: Text(achievement['name']),
                        subtitle: Text(achievement['description']),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
