import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('JournalScreen Tests', () {
    late Database db;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE journal_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mood TEXT NOT NULL,
          intensity INTEGER NOT NULL,
          note TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      databaseHelper = DatabaseHelper(testDatabase: db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Save a journal entry in JournalScreen',
        (WidgetTester tester) async {
      // Inițializăm aplicația cu JournalScreen
      await tester.pumpWidget(
        MaterialApp(
          home: JournalScreen(databaseHelper: databaseHelper),
        ),
      );

      await tester.pumpAndSettle();

      // Căutăm DropdownButton și selectăm opțiunea "Good 😊"
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget,
          reason: 'DropdownButton should be present');

      // Tap pe dropdown pentru a afișa opțiunile
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Selectăm opțiunea "Good 😊"
      final goodOptionFinder = find
          .text('Good 😊')
          .last; // Folosim .last pentru a găsi opțiunea din meniu
      expect(goodOptionFinder, findsOneWidget,
          reason: 'Good 😊 option should be visible');
      await tester.tap(goodOptionFinder);
      await tester.pumpAndSettle();

      // Ajustăm intensitatea cu Slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget, reason: 'Slider should be present');
      await tester.drag(sliderFinder,
          const Offset(50, 0)); // Simulăm glisarea pentru a seta intensitatea
      await tester.pumpAndSettle();

      // Adăugăm o notă
      final textFieldFinder = find.byType(TextFormField);
      expect(textFieldFinder, findsOneWidget,
          reason: 'TextFormField should be present');
      await tester.enterText(textFieldFinder, 'Test Journal Entry');
      await tester.pumpAndSettle();

      // Salvăm intrarea
      final saveButtonFinder = find.byType(ElevatedButton);
      expect(saveButtonFinder, findsOneWidget,
          reason: 'Save button should be present');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Verificăm dacă intrarea a fost salvată corect
      expect(find.text('Good 😊 (5/10)'), findsOneWidget,
          reason: 'Saved entry should display "Good 😊 (5/10)"');
      expect(find.text('Test Journal Entry'), findsOneWidget,
          reason: 'Saved note should display "Test Journal Entry"');
    });
  });
}
