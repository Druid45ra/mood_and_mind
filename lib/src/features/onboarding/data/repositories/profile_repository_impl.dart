import 'package:mood_and_mind/src/features/onboarding/data/datasources/profile_local_datasource.dart';
import 'package:mood_and_mind/src/features/onboarding/data/models/user_profile_model.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);
  final ProfileLocalDataSource _dataSource;

  @override
  Future<UserProfile?> loadProfile() => _dataSource.loadProfile();

  @override
  Future<void> saveProfile(UserProfile profile) => _dataSource.saveProfile(UserProfileModel.fromEntity(profile));
}
