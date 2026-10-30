import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
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

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _assigneeController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController();
    _assigneeController = TextEditingController();
    _descriptionController = TextEditingController();
    // Start in view mode
    _isEditing = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _assigneeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
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
            const SnackBar(content: Text('Task saved')),
          );
          setState(() => _isEditing = false);
        }
      }
    } catch (e, stack) {
      print('❌ Save error: $e');
      print('   Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _saveAssignee() async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateMetadata(
        widget.projectId,
        widget.taskNumber,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignee updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Description'),
                Tab(text: 'Comments'),
              ],
            ),
            actions: [
              if (_tabController.index == 0) ...[
                if (_isEditing) ...[
                  TextButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                    onPressed: _isSaving ? null : _saveAll,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                    },
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit',
                  ),
                ],
              ],
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDescriptionTab(task),
              _buildCommentsTab(task),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildDescriptionTab(dynamic task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Metadata section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Metadata',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Task title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    onSubmitted: (_) => _saveAll(),
                  ),
                  const SizedBox(height: 12),
                  // Assignee
                  TextField(
                    controller: _assigneeController,
                    decoration: const InputDecoration(
                      labelText: 'Assignee',
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person),
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
                          label: const Text('Add Tag'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Description',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_isEditing)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _descriptionController.text = task.description;
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    SizedBox(
                      height: 300,
                      child: MarkdownEditor(
                        controller: _descriptionController,
                        placeholder: 'Enter description (Markdown supported)',
                      ),
                    )
                  else
                    SelectableText(
                      task.description.isEmpty
                          ? 'No description yet'
                          : task.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Attachments section placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No attachments yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // File picker integration
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Upload File'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(dynamic task) {
    return Column(
      children: [
        Expanded(
          child: CommentThread(
            projectId: widget.projectId,
            taskNumber: widget.taskNumber,
          ),
        ),
        const Divider(height: 1),
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
