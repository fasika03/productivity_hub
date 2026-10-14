/// Formats a date as a 'YYYY-MM-DD' key, used to record and look up
/// which days a habit was completed on.
String habitDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The current streak length in days, counting backward from today.
/// If today isn't marked done yet, that alone doesn't break the streak —
/// counting simply starts from yesterday instead, so the streak only
/// actually resets once a full day is missed.
int currentStreak(Set<String> doneDates, DateTime now) {
  DateTime cursor = DateTime(now.year, now.month, now.day);
  if (!doneDates.contains(habitDateKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  int streak = 0;
  while (doneDates.contains(habitDateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The longest run of consecutive completed days ever recorded, scanning
/// the full history rather than just the current streak.
int bestStreak(Set<String> doneDates) {
  if (doneDates.isEmpty) return 0;
  final parsed = doneDates.map((k) {
    final parts = k.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }).toList()
    ..sort();

  int best = 1;
  int run = 1;
  for (int i = 1; i < parsed.length; i++) {
    final diff = parsed[i].difference(parsed[i - 1]).inDays;
    if (diff == 1) {
      run++;
    } else if (diff > 1) {
      run = 1;
    }
    if (run > best) best = run;
  }
  return best;
}

/// The last [n] calendar days, oldest first, ending today.
List<DateTime> lastNDays(int n, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
}
