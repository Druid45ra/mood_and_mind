import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mood_and_mind/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mood_and_mind/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/screens/meal_editor_screen.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:mood_and_mind/src/features/weight/presentation/screens/weight_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/tracking', builder: (context, state) => const TrackingScreen()),
      GoRoute(path: '/tracking/editor', builder: (context, state) => MealEditorScreen(mealId: state.uri.queryParameters['id'])),
      GoRoute(path: '/weight', builder: (context, state) => const WeightScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
