import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_and_mind/src/features/analytics/presentation/widgets/trend_summary_card.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/macro_ring_card.dart';
import 'package:mood_and_mind/src/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/providers/tracking_controller.dart';
import 'package:mood_and_mind/src/features/weight/presentation/providers/weight_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingControllerProvider).valueOrNull;
    final meals = ref.watch(dailyMealsProvider).valueOrNull ?? <MealEntry>[];
    final calories = ref.watch(dailyCaloriesProvider);
    final remaining = ref.watch(remainingCaloriesProvider);
    final weights = ref.watch(weightHistoryProvider).valueOrNull ?? [];
    final protein = meals.fold<double>(0, (sum, item) => sum + item.protein);
    final carbs = meals.fold<double>(0, (sum, item) => sum + item.carbs);
    final fat = meals.fold<double>(0, (sum, item) => sum + item.fat);

    return DashboardShell(
      index: 0,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyMealsProvider);
          ref.invalidate(weightHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calorie Compass', style: Theme.of(context).textTheme.headlineSmall),
                      Text(profile == null ? 'Complete onboarding to personalize targets.' : 'Daily target: ${ref.watch(calorieTargetProvider)?.round() ?? 0} kcal'),
                    ],
                  ),
                ),
                FilledButton.tonal(onPressed: () => context.go('/onboarding'), child: Text(profile == null ? 'Start' : 'Edit profile')),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today summary'),
                    const SizedBox(height: 12),
                    Text('$calories kcal', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(remaining == null ? 'No target available yet.' : '${remaining.round()} kcal remaining'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: remaining == null || ref.watch(calorieTargetProvider) == 0 ? 0 : (calories / ref.watch(calorieTargetProvider)!).clamp(0, 1).toDouble()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [MacroRingCard(label: 'Protein', value: protein, color: Colors.blue), const SizedBox(width: 12), MacroRingCard(label: 'Carbs', value: carbs, color: Colors.orange), const SizedBox(width: 12), MacroRingCard(label: 'Fat', value: fat, color: Colors.purple)]),
            const SizedBox(height: 16),
            TrendSummaryCard(entries: weights),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recent meals', style: Theme.of(context).textTheme.titleLarge), TextButton(onPressed: () => context.go('/tracking'), child: const Text('View all'))]),
                    const SizedBox(height: 8),
                    if (meals.isEmpty)
                      const Text('No meals logged today.')
                    else
                      ...meals.take(4).map((meal) => ListTile(contentPadding: EdgeInsets.zero, title: Text(meal.name), subtitle: Text(meal.mealType.name), trailing: Text('${meal.calories} kcal'))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
