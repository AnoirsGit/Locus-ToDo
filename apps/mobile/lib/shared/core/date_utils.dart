/// Calendar-date helpers based on LOCAL time — mirrors web's `shared/lib/date.ts`.
///
/// `DateTime.now()` and other non-UTC `DateTime`s already carry local
/// year/month/day fields, so `.toIso8601String().split('T')[0]` (used
/// throughout the app before this helper existed) happens to produce the
/// correct local calendar date on mobile — unlike JS's `Date.toISOString()`,
/// which always converts to UTC first (see web B1). Kept here anyway to dedup
/// the repeated `iso(DateTime d) => ...` closures across call sites and to
/// guard against ever calling this on a UTC `DateTime` by accident.
library;

String localIso(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String localToday() => localIso(DateTime.now());

/// Monday of the week containing [d] (local).
String weekStartISO(DateTime d) {
  final dow = d.weekday; // 1 = Monday .. 7 = Sunday
  return localIso(d.subtract(Duration(days: dow - 1)));
}

String monthStartISO(DateTime d) => localIso(DateTime(d.year, d.month, 1));

String yearStartISO(DateTime d) => '${d.year}-01-01';
