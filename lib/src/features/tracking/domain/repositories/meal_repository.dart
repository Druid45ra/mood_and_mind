import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';

abstract class MealRepository {
  Future<List<MealEntry>> getMealsForDate(DateTime date);
  Future<MealEntry?> getMealById(String id);
  Future<void> saveMeal(MealEntry meal);
  Future<void> deleteMeal(String id);
}
