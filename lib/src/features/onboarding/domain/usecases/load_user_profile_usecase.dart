import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/repositories/profile_repository.dart';

class LoadUserProfileUseCase {
  const LoadUserProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<UserProfile?> call() => _repository.loadProfile();
}
