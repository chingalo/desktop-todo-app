import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../services/dhis_client.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  final _url = TextEditingController(text: DhisClient.defaultProgramsUrl);
  final _user = TextEditingController(text: DhisClient.defaultUsername);
  final _pass = TextEditingController(text: DhisClient.defaultPassword);
  final _client = DhisClient();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final programs = await _client.fetchPrograms(
        programsUrl: _url.text.trim(),
        username: _user.text.trim(),
        password: _pass.text,
      );
      final db = context.read<AppDatabase>();
      await db.replaceCachedPrograms(
        programs
            .map(
              (p) => CachedProgramsCompanion.insert(
                id: p.id,
                displayName: p.displayName,
                shortName: Value(p.shortName),
              ),
            )
            .toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cached ${programs.length} programs for offline use.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DHIS2 programs',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulls programs over the network with Basic auth, then stores them locally so you can browse the last snapshot while offline.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Programs JSON URL',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _user,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
            label: Text(_loading ? 'Fetching…' : 'Fetch & cache offline'),
          ),
          const SizedBox(height: 20),
          Text(
            'Cached programs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<CachedProgram>>(
              stream: db.watchCachedPrograms(),
              builder: (context, snap) {
                final rows = snap.data ?? [];
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'Nothing cached yet.\nConnect once, then work offline.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = rows[i];
                    return ListTile(
                      title: Text(p.displayName),
                      subtitle: Text(p.shortName ?? p.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
