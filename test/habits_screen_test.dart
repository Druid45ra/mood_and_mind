import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mood_and_mind/services/database_service.dart';
import 'package:mood_and_mind/models/settings_model.dart'; // Adăugăm importul
import 'package:mood_and_mind/models/achievements_model.dart';
import 'package:mood_and_mind/screens/journal_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Save a journal entry in JournalScreen',
      (WidgetTester tester) async {
    // Arrange: Inițializăm baza de date și providerii
    final databaseHelper = DatabaseHelper();
    final database = await databaseHelper.database;

    // Curățăm tabela journal înainte de test
    await database.execute('DELETE FROM journal');

    // Creăm providerii
    final settingsModel = SettingsModel(database);
    final achievementsModel = AchievementsModel(database);

    // Construim widget-ul JournalScreen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsModel>.value(value: settingsModel),
          ChangeNotifierProvider<AchievementsModel>.value(
              value: achievementsModel),
        ],
        child: MaterialApp(
          home: JournalScreen(database: database),
        ),
      ),
    );

    // Așteptăm ca UI-ul să se construiască
    await tester.pumpAndSettle();

    // Act: Selectăm o stare de spirit (Happy)
    await tester.tap(find.text('😃')); // Emoji pentru "Happy"
    await tester.pump();

    // Act: Setăm o intensitate (ex. 7)
    await tester.drag(
        find.byType(Slider), const Offset(200, 0)); // Ajustăm slider-ul
    await tester.pump();

    // Act: Adăugăm o notă
    await tester.enterText(find.byType(TextField), 'Feeling awesome!');
    await tester.pump();

    // Act: Apăsăm butonul "Save"
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(
        const Duration(seconds: 1)); // Așteptăm ca SnackBar-ul să apară

    // Assert: Verificăm că intrarea a fost salvată în baza de date
    final entries = await databaseHelper.getJournalEntries();
    expect(entries.length, 1);
    expect(entries[0].mood, 'Happy');
    expect(entries[0].note, 'Feeling awesome!');
    expect(entries[0].intensity,
        greaterThanOrEqualTo(5)); // Flexibilitate pentru slider

    // Assert: Verificăm că SnackBar-ul de succes este afișat
    expect(find.text('Mood entry saved successfully!'), findsOneWidget);

    // Curățăm
    await database.close();
  });
}
