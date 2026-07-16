/// Free-tier pantry scan weekly quota (aligned with backend `rate_limits.js`).
class PantryScanQuota {
  const PantryScanQuota({
    required this.utcWeek,
    required this.count,
    required this.weeklyLimit,
    required this.remaining,
  });

  final String utcWeek;
  final int count;
  final int weeklyLimit;
  final int remaining;

  /// ISO week key in UTC, e.g. `2026-W29` (Monday-based).
  static String utcWeekKeyNow([DateTime? now]) {
    final n = (now ?? DateTime.now()).toUtc();
    final date = DateTime.utc(n.year, n.month, n.day);
    // ISO: Thursday of this week determines the week-year.
    final dayNum = date.weekday; // Mon=1 … Sun=7
    final thursday = date.add(Duration(days: 4 - dayNum));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final weekNo = ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${weekNo.toString().padLeft(2, '0')}';
  }

  factory PantryScanQuota.empty({required int weeklyLimit}) {
    return PantryScanQuota(
      utcWeek: utcWeekKeyNow(),
      count: 0,
      weeklyLimit: weeklyLimit,
      remaining: weeklyLimit,
    );
  }

  factory PantryScanQuota.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    final rawLimit = json['weeklyLimit'];
    final limit = rawLimit is num ? rawLimit.toInt() : 2;
    final count = rawCount is num ? rawCount.toInt() : 0;
    final rawRemaining = json['remaining'];
    final remaining = rawRemaining is num
        ? rawRemaining.toInt()
        : (limit - count).clamp(0, limit);
    return PantryScanQuota(
      utcWeek: json['utcWeek']?.toString() ?? utcWeekKeyNow(),
      count: count,
      weeklyLimit: limit,
      remaining: remaining,
    );
  }

  PantryScanQuota copyWith({
    String? utcWeek,
    int? count,
    int? weeklyLimit,
    int? remaining,
  }) {
    final nextLimit = weeklyLimit ?? this.weeklyLimit;
    final nextCount = count ?? this.count;
    return PantryScanQuota(
      utcWeek: utcWeek ?? this.utcWeek,
      count: nextCount,
      weeklyLimit: nextLimit,
      remaining: remaining ?? (nextLimit - nextCount).clamp(0, nextLimit),
    );
  }
}
