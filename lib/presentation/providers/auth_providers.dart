import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/services/git_service.dart';
import '../../data/services/git_service_factory.dart';
import '../../data/models/git_service_config.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/models/comment.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final GitServiceConfig? config;
  final GitService? gitService;
  final String? currentUserName;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.config,
    this.gitService,
    this.currentUserName,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    GitServiceConfig? config,
    GitService? gitService,
    String? currentUserName,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      config: config ?? this.config,
      gitService: gitService ?? this.gitService,
      currentUserName: currentUserName ?? this.currentUserName,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final repo = _ref.read(authRepositoryProvider);
    try {
      // Load saved config and PAT
      final config = await repo.loadConfig();
      final pat = await repo.loadPat();

      if (config != null && pat != null) {
        print('🔄 Restoring saved credentials...');

        // Validate token is still valid
        try {
          final isValid = await repo.validateCredentials(config, pat);
          if (isValid) {
            final gitService = GitServiceFactory.create(config, pat);
            // Wait a moment for committer info to be fetched
            await Future.delayed(const Duration(milliseconds: 500));
            final userName = gitService.committerName;
            state = state.copyWith(
              status: AuthStatus.authenticated,
              config: config,
              gitService: gitService,
              currentUserName: userName,
              error: null,
            );
            print('✅ Credentials restored successfully');
          } else {
            print('❌ Token invalid, clearing credentials');
            await repo.clearCredentials();
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        } catch (e) {
          // If validation fails (network issue), still restore but warn
          print('⚠️ Could not validate token: $e');
          final gitService = GitServiceFactory.create(config, pat);
          await Future.delayed(const Duration(milliseconds: 500));
          final userName = gitService.committerName;
          state = state.copyWith(
            status: AuthStatus.authenticated,
            config: config,
            gitService: gitService,
            currentUserName: userName,
            error: 'Token not validated (offline mode)',
          );
        }
      } else {
        print('🔑 No saved credentials found');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('❌ Error restoring credentials: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> selectService(GitServiceType type) async {
    // Just update UI state — actual connection happens in connect()
  }

  Future<void> connect(String baseUrl, String pat) async {
    final repo = _ref.read(authRepositoryProvider);
    try {
      GitServiceType type;
      String actualBaseUrl;
      if (baseUrl.contains('github.com')) {
        type = GitServiceType.github;
        actualBaseUrl = 'https://api.github.com';
      } else if (baseUrl.contains('gitlab.com')) {
        type = GitServiceType.gitlab;
        actualBaseUrl = 'https://gitlab.com/api/v4';
      } else if (baseUrl.contains('gitea') || baseUrl.contains('gitverse')) {
        type = GitServiceType.gitea;
        actualBaseUrl = baseUrl.endsWith('/api/v1') ? baseUrl : '$baseUrl/api/v1';
      } else {
        type = GitServiceType.custom;
        actualBaseUrl = baseUrl;
      }

      final config = GitServiceConfig(
        type: type,
        baseUrl: actualBaseUrl,
      );

      final isValid = await repo.validateCredentials(config, pat);
      if (!isValid) {
        state = state.copyWith(error: 'Invalid credentials');
        return;
      }

      await repo.saveConfig(config, pat);

      final gitService = GitServiceFactory.create(config, pat);
      await Future.delayed(const Duration(milliseconds: 500));
      final userName = gitService.committerName;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        config: config,
        gitService: gitService,
        currentUserName: userName,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: 'Connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.clearCredentials();
    await state.gitService?.dispose();
    // Clear caches
    _ref.read(projectCacheProvider.notifier).clear();
    _ref.read(taskCacheProvider.notifier).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Projects
class ProjectCache extends StateNotifier<AsyncValue<List<Project>>> {
  final Ref _ref;
  DateTime? _fetchedAt;
  GitServiceType? _serviceType;

  ProjectCache(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Load from cache on init
    final cached = await _loadCached();
    if (cached != null) {
      state = AsyncValue.data(cached);
    }
  }

  Future<List<Project>?> _loadCached() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final json = await prefs.getString('projects_cache');
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      final ts = DateTime.tryParse(map['ts'] as String);
      if (ts == null || DateTime.now().difference(ts).inMinutes > 30) return null;
      final typeIndex = map['type'] as int? ?? 0;
      final serviceType = GitServiceType.values[typeIndex];
      final list = map['projects'] as List<dynamic>;
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>, serviceType)).toList();
    } catch (_) {
      return null;
    }
  }

  void _saveCached(List<Project> projects, GitServiceType type) {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      prefs.setString('projects_cache', jsonEncode({
        'ts': DateTime.now().toUtc().toIso8601String(),
        'type': type.index,
        'projects': projects.map((p) => p.toJson()).toList(),
      }));
    } catch (_) {
      // ignore
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.gitService == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return;
      }
      final repo = ProjectRepository(authState.gitService!);
      final projects = await repo.fetchProjects();
      _fetchedAt = DateTime.now();
      _serviceType = authState.config?.type;
      _saveCached(projects, _serviceType ?? GitServiceType.github);
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> forceRefresh() async {
    _fetchedAt = null;
    await refresh();
  }

  void clear() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      prefs.remove('projects_cache');
    } catch (_) {}
    _serviceType = null;
    state = AsyncValue.data(<Project>[]);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final projectCacheProvider = StateNotifierProvider<ProjectCache, AsyncValue<List<Project>>>((ref) {
  return ProjectCache(ref);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final gitService = ref.read(authStateProvider).gitService;
  if (gitService == null) throw Exception('Not authenticated');
  return ProjectRepository(gitService);
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final projects = ref.read(projectCacheProvider).valueOrNull ?? [];
  return projects;
});

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

// Tasks
class TaskCache extends StateNotifier<Map<String, AsyncValue<List<Task>>>> {
  final Ref _ref;

  TaskCache(this._ref) : super({});

  AsyncValue<List<Task>> getTaskState(String projectId) {
    return state[projectId] ?? const AsyncValue.loading();
  }

  List<Task>? getTaskData(String projectId) {
    return state[projectId]?.value;
  }

  Future<void> load(String projectId) async {
    // Return cached data if available
    final cached = await _loadCached(projectId);
    if (cached != null) {
      state = {...state, projectId: AsyncValue.data(cached)};
      return;
    }

    // Not cached — trigger fetch
    await _fetch(projectId);
  }

  Future<void> _fetch(String projectId) async {
    // Mark loading
    state = {...state, projectId: const AsyncValue.loading()};
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.gitService == null) {
        state = {...state, projectId: AsyncValue.error('Not authenticated', StackTrace.current)};
        return;
      }
      final repo = TaskRepository(authState.gitService!);
      final tasks = await repo.fetchTasks(projectId);
      await _saveCached(projectId, tasks);
      state = {...state, projectId: AsyncValue.data(tasks)};
    } catch (e, st) {
      state = {...state, projectId: AsyncValue.error(e, st)};
    }
  }

  Future<void> refresh(String projectId) async {
    await _fetch(projectId);
  }

  Future<void> invalidate(String projectId) async {
    state = {...state, projectId: const AsyncValue.loading()};
    await _fetch(projectId);
  }

  void clear() {
    state = {};
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      prefs.remove('tasks_cache');
    } catch (_) {}
  }

  Future<void> clearProject(String projectId) async {
    final newState = Map<String, AsyncValue<List<Task>>>.from(state);
    newState.remove(projectId);
    state = newState;
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final json = await prefs.getString('tasks_cache');
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        map.remove(projectId);
        prefs.setString('tasks_cache', jsonEncode(map));
      }
    } catch (_) {}
  }

  Future<List<Task>?> _loadCached(String projectId) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final json = await prefs.getString('tasks_cache');
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      final projectEntry = map[projectId] as Map<String, dynamic>?;
      if (projectEntry == null) return null;
      final ts = DateTime.tryParse(projectEntry['ts'] as String);
      if (ts == null || DateTime.now().difference(ts).inMinutes > 30) return null;
      final list = projectEntry['tasks'] as List<dynamic>?;
      if (list == null) return null;
      return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCached(String projectId, List<Task> tasks) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final json = await prefs.getString('tasks_cache');
      Map<String, dynamic> fullMap;
      if (json != null) {
        fullMap = jsonDecode(json) as Map<String, dynamic>;
      } else {
        fullMap = {};
      }
      fullMap[projectId] = {
        'ts': DateTime.now().toUtc().toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };
      prefs.setString('tasks_cache', jsonEncode(fullMap));
    } catch (_) {
      // ignore
    }
  }
}

