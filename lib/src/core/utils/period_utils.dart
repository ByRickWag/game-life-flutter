class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  String get startIso => start.toIso8601String();
  String get endIso => end.toIso8601String();
}

class PeriodUtils {
  PeriodUtils._();

  static PeriodRange rangeForMissionType(String type, DateTime reference) {
    final local = DateTime(reference.year, reference.month, reference.day);

    switch (type) {
      case 'weekly':
        final start = local.subtract(Duration(days: local.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return PeriodRange(start: start, end: end);
      case 'monthly':
        final start = DateTime(local.year, local.month, 1);
        final end = DateTime(local.year, local.month + 1, 1);
        return PeriodRange(start: start, end: end);
      case 'special':
        return PeriodRange(
          start: DateTime(2000, 1, 1),
          end: DateTime(2100, 1, 1),
        );
      case 'daily':
      default:
        final start = local;
        final end = start.add(const Duration(days: 1));
        return PeriodRange(start: start, end: end);
    }
  }
}
