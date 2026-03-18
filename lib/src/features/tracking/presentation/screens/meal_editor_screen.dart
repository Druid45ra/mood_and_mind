import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';
import 'package:mood_and_mind/src/features/tracking/domain/repositories/meal_repository.dart';
import 'package:mood_and_mind/src/features/tracking/presentation/providers/tracking_controller.dart';

class MealEditorScreen extends ConsumerStatefulWidget {
  const MealEditorScreen({super.key, this.mealId});
  final String? mealId;

  @override
  ConsumerState<MealEditorScreen> createState() => _MealEditorScreenState();
}

class _MealEditorScreenState extends ConsumerState<MealEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController(text: '450');
  final _proteinController = TextEditingController(text: '30');
  final _carbsController = TextEditingController(text: '40');
  final _fatController = TextEditingController(text: '12');
  MealType _mealType = MealType.lunch;
  MealEntry? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.mealId == null) return;
    final meal = await sl<MealRepository>().getMealById(widget.mealId!);
    if (meal == null || !mounted) return;
    setState(() {
      _existing = meal;
      _nameController.text = meal.name;
      _caloriesController.text = meal.calories.toString();
      _proteinController.text = meal.protein.toStringAsFixed(0);
      _carbsController.text = meal.carbs.toStringAsFixed(0);
      _fatController.text = meal.fat.toStringAsFixed(0);
      _mealType = meal.mealType;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mealId == null ? 'Add meal' : 'Edit meal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Meal name'), validator: _required),
            const SizedBox(height: 16),
            DropdownButtonFormField<MealType>(value: _mealType, items: MealType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(), onChanged: (value) => setState(() => _mealType = value ?? _mealType), decoration: const InputDecoration(labelText: 'Meal type')),
            const SizedBox(height: 16),
            TextFormField(controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number, validator: _required),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: TextFormField(controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _fatController, decoration: const InputDecoration(labelText: 'Fat'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _required))]),
            const SizedBox(height: 24),
            FilledButton(onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final meal = MealEntry(
                id: _existing?.id ?? const Uuid().v4(),
                name: _nameController.text.trim(),
                calories: int.parse(_caloriesController.text),
                protein: double.parse(_proteinController.text),
                carbs: double.parse(_carbsController.text),
                fat: double.parse(_fatController.text),
                mealType: _mealType,
                loggedAt: ref.read(selectedDateProvider),
              );
              await ref.read(trackingControllerProvider).saveMeal(meal, ref);
              if (context.mounted) context.pop();
            }, child: const Text('Save meal')),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
