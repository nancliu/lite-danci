import 'badge.dart';

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
    this.unlockedBadges = const <GrowthBadge>[],
  });

  final int energy;
  final int shards;

  /// 0..[WordLiteRepository.skinLevels] 表示已解锁皮肤档位。
  final int unlockedSkinLevel;

  final int totalMastered;
  final int streakDays;
  final String? lastStudyDateKey;

  /// 今日「完成单词」数（完成四步算 1）。
  final int todayCompletedWords;

  /// 昨日「累计掌握」快照（用于「比昨天提升」）。
  final int yesterdayMasteredSnapshot;

  /// 当前已达成的勋章（按 [totalMastered] 即时推导，按 enum 顺序）。
  final List<GrowthBadge> unlockedBadges;

  int get deltaVsYesterday => totalMastered - yesterdayMasteredSnapshot;

  /// 下一个未解锁的勋章；全部达成时为 null。
  GrowthBadge? get nextBadge {
    for (final GrowthBadge b in GrowthBadge.values) {
      if (!unlockedBadges.contains(b)) {
        return b;
      }
    }
    return null;
  }

  /// 连续学习对单词能量的额外加成（≥7 天 +1, ≥14 +2, ≥21 +3）。
  int get streakEnergyBonus {
    if (streakDays >= 21) return 3;
    if (streakDays >= 14) return 2;
    if (streakDays >= 7) return 1;
    return 0;
  }

  UserStats copyWith({
    int? energy,
    int? shards,
    int? unlockedSkinLevel,
    int? totalMastered,
    int? streakDays,
    String? lastStudyDateKey,
    int? todayCompletedWords,
    int? yesterdayMasteredSnapshot,
    List<GrowthBadge>? unlockedBadges,
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
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }
}
