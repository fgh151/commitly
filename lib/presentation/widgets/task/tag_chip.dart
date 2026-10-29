import 'package:flutter/material.dart';

/// A chip widget for displaying tags.
class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onRemove;

  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Theme.of(context).colorScheme.secondaryContainer;
    final textColor = Theme.of(context).colorScheme.onSecondaryContainer;

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11),
      ),
      backgroundColor: bgColor,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIcon: onRemove != null
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: onRemove,
    );
  }
}
