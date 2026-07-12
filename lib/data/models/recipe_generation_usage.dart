class RecipeGenerationUsage {
  const RecipeGenerationUsage({
    required this.utcDay,
    required this.count,
    required this.dailyLimit,
  });

  final String utcDay;
  final int count;
  final int dailyLimit;

  static String utcDayKeyNow() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  factory RecipeGenerationUsage.empty({required int dailyLimit}) {
    return RecipeGenerationUsage(
      utcDay: utcDayKeyNow(),
      count: 0,
      dailyLimit: dailyLimit,
    );
  }

  factory RecipeGenerationUsage.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    final rawLimit = json['dailyLimit'];
    return RecipeGenerationUsage(
      utcDay: json['utcDay']?.toString() ?? utcDayKeyNow(),
      count: rawCount is num ? rawCount.toInt() : 0,
      dailyLimit: rawLimit is num ? rawLimit.toInt() : 3,
    );
  }

  RecipeGenerationUsage copyWith({
    String? utcDay,
    int? count,
    int? dailyLimit,
  }) {
    return RecipeGenerationUsage(
      utcDay: utcDay ?? this.utcDay,
      count: count ?? this.count,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
