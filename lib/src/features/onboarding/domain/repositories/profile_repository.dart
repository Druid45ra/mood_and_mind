import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> loadProfile();
  Future<void> saveProfile(UserProfile profile);
}
