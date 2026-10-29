import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/git_service_config.dart';
import '../models/project.dart';
import '../models/sync_status.dart';
import 'git_service.dart';

/// REST API implementation of GitService for cloud services (GitHub, GitLab, Gitea).
class RestApiGitService implements GitService {
  final GitServiceConfig _config;
  final String _pat;
  late final Dio _dio;

  RestApiGitService(this._config, this._pat) {
    _dio = Dio(BaseOptions(
      baseUrl: _config.baseUrl,
      headers: _buildHeaders(),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Don't overwrite headers set in constructor
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              message: 'Invalid token or unauthorized',
              type: DioExceptionType.badResponse,
            ),
          );
        } else if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              message: 'Connection timeout',
              type: error.type,
            ),
          );
        }
        return handler.next(error);
      },
    ));
  }

  Map<String, String> _buildHeaders() {
    switch (_config.type) {
      case GitServiceType.github:
        return {
          'Authorization': 'Bearer $_pat',
          'Accept': 'application/vnd.github.v3+json',
        };
      case GitServiceType.gitlab:
        return {'PRIVATE-TOKEN': _pat};
      case GitServiceType.gitea:
      case GitServiceType.custom:
        return {'Authorization': 'Bearer $_pat'};
    }
  }

  String _getOwnerAndRepo(String projectId, {String separator = '/'}) {
    // projectId can be "owner/repo" or just repo ID
    if (projectId.contains(separator)) {
      return projectId;
    }
    // For API-based approach, we expect projectId to be full_name format
    throw ArgumentError('projectId must be in "owner/repo" format, got: $projectId');
  }

  @override
  Future<void> initialize(GitServiceConfig config, String pat) async {
    // Already initialized in constructor
  }

  @override
  Future<List<Project>> listRepositories() async {
    final List<Project> projects = [];

    // Try user repos first
    try {
      final response = await _dio.get('/user/repos', queryParameters: {
        'type': 'all',
        'sort': 'updated',
        'per_page': 100,
      });

      if (response.data is List) {
        for (final item in response.data) {
          projects.add(Project.fromJson(item, _config.type));
        }
      }
    } on DioException {
      // Fall back to searching
    }

    return projects;
  }

  @override
  Future<List<int>> listTaskNumbers(String projectId) async {
    final repo = _getOwnerAndRepo(projectId);
    final List<int> numbers = [];

    try {
      final response = await _dio.get(
        '/repos/$repo/contents/tasks',
      );

      if (response.data is List) {
        for (final item in response.data) {
          final name = item['name'] as String? ?? '';
          // Parse folder name "001" -> 1
          final parsed = int.tryParse(name);
          if (parsed != null) {
            numbers.add(parsed);
          }
        }
      }
    } on DioException catch (e) {
      // Tasks folder doesn't exist yet
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }

    numbers.sort();
    return numbers;
  }

  @override
  Future<Map<String, dynamic>> readMetadata(
    String projectId,
    int taskNumber,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    try {
      final response = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/metadata.json',
      );

      final content = response.data['content'] as String;
      final decoded = base64Decode(content);
      final json = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
      return json;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'id': taskNumber,
          'assignee': null,
          'tags': <String>[],
          'created': DateTime.now().toUtc().toIso8601String(),
          'updated': DateTime.now().toUtc().toIso8601String(),
        };
      }
      rethrow;
    }
  }

  @override
  Future<void> writeMetadata(
    String projectId,
    int taskNumber,
    Map<String, dynamic> metadata,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    // First read to get the SHA
    String? sha;
    try {
      final readResponse = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/metadata.json',
      );
      sha = readResponse.data['sha'] as String?;
    } on DioException {
      // File doesn't exist yet, will create new
    }

    final encoded = base64Encode(utf8.encode(jsonEncode(metadata)));

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/metadata.json',
      data: {
        'message': 'Update metadata for task $taskNumber',
        'content': encoded,
        'branch': _config.customGitPath ?? 'main',
        'committer': {
          'name': 'Commitly',
          'email': 'commitly@openitstudio.com',
        },
        if (sha != null) 'sha': sha,
      },
    );
  }

  @override
  Future<String> readDescription(String projectId, int taskNumber) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    final response = await _dio.get(
      '/repos/$repo/contents/tasks/$folderName/description.md',
    );

    final content = response.data['content'] as String;
    return utf8.decode(base64Decode(content));
  }

  @override
  Future<void> writeDescription(
    String projectId,
    int taskNumber,
    String content,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    // First read to get the SHA
    String? sha;
    try {
      final readResponse = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/description.md',
      );
      sha = readResponse.data['sha'] as String?;
    } on DioException {
      // File doesn't exist yet
    }

    final encoded = base64Encode(utf8.encode(content));

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/description.md',
      data: {
        'message': 'Update description for task $taskNumber',
        'content': encoded,
        'branch': _config.customGitPath ?? 'main',
        'committer': {
          'name': 'Commitly',
          'email': 'commitly@openitstudio.com',
        },
        if (sha != null) 'sha': sha,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listComments(
    String projectId,
    int taskNumber,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');
    final List<Map<String, dynamic>> comments = [];

    try {
      final response = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/comments',
      );

      if (response.data is List) {
        for (final item in response.data) {
          final name = item['name'] as String? ?? '';
          comments.add({
            'number': int.tryParse(name) ?? 0,
            'path': item['path'] as String? ?? '',
          });
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }

    return comments;
  }

  @override
  Future<void> addComment(
    String projectId,
    int taskNumber,
    String content,
    String author,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    // Get next comment number
    int commentNumber = 1;
    try {
      final existing = await listComments(projectId, taskNumber);
      if (existing.isNotEmpty) {
        commentNumber =
            existing.map((e) => e['number'] as int).reduce((a, b) => a > b ? a : b) +
                1;
      }
    } on DioException {
      // Comments folder doesn't exist yet
    }

    final padded = commentNumber.toString().padLeft(3, '0');
    final commentContent =
        '---\nauthor: $author\ndate: ${DateTime.now().toUtc().toIso8601String()}\n---\n\n$content';
    final encoded = base64Encode(utf8.encode(commentContent));

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
      data: {
        'message': 'Add comment to task $taskNumber',
        'content': encoded,
        'branch': _config.customGitPath ?? 'main',
        'committer': {
          'name': 'Commitly',
          'email': 'commitly@openitstudio.com',
        },
      },
    );
  }

  @override
  Future<void> deleteComment(
    String projectId,
    int taskNumber,
    int commentNumber,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');
    final padded = commentNumber.toString().padLeft(3, '0');

    final response = await _dio.get(
      '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
    );

    final sha = response.data['sha'] as String?;

    await _dio.delete(
      '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
      data: {
        'message': 'Delete comment $commentNumber from task $taskNumber',
        'sha': sha,
        'branch': _config.customGitPath ?? 'main',
        'committer': {
          'name': 'Commitly',
          'email': 'commitly@openitstudio.com',
        },
      },
    );
  }

  @override
  Future<void> uploadAttachment(
    String projectId,
    int taskNumber,
    String fileName,
    Uint8List data,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');
    final encoded = base64Encode(data);

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/attachments/$fileName',
      data: {
        'message': 'Upload attachment $fileName to task $taskNumber',
        'content': encoded,
        'branch': _config.customGitPath ?? 'main',
        'committer': {
          'name': 'Commitly',
          'email': 'commitly@openitstudio.com',
        },
      },
    );
  }

  @override
  Future<Uint8List> downloadAttachment(
    String projectId,
    int taskNumber,
    String fileName,
  ) async {
    final repo = _getOwnerAndRepo(projectId);
    final folderName = taskNumber.toString().padLeft(3, '0');

    final response = await _dio.get(
      '/repos/$repo/contents/tasks/$folderName/attachments/$fileName',
    );

    final content = response.data['content'] as String;
    return base64Decode(content);
  }

  @override
  Future<SyncResult> pull(String projectId) async {
    // For REST API, pull means fetching latest state
    // The actual "pull" is implicit since we always read from remote
    return SyncResult.success(message: 'Up to date');
  }

  @override
  Future<SyncResult> push(String projectId) async {
    // For REST API, writes are committed directly
    return SyncResult.success(message: 'All changes pushed');
  }

  @override
  Future<List<ConflictInfo>> checkConflicts(String projectId) async {
    // REST API operations are atomic per-file via SHA checking
    // No explicit conflict detection needed for V1
    return [];
  }

  @override
  Future<void> resolveConflict(String projectId, ConflictInfo conflict) async {
    // Not needed for REST API V1
  }

  @override
  Future<int> getNextTaskNumber(String projectId) async {
    final numbers = await listTaskNumbers(projectId);
    if (numbers.isEmpty) return 1;
    return numbers.last + 1;
  }

  @override
  Future<String> getDefaultBranch(String projectId) async {
    final repo = _getOwnerAndRepo(projectId);
    try {
      final response = await _dio.get('/repos/$repo');
      return response.data['default_branch'] as String? ?? 'main';
    } on DioException {
      return 'main';
    }
  }

  @override
  Future<void> dispose() async {
    _dio.close();
  }
}
