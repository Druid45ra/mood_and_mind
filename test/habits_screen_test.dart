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
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          completed INTEGER NOT NULL,
          date TEXT NOT NULL,
          notification_time TEXT
        )
      ''');
      databaseHelper = DatabaseHelper(testDatabase: db);
      habitsModel = HabitsModel(databaseHelper);
      await habitsModel.initialize();
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
            child: HabitsScreen(databaseHelper: databaseHelper),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Adăugăm un obicei nou
      final textFieldFinder = find.byType(TextFormField);
      expect(textFieldFinder, findsOneWidget,
          reason: 'TextFormField should be present');
      await tester.enterText(textFieldFinder, 'Test Habit');
      await tester.pumpAndSettle();

      // Apăsăm butonul "Add"
      final addButtonFinder = find.byType(ElevatedButton);
      expect(addButtonFinder, findsOneWidget,
          reason: 'Add button should be present');
      await tester.tap(addButtonFinder);
      await tester.pumpAndSettle(
          const Duration(seconds: 1)); // Așteptăm operațiunile asincrone

      // Verificăm dacă obiceiul a fost adăugat
      expect(find.text('Test Habit'), findsOneWidget,
          reason: 'Test Habit should be displayed in the list');
    });
  });
}
