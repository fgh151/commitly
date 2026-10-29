import '../models/project.dart';
import '../services/git_service.dart';

/// Repository for project (repository) operations.
class ProjectRepository {
  final GitService _gitService;

  ProjectRepository(this._gitService);

  /// Fetch list of user's repositories
  Future<List<Project>> fetchProjects() {
    return _gitService.listRepositories();
  }
}
