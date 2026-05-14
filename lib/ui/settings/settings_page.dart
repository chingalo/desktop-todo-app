import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../state/auth_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Map<String, dynamic> _todoToJson(Todo t) => {
    'id': t.id,
    'userId': t.userId,
    'title': t.title,
    'description': t.description,
    'completed': t.completed,
    'createdAt': t.createdAt.toIso8601String(),
    'updatedAt': t.updatedAt.toIso8601String(),
  };

  static Future<void> _showTodosJsonPreview(
    BuildContext context,
    String json,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Todos (JSON preview)'),
          content: SizedBox(
            width: 560,
            height: 360,
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.userId;
    final db = context.read<AppDatabase>();
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
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Backup todos (JSON preview)'),
          subtitle: const Text(
            'Exports all your todos as JSON and opens a preview you can copy.',
          ),
          enabled: userId != null,
          onTap: userId == null
              ? null
              : () async {
                  try {
                    final list = await db.todosForUser(userId);
                    final payload = {
                      'exportedAt': DateTime.now().toIso8601String(),
                      'userId': userId,
                      'todos': list.map(_todoToJson).toList(),
                    };
                    final json = const JsonEncoder.withIndent(
                      '  ',
                    ).convert(payload);
                    if (!context.mounted) return;
                    await _showTodosJsonPreview(context, json);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not export todos: $e')),
                    );
                  }
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
