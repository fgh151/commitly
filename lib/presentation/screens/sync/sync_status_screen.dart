import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';

/// Screen showing sync status and history.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sync status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (syncState.isSyncing)
                      const CircularProgressIndicator()
                    else if (syncState.hasConflicts)
                      const Icon(Icons.warning, color: Colors.orange, size: 48)
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      syncState.isSyncing
                          ? syncState.message ?? 'Syncing...'
                          : syncState.hasConflicts
                              ? 'Conflicts detected'
                              : syncState.message ?? 'Up to date',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sync actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: syncState.isSyncing || selectedProjectId == null
                        ? null
                        : () async {
                            final notifier =
                                ref.read(syncStateProvider.notifier);
                            await notifier.pull(selectedProjectId);
                          },
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Pull'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: syncState.isSyncing || selectedProjectId == null
                        ? null
                        : () async {
                            final notifier =
                                ref.read(syncStateProvider.notifier);
                            await notifier.push(selectedProjectId);
                          },
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Push'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Conflict resolution
            if (syncState.hasConflicts) ...[
              const Text(
                'Conflicts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Conflict resolution UI will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
