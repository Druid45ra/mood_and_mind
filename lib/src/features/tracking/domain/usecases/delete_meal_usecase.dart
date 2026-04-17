import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';

class DeleteMealUseCase {
  const DeleteMealUseCase(this._repository);
  final MealRepository _repository;

  Future<void> call(String id) => _repository.deleteMeal(id);
}
