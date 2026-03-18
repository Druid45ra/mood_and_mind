import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/delete_meal_usecase.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/get_daily_meals_usecase.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/save_meal_usecase.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final dailyMealsProvider = FutureProvider.autoDispose<List<MealEntry>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return sl<GetDailyMealsUseCase>()(date);
});

class TrackingController {
  Future<void> saveMeal(MealEntry meal, WidgetRef ref) async {
    await sl<SaveMealUseCase>()(meal);
    ref.invalidate(dailyMealsProvider);
  }

  Future<void> deleteMeal(String id, WidgetRef ref) async {
    await sl<DeleteMealUseCase>()(id);
    ref.invalidate(dailyMealsProvider);
  }
}

final trackingControllerProvider = Provider((ref) => TrackingController());
