import '../models/task.dart';
import '../models/comment.dart';
import '../services/git_service.dart';

/// Repository for task operations.
class TaskRepository {
  final GitService _gitService;

  TaskRepository(this._gitService);

  /// Fetch all tasks for a project
  Future<List<Task>> fetchTasks(String projectId) async {
    final numbers = await _gitService.listTaskNumbers(projectId);
    final tasks = <Task>[];

    for (final number in numbers) {
      try {
        final metadata = await _gitService.readMetadata(projectId, number);
        final description = await _gitService.readDescription(projectId, number);

        tasks.add(Task(
          number: number,
          description: description,
          assignee: metadata['assignee'] as String?,
          tags: List<String>.from(metadata['tags'] as List? ?? []),
          createdAt: DateTime.tryParse(metadata['created'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(metadata['updated'] as String? ?? '') ??
              DateTime.now(),
          projectId: projectId,
        ));
      } catch (e) {
        // Skip tasks that can't be loaded
        continue;
      }
    }

    return tasks;
  }

  /// Fetch a single task by number
  Future<Task> fetchTask(String projectId, int taskNumber) async {
    final metadata = await _gitService.readMetadata(projectId, taskNumber);
    final description = await _gitService.readDescription(projectId, taskNumber);

    return Task(
      number: taskNumber,
      description: description,
      assignee: metadata['assignee'] as String?,
      tags: List<String>.from(metadata['tags'] as List? ?? []),
      createdAt: DateTime.tryParse(metadata['created'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(metadata['updated'] as String? ?? '') ??
          DateTime.now(),
      projectId: projectId,
    );
  }

  /// Create a new task (returns the new task number)
  Future<int> createTask(String projectId) async {
    final nextNumber = await _gitService.getNextTaskNumber(projectId);

    // Create description.md
    await _gitService.writeDescription(
      projectId,
      nextNumber,
      '# Task $nextNumber\n\n',
    );

    // Create metadata.json
    final now = DateTime.now().toUtc().toIso8601String();
    await _gitService.writeMetadata(projectId, nextNumber, {
      'id': nextNumber,
      'assignee': null,
      'tags': <String>[],
      'created': now,
      'updated': now,
    });

    return nextNumber;
  }

  /// Update task description
  Future<void> updateDescription(
    String projectId,
    int taskNumber,
    String description,
  ) async {
    await _gitService.writeDescription(projectId, taskNumber, description);

    // Update metadata timestamp
    final metadata = await _gitService.readMetadata(projectId, taskNumber);
    metadata['updated'] = DateTime.now().toUtc().toIso8601String();
    await _gitService.writeMetadata(projectId, taskNumber, metadata);
  }

  /// Update task metadata (assignee, tags)
  Future<void> updateMetadata(
    String projectId,
    int taskNumber, {
    String? assignee,
    List<String>? tags,
  }) async {
    final metadata = await _gitService.readMetadata(projectId, taskNumber);
    if (assignee != null) metadata['assignee'] = assignee;
    if (tags != null) metadata['tags'] = tags;
    metadata['updated'] = DateTime.now().toUtc().toIso8601String();
    await _gitService.writeMetadata(projectId, taskNumber, metadata);
  }

  /// Add a comment to a task
  Future<void> addComment(
    String projectId,
    int taskNumber,
    String content,
    String author,
  ) async {
    await _gitService.addComment(projectId, taskNumber, content, author);
  }

  /// Delete a comment from a task
  Future<void> deleteComment(
    String projectId,
    int taskNumber,
    int commentNumber,
  ) async {
    await _gitService.deleteComment(projectId, taskNumber, commentNumber);
  }

  /// List comments for a task
  Future<List<Comment>> listComments(String projectId, int taskNumber) async {
    final commentsData = await _gitService.listComments(projectId, taskNumber);
    final comments = <Comment>[];

    for (final data in commentsData) {
      final number = data['number'] as int? ?? 0;
      final path = data['path'] as String? ?? '';

      // Extract comment number from filename
      final commentNum = int.tryParse(
        path.split('/').lastOrNull?.replaceAll('.md', '') ?? '',
      ) ??
          number;

      comments.add(Comment(
        number: commentNum,
        content: '', // Will be fetched separately
        author: '',
        createdAt: DateTime.now(),
        taskNumber: taskNumber.toString().padLeft(3, '0'),
      ));
    }

    return comments;
  }
}
