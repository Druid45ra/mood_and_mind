import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/macro_ring_card.dart';

void main() {
  testWidgets('macro ring card displays label and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MacroRingCard(label: 'Protein', value: 42, color: Colors.blue),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });
}
