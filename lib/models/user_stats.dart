/// 奖励与家长页统计。
class UserStats {
  const UserStats({
    required this.energy,
    required this.shards,
    required this.unlockedSkinLevel,
    required this.totalMastered,
    required this.streakDays,
    required this.lastStudyDateKey,
    required this.todayCompletedWords,
    required this.yesterdayMasteredSnapshot,
  });

  final int energy;
  final int shards;

  /// 0..3 表示已解锁皮肤档位。
  final int unlockedSkinLevel;

  final int totalMastered;
  final int streakDays;
  final String? lastStudyDateKey;

  /// 今日「完成单词」数（完成四步算 1）。
  final int todayCompletedWords;

  /// 昨日「累计掌握」快照（用于「比昨天提升」）。
  final int yesterdayMasteredSnapshot;

  int get deltaVsYesterday => totalMastered - yesterdayMasteredSnapshot;

  UserStats copyWith({
    int? energy,
    int? shards,
    int? unlockedSkinLevel,
    int? totalMastered,
    int? streakDays,
    String? lastStudyDateKey,
    int? todayCompletedWords,
    int? yesterdayMasteredSnapshot,
  }) {
    return UserStats(
      energy: energy ?? this.energy,
      shards: shards ?? this.shards,
      unlockedSkinLevel: unlockedSkinLevel ?? this.unlockedSkinLevel,
      totalMastered: totalMastered ?? this.totalMastered,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDateKey: lastStudyDateKey ?? this.lastStudyDateKey,
      todayCompletedWords: todayCompletedWords ?? this.todayCompletedWords,
      yesterdayMasteredSnapshot:
          yesterdayMasteredSnapshot ?? this.yesterdayMasteredSnapshot,
    );
  }
}