final taskCacheProvider = StateNotifierProvider<TaskCache, Map<String, AsyncValue<List<Task>>>>((ref) {
  return TaskCache(ref);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final gitService = ref.read(authStateProvider).gitService;
  if (gitService == null) throw Exception('Not authenticated');
  return TaskRepository(gitService);
});

final tasksProvider = FutureProvider.family<List<Task>, String>((ref, projectId) async {
  final tasks = ref.read(taskCacheProvider).values.firstOrNull?.value;
  // This is a fallback; the actual data comes from taskCacheProvider
  final repo = ref.read(taskRepositoryProvider);
  return repo.fetchTasks(projectId);
});

// Convenience provider to watch cached tasks for a specific project
final cachedTasksProvider = Provider.family<AsyncValue<List<Task>>, String>((ref, projectId) {
  return ref.watch(taskCacheProvider)[projectId] ?? const AsyncValue.loading();
});

// Comments
class CommentCache extends StateNotifier<Map<String, AsyncValue<List<Comment>>>> {
  final Ref _ref;

  CommentCache(this._ref) : super({});

  AsyncValue<List<Comment>> getCommentState(String key) {
    return state[key] ?? const AsyncValue.loading();
  }

  Future<void> load(String projectId, int taskNumber) async {
    final key = '$projectId/$taskNumber';
    state = {...state, key: const AsyncValue.loading()};
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.gitService == null) {
        state = {...state, key: AsyncValue.error('Not authenticated', StackTrace.current)};
        return;
      }
      final repo = TaskRepository(authState.gitService!);
      final comments = await repo.listComments(projectId, taskNumber);
      state = {...state, key: AsyncValue.data(comments)};
    } catch (e, st) {
      state = {...state, key: AsyncValue.error(e, st)};
    }
  }

  Future<void> refresh(String projectId, int taskNumber) async {
    final key = '$projectId/$taskNumber';
    state = {...state, key: const AsyncValue.loading()};
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.gitService == null) {
        state = {...state, key: AsyncValue.error('Not authenticated', StackTrace.current)};
        return;
      }
      final repo = TaskRepository(authState.gitService!);
      final comments = await repo.listComments(projectId, taskNumber);
      state = {...state, key: AsyncValue.data(comments)};
    } catch (e, st) {
      state = {...state, key: AsyncValue.error(e, st)};
    }
  }

  void clear() {
    state = {};
  }
}

