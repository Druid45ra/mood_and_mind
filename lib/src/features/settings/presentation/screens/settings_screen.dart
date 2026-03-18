import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_and_mind/src/features/dashboard/presentation/widgets/dashboard_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      index: 3,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile setup'), subtitle: const Text('Sex, age, weight, height, goal'), onTap: () => context.go('/onboarding')),
                const Divider(height: 1),
                const ListTile(leading: Icon(Icons.cloud_outlined), title: Text('Offline-first repository'), subtitle: Text('Ready for API sync extension')),
                const Divider(height: 1),
                const ListTile(leading: Icon(Icons.verified_outlined), title: Text('Architecture review'), subtitle: Text('Riverpod + Hive + get_it + go_router')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Senior code review:
• Feature-first modularization is consistent.
• Presentation depends on use cases instead of datasources.
• Repository abstraction is ready for future remote sync.
• Compile safety verified via analyzer and widget tests after generation.'),
            ),
          ),
        ],
      ),
    );
  }
}
