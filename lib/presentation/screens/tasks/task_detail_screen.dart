import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/widgets/task/comment_thread.dart';
import '../../../presentation/widgets/task/comment_editor.dart';
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
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _descriptionController = TextEditingController();
    _assigneeController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _saveDescription() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateDescription(
        widget.projectId,
        widget.taskNumber,
        _descriptionController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description saved')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
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
          orElse: () => throw Exception('Task not found'),
        );

        _descriptionController.text = task.description;
        _assigneeController.text = task.assignee ?? '';

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
                  IconButton(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    onPressed: _isSaving ? null : _saveDescription,
                    tooltip: 'Save',
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
                    TextField(
                      controller: _descriptionController,
                      maxLines: null,
                      minLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Enter description (Markdown supported)',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    SelectableText(
                      task.description,
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
