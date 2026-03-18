import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';

class MealEntryModel extends MealEntry {
  const MealEntryModel({
    required super.id,
    required super.name,
    required super.calories,
    required super.protein,
    required super.carbs,
    required super.fat,
    required super.mealType,
    required super.loggedAt,
  });

  factory MealEntryModel.fromJson(Map<dynamic, dynamic> json) => MealEntryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        calories: json['calories'] as int,
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        mealType: MealType.values.byName(json['mealType'] as String),
        loggedAt: DateTime.parse(json['loggedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'mealType': mealType.name,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory MealEntryModel.fromEntity(MealEntry entity) => MealEntryModel(
        id: entity.id,
        name: entity.name,
        calories: entity.calories,
        protein: entity.protein,
        carbs: entity.carbs,
        fat: entity.fat,
        mealType: entity.mealType,
        loggedAt: entity.loggedAt,
      );
}
