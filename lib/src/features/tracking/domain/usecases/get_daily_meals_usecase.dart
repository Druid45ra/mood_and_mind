import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';

class GetDailyMealsUseCase {
  const GetDailyMealsUseCase(this._repository);
  final MealRepository _repository;

  Future<List<MealEntry>> call(DateTime date) => _repository.getMealsForDate(date);
}
