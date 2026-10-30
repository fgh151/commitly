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
  String? _committerName;
  String? _committerEmail;

  RestApiGitService(this._config, this._pat) {
    _dio = Dio(BaseOptions(
      baseUrl: _config.baseUrl,
      headers: _buildHeaders(),
      contentType: 'application/json',
    ));

    // Fetch committer info eagerly; if it fails, defaults are used
    _fetchCommitterInfo().then((_) {
      // committer info ready
    }).catchError((_) {
      // will use defaults
    });

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
        } else if (error.response?.statusCode == 422) {
          // 422 = Unprocessable Entity - usually branch name or commit validation
          final errorData = error.response?.data as Map<String, dynamic>?;
          final message = errorData?['message'] as String? ?? 'Validation failed';
          print('❌ 422 Error: $message');
          print('   Response: ${error.response?.data}');
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              message: 'Commit validation failed: $message',
              type: DioExceptionType.badResponse,
              response: error.response,
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

  @override
  String? get committerName => _committerName;

  Map<String, String> get _committer => {
        'name': _committerName ?? 'Commitly',
        'email': _committerEmail ?? 'commitly@openitstudio.com',
      };

  String? _defaultBranch;

  Future<String> _getBranch(String projectId) async {
    // Return cached branch if available
    if (_defaultBranch != null) return _defaultBranch!;

    final repo = _getOwnerAndRepo(projectId);
    try {
      final response = await _dio.get('/repos/$repo');
      _defaultBranch = response.data['default_branch'] as String? ?? 'main';
      return _defaultBranch!;
    } on DioException {
      return _config.customGitPath ?? 'main';
    }
  }

  /// Fetch the authenticated user's name and email from the Git service.
  Future<void> _fetchCommitterInfo() async {
    try {
      final response = await _dio.get('/user');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        switch (_config.type) {
          case GitServiceType.github:
            _committerName = (data['name'] as String?) ??
                (data['login'] as String?) ??
                'User';
            _committerEmail = data['email'] as String?;
            // GitHub may not expose email publicly, fall back to login-based email
            if (_committerEmail == null || _committerEmail!.isEmpty) {
              _committerEmail =
                  '${_committerName?.toLowerCase().replaceAll(' ', '.')}@users.noreply.github.com';
            }
            break;
          case GitServiceType.gitlab:
            _committerName = (data['name'] as String?) ??
                (data['username'] as String?) ??
                'User';
            _committerEmail = data['email'] as String? ??
                '${data['username']}@users.noreply.gitlab.com';
            break;
          case GitServiceType.gitea:
            _committerName = (data['full_name'] as String?) ??
                (data['username'] as String?) ??
                'User';
            _committerEmail = data['email'] as String? ??
                '${data['username']}@users.noreply.gitea.com';
            break;
          case GitServiceType.custom:
            _committerName = (data['name'] as String?) ??
                (data['login'] as String?) ??
                'User';
            _committerEmail =
                data['email'] as String? ?? 'user@example.com';
            break;
        }
        print('👤 Committer: $_committerName <$_committerEmail>');
      }
    } catch (e) {
      print('⚠️ Could not fetch committer info: $e');
      // Fall back to defaults
      _committerName = 'Commitly';
      _committerEmail = 'commitly@openitstudio.com';
    }
  }

  String _getOwnerAndRepo(String projectId, {String separator = '/'}) {
    // URL-decode the projectId (e.g., 'owner%2Frepo' -> 'owner/repo')
    final decoded = Uri.decodeComponent(projectId);
    if (decoded.contains(separator)) {
      return decoded;
    }
    throw ArgumentError('projectId must be in "owner/repo" format, got: $decoded');
  }

  @override
  Future<void> initialize(GitServiceConfig config, String pat) async {
    await _fetchCommitterInfo();
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
      print('📂 Listing task folders in /tasks');
      final response = await _dio.get(
        '/repos/$repo/contents/tasks',
      );

      print('📂 Response type: ${response.data.runtimeType}');
      print('📂 Response length: ${response.data is List ? (response.data as List).length : "N/A"}');

      if (response.data is List) {
        for (final item in response.data) {
          final name = item['name'] as String? ?? '';
          final type = item['type'] as String? ?? '';
          print('📂 Item: name=$name, type=$type');

          // Parse folder name "001" -> 1
          final parsed = int.tryParse(name);
          if (parsed != null && type == 'dir') {
            numbers.add(parsed);
          }
        }
      }
    } on DioException catch (e) {
      print('❌ Error listing tasks: ${e.message}');
      print('   Status: ${e.response?.statusCode}');
      // Tasks folder doesn't exist yet
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }

    numbers.sort();
    print('📂 Found ${numbers.length} tasks: $numbers');
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

      final content = response.data['content'] as String?;
      if (content == null || content.isEmpty) {
        print('⚠️ Empty content from GitHub for metadata.json');
        return {
          'id': taskNumber,
          'assignee': null,
          'tags': <String>[],
          'created': DateTime.now().toUtc().toIso8601String(),
          'updated': DateTime.now().toUtc().toIso8601String(),
        };
      }

      // Normalize base64: handle whitespace, base64url encoding
      final normalized = content
          .replaceAll('-', '+')
          .replaceAll('_', '/')
          .replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(normalized);
      final decodedContent = utf8.decode(bytes);

      final json = jsonDecode(decodedContent) as Map<String, dynamic>;
      return json;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('📝 metadata.json not found, creating defaults for task $taskNumber');
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

    final branch = await _getBranch(projectId);
    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/metadata.json',
      data: {
        'message': 'Update metadata for task $taskNumber',
        'content': encoded,
        'branch': branch,
        'committer': _committer,
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

    var content = response.data['content'] as String;
    // Normalize base64: remove whitespace, handle base64url encoding
    content = content
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .replaceAll(RegExp(r'\s+'), '');
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
    final branch = await _getBranch(projectId);

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/description.md',
      data: {
        'message': 'Update description for task $taskNumber',
        'content': encoded,
        'branch': branch,
        'committer': _committer,
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
          final number = int.tryParse(name) ?? 0;
          // Read each comment file to get content, author, date
          try {
            final contentPath = 'tasks/$folderName/comments/$name';
            final contentResponse = await _dio.get(
              '/repos/$repo/contents/$contentPath',
            );
            var content = (contentResponse.data['content'] as String?) ?? '';
            content = content
                .replaceAll('-', '+')
                .replaceAll('_', '/')
                .replaceAll(RegExp(r'\s+'), '');
            final decoded = utf8.decode(base64Decode(content));
            // Parse YAML frontmatter
            String author = 'Unknown';
            DateTime date = DateTime.now();
            String body = decoded;
            final yamlMatch = RegExp(r'^---\n(.*?)\n---').firstMatch(decoded);
            if (yamlMatch != null) {
              final yaml = yamlMatch.group(1)!;
              for (final line in yaml.split('\n')) {
                if (line.startsWith('author: ')) {
                  author = line.substring(8).trim();
                } else if (line.startsWith('date: ')) {
                  date = DateTime.tryParse(line.substring(6).trim()) ?? DateTime.now();
                }
              }
              body = decoded.substring(yamlMatch.end).trim();
            }
            comments.add({
              'number': number,
              'content': body,
              'author': author,
              'date': date.toIso8601String(),
              'path': contentPath,
            });
          } on DioException {
            comments.add({
              'number': number,
              'content': '',
              'author': 'Unknown',
              'date': DateTime.now().toIso8601String(),
              'path': 'tasks/$folderName/comments/$name',
            });
          }
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

    // Get existing comment numbers by listing the comments folder
    int commentNumber = 1;
    try {
      final response = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/comments',
      );
      if (response.data is List) {
        int maxNum = 0;
        for (final item in response.data) {
          final name = (item['name'] as String? ?? '').replaceAll('.md', '');
          final num = int.tryParse(name);
          if (num != null && num > maxNum) maxNum = num;
        }
        commentNumber = maxNum + 1;
        print('📝 Found $maxNum existing comments, creating #$commentNumber');
      }
    } on DioException {
      print('📝 Comments folder does not exist yet, starting from #1');
      // Comments folder doesn't exist yet, start from 1
    }

    final padded = commentNumber.toString().padLeft(3, '0');
    final commentContent =
        '---\nauthor: $author\ndate: ${DateTime.now().toUtc().toIso8601String()}\n---\n\n$content';
    final encoded = base64Encode(utf8.encode(commentContent));
    final branch = await _getBranch(projectId);

    // Check if the target file already exists (from a previous failed attempt)
    String? sha;
    try {
      final readResponse = await _dio.get(
        '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
      );
      sha = readResponse.data['sha'] as String?;
      print('⚠️ Comment #$commentNumber already exists, will update');
    } on DioException {
      print('📝 Creating new comment #$commentNumber');
      // File doesn't exist yet, will create new
    }

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
      data: {
        'message': 'Add comment to task $taskNumber',
        'content': encoded,
        'branch': branch,
        'committer': _committer,
        if (sha != null) 'sha': sha,
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
    final branch = await _getBranch(projectId);

    await _dio.delete(
      '/repos/$repo/contents/tasks/$folderName/comments/$padded.md',
      data: {
        'message': 'Delete comment $commentNumber from task $taskNumber',
        'sha': sha,
        'branch': branch,
        'committer': _committer,
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
    final branch = await _getBranch(projectId);

    await _dio.put(
      '/repos/$repo/contents/tasks/$folderName/attachments/$fileName',
      data: {
        'message': 'Upload attachment $fileName to task $taskNumber',
        'content': encoded,
        'branch': branch,
        'committer': _committer,
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

    var content = response.data['content'] as String;
    content = content
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .replaceAll(RegExp(r'\s+'), '');
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
