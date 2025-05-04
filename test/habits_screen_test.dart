import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_and_mind/models/habit.dart';
import 'package:mood_and_mind/screens/habits_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HabitsScreen Tests', () {
    late Database db;
    late DatabaseHelper databaseHelper;
    late HabitsModel habitsModel;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE habits (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          completed INTEGER NOT NULL,
          date TEXT NOT NULL,
          notification_time TEXT
        )
      ''');
      databaseHelper = DatabaseHelper(testDatabase: db);
      habitsModel = HabitsModel(databaseHelper);
      await habitsModel._initialize(); // Așteptăm inițializarea
    });

    tearDown(() async {
      habitsModel.dispose();
      await db.close();
    });

    testWidgets('Add a habit in HabitsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: habitsModel),
            ],
            child: const HabitsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Test Habit');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test Habit'), findsOneWidget);
    });
  });
}
