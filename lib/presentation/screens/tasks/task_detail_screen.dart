import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/task/comment_thread.dart';
import '../../../presentation/widgets/task/comment_editor.dart';
import '../../../presentation/widgets/task/markdown_editor.dart';
import '../../../presentation/widgets/task/tag_chip.dart';
import '../../../presentation/providers/auth_providers.dart';

/// Screen for viewing and editing a single task.
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final int taskNumber;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskNumber,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _assigneeController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _assigneeController = TextEditingController();
    _descriptionController = TextEditingController();
    // Start in view mode
    _isEditing = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _assigneeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final repo = ref.read(taskRepositoryProvider);
      final title = _titleController.text.isEmpty
          ? 'Task ${widget.taskNumber}'
          : _titleController.text;

      print('💾 Saving task...');
      print('   projectId: ${widget.projectId}');
      print('   taskNumber: ${widget.taskNumber}');
      print('   title: $title');
      print('   description: ${_descriptionController.text.substring(0, _descriptionController.text.length.clamp(0, 100))}...');

      // Save everything in a single commit
      await repo.updateTask(
        widget.projectId,
        widget.taskNumber,
        description: _descriptionController.text,
        title: title,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
      );

      if (mounted) {
        // Refresh cache and wait for fresh data before exiting edit mode
        await ref.read(taskCacheProvider.notifier).refresh(widget.projectId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.taskSaved)),
          );
          setState(() => _isEditing = false);
        }
      }
    } catch (e, stack) {
      print('❌ Save error: $e');
      print('   Stack: $stack');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.saveFailed}: $e'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveAssignee() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateMetadata(
        widget.projectId,
        widget.taskNumber,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assigneeUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(tasksProvider(widget.projectId));

    return tasksAsync.when(
      data: (tasks) {
        final task = tasks.firstWhere(
          (t) => t.number == widget.taskNumber,
          orElse: () => Task(
            number: widget.taskNumber,
            title: '',
            description: '',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            projectId: widget.projectId,
          ),
        );

        _assigneeController.text = task.assignee ?? '';
        _titleController.text = task.title;
        _descriptionController.text = task.description;

        return Scaffold(
          appBar: AppBar(
            title: Text('Task #${task.number.toString().padLeft(3, '0')}'),
            actions: [
              if (_isEditing) ...[
                TextButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(l10n.save),
                  onPressed: _isSaving ? null : _saveAll,
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                  },
                  child: Text(l10n.cancel),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: l10n.edit,
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metadata section
                _buildMetadataCard(task, l10n),
                const SizedBox(height: 16),
                // Description
                _buildDescriptionCard(task, l10n),
                const SizedBox(height: 16),
                // Comments section
                _buildCommentsSection(task, l10n),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMetadataCard(dynamic task, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.metadata,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.title,
                hintText: l10n.titleHint,
                prefixIcon: const Icon(Icons.title),
              ),
              onSubmitted: (_) => _saveAll(),
            ),
            const SizedBox(height: 12),
            // Assignee
            TextField(
              controller: _assigneeController,
              decoration: InputDecoration(
                labelText: l10n.assignee,
                hintText: l10n.assigneeHint,
                prefixIcon: const Icon(Icons.person),
              ),
              onSubmitted: (_) => _saveAssignee(),
            ),
            const SizedBox(height: 12),
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...task.tags.map((tag) => TagChip(label: tag)),
                if (_isEditing)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Add tag logic
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addTag),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(dynamic task, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _descriptionController.text = task.description;
                    },
                    child: Text(l10n.cancel),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              SizedBox(
                height: 300,
                child: MarkdownEditor(
                  controller: _descriptionController,
                  placeholder: l10n.descriptionHint,
                ),
              )
            else
              SelectableText(
                task.description.isEmpty
                    ? l10n.noDescriptionYet
                    : task.description,
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(dynamic task, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.comments,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CommentThread(
          projectId: widget.projectId,
          taskNumber: widget.taskNumber,
        ),
        CommentEditor(
          projectId: widget.projectId,
          taskNumber: widget.taskNumber,
          onSent: () {
            ref.invalidate(tasksProvider(widget.projectId));
          },
        ),
      ],
    );
  }
}
