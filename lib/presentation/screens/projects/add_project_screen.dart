import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';

/// Screen for adding a new project by repository URL.
class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = _urlController.text.trim();
    String? ownerRepo;

    final patterns = [
      RegExp(r'github\.com/([^/]+)/([^/]+?)(?:\.git)?$'),
      RegExp(r'gitlab\.com/([^/]+)/([^/]+?)(?:\.git)?$'),
      RegExp(r'([^./]+)\.([^/]+)/(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 2) {
        ownerRepo = '${match.group(1)}/${match.group(2)}';
        break;
      }
    }

    if (ownerRepo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not parse repository URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    if (mounted) {
      ref.read(selectedProjectIdProvider.notifier).state = ownerRepo;
      context.go('/projects/$ownerRepo/tasks');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Repository URL',
                  hintText: 'https://github.com/owner/repo',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'URL is required';
                  if (!v.startsWith('http')) return 'Must start with http:// or https://';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addProject,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
