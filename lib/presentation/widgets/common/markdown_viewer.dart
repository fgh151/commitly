import 'package:flutter/material.dart';

/// Widget for rendering and editing Markdown content.
class MarkdownViewer extends StatelessWidget {
  final String markdown;
  final bool editable;
  final ValueChanged<String>? onChanged;

  const MarkdownViewer({
    super.key,
    required this.markdown,
    this.editable = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (editable) {
      return TextField(
        maxLines: null,
        minLines: 10,
        decoration: const InputDecoration(
          hintText: 'Enter Markdown...',
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
        controller: TextEditingController(text: markdown),
      );
    }

    return SingleChildScrollView(
      child: SelectableText.rich(_parseMarkdown(markdown: markdown)),
    );
  }

  TextSpan _parseMarkdown({required String markdown}) {
    final lines = markdown.split('\n');
    final children = <InlineSpan>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        children.add(TextSpan(
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          text: line.substring(2),
        ));
      } else if (line.startsWith('## ')) {
        children.add(TextSpan(
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          text: line.substring(3),
        ));
      } else if (line.startsWith('### ')) {
        children.add(TextSpan(
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          text: line.substring(4),
        ));
      } else if (line.startsWith('- ')) {
        children.add(TextSpan(
          text: '• ${line.substring(2)}\n',
        ));
      } else if (line.isEmpty) {
        children.add(const TextSpan(text: '\n'));
      } else {
        children.add(TextSpan(text: '$line\n'));
      }
    }

    return TextSpan(children: children);
  }
}