final commentCacheProvider = StateNotifierProvider<CommentCache, Map<String, AsyncValue<List<Comment>>>>((ref) {
  return CommentCache(ref);
});

final cachedCommentsProvider = Provider.family<AsyncValue<List<Comment>>, String>((ref, key) {
  return ref.watch(commentCacheProvider)[key] ?? const AsyncValue.loading();
});

final taskDetailProvider = FutureProvider.family<Task?, String>((ref, projectId) async {
  final repo = ref.read(taskRepositoryProvider);
  try {
    return await repo.fetchTask(projectId, 1);
  } catch (e) {
    return null;
  }
});

// Sync
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final gitService = ref.read(authStateProvider).gitService;
  if (gitService == null) throw Exception('Not authenticated');
  return SyncRepository(gitService);
});

class SyncState {
  final bool isSyncing;
  final String? message;
  final bool hasConflicts;

  const SyncState({
    this.isSyncing = false,
    this.message,
    this.hasConflicts = false,
  });

  SyncState copyWith({
    bool? isSyncing,
    String? message,
    bool? hasConflicts,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      message: message ?? this.message,
      hasConflicts: hasConflicts ?? this.hasConflicts,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;

  SyncNotifier(this._ref) : super(const SyncState());

  Future<void> pull(String projectId) async {
    state = const SyncState(isSyncing: true, message: 'Pulling changes...');
    try {
      final repo = _ref.read(syncRepositoryProvider);
      final result = await repo.pull(projectId);
      state = SyncState(
        isSyncing: false,
        message: result.message,
        hasConflicts: result.conflicts?.isNotEmpty ?? false,
      );
    } catch (e) {
      state = SyncState(isSyncing: false, message: 'Pull failed: $e');
    }
  }

  Future<void> push(String projectId) async {
    state = const SyncState(isSyncing: true, message: 'Pushing changes...');
    try {
      final repo = _ref.read(syncRepositoryProvider);
      final result = await repo.push(projectId);
      state = SyncState(
        isSyncing: false,
        message: result.message,
        hasConflicts: result.conflicts?.isNotEmpty ?? false,
      );
    } catch (e) {
      state = SyncState(isSyncing: false, message: 'Push failed: $e');
    }
  }
}

final syncStateProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
