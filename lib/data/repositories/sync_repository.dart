import '../services/git_service.dart';
import '../models/sync_status.dart';

/// Repository for sync operations.
class SyncRepository {
  final GitService _gitService;

  SyncRepository(this._gitService);

  /// Pull latest changes from remote
  Future<SyncResult> pull(String projectId) {
    return _gitService.pull(projectId);
  }

  /// Push local changes to remote
  Future<SyncResult> push(String projectId) {
    return _gitService.push(projectId);
  }

  /// Check for conflicts between local and remote
  Future<List<ConflictInfo>> checkConflicts(String projectId) {
    return _gitService.checkConflicts(projectId);
  }

  /// Resolve a specific conflict
  Future<void> resolveConflict(String projectId, ConflictInfo conflict) {
    return _gitService.resolveConflict(projectId, conflict);
  }
}
