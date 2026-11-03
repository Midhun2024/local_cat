class DateTimeUtils {
  const DateTimeUtils._();

  /// Converts a DateTime to ISO 8601 string for SQLite storage.
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parses an ISO 8601 string or returns DateTime.now() if invalid.
  static DateTime parseIso8601(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  /// Formats a DateTime for user-friendly display (e.g., "2026-11-03 21:12").
  static String formatShortDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
