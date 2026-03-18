import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/usecases/load_user_profile_usecase.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/usecases/save_user_profile_usecase.dart';

final onboardingControllerProvider = AutoDisposeAsyncNotifierProvider<OnboardingController, UserProfile?>(OnboardingController.new);

class OnboardingController extends AutoDisposeAsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => sl<LoadUserProfileUseCase>()();

  Future<void> save(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await sl<SaveUserProfileUseCase>()(profile);
      return profile;
    });
  }
}
