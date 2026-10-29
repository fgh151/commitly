import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/git_service_config.dart';
import '../../../presentation/providers/auth_providers.dart';

/// Screen for entering connection details (URL + PAT).
class AuthFormScreen extends ConsumerStatefulWidget {
  final GitServiceType serviceType;

  const AuthFormScreen({super.key, required this.serviceType});

  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends ConsumerState<AuthFormScreen> {
  final _urlController = TextEditingController();
  final _patController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController.text = _getDefaultUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _patController.dispose();
    super.dispose();
  }

  String _getDefaultUrl() {
    switch (widget.serviceType) {
      case GitServiceType.github:
        return 'https://api.github.com';
      case GitServiceType.gitlab:
        return 'https://gitlab.com/api/v4';
      case GitServiceType.gitea:
        return 'https://gitea.example.com/api/v1';
      case GitServiceType.custom:
        return '';
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authStateProvider.notifier);
    await notifier.connect(_urlController.text, _patController.text);

    // React to state change
    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.authenticated) {
      if (mounted) context.go('/projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serviceType.name.capitalize} Connection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Error message
              if (authState.error != null &&
                  authState.status != AuthStatus.authenticated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _showErrorDetails(context, authState.error!),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close,
                                    size: 20, color: Colors.red.shade700),
                                onPressed: () {
                                  ref.invalidate(authStateProvider);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap for details • Check console logs',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.github.com',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'URL is required';
                  if (!v.startsWith('http')) {
                    return 'Must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Personal Access Token',
                  hintText: 'ghp_xxxxxxxxxxxx',
                  prefixIcon: Icon(Icons.key),
                  helperText:
                      'GitHub: Settings → Developer settings → Personal access tokens',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Token is required';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 GitHub PAT requires these scopes:\n'
                '• repo — full control of private repositories\n'
                '• workflow — manage GitHub Actions workflows',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authState.status == AuthStatus.authenticated
                      ? null
                      : _connect,
                  child: authState.status == AuthStatus.authenticated
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Connected'),
                          ],
                        )
                      : const Text('Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDetails(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connection Error'),
        content: SingleChildScrollView(
          child: SelectableText(
            'Error: $error\n\n'
            'Check the Flutter console for detailed logs.\n'
            'Common issues:\n'
            '• Firewall blocking the connection\n'
            '• Corporate proxy not configured\n'
            '• Invalid PAT (needs repo scope)\n'
            '• Network issues on macOS/iOS',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String get capitalize =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
