import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';

class TrendSummaryCard extends StatelessWidget {
  const TrendSummaryCard({super.key, required this.entries});
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = entries.isNotEmpty ? entries.last : null;
    final first = entries.isNotEmpty ? entries.first : null;
    final delta = latest != null && first != null ? latest.weightKg - first.weightKg : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(latest == null ? 'Add weight entries to unlock trends.' : 'Latest entry: ${latest.weightKg.toStringAsFixed(1)} kg on ${DateFormat.yMMMd().format(latest.recordedAt)}'),
            const SizedBox(height: 8),
            Text('Overall change: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg'),
          ],
        ),
      ),
    );
  }
}
