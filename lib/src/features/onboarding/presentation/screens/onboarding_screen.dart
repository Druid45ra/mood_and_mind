import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_and_mind/src/features/onboarding/domain/entities/user_profile.dart';
import 'package:mood_and_mind/src/features/onboarding/presentation/providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  Sex _sex = Sex.male;
  Goal _goal = Goal.maintain;
  ActivityLevel _activityLevel = ActivityLevel.moderate;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingControllerProvider).valueOrNull;
    _ageController = TextEditingController(text: profile?.age.toString() ?? '30');
    _weightController = TextEditingController(text: profile?.weightKg.toStringAsFixed(1) ?? '70.0');
    _heightController = TextEditingController(text: profile?.heightCm.toStringAsFixed(0) ?? '170');
    _sex = profile?.sex ?? Sex.male;
    _goal = profile?.goal ?? Goal.maintain;
    _activityLevel = profile?.activityLevel ?? ActivityLevel.moderate;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile setup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<Sex>(segments: const [ButtonSegment(value: Sex.male, label: Text('Male')), ButtonSegment(value: Sex.female, label: Text('Female'))], selected: {_sex}, onSelectionChanged: (value) => setState(() => _sex = value.first)),
            const SizedBox(height: 16),
            TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number, validator: _required),
            const SizedBox(height: 16),
            TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required),
            const SizedBox(height: 16),
            TextFormField(controller: _heightController, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required),
            const SizedBox(height: 16),
            DropdownButtonFormField<Goal>(value: _goal, items: Goal.values.map((goal) => DropdownMenuItem(value: goal, child: Text(goal.name))).toList(), onChanged: (value) => setState(() => _goal = value ?? _goal), decoration: const InputDecoration(labelText: 'Goal')),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityLevel>(value: _activityLevel, items: ActivityLevel.values.map((level) => DropdownMenuItem(value: level, child: Text(level.label))).toList(), onChanged: (value) => setState(() => _activityLevel = value ?? _activityLevel), decoration: const InputDecoration(labelText: 'Activity level')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                final profile = UserProfile(
                  sex: _sex,
                  age: int.parse(_ageController.text),
                  weightKg: double.parse(_weightController.text),
                  heightCm: double.parse(_heightController.text),
                  goal: _goal,
                  activityLevel: _activityLevel,
                );
                await ref.read(onboardingControllerProvider.notifier).save(profile);
                if (context.mounted) {
                  context.go('/dashboard');
                }
              },
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
