import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:mood_and_mind/src/core/extensions/date_extensions.dart';
import 'package:mood_and_mind/src/features/tracking/data/models/meal_entry_model.dart';

abstract class MealLocalDataSource {
  Future<List<MealEntryModel>> getMealsForDate(DateTime date);
  Future<MealEntryModel?> getMealById(String id);
  Future<void> saveMeal(MealEntryModel meal);
  Future<void> deleteMeal(String id);
}

class HiveMealLocalDataSource implements MealLocalDataSource {
  HiveMealLocalDataSource(this._box);
  final Box _box;

  List<Map<dynamic, dynamic>> _allRaw() => (_box.get('meals', defaultValue: <Map<dynamic, dynamic>>[]) as List).cast<Map<dynamic, dynamic>>();

  @override
  Future<void> deleteMeal(String id) async {
    final meals = _allRaw()..removeWhere((item) => item['id'] == id);
    await _box.put('meals', meals);
  }

  @override
  Future<MealEntryModel?> getMealById(String id) async {
    final raw = _allRaw().firstWhereOrNull((item) => item['id'] == id);
    return raw == null ? null : MealEntryModel.fromJson(raw);
  }

  @override
  Future<List<MealEntryModel>> getMealsForDate(DateTime date) async {
    final targetKey = date.dateOnly.localKey;
    return _allRaw().map(MealEntryModel.fromJson).where((meal) => meal.loggedAt.dateOnly.localKey == targetKey).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  @override
  Future<void> saveMeal(MealEntryModel meal) async {
    final meals = _allRaw();
    final index = meals.indexWhere((item) => item['id'] == meal.id);
    if (index >= 0) {
      meals[index] = meal.toJson();
    } else {
      meals.add(meal.toJson());
    }
    await _box.put('meals', meals);
  }
}
