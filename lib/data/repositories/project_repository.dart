import 'dart:convert';
import '../models/project.dart';
import '../services/git_service.dart';

/// Repository for project (repository) operations.
class ProjectRepository {
  final GitService _gitService;

  ProjectRepository(this._gitService);

  /// Fetch list of user's repositories
  Future<List<Project>> fetchProjects() async {
    final projects = await _gitService.listRepositories();
    
    // Read metadata.json for each project to get custom name
    final enriched = <Project>[];
    for (final project in projects) {
      try {
        final content = await _gitService.readFileContent(project.fullName, 'metadata.json');
        if (content != null && content.isNotEmpty) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          final customName = json['name'] as String?;
          enriched.add(project.copyWith(customName: customName));
        } else {
          enriched.add(project);
        }
      } catch (e) {
        // If metadata.json doesn't exist or parsing fails, use project as-is
        enriched.add(project);
      }
    }
    
    return enriched;
  }
}
