import 'package:commitly/data/repositories/sync_repository.dart';
import 'package:commitly/data/services/git_service.dart';
import 'package:commitly/data/models/sync_status.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock classes
class _MockGitService extends Mock implements GitService {}

void main() {
  late _MockGitService gitService;
  late SyncRepository repository;

  const projectId = 'owner/repo';

  setUp(() {
    gitService = _MockGitService();
    repository = SyncRepository(gitService);
  });

  group('SyncRepository.pull', () {
    test('should delegate to gitService.pull', () async {
      when(() => gitService.pull(projectId)).thenAnswer(
        (_) async => SyncResult.success(message: 'Up to date'),
      );

      final result = await repository.pull(projectId);

      expect(result.success, true);
      expect(result.message, 'Up to date');
      verify(() => gitService.pull(projectId)).called(1);
    });

    test('should return failure result', () async {
      when(
        () => gitService.pull(projectId),
      ).thenAnswer(
        (_) async => SyncResult.failure(message: 'Pull failed'),
      );

      final result = await repository.pull(projectId);

      expect(result.success, false);
      expect(result.message, 'Pull failed');
    });
  });

  group('SyncRepository.push', () {
    test('should delegate to gitService.push', () async {
      when(() => gitService.push(projectId)).thenAnswer(
        (_) async => SyncResult.success(message: 'All changes pushed'),
      );

      final result = await repository.push(projectId);

      expect(result.success, true);
      expect(result.message, 'All changes pushed');
      verify(() => gitService.push(projectId)).called(1);
    });

    test('should return failure result', () async {
      when(
        () => gitService.push(projectId),
      ).thenAnswer(
        (_) async => SyncResult.failure(message: 'Push failed'),
      );

      final result = await repository.push(projectId);

      expect(result.success, false);
      expect(result.message, 'Push failed');
    });
  });

  group('SyncRepository.checkConflicts', () {
    test('should return empty list when no conflicts', () async {
      when(() => gitService.checkConflicts(projectId))
          .thenAnswer((_) async => []);

      final result = await repository.checkConflicts(projectId);

      expect(result, isEmpty);
      verify(() => gitService.checkConflicts(projectId)).called(1);
    });

    test('should return conflicts when they exist', () async {
      final conflicts = [
        const ConflictInfo(
          filePath: 'tasks/001/metadata.json',
          localContent: 'local',
          remoteContent: 'remote',
        ),
      ];

      when(
        () => gitService.checkConflicts(projectId),
      ).thenAnswer((_) async => conflicts);

      final result = await repository.checkConflicts(projectId);

      expect(result, conflicts);
      expect(result.first.filePath, 'tasks/001/metadata.json');
    });
  });

  group('SyncRepository.resolveConflict', () {
    test('should delegate to gitService.resolveConflict', () async {
      final conflict = const ConflictInfo(
        filePath: 'test.txt',
        localContent: 'local',
        remoteContent: 'remote',
      );
      when(
        () => gitService.resolveConflict(projectId, conflict),
      ).thenAnswer((_) async {});

      await repository.resolveConflict(projectId, conflict);

      verify(() => gitService.resolveConflict(projectId, conflict)).called(1);
    });
  });
}
