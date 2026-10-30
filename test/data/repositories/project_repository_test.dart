import 'package:commitly/data/models/git_service_config.dart';
import 'package:commitly/data/models/project.dart';
import 'package:commitly/data/repositories/project_repository.dart';
import 'package:commitly/data/services/git_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock classes
class _MockGitService extends Mock implements GitService {}

class _FakeProject extends Fake implements Project {}

void main() {
  late _MockGitService gitService;
  late ProjectRepository repository;

  setUp(() {
    gitService = _MockGitService();
    repository = ProjectRepository(gitService);
  });

  group('ProjectRepository.fetchProjects', () {
    final testProjects = [
      const Project(
        id: 1,
        name: 'repo1',
        owner: 'owner1',
        fullName: 'owner1/repo1',
        isPrivate: false,
        defaultBranch: 'main',
        serviceType: GitServiceType.github,
      ),
      const Project(
        id: 2,
        name: 'repo2',
        owner: 'owner2',
        fullName: 'owner2/repo2',
        isPrivate: true,
        defaultBranch: 'develop',
        serviceType: GitServiceType.github,
      ),
    ];

    test('should return projects when metadata.json does not exist', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(() => gitService.readFileContent(any(), any()))
          .thenAnswer((_) async => null);

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, isNull);
      expect(result[1].customName, isNull);
      verify(() => gitService.listRepositories()).called(1);
      verify(() => gitService.readFileContent('owner1/repo1', 'metadata.json'))
          .called(1);
      verify(
        () => gitService.readFileContent('owner2/repo2', 'metadata.json'),
      ).called(1);
    });

    test('should enrich projects with customName from metadata.json', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(
        () => gitService.readFileContent('owner1/repo1', 'metadata.json'),
      ).thenAnswer((_) async => '{"name": "My Repo One"}');
      when(
        () => gitService.readFileContent('owner2/repo2', 'metadata.json'),
      ).thenAnswer((_) async => '{"name": "My Repo Two"}');

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, 'My Repo One');
      expect(result[1].customName, 'My Repo Two');
      expect(result[0].name, 'repo1'); // Original name preserved
    });

    test('should handle invalid JSON in metadata.json', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(
        () => gitService.readFileContent('owner1/repo1', 'metadata.json'),
      ).thenAnswer((_) async => 'not valid json {{{');

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, isNull);
    });

    test('should handle empty metadata.json', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(
        () => gitService.readFileContent('owner1/repo1', 'metadata.json'),
      ).thenAnswer((_) async => '');

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, isNull);
    });

    test('should handle missing name field in metadata.json', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(
        () => gitService.readFileContent('owner1/repo1', 'metadata.json'),
      ).thenAnswer((_) async => '{"otherField": "value"}');

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, isNull);
    });

    test('should return empty list when no repositories', () async {
      when(() => gitService.listRepositories()).thenAnswer((_) async => []);

      final result = await repository.fetchProjects();

      expect(result, isEmpty);
      verifyNever(() => gitService.readFileContent(any(), any()));
    });

    test('should skip project when readFileContent throws', () async {
      when(() => gitService.listRepositories())
          .thenAnswer((_) async => testProjects);
      when(
        () => gitService.readFileContent('owner1/repo1', 'metadata.json'),
      ).thenThrow(Exception('Network error'));
      when(
        () => gitService.readFileContent('owner2/repo2', 'metadata.json'),
      ).thenAnswer((_) async => '{"name": "Repo Two"}');

      final result = await repository.fetchProjects();

      expect(result, hasLength(2));
      expect(result[0].customName, isNull);
      expect(result[1].customName, 'Repo Two');
    });
  });
}
