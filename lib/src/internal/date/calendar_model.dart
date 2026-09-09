/// Civil-date arithmetic shared by calendar rendering and keyboard navigation.
/// Constructing dates by year/month/day avoids skipping a day at DST changes.
abstract final class CalendarModel {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime monthOnly(DateTime value) =>
      DateTime(value.year, value.month);
  static bool sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime addDays(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);
  static DateTime addMonths(DateTime value, int months) {
    final first = DateTime(value.year, value.month + months);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, value.day.clamp(1, lastDay));
  }

  static DateTime clamp(DateTime value, DateTime? first, DateTime? last) {
    final date = dateOnly(value);
    if (first != null && date.isBefore(dateOnly(first))) return dateOnly(first);
    if (last != null && date.isAfter(dateOnly(last))) return dateOnly(last);
    return date;
  }

  static bool enabled(DateTime value, DateTime? first, DateTime? last) =>
      sameDate(value, clamp(value, first, last));
  static bool canShow(DateTime month, DateTime? first, DateTime? last) =>
      (first == null ||
          !DateTime(
            month.year,
            month.month + 1,
            0,
          ).isBefore(dateOnly(first))) &&
      (last == null || !monthOnly(month).isAfter(dateOnly(last)));
  static List<DateTime> days(DateTime month) {
    final first = monthOnly(month);
    final start = addDays(first, 1 - first.weekday);
    return List.generate(42, (index) => addDays(start, index));
  }
}
