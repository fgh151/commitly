import 'package:flutter/material.dart';
import '../task/tag_chip.dart';

/// A card widget displaying task summary information.
class TaskCard extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final String? assignee;
  final List<String> tags;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    this.assignee,
    this.tags = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (tags.isNotEmpty || assignee != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (assignee != null)
                    Chip(
                      label: Text(
                        '@$assignee',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ...tags.take(3).map((tag) => TagChip(label: tag)),
                  if (tags.length > 3)
                    Chip(
                      label: Text(
                        '+${tags.length - 3}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

}
