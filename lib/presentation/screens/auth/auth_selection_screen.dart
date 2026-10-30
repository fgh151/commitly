import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

/// Screen for selecting a Git service to connect to.
class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authSelectionTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ServiceCard(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: l10n.authSelectionGitHubDesc,
              onTap: () => context.go('/auth/form?service=github'),
            ),
            const SizedBox(height: 16),
            _ServiceCard(
              icon: Icons.language,
              title: 'GitLab',
              subtitle: l10n.authSelectionGitLabDesc,
              onTap: () => context.go('/auth/form?service=gitlab'),
            ),
            const SizedBox(height: 16),
            _ServiceCard(
              icon: Icons.storage,
              title: 'Gitea',
              subtitle: l10n.authSelectionGiteaDesc,
              onTap: () => context.go('/auth/form?service=gitea'),
            ),
            const SizedBox(height: 16),
            _ServiceCard(
              icon: Icons.settings_input_component,
              title: l10n.authSelectionCustom,
              subtitle: l10n.authSelectionCustomDesc,
              onTap: () => context.go('/auth/form?service=custom'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
