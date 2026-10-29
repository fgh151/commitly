import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main application scaffold with bottom navigation bar.
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync_outlined),
            activeIcon: Icon(Icons.sync),
            label: 'Sync',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/projects');
              break;
            case 1:
              // Tasks requires a project ID — stay on current screen if none selected
              break;
            case 2:
              context.go('/sync');
              break;
          }
        },
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/projects') && !location.contains('/tasks')) {
      return 0;
    }
    if (location.contains('/tasks')) {
      return 1;
    }
    if (location == '/sync') {
      return 2;
    }
    return 0;
  }
}
