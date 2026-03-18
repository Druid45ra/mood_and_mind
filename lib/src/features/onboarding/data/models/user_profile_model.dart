import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.sex,
    required super.age,
    required super.weightKg,
    required super.heightCm,
    required super.goal,
    required super.activityLevel,
  });

  factory UserProfileModel.fromJson(Map<dynamic, dynamic> json) {
    return UserProfileModel(
      sex: Sex.values.byName(json['sex'] as String),
      age: json['age'] as int,
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      goal: Goal.values.byName(json['goal'] as String),
      activityLevel: ActivityLevel.values.byName(json['activityLevel'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'goal': goal.name,
        'activityLevel': activityLevel.name,
      };

  factory UserProfileModel.fromEntity(UserProfile profile) => UserProfileModel(
        sex: profile.sex,
        age: profile.age,
        weightKg: profile.weightKg,
        heightCm: profile.heightCm,
        goal: profile.goal,
        activityLevel: profile.activityLevel,
      );
}
