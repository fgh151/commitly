import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';
import 'markdown_editor.dart';

/// A markdown editor for adding comments to a task.
class CommentEditor extends ConsumerStatefulWidget {
  final String projectId;
  final int taskNumber;
  final VoidCallback onSent;

  const CommentEditor({
    super.key,
    required this.projectId,
    required this.taskNumber,
    required this.onSent,
  });

  @override
  ConsumerState<CommentEditor> createState() => _CommentEditorState();
}

class _CommentEditorState extends ConsumerState<CommentEditor> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      // Get current user's name from auth state
      final authState = ref.read(authStateProvider);
      final userName = authState.currentUserName ?? 'user';

      final repo = ref.read(taskRepositoryProvider);
      await repo.addComment(
        widget.projectId,
        widget.taskNumber,
        text,
        userName,
      );
      if (mounted) {
        // Refresh comment cache
        await ref.read(commentCacheProvider.notifier).refresh(
          widget.projectId,
          widget.taskNumber,
        );
        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send comment: $e')),
        );
      }
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: MarkdownEditor(
              controller: _controller,
              placeholder: 'Write a comment (Markdown supported)...',
              height: 100,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
