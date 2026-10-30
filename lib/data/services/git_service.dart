import 'dart:typed_data';
import '../models/project.dart';
import '../models/sync_status.dart';
import '../models/git_service_config.dart';

/// Abstract interface for all Git operations.
/// Implementations can use REST API (GitHub/GitLab/Gitea) or libgit2.
abstract class GitService {
  /// The authenticated user's display name for commits
  String? get committerName;

  /// Initialize the service with config and PAT
  Future<void> initialize(GitServiceConfig config, String pat);

  /// List repositories for the authenticated user
  Future<List<Project>> listRepositories();

  /// List task folder numbers in a project
  Future<List<int>> listTaskNumbers(String projectId);

  /// Read task metadata.json
  Future<Map<String, dynamic>> readMetadata(String projectId, int taskNumber);

  /// Write task metadata.json (creates commit)
  Future<void> writeMetadata(
    String projectId,
    int taskNumber,
    Map<String, dynamic> metadata,
  );

  /// Read task description.md
  Future<String> readDescription(String projectId, int taskNumber);

  /// Write task description.md (creates commit)
  Future<void> writeDescription(
    String projectId,
    int taskNumber,
    String content,
  );

  /// List comments in a task
  Future<List<Map<String, dynamic>>> listComments(
    String projectId,
    int taskNumber,
  );

  /// Add a comment (creates file + commit)
  Future<void> addComment(
    String projectId,
    int taskNumber,
    String content,
    String author,
  );

  /// Delete a comment
  Future<void> deleteComment(
    String projectId,
    int taskNumber,
    int commentNumber,
  );

  /// Upload an attachment file
  Future<void> uploadAttachment(
    String projectId,
    int taskNumber,
    String fileName,
    Uint8List data,
  );

  /// Download an attachment file
  Future<Uint8List> downloadAttachment(
    String projectId,
    int taskNumber,
    String fileName,
  );

  /// Pull latest changes from remote
  Future<SyncResult> pull(String projectId);

  /// Push local changes to remote
  Future<SyncResult> push(String projectId);

  /// Check for conflicts
  Future<List<ConflictInfo>> checkConflicts(String projectId);

  /// Resolve a conflict
  Future<void> resolveConflict(
    String projectId,
    ConflictInfo conflict,
  );

  /// Generate next task number for a project
  Future<int> getNextTaskNumber(String projectId);

  /// Get the default branch name
  Future<String> getDefaultBranch(String projectId);

  /// Dispose resources
  Future<void> dispose();
}
