import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../state/auth_controller.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final userId = context.watch<AuthController>().userId;
    if (userId == null) {
      return const Center(child: Text('Sign in to manage todos.'));
    }
    return StreamBuilder<List<Todo>>(
      stream: db.watchTodosForUser(userId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return Center(
            child: Text(
              'No todos yet.\nTap + to add your first item.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_context, _index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final todo = items[index];
            return _TodoTile(todo: todo, userId: userId);
          },
        );
      },
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.todo, required this.userId});

  final Todo todo;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppDatabase>();
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMd().add_jm().format(todo.updatedAt);
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (v) {
            if (v == null) return;
            db.updateTodo(
              todo.copyWith(completed: v, updatedAt: DateTime.now()),
            );
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          [
            if (todo.description.isNotEmpty) todo.description,
            if (todo.dhisProgramId != null)
              'DHIS program: ${todo.dhisProgramId}',
            'Updated $date',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(context, db, todo, userId),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete todo?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await db.deleteTodo(todo.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openEditor(
  BuildContext context,
  AppDatabase db,
  Todo? existing,
  int userId,
) async {
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final bodyCtrl = TextEditingController(text: existing?.description ?? '');
  final programCtrl = TextEditingController(
    text: existing?.dhisProgramId ?? '',
  );
  final created = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(existing == null ? 'New todo' : 'Edit todo'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: programCtrl,
                decoration: const InputDecoration(
                  labelText: 'DHIS program id (optional)',
                  hintText: 'Links this todo to a cached program id',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  if (created != true || !context.mounted) return;
  final title = titleCtrl.text.trim();
  if (title.isEmpty) return;
  final program = programCtrl.text.trim();
  if (existing == null) {
    await db.insertTodo(
      userId: userId,
      title: title,
      description: bodyCtrl.text.trim(),
      dhisProgramId: program.isEmpty ? null : program,
    );
  } else {
    await db.updateTodo(
      existing.copyWith(
        title: title,
        description: bodyCtrl.text.trim(),
        dhisProgramId: Value(program.isEmpty ? null : program),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class TodosFab extends StatelessWidget {
  const TodosFab({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthController>().userId;
    if (userId == null) return const SizedBox.shrink();
    final db = context.read<AppDatabase>();
    return FloatingActionButton.extended(
      onPressed: () => _openEditor(context, db, null, userId),
      icon: const Icon(Icons.add),
      label: const Text('New todo'),
    );
  }
}
