/// How often a recurring transaction repeats. The [nextAfter] helper advances
/// a date by one interval, clamping the day-of-month for monthly/yearly so
/// e.g. the 31st rolls to the last valid day of shorter months.
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get storageValue => name;

  static RecurrenceFrequency fromStorage(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (RecurrenceFrequency f) => f.name == value,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }

  String get label => switch (this) {
        RecurrenceFrequency.daily => 'Daily',
        RecurrenceFrequency.weekly => 'Weekly',
        RecurrenceFrequency.monthly => 'Monthly',
        RecurrenceFrequency.yearly => 'Yearly',
      };

  /// The date one interval after [date].
  DateTime nextAfter(DateTime date) => switch (this) {
        RecurrenceFrequency.daily =>
          DateTime(date.year, date.month, date.day + 1),
        RecurrenceFrequency.weekly =>
          DateTime(date.year, date.month, date.day + 7),
        RecurrenceFrequency.monthly => _addMonths(date, 1),
        RecurrenceFrequency.yearly => _addMonths(date, 12),
      };

  static DateTime _addMonths(DateTime date, int months) {
    final int total = date.month - 1 + months;
    final int year = date.year + total ~/ 12;
    final int month = total % 12 + 1;
    final int lastDay = DateTime(year, month + 1, 0).day; // day 0 = prev month's last
    final int day = date.day < lastDay ? date.day : lastDay;
    return DateTime(year, month, day);
  }
}
