import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/core/utils/calorie_calculator.dart';
import 'package:mood_and_mind/src/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/providers/tracking_controller.dart';

final dailyCaloriesProvider = Provider<int>((ref) {
  final meals = ref.watch(dailyMealsProvider).valueOrNull ?? <MealEntry>[];
  return meals.fold<int>(0, (sum, meal) => sum + meal.calories);
});

final calorieTargetProvider = Provider<double?>((ref) {
  final profile = ref.watch(onboardingControllerProvider).valueOrNull;
  return profile == null ? null : CalorieCalculator.dailyTarget(profile);
});

final remainingCaloriesProvider = Provider<double?>((ref) {
  final target = ref.watch(calorieTargetProvider);
  if (target == null) return null;
  return target - ref.watch(dailyCaloriesProvider);
});
