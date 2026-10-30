import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/auth/auth_selection_screen.dart';
import 'presentation/screens/auth/auth_form_screen.dart';
import 'presentation/screens/projects/project_list_screen.dart';
import 'presentation/screens/projects/add_project_screen.dart';
import 'presentation/screens/tasks/task_list_screen.dart';
import 'presentation/screens/tasks/task_detail_screen.dart';
import 'presentation/screens/sync/sync_status_screen.dart';
import 'presentation/widgets/common/app_scaffold.dart';
import 'presentation/providers/auth_providers.dart';
import 'data/models/git_service_config.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth',
  redirect: (context, state) {
    final ref = ProviderScope.containerOf(context, listen: false);
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final isAuthRoute = state.matchedLocation == '/auth' ||
        state.matchedLocation == '/auth/form';

    if (isAuthenticated && isAuthRoute) {
      return '/projects';
    }
    if (!isAuthenticated && !isAuthRoute) {
      return '/auth';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthSelectionScreen(),
      routes: [
        GoRoute(
          path: 'form',
          name: 'auth-form',
          builder: (context, state) {
            final serviceParam = state.uri.queryParameters['service'];
            final serviceType = serviceParam != null
                ? GitServiceType.values.firstWhere(
                    (e) => e.name == serviceParam,
                    orElse: () => GitServiceType.github,
                  )
                : GitServiceType.github;
            return AuthFormScreen(serviceType: serviceType);
          },
        ),
      ],
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/projects',
          name: 'projects',
          builder: (context, state) => const ProjectListScreen(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'add-project',
              builder: (context, state) => const AddProjectScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/projects/:projectId/tasks',
          name: 'task-list',
          builder: (context, state) => TaskListScreen(
            projectId: state.pathParameters['projectId']!,
          ),
          routes: [
            GoRoute(
              path: ':taskNumber',
              name: 'task-detail',
              builder: (context, state) => TaskDetailScreen(
                projectId: state.pathParameters['projectId']!,
                taskNumber: int.parse(state.pathParameters['taskNumber']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/sync',
          name: 'sync',
          builder: (context, state) => const SyncStatusScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const ErrorScreen(),
);

class CommitlyApp extends StatelessWidget {
  const CommitlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Commitly',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page not found')),
    );
  }
}
