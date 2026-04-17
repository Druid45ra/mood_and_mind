import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mood_and_mind/src/core/constants/app_constants.dart';
import 'package:mood_and_mind/src/features/onboarding/data/datasources/profile_local_datasource.dart';
import 'package:mood_and_mind/src/features/onboarding/data/repositories/profile_repository_impl.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/usecases/load_user_profile_usecase.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/usecases/save_user_profile_usecase.dart';
import 'package:mood_and_mind/src/features/tracking/data/datasources/meal_local_datasource.dart';
import 'package:mood_and_mind/src/features/tracking/data/repositories/meal_repository_impl.dart';
import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/delete_meal_usecase.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/get_daily_meals_usecase.dart';
import 'package:mood_and_mind/src/features/tracking/domain/usecases/save_meal_usecase.dart';
import 'package:mood_and_mind/src/features/weight/data/datasources/weight_local_datasource.dart';
import 'package:mood_and_mind/src/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:mood_and_mind/src/features/weight/domain/repositories/weight_repository.dart';
import 'package:mood_and_mind/src/features/weight/domain/usecases/add_weight_entry_usecase.dart';
import 'package:mood_and_mind/src/features/weight/domain/usecases/watch_weight_history_usecase.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  await Hive.initFlutter();

  final profileBox = await Hive.openBox(AppConstants.userProfileBox);
  final mealsBox = await Hive.openBox(AppConstants.mealsBox);
  final weightsBox = await Hive.openBox(AppConstants.weightsBox);
  final settingsBox = await Hive.openBox(AppConstants.settingsBox);

  sl
    ..registerLazySingleton(() => profileBox)
    ..registerLazySingleton(() => mealsBox)
    ..registerLazySingleton(() => weightsBox)
    ..registerLazySingleton(() => settingsBox)
    ..registerLazySingleton<ProfileLocalDataSource>(() => HiveProfileLocalDataSource(sl()))
    ..registerLazySingleton<MealLocalDataSource>(() => HiveMealLocalDataSource(sl()))
    ..registerLazySingleton<WeightLocalDataSource>(() => HiveWeightLocalDataSource(sl()))
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()))
    ..registerLazySingleton<MealRepository>(() => MealRepositoryImpl(sl()))
    ..registerLazySingleton<WeightRepository>(() => WeightRepositoryImpl(sl()))
    ..registerLazySingleton(() => LoadUserProfileUseCase(sl()))
    ..registerLazySingleton(() => SaveUserProfileUseCase(sl()))
    ..registerLazySingleton(() => GetDailyMealsUseCase(sl()))
    ..registerLazySingleton(() => SaveMealUseCase(sl()))
    ..registerLazySingleton(() => DeleteMealUseCase(sl()))
    ..registerLazySingleton(() => AddWeightEntryUseCase(sl()))
    ..registerLazySingleton(() => WatchWeightHistoryUseCase(sl()));
}
