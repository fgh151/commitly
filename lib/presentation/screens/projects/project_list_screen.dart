import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../../presentation/widgets/common/task_card.dart';

/// Screen listing all projects (repositories).
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh project cache on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectCacheProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(projectCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projectsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () async {
              await ref.read(projectCacheProvider.notifier).forceRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.disconnect,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noProjectsFound, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addRepository,
                    style: const TextStyle(color: Colors.grey),
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
              final displayName = project.customName ?? project.fullName;
              return TaskCard(
                number: project.id,
                title: displayName,
                subtitle: project.description ?? '',
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
        label: Text(l10n.addProject),
      ),
    );
  }
}
