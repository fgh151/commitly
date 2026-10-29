enum GitServiceType {
  github,
  gitlab,
  gitea,
  custom,
}

/// Configuration for a Git service connection.
class GitServiceConfig {
  final GitServiceType type;
  /// Base URL for the API, e.g. "https://api.github.com"
  final String baseUrl;
  /// Custom API path for self-hosted instances
  final String? customApiPath;
  /// Custom git endpoint for self-hosted
  final String? customGitPath;

  const GitServiceConfig({
    required this.type,
    required this.baseUrl,
    this.customApiPath,
    this.customGitPath,
  });

  factory GitServiceConfig.fromType(GitServiceType type) {
    switch (type) {
      case GitServiceType.github:
        return const GitServiceConfig(
          type: GitServiceType.github,
          baseUrl: 'https://api.github.com',
        );
      case GitServiceType.gitlab:
        return const GitServiceConfig(
          type: GitServiceType.gitlab,
          baseUrl: 'https://gitlab.com/api/v4',
        );
      case GitServiceType.gitea:
        return const GitServiceConfig(
          type: GitServiceType.gitea,
          baseUrl: 'https://gitea.example.com/api/v1',
        );
      case GitServiceType.custom:
        return const GitServiceConfig(
          type: GitServiceType.custom,
          baseUrl: '',
        );
    }
  }

  factory GitServiceConfig.fromJson(Map<String, dynamic> json) {
    return GitServiceConfig(
      type: GitServiceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GitServiceType.github,
      ),
      baseUrl: json['baseUrl'] as String,
      customApiPath: json['customApiPath'] as String?,
      customGitPath: json['customGitPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'baseUrl': baseUrl,
      'customApiPath': customApiPath,
      'customGitPath': customGitPath,
    };
  }

  GitServiceConfig copyWith({
    GitServiceType? type,
    String? baseUrl,
    String? customApiPath,
    String? customGitPath,
  }) {
    return GitServiceConfig(
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      customApiPath: customApiPath ?? this.customApiPath,
      customGitPath: customGitPath ?? this.customGitPath,
    );
  }
}
