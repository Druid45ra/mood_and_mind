import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';

class WeightChartCard extends StatelessWidget {
  const WeightChartCard({super.key, required this.entries});
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight evolution', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No data yet')
            else
              ...entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat.yMMMd().format(entry.recordedAt)), Text('${entry.weightKg.toStringAsFixed(1)} kg')]),
                  )),
          ],
        ),
      ),
    );
  }
}
