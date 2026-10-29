import 'git_service_config.dart';

/// Represents a Git repository (project).
class Project {
  final int id;
  final String name;
  final String owner;
  final String fullName; // "owner/repo"
  final String? description;
  final bool isPrivate;
  final String defaultBranch;
  final GitServiceType serviceType;
  final DateTime? updatedAt;
  final String? localPath; // For self-hosted with local clone

  const Project({
    required this.id,
    required this.name,
    required this.owner,
    required this.fullName,
    this.description,
    required this.isPrivate,
    required this.defaultBranch,
    required this.serviceType,
    this.updatedAt,
    this.localPath,
  });

  factory Project.fromJson(Map<String, dynamic> json, GitServiceType type) {
    return Project(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      owner: json['owner'] is Map
          ? (json['owner']['login'] as String? ?? '')
          : (json['owner'] as String? ?? ''),
      fullName: json['full_name'] as String? ?? '',
      description: json['description'] as String?,
      isPrivate: json['private'] as bool? ?? false,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      serviceType: type,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner': owner,
      'full_name': fullName,
      'description': description,
      'private': isPrivate,
      'default_branch': defaultBranch,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Project copyWith({
    int? id,
    String? name,
    String? owner,
    String? fullName,
    String? description,
    bool? isPrivate,
    String? defaultBranch,
    GitServiceType? serviceType,
    DateTime? updatedAt,
    String? localPath,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      isPrivate: isPrivate ?? this.isPrivate,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      serviceType: serviceType ?? this.serviceType,
      updatedAt: updatedAt ?? this.updatedAt,
      localPath: localPath ?? this.localPath,
    );
  }
}
