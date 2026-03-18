import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';

class SaveMealUseCase {
  const SaveMealUseCase(this._repository);
  final MealRepository _repository;

  Future<void> call(MealEntry meal) => _repository.saveMeal(meal);
}
