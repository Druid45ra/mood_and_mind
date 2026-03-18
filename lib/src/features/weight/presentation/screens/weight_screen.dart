import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';
import 'package:mood_and_mind/src/features/weight/presentation/providers/weight_controller.dart';
import 'package:mood_and_mind/src/features/weight/presentation/widgets/weight_chart_card.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(weightHistoryProvider);
    return DashboardShell(
      index: 2,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Weight tracking', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true))), const SizedBox(width: 12), FilledButton(onPressed: () async {
            final value = double.tryParse(_controller.text);
            if (value == null) return;
            await ref.read(weightControllerProvider).addEntry(WeightEntry(id: const Uuid().v4(), weightKg: value, recordedAt: DateTime.now()), ref);
            _controller.clear();
          }, child: const Text('Add'))]),
          const SizedBox(height: 16),
          historyAsync.when(data: (entries) => WeightChartCard(entries: entries), error: (error, stackTrace) => Text(error.toString()), loading: () => const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
