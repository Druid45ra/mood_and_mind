import 'package:mood_and_mind/src/features/tracking/data/datasources/meal_local_datasource.dart';
import 'package:mood_and_mind/src/features/tracking/data/models/meal_entry_model.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  const MealRepositoryImpl(this._dataSource);
  final MealLocalDataSource _dataSource;

  @override
  Future<void> deleteMeal(String id) => _dataSource.deleteMeal(id);

  @override
  Future<MealEntry?> getMealById(String id) => _dataSource.getMealById(id);

  @override
  Future<List<MealEntry>> getMealsForDate(DateTime date) => _dataSource.getMealsForDate(date);

  @override
  Future<void> saveMeal(MealEntry meal) => _dataSource.saveMeal(MealEntryModel.fromEntity(meal));
}
