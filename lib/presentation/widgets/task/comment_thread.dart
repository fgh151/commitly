import 'package:flutter/material.dart';

/// A scrollable list of comments for a task.
class CommentThread extends StatelessWidget {
  final String projectId;
  final int taskNumber;

  const CommentThread({
    super.key,
    required this.projectId,
    required this.taskNumber,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No comments yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
