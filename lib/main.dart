import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await initDatabase();
  runApp(MoodAndMindApp(database: database));
}

Future<Database> initDatabase() async {
  return openDatabase(
    join(await getDatabasesPath(), 'mood_mind.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE journal(id INTEGER PRIMARY KEY, mood TEXT, note TEXT, timestamp TEXT)',
      );
    },
    version: 1,
  );
}

class MoodAndMindApp extends StatelessWidget {
  final Database database;
  const MoodAndMindApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood & Mind',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: JournalScreen(database: database),
    );
  }
}

class JournalScreen extends StatefulWidget {
  final Database database;
  const JournalScreen({Key? key, required this.database}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? selectedMood;
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> journalEntries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final List<Map<String, dynamic>> entries =
        await widget.database.query('journal');
    setState(() {
      journalEntries = entries.reversed.toList();
    });
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null || _noteController.text.isEmpty) return;
    await widget.database.insert(
        'journal',
        {
          'mood': selectedMood,
          'note': _noteController.text,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    _noteController.clear();
    setState(() => selectedMood = null);
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Jurnal zilnic - ${DateTime.now().day}/${DateTime.now().month}'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.teal[300],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal[50]!, Colors.amber[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cum te simți azi?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800])),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MoodEmoji(
                      emoji: '😢',
                      value: 'Trist',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val)),
                  MoodEmoji(
                      emoji: '😐',
                      value: 'Neutru',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val)),
                  MoodEmoji(
                      emoji: '😊',
                      value: 'Bine',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val)),
                  MoodEmoji(
                      emoji: '😃',
                      value: 'Fericit',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val)),
                  MoodEmoji(
                      emoji: '🥰',
                      value: 'Împlinit',
                      selected: selectedMood,
                      onTap: (val) => setState(() => selectedMood = val)),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _noteController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Notă scurtă',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 20),
                    SizedBox(width: 8),
                    Text('Salvează', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MeditationScreen())),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.self_improvement, size: 20),
                    SizedBox(width: 8),
                    Text('Meditează', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: journalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = journalEntries[index];
                    return ListTile(
                      leading: Text(entry['mood']),
                      title: Text(entry['note']),
                      subtitle: Text(entry['timestamp'].substring(0, 10)),
                    );
                  },
                ),
              ),
            ],
          ),
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
  const MoodEmoji(
      {Key? key,
      required this.emoji,
      required this.value,
      this.selected,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey[200] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: TextStyle(fontSize: 30)),
      ),
    );
  }
}

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({Key? key}) : super(key: key);

  @override
  _MeditationScreenState createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  int _seconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _startTimer(int minutes) {
    setState(() {
      _seconds = minutes * 60;
      _isRunning = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        _playEndSound();
        _redirectToJournal();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _seconds = 0;
    });
  }

  Future<void> _playEndSound() async {
    await _audioPlayer.play(AssetSource('bell.wav'));
  }

  void _redirectToJournal() {
    Navigator.pop(this.context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meditație'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (!_isRunning) ...[
              ElevatedButton(
                onPressed: () => _startTimer(5),
                child: Text('5 minute'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _startTimer(10),
                child: Text('10 minute'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _startTimer(15),
                child: Text('15 minute'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _stopTimer,
                child: Text('Oprește'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
