import 'package:flutter/foundation.dart';
import '../models/git_service_config.dart';
import 'git_service.dart';
import 'rest_api_git_service.dart';

/// Factory for creating GitService instances based on platform and configuration.
class GitServiceFactory {
  /// Creates a GitService appropriate for the current platform.
  ///
  /// On Web, always uses REST API.
  /// On desktop/mobile, could be extended to use libgit2 for self-hosted instances.
  static GitService create(GitServiceConfig config, String pat) {
    if (kIsWeb) {
      return RestApiGitService(config, pat);
    }
    // For now, use REST API for all platforms
    // Future: detect self-hosted and use libgit2 on desktop
    return RestApiGitService(config, pat);
  }
}
