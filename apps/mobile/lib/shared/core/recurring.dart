// Shared recurring-task formatting rules, kept identical to web `TaskCard`.

/// Sort weekday indices (0 = Sunday … 6 = Saturday) Mon-first, so Sunday sorts
/// last. Mirrors the web comparator `(a, b) => (a === 0 ? 7 : a) - (b === 0 ? 7 : b)`.
List<int> sortDaysMonFirst(Iterable<int> days) =>
    [...days]..sort((a, b) => (a == 0 ? 7 : a) - (b == 0 ? 7 : b));
