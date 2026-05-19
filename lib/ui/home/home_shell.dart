import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../state/auth_controller.dart';
import '../programs/programs_page.dart';
import '../settings/settings_page.dart';
import '../todos/todos_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.userId;
    final db = context.watch<AppDatabase>();
    final destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.checklist_outlined),
        selectedIcon: Icon(Icons.checklist),
        label: Text('Todos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.dataset_linked_outlined),
        selectedIcon: Icon(Icons.dataset_linked),
        label: Text('Programs'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
    final body = switch (_index) {
      0 => const TodosPage(),
      1 => const ProgramsPage(),
      _ => const SettingsPage(),
    };
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProgramPilot'),
        actions: [
          if (userId != null)
            StreamBuilder(
              stream: db.watchUser(userId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final label = user.name.trim().isEmpty
                    ? user.email.split('@').first
                    : user.name.trim();
                final initial = label.isNotEmpty
                    ? label.characters.first.toUpperCase()
                    : '?';
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 18,
                        child: Text(
                          initial,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.verified_user_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: _index == 0 ? const TodosFab() : null,
    );
  }
}
