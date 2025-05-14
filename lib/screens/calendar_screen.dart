import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mood_and_mind/models/journal_model.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  final Database database;
  const CalendarScreen({super.key, required this.database});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    // Ascultăm schimbările din JournalModel
    Provider.of<JournalModel>(context, listen: false).addListener(_loadEvents);
  }

  @override
  void dispose() {
    Provider.of<JournalModel>(context, listen: false)
        .removeListener(_loadEvents);
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final events = await widget.database.query(
      'journal_entries',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
    );

    setState(() {
      _events = {};
      for (var event in events) {
        final date = DateTime.parse(event['timestamp'] as String);
        final day = DateTime(date.year, date.month, date.day);
        if (_events[day] == null) {
          _events[day] = [];
        }
        _events[day]!.add(event);
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Calendar'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadEvents();
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(fontSize: 16),
                weekendTextStyle: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<JournalModel>(
                builder: (context, journalModel, child) {
                  final events = _getEventsForDay(_selectedDay!);
                  return events.isEmpty
                      ? const Center(child: Text('No entries for this day.'))
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.mood,
                                    color: Colors.orange),
                                title: Text(
                                  '${event['mood']} (${event['intensity']}/10)',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                subtitle: Text(
                                  event['note']?.isNotEmpty ?? false
                                      ? event['note']
                                      : 'No note',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
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
