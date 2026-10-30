import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../../presentation/widgets/common/task_card.dart';

/// Screen listing all projects (repositories).
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Disconnect',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).disconnect();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No projects found', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Add a repository to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final project = projects[index];
              return TaskCard(
                number: project.id,
                title: project.fullName,
                subtitle: project.description ?? 'No description',
                assignee: null,
                tags: [],
                onTap: () {
                  // URL-encode the project name to handle '/' in 'owner/repo'
                  final encodedProjectId = Uri.encodeComponent(project.fullName);
                  ref.read(selectedProjectIdProvider.notifier).state = project.fullName;
                  context.go('/projects/$encodedProjectId/tasks');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/projects/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }
}
