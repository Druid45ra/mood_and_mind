import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';

class CalorieCalculator {
  static double bmr(UserProfile profile) {
    final base = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
    return profile.sex == Sex.male ? base + 5 : base - 161;
  }

  static double maintenanceCalories(UserProfile profile) => bmr(profile) * profile.activityLevel.multiplier;

  static double dailyTarget(UserProfile profile) {
    final maintenance = maintenanceCalories(profile);
    switch (profile.goal) {
      case Goal.lose:
        return maintenance - 450;
      case Goal.gain:
        return maintenance + 300;
      case Goal.maintain:
        return maintenance;
    }
  }
}
