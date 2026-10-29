import 'package:intl/intl.dart';

/// Utility for formatting dates.
class DateFormatter {
  DateFormatter._();

  /// Format as relative time: "2 hours ago", "3 days ago"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Format as short date: "Oct 29, 2026"
  static String formatShort(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format as full date: "October 29, 2026 at 14:30"
  static String formatFull(DateTime date) {
    return DateFormat('MMMM d, y \'at\' HH:mm').format(date);
  }

  /// Format as ISO 8601 string
  static String formatIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
