import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/services/git_service.dart';
import '../../data/services/git_service_factory.dart';
import '../../data/models/git_service_config.dart';
import '../../data/models/project.dart';

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
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.config,
    this.gitService,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    GitServiceConfig? config,
    GitService? gitService,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      config: config ?? this.config,
      gitService: gitService ?? this.gitService,
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
      final hasCreds = await repo.hasCredentials();
      if (hasCreds) {
        state = state.copyWith(status: AuthStatus.authenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
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

      state = state.copyWith(
        status: AuthStatus.authenticated,
        config: config,
        gitService: gitService,
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
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Projects
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final gitService = ref.read(authStateProvider).gitService;
  if (gitService == null) throw Exception('Not authenticated');
  return ProjectRepository(gitService);
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.read(projectRepositoryProvider);
  return repo.fetchProjects();
});

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

// Tasks
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final gitService = ref.read(authStateProvider).gitService;
  if (gitService == null) throw Exception('Not authenticated');
  return TaskRepository(gitService);
});

final tasksProvider = FutureProvider.family<List<dynamic>, String>((ref, projectId) async {
  final repo = ref.read(taskRepositoryProvider);
  return repo.fetchTasks(projectId);
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
