enum Sex { male, female }
enum Goal { lose, maintain, gain }
enum ActivityLevel { sedentary, light, moderate, active }

extension ActivityLevelX on ActivityLevel {
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
    }
  }

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Light';
      case ActivityLevel.moderate:
        return 'Moderate';
      case ActivityLevel.active:
        return 'Active';
    }
  }
}

class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.activityLevel,
  });

  final Sex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final Goal goal;
  final ActivityLevel activityLevel;

  UserProfile copyWith({Sex? sex, int? age, double? weightKg, double? heightCm, Goal? goal, ActivityLevel? activityLevel}) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}
