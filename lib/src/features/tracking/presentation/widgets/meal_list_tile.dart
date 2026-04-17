import 'package:flutter/material.dart';
import 'package:mood_and_mind/src/features/tracking/domain/entities/meal_entry.dart';

class MealListTile extends StatelessWidget {
  const MealListTile({super.key, required this.meal, this.onTap, this.onDelete});
  final MealEntry meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(meal.name),
        subtitle: Text('${meal.mealType.name} • P ${meal.protein.toStringAsFixed(0)} / C ${meal.carbs.toStringAsFixed(0)} / F ${meal.fat.toStringAsFixed(0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${meal.calories} kcal'),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
      ),
    );
  }
}
