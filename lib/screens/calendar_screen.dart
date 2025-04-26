import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/settings_model.dart';

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
      bool hasData = _journalEntries.any((entry) =>
              (entry['timestamp'] as String?)?.startsWith(dateStr) ?? false) ||
          _habits.any((habit) => (habit['date'] as String?) == dateStr);
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
                          (entry['note'] as String?)?.isNotEmpty ?? false
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
