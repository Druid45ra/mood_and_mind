import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_and_mind/models/journal_entry.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('JournalScreen Tests', () {
    late Database db;
    late JournalModel journalModel;
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
      journalModel = JournalModel(databaseHelper);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Save a journal entry in JournalScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => journalModel),
            ],
            child: const JournalScreen(),
          ),
        ),
      );

      await tester.tap(find.text('😊')); // Select "Good" mood
      await tester.enterText(find.byType(TextField), 'Test Journal Entry');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Good (5/10)'), findsOneWidget);
      expect(find.text('Test Journal Entry'), findsOneWidget);
    });
  });
}
