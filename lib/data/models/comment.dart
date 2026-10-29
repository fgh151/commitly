/// Represents a comment on a task.
class Comment {
  final int number; // Sequential within a task
  final String content; // Markdown
  final String author; // Username
  final DateTime createdAt;
  final String taskNumber; // Parent task number, e.g. "001"

  const Comment({
    required this.number,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.taskNumber,
  });

  /// File path within the repository
  String get filePath => 'tasks/$taskNumber/comments/$number.md';

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      number: json['number'] as int? ?? json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      author: json['author'] as String? ?? '',
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'] as String) ?? DateTime.now()
          : DateTime.now(),
      taskNumber: json['taskNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'content': content,
      'author': author,
      'created': createdAt.toIso8601String(),
      'taskNumber': taskNumber,
    };
  }

  Comment copyWith({
    int? number,
    String? content,
    String? author,
    DateTime? createdAt,
    String? taskNumber,
  }) {
    return Comment(
      number: number ?? this.number,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      taskNumber: taskNumber ?? this.taskNumber,
    );
  }
}
