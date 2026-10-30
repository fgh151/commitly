import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../../presentation/widgets/common/task_card.dart';

/// Screen listing all tasks for a project.
class TaskListScreen extends ConsumerStatefulWidget {
  final String projectId;

  const TaskListScreen({super.key, required this.projectId});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _filterNumber = TextEditingController();
  final TextEditingController _filterTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load tasks from cache (or fetch if not cached)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskCacheProvider.notifier).load(widget.projectId);
    });
  }

  @override
  void dispose() {
    _filterNumber.dispose();
    _filterTitle.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _filterNumber.clear();
      _filterTitle.clear();
    });
  }

  bool _hasActiveFilters() {
    return _filterNumber.text.trim().isNotEmpty ||
        _filterTitle.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskCacheProvider)[widget.projectId] ?? const AsyncValue.loading();
    final projectFullName = widget.projectId.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks: $projectFullName'),
        actions: [
          if (_hasActiveFilters())
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () async {
              final syncNotifier = ref.read(syncStateProvider.notifier);
              await syncNotifier.push(widget.projectId);
              if (mounted) {
                await ref.read(taskCacheProvider.notifier).refresh(widget.projectId);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search fields
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Filter by number
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _filterNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '# Number',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter by title (ILIKE)
                Expanded(
                  child: TextField(
                    controller: _filterTitle,
                    decoration: const InputDecoration(
                      hintText: 'Search by title...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((task) {
                  // Filter by number (exact match)
                  if (_filterNumber.text.trim().isNotEmpty) {
                    final filterNum = int.tryParse(_filterNumber.text.trim());
                    if (filterNum == null || task.number != filterNum) return false;
                  }
                  // Filter by title (case-insensitive substring match, like ILIKE)
                  if (_filterTitle.text.trim().isNotEmpty) {
                    final filterTitle = _filterTitle.text.trim().toLowerCase();
                    if (!task.title.toLowerCase().contains(filterTitle)) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasActiveFilters()
                              ? Icons.filter_list_off
                              : Icons.assignment,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters()
                              ? 'No tasks match filters'
                              : 'No tasks yet',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_hasActiveFilters())
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return TaskCard(
                      number: task.number,
                      title: task.title,
                      subtitle: task.description.length > 80
                          ? '${task.description.substring(0, 80)}...'
                          : task.description,
                      assignee: task.assignee,
                      tags: task.tags,
                      onTap: () {
                        final encoded = Uri.encodeComponent(task.number.toString().padLeft(3, '0'));
                        context.pushNamed('task-detail', pathParameters: {
                          'projectId': widget.projectId,
                          'taskNumber': encoded,
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final repo = ref.read(taskRepositoryProvider);
            final newNumber = await repo.createTask(widget.projectId);
            if (mounted) {
              // Refresh cache after creating a new task
              await ref.read(taskCacheProvider.notifier).refresh(widget.projectId);
              final encoded = Uri.encodeComponent(newNumber.toString().padLeft(3, '0'));
              context.pushNamed('task-detail', pathParameters: {
                'projectId': widget.projectId,
                'taskNumber': encoded,
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to create task: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
