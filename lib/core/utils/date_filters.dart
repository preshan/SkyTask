/// Shared date helpers for list filters.
abstract final class DateFilters {
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isCreatedToday(DateTime createdAt, [DateTime? now]) {
    return isSameDay(createdAt, now ?? DateTime.now());
  }
}
