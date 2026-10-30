import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Toolbar button for markdown formatting.
class _MarkdownToolbarButton extends StatelessWidget {
  final IconData icon;
  final String before;
  final String after;
  final String label;
  final VoidCallback onTap;

  const _MarkdownToolbarButton({
    required this.icon,
    required this.before,
    required this.after,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// A WYSIWYG markdown editor with toolbar and live preview.
class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final double height;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.placeholder = 'Start writing...',
    this.height = 300,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  final FocusNode _focusNode = FocusNode();
  bool _showPreview = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _insertText(String before, String after) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final beforeText = text.substring(0, selection.start);
    final afterText = text.substring(selection.end);
    final selectedText = text.substring(selection.start, selection.end);

    widget.controller.text = '$beforeText$before$selectedText$after$afterText';
    widget.controller.selection = TextSelection(
      baseOffset: selection.start + before.length,
      extentOffset: selection.end + before.length,
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              _MarkdownToolbarButton(
                icon: Icons.format_bold,
                before: '**',
                after: '**',
                label: 'Bold',
                onTap: () => _insertText('**', '**'),
              ),
              _MarkdownToolbarButton(
                icon: Icons.format_italic,
                before: '_',
                after: '_',
                label: 'Italic',
                onTap: () => _insertText('_', '_'),
              ),
              _MarkdownToolbarButton(
                icon: Icons.format_strikethrough,
                before: '~~',
                after: '~~',
                label: 'Strikethrough',
                onTap: () => _insertText('~~', '~~'),
              ),
              const SizedBox(width: 8),
              _MarkdownToolbarButton(
                icon: Icons.title,
                before: '# ',
                after: '',
                label: 'Heading 1',
                onTap: () => _insertText('# ', ''),
              ),
              _MarkdownToolbarButton(
                icon: Icons.title,
                before: '## ',
                after: '',
                label: 'Heading 2',
                onTap: () => _insertText('## ', ''),
              ),
              _MarkdownToolbarButton(
                icon: Icons.title,
                before: '### ',
                after: '',
                label: 'Heading 3',
                onTap: () => _insertText('### ', ''),
              ),
              const SizedBox(width: 8),
              _MarkdownToolbarButton(
                icon: Icons.format_list_bulleted,
                before: '- ',
                after: '',
                label: 'Bullet list',
                onTap: () => _insertText('- ', ''),
              ),
              _MarkdownToolbarButton(
                icon: Icons.format_list_numbered,
                before: '1. ',
                after: '',
                label: 'Numbered list',
                onTap: () => _insertText('1. ', ''),
              ),
              const SizedBox(width: 8),
              _MarkdownToolbarButton(
                icon: Icons.format_quote,
                before: '> ',
                after: '',
                label: 'Quote',
                onTap: () => _insertText('> ', ''),
              ),
              _MarkdownToolbarButton(
                icon: Icons.code,
                before: '`',
                after: '`',
                label: 'Inline code',
                onTap: () => _insertText('`', '`'),
              ),
              _MarkdownToolbarButton(
                icon: Icons.link,
                before: '[',
                after: '](url)',
                label: 'Link',
                onTap: () => _insertText('[', '](url)'),
              ),
              const Spacer(),
              // Toggle preview
              IconButton(
                icon: Icon(
                  _showPreview ? Icons.edit : Icons.preview,
                  size: 18,
                ),
                onPressed: () => setState(() => _showPreview = !_showPreview),
                tooltip: _showPreview ? 'Edit' : 'Preview',
              ),
            ],
          ),
        ),
        // Editor or Preview
        Expanded(
          child: _showPreview
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Markdown(
                    data: widget.controller.text,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      blockquoteDecoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey, width: 4)),
                      ),
                    ),
                  ),
                )
              : TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 10,
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
        ),
      ],
    );
  }
}
