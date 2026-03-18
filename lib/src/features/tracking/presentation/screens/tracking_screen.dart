import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/providers/tracking_controller.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/widgets/meal_list_tile.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final mealsAsync = ref.watch(dailyMealsProvider);
    final controller = ref.watch(trackingControllerProvider);

    return DashboardShell(
      index: 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: Text(DateFormat.yMMMMd().format(selectedDate), style: Theme.of(context).textTheme.headlineSmall)),
                IconButton(onPressed: () => context.go('/tracking/editor'), icon: const Icon(Icons.add_circle_outline)),
                IconButton(onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: selectedDate);
                  if (picked != null) {
                    ref.read(selectedDateProvider.notifier).state = picked;
                  }
                }, icon: const Icon(Icons.calendar_month)),
              ],
            ),
          ),
          Expanded(
            child: mealsAsync.when(
              data: (meals) => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...meals.map((meal) => MealListTile(meal: meal, onTap: () => context.go('/tracking/editor?id=${meal.id}'), onDelete: () => controller.deleteMeal(meal.id, ref))),
                  const SizedBox(height: 100),
                ],
              ),
              error: (error, stackTrace) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
