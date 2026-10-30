import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/git_service_config.dart';
import '../../../data/models/project.dart';
import '../../../presentation/providers/auth_providers.dart';

/// Screen for editing project settings.
class ProjectSettingsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectSettingsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current project name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projects = ref.read(projectCacheProvider).value;
      final project = projects?.firstWhere(
        (p) => p.fullName == widget.projectId,
        orElse: () => const Project(
          id: 0,
          name: '',
          owner: '',
          fullName: '',
          isPrivate: false,
          defaultBranch: 'main',
          serviceType: GitServiceType.github,
        ),
      );
      _nameController.text = project?.customName ?? project?.fullName ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authStateProvider);
      if (authState.gitService == null) {
        throw Exception('Not authenticated');
      }

      final gitService = authState.gitService!;

      // Read existing metadata.json
      String? existingContent;
      try {
        existingContent = await gitService.readFileContent(
          widget.projectId,
          'metadata.json',
        );
      } catch (_) {
        // File doesn't exist yet
      }

      Map<String, dynamic> metadata = {};
      if (existingContent != null && existingContent.isNotEmpty) {
        try {
          metadata = jsonDecode(existingContent) as Map<String, dynamic>;
        } catch (_) {
          // Invalid JSON, start fresh
        }
      }

      // Update name
      metadata['name'] = newName;

      // Write metadata.json to remote
      await gitService.writeFileContent(
        widget.projectId,
        'metadata.json',
        jsonEncode(metadata),
      );

      // Update local cache
      final prefs = ref.read(sharedPreferencesProvider);
      final cachedProjects = ref.read(projectCacheProvider).value ?? [];
      final updatedProjects = cachedProjects.map((p) {
        if (p.fullName == widget.projectId) {
          return p.copyWith(customName: newName);
        }
        return p;
      }).toList();

      // Save to cache
      try {
        prefs.setString(
          'projects_cache',
          jsonEncode({
            'ts': DateTime.now().toUtc().toIso8601String(),
            'type': GitServiceType.github.index,
            'projects': updatedProjects.map((p) => p.toJson()).toList(),
          }),
        );
      } catch (_) {}

      ref.invalidate(projectCacheProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.projectNameSaved),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.saveFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projectSettings),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveName,
              child: Text(l10n.save, style: const TextStyle(fontSize: 16)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.projectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.projectNameHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.projectNameDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
