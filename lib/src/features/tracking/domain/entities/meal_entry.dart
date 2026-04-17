enum MealType { breakfast, lunch, dinner, snack }

class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.loggedAt,
  });

  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final MealType mealType;
  final DateTime loggedAt;

  MealEntry copyWith({String? id, String? name, int? calories, double? protein, double? carbs, double? fat, MealType? mealType, DateTime? loggedAt}) {
    return MealEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
