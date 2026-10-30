import 'package:commitly/data/models/git_service_config.dart';
import 'package:commitly/data/models/task.dart';
import 'package:commitly/data/models/comment.dart';
import 'package:commitly/data/repositories/task_repository.dart';
import 'package:commitly/data/services/git_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock classes
class _MockGitService extends Mock implements GitService {}

void main() {
  late _MockGitService gitService;
  late TaskRepository repository;

  const projectId = 'owner/repo';

  setUp(() {
    gitService = _MockGitService();
    repository = TaskRepository(gitService);
  });

  group('TaskRepository.fetchTasks', () {
    test('should fetch all tasks for a project', () async {
      when(() => gitService.listTaskNumbers(projectId))
          .thenAnswer((_) async => [1, 2, 3]);

      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Task 1',
        'assignee': 'alice',
        'tags': ['feature'],
        'created': '2025-01-01T00:00:00Z',
        'updated': '2025-01-02T00:00:00Z',
      });
      when(
        () => gitService.readDescription(projectId, 1),
      ).thenAnswer((_) async => 'Description 1');

      when(
        () => gitService.readMetadata(projectId, 2),
      ).thenAnswer((_) async => {
        'title': 'Task 2',
        'assignee': null,
        'tags': <String>[],
        'created': '2025-01-03T00:00:00Z',
        'updated': '2025-01-04T00:00:00Z',
      });
      when(
        () => gitService.readDescription(projectId, 2),
      ).thenAnswer((_) async => 'Description 2');

      when(
        () => gitService.readMetadata(projectId, 3),
      ).thenAnswer((_) async => {
        'title': 'Task 3',
        'assignee': 'bob',
        'tags': ['bug', 'urgent'],
        'created': '2025-01-05T00:00:00Z',
        'updated': '2025-01-06T00:00:00Z',
      });
      when(
        () => gitService.readDescription(projectId, 3),
      ).thenAnswer((_) async => 'Description 3');

      final result = await repository.fetchTasks(projectId);

      expect(result, hasLength(3));
      expect(result[0].number, 1);
      expect(result[0].title, 'Task 1');
      expect(result[0].assignee, 'alice');
      expect(result[0].tags, ['feature']);
      expect(result[0].description, 'Description 1');
      expect(result[0].projectId, projectId);

      expect(result[1].number, 2);
      expect(result[1].assignee, isNull);
      expect(result[1].tags, isEmpty);

      expect(result[2].number, 3);
      expect(result[2].assignee, 'bob');
      expect(result[2].tags, ['bug', 'urgent']);
    });

    test('should return empty list when no task numbers', () async {
      when(() => gitService.listTaskNumbers(projectId))
          .thenAnswer((_) async => []);

      final result = await repository.fetchTasks(projectId);

      expect(result, isEmpty);
      verifyNever(() => gitService.readMetadata(any(), any()));
    });

    test('should skip tasks that throw errors', () async {
      when(() => gitService.listTaskNumbers(projectId))
          .thenAnswer((_) async => [1, 2]);

      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {'title': 'Task 1', 'tags': <String>[], 'created': '', 'updated': ''});
      when(
        () => gitService.readDescription(projectId, 1),
      ).thenAnswer((_) async => 'Desc 1');

      when(
        () => gitService.readMetadata(projectId, 2),
      ).thenThrow(Exception('File not found'));

      final result = await repository.fetchTasks(projectId);

      expect(result, hasLength(1));
      expect(result[0].number, 1);
    });

    test('should use DateTime.now() for invalid dates', () async {
      final now = DateTime.now();
      when(() => gitService.listTaskNumbers(projectId))
          .thenAnswer((_) async => [1]);
      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Task',
        'assignee': null,
        'tags': <String>[],
        'created': 'invalid',
        'updated': 'invalid',
      });
      when(
        () => gitService.readDescription(projectId, 1),
      ).thenAnswer((_) async => '');

      final result = await repository.fetchTasks(projectId);

      expect(result[0].createdAt.difference(now).inSeconds, lessThan(2));
      expect(result[0].updatedAt.difference(now).inSeconds, lessThan(2));
    });
  });

  group('TaskRepository.fetchTask', () {
    test('should fetch single task', () async {
      when(
        () => gitService.readMetadata(projectId, 5),
      ).thenAnswer((_) async => {
        'title': 'Single Task',
        'assignee': 'charlie',
        'tags': ['test'],
        'created': '2025-02-01T00:00:00Z',
        'updated': '2025-02-02T00:00:00Z',
      });
      when(
        () => gitService.readDescription(projectId, 5),
      ).thenAnswer((_) async => 'Single description');

      final result = await repository.fetchTask(projectId, 5);

      expect(result.number, 5);
      expect(result.title, 'Single Task');
      expect(result.assignee, 'charlie');
      expect(result.tags, ['test']);
      expect(result.description, 'Single description');
      expect(result.projectId, projectId);
    });
  });

  group('TaskRepository.createTask', () {
    test('should create new task and return number', () async {
      when(() => gitService.getNextTaskNumber(projectId))
          .thenAnswer((_) async => 4);
      when(
        () => gitService.writeDescription(projectId, 4, any()),
      ).thenAnswer((_) async {});
      when(
        () => gitService.writeMetadata(projectId, 4, any()),
      ).thenAnswer((_) async {});

      final result = await repository.createTask(projectId);

      expect(result, 4);
      verify(() => gitService.getNextTaskNumber(projectId)).called(1);
      verify(
        () => gitService.writeDescription(projectId, 4, '# Task 4\n\n'),
      ).called(1);
      verify(() => gitService.writeMetadata(projectId, 4, any())).called(1);
    });
  });

  group('TaskRepository.updateDescription', () {
    test('should update description and metadata timestamp', () async {
      when(
        () => gitService.writeDescription(projectId, 1, 'New description'),
      ).thenAnswer((_) async {});
      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Task',
        'assignee': null,
        'tags': <String>[],
        'created': '2025-01-01T00:00:00Z',
      });
      when(
        () => gitService.writeMetadata(projectId, 1, any()),
      ).thenAnswer((_) async {});

      await repository.updateDescription(projectId, 1, 'New description');

      verify(
        () => gitService.writeDescription(projectId, 1, 'New description'),
      ).called(1);
      verify(() => gitService.readMetadata(projectId, 1)).called(1);
      verify(() => gitService.writeMetadata(projectId, 1, any())).called(1);
    });
  });

  group('TaskRepository.updateTask', () {
    test('should update multiple fields', () async {
      when(
        () => gitService.writeDescription(projectId, 1, 'New desc'),
      ).thenAnswer((_) async {});
      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Old title',
        'assignee': null,
        'tags': <String>[],
        'created': '2025-01-01T00:00:00Z',
      });
      when(
        () => gitService.writeMetadata(projectId, 1, any()),
      ).thenAnswer((_) async {});

      await repository.updateTask(
        projectId,
        1,
        description: 'New desc',
        title: 'New title',
        assignee: 'new-assignee',
        tags: ['new', 'tags'],
      );

      verify(() => gitService.writeDescription(projectId, 1, 'New desc'))
          .called(1);
      verify(() => gitService.readMetadata(projectId, 1)).called(1);
      verify(() => gitService.writeMetadata(projectId, 1, any())).called(1);
    });

    test('should only update metadata when description not provided', () async {
      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Title',
        'assignee': null,
        'tags': <String>[],
        'created': '2025-01-01T00:00:00Z',
      });
      when(
        () => gitService.writeMetadata(projectId, 1, any()),
      ).thenAnswer((_) async {});

      await repository.updateTask(
        projectId,
        1,
        title: 'Updated title',
        tags: ['updated'],
      );

      verifyNever(() => gitService.writeDescription(any(), any(), any()));
      verify(() => gitService.readMetadata(projectId, 1)).called(1);
      verify(() => gitService.writeMetadata(projectId, 1, any())).called(1);
    });
  });

  group('TaskRepository.updateMetadata', () {
    test('should update metadata fields', () async {
      when(
        () => gitService.readMetadata(projectId, 1),
      ).thenAnswer((_) async => {
        'title': 'Old',
        'assignee': null,
        'tags': <String>[],
        'created': '2025-01-01T00:00:00Z',
      });
      when(
        () => gitService.writeMetadata(projectId, 1, any()),
      ).thenAnswer((_) async {});

      await repository.updateMetadata(
        projectId,
        1,
        title: 'New Title',
        assignee: 'bob',
        tags: ['tag1'],
      );

      verify(() => gitService.readMetadata(projectId, 1)).called(1);
      verify(() => gitService.writeMetadata(projectId, 1, any())).called(1);
    });
  });

  group('TaskRepository.addComment', () {
    test('should add comment via git service', () async {
      when(
        () => gitService.addComment(projectId, 1, 'Comment text', 'alice'),
      ).thenAnswer((_) async {});

      await repository.addComment(projectId, 1, 'Comment text', 'alice');

      verify(
        () => gitService.addComment(projectId, 1, 'Comment text', 'alice'),
      ).called(1);
    });
  });

  group('TaskRepository.deleteComment', () {
    test('should delete comment via git service', () async {
      when(
        () => gitService.deleteComment(projectId, 1, 5),
      ).thenAnswer((_) async {});

      await repository.deleteComment(projectId, 1, 5);

      verify(() => gitService.deleteComment(projectId, 1, 5)).called(1);
    });
  });

  group('TaskRepository.listComments', () {
    test('should list comments for a task', () async {
      when(
        () => gitService.listComments(projectId, 1),
      ).thenAnswer((_) async => [
        {
          'number': 1,
          'content': 'First comment',
          'author': 'alice',
          'date': '2025-01-01T10:00:00Z',
        },
        {
          'number': 2,
          'content': 'Second comment',
          'author': 'bob',
          'date': '2025-01-02T12:00:00Z',
        },
      ]);

      final result = await repository.listComments(projectId, 1);

      expect(result, hasLength(2));
      expect(result[0].number, 1);
      expect(result[0].content, 'First comment');
      expect(result[0].author, 'alice');
      expect(result[0].taskNumber, '001');

      expect(result[1].number, 2);
      expect(result[1].author, 'bob');
    });

    test('should use DateTime.now() for invalid dates', () async {
      final now = DateTime.now();
      when(
        () => gitService.listComments(projectId, 1),
      ).thenAnswer((_) async => [
        {
          'number': 1,
          'content': 'Comment',
          'author': 'user',
          'date': 'invalid-date',
        },
      ]);

      final result = await repository.listComments(projectId, 1);

      expect(result[0].createdAt.difference(now).inSeconds, lessThan(2));
    });

    test('should handle missing fields in comments', () async {
      when(
        () => gitService.listComments(projectId, 1),
      ).thenAnswer((_) async => [
        {'number': null, 'content': null, 'author': null, 'date': null},
      ]);

      final result = await repository.listComments(projectId, 1);

      expect(result[0].number, 0);
      expect(result[0].content, '');
      expect(result[0].author, 'Unknown');
    });
  });
}
