import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/app/router.dart';
import 'package:mood_and_mind/src/core/theme/app_theme.dart';

class CalorieTrackerApp extends ConsumerWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Calorie Compass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
