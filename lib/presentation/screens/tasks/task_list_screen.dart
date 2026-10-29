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
  String _filterTag = '';
  String _filterAssignee = '';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(widget.projectId));
    final projectFullName = widget.projectId.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks: $projectFullName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync',
            onPressed: () async {
              final syncNotifier = ref.read(syncStateProvider.notifier);
              await syncNotifier.push(widget.projectId);
              if (mounted) {
                ref.invalidate(tasksProvider(widget.projectId));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterTag.isEmpty && _filterAssignee.isEmpty,
                  onSelected: (_) {
                    setState(() {
                      _filterTag = '';
                      _filterAssignee = '';
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Tags filter (would need to collect from tasks)
                // Assignee filter
              ],
            ),
          ),
          const Divider(height: 1),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((task) {
                  if (_filterTag.isNotEmpty &&
                      !task.tags.contains(_filterTag)) return false;
                  if (_filterAssignee.isNotEmpty &&
                      task.assignee != _filterAssignee) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No tasks yet'),
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
                        context.push('${task.number.toString().padLeft(3, '0')}');
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
              ref.invalidate(tasksProvider(widget.projectId));
              context.push('${newNumber.toString().padLeft(3, '0')}');
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
