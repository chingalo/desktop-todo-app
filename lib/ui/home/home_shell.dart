import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProgramPilot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.verified_user_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
