import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:mood_and_mind/utils/logger.dart';

class CalendarScreen extends StatefulWidget {
  final Future<Database> databaseFuture;

  const CalendarScreen({super.key, required this.databaseFuture});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    AppLogger.i('Starting to load calendar events...');
    setState(() {
      isLoading = true;
    });

    try {
      final database = await widget.databaseFuture;
      final journalEntries = await database.query('journal_entries');
      final Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var entry in journalEntries) {
        final date = DateTime.parse(entry['timestamp'] as String).toLocal();
        final dateKey = DateTime(date.year, date.month, date.day);
        if (events[dateKey] == null) {
          events[dateKey] = [];
        }
        events[dateKey]!.add(entry);
      }

      setState(() {
        _events = events;
        isLoading = false;
      });
      AppLogger.i(
          'Loaded ${journalEntries.length} journal entries for calendar.');
    } catch (e) {
      AppLogger.e('Error loading calendar events: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _getEventsForDay(_selectedDay!).isEmpty
                      ? const Center(
                          child: Text('No journal entries for this day.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final event =
                                _getEventsForDay(_selectedDay!)[index];
                            return Card(
                              child: ListTile(
                                leading:
                                    const Icon(Icons.book, color: Colors.blue),
                                title: Text(
                                    '${event['mood']} (${event['intensity']}/10)'),
                                subtitle: Text(event['timestamp'].toString()),
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
