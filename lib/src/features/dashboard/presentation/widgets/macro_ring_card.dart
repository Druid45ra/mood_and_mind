import 'package:flutter/material.dart';

class MacroRingCard extends StatelessWidget {
  const MacroRingCard({super.key, required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 10),
              CircleAvatar(radius: 28, backgroundColor: color.withOpacity(0.15), child: Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}
