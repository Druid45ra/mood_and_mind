import 'package:hive/hive.dart';
import 'package:mood_and_mind/src/features/onboarding/data/models/user_profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<UserProfileModel?> loadProfile();
  Future<void> saveProfile(UserProfileModel profile);
}

class HiveProfileLocalDataSource implements ProfileLocalDataSource {
  HiveProfileLocalDataSource(this._box);
  final Box _box;

  @override
  Future<UserProfileModel?> loadProfile() async {
    final raw = _box.get('profile');
    if (raw is Map) {
      return UserProfileModel.fromJson(raw);
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfileModel profile) => _box.put('profile', profile.toJson());
}
