import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          subtitle: const Text('Clears this device session only'),
          onTap: () async {
            await auth.signOut();
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Local database'),
          subtitle: const Text(
            'Todos and cached DHIS2 programs are stored in an SQLite file under Application Support (Drift).',
          ),
        ),
      ],
    );
  }
}
