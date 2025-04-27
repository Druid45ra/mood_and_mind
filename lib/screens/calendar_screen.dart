import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mood_and_mind/utils/logger.dart';

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
      AppLogger.e(
          'Error loading data for day: $e'); // TODO: Replace with a proper logging system (e.g., logger package)
    }
  }

  Future<Map<DateTime, List<dynamic>>> _getEventsForDays() async {
    Map<DateTime, List<dynamic>> events = {};
    // Încarcă doar datele din ultimele 365 de zile pentru a optimiza performanța
    final startDate = DateTime.now().subtract(const Duration(days: 365));
    final endDate =
        DateTime.now().add(const Duration(days: 1)); // Include astăzi

    // Interoghează jurnalul și obiceiurile direct din baza de date
    final journalEntries = await widget.database.query(
      'journal',
      where: 'timestamp >= ?',
      whereArgs: [startDate.toIso8601String()],
    );
    final habits = await widget.database.query(
      'habits',
      where: 'date >= ?',
      whereArgs: [startDate.toIso8601String().substring(0, 10)],
    );

    // Creează un set de date unice care au date
    Set<String> datesWithData = {};
    for (var entry in journalEntries) {
      final dateStr = (entry['timestamp'] as String).substring(0, 10);
      datesWithData.add(dateStr);
    }
    for (var habit in habits) {
      final dateStr = habit['date'] as String;
      datesWithData.add(dateStr);
    }

    // Construiește harta de evenimente
    for (var dateStr in datesWithData) {
      final date = DateTime.parse(dateStr);
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        events[DateTime(date.year, date.month, date.day)] = ['Data'];
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'), // Text fix în engleză
        centerTitle: true,
        backgroundColor: Colors.teal[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<DateTime, List<dynamic>>>(
              future: _getEventsForDays(),
              builder: (context, snapshot) {
                final events = snapshot.data ?? {};
                return TableCalendar(
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
                  eventLoader: (day) => events[day] ?? [],
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
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Details for ${_selectedDay?.toIso8601String().substring(0, 10) ?? 'selected day'}', // Text fix în engleză
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Moods', // Text fix în engleză
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _journalEntries.isEmpty
                ? const Text('No moods recorded.') // Text fix în engleză
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
                          (entry['note'] as String?)?.isNotEmpty ?? false
                              ? entry['note'] as String
                              : 'No note', // Text fix în engleză
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
            const Text(
              'Habits', // Text fix în engleză
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            _habits.isEmpty
                ? const Text('No habits recorded.') // Text fix în engleză
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
      case 'Sad':
        return '😢';
      case 'Neutral':
        return '😐';
      case 'Good':
        return '😊';
      case 'Happy':
        return '😃';
      case 'Fulfilled':
        return '🥰';
      default:
        return '😐';
    }
  }
}
