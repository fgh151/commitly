/// Represents a task within a project.
class Task {
  final int number; // 1, 2, 3 — used as folder name "001/"
  final String title; // Task title
  final String description; // Markdown content
  final String? assignee; // Username
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String projectId; // Parent project ID

  const Task({
    required this.number,
    required this.title,
    required this.description,
    this.assignee,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.projectId,
  });

  /// Folder name zero-padded to 3 digits, e.g. "001"
  String get folderName => number.toString().padLeft(3, '0');

  /// Path to description.md in the repository
  String get descriptionPath => 'tasks/$folderName/description.md';

  /// Path to metadata.json in the repository
  String get metadataPath => 'tasks/$folderName/metadata.json';

  factory Task.fromJson(Map<String, dynamic> json) {
    final tagsJson = json['tags'] as List<dynamic>?;
    return Task(
      number: json['id'] as int? ?? json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assignee: json['assignee'] as String?,
      tags: tagsJson?.map((e) => e as String).toList() ?? [],
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String) ?? DateTime.now()
          : DateTime.now(),
      projectId: json['projectId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': number,
      'number': number,
      'title': title,
      'description': description,
      'assignee': assignee,
      'tags': tags,
      'created': createdAt.toIso8601String(),
      'updated': updatedAt.toIso8601String(),
      'projectId': projectId,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    String? assignee,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? projectId,
  }) {
    return Task(
      number: number,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectId: projectId ?? this.projectId,
    );
  }
}
