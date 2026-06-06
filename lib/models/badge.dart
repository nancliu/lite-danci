/// 成长勋章（按累计 mastered 词数自动解锁）。
///
/// 不持久化：阈值与 [WordLiteRepository.stats.totalMastered] 即时比较。
/// 与皮肤档不同：皮肤靠碎片消耗，需写入存档；勋章随掌握进度自动可见。
///
/// 命名加 `Growth` 前缀避免与 Flutter Material 自带的 [Badge] 冲突。
enum GrowthBadge {
  apprentice(label: '学徒', emoji: '🌱', threshold: 50),
  scholar(label: '学子', emoji: '📖', threshold: 200),
  master(label: '习长', emoji: '🎓', threshold: 500),
  sage(label: '词玄', emoji: '🏆', threshold: 750);

  const GrowthBadge({
    required this.label,
    required this.emoji,
    required this.threshold,
  });

  /// 中文显示名（如「学徒」）。
  final String label;

  /// 单字符 emoji。
  final String emoji;

  /// 解锁需要的累计 mastered 词数（含等于）。
  final int threshold;
}

extension GrowthBadgeUnlock on GrowthBadge {
  /// 给定累计掌握词数，是否已解锁。
  bool isUnlockedAt(int totalMastered) => totalMastered >= threshold;
}
