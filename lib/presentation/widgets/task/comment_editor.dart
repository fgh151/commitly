import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/auth_providers.dart';

/// A text field for adding comments to a task.
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
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.addComment(
        widget.projectId,
        widget.taskNumber,
        _controller.text.trim(),
        'user', // TODO: Get current user
      );
      if (mounted) {
        widget.onSent();
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }
}
