/// Sync state enum.
enum SyncState { idle, pulling, pushing, conflict, error }

/// Information about a merge conflict.
class ConflictInfo {
  final String filePath;
  final String? localContent;
  final String? remoteContent;

  const ConflictInfo({
    required this.filePath,
    this.localContent,
    this.remoteContent,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'localContent': localContent,
      'remoteContent': remoteContent,
    };
  }

  factory ConflictInfo.fromJson(Map<String, dynamic> json) {
    return ConflictInfo(
      filePath: json['filePath'] as String? ?? '',
      localContent: json['localContent'] as String?,
      remoteContent: json['remoteContent'] as String?,
    );
  }
}

/// Resolution strategy for conflicts.
enum ConflictResolution { acceptLocal, acceptRemote, manual }

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final String? message;
  final List<ConflictInfo>? conflicts;

  const SyncResult({
    required this.success,
    this.message,
    this.conflicts,
  });

  factory SyncResult.success({String? message}) {
    return SyncResult(success: true, message: message ?? 'Sync complete');
  }

  factory SyncResult.failure({
    required String message,
    List<ConflictInfo>? conflicts,
  }) {
    return SyncResult(
      success: false,
      message: message,
      conflicts: conflicts,
    );
  }
}
