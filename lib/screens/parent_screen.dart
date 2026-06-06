import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge.dart';
import '../services/word_lite_repository.dart';

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordLiteRepository>(
      builder: (BuildContext context, WordLiteRepository r, _) {
        final s = r.stats;
        return Scaffold(
          appBar: AppBar(
            title: const Text('家长观察'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _InfoTile(
                title: '今日学习',
                value: '${s.todayCompletedWords} 个词',
                subtitle: '完成四步算完成 1 个词',
              ),
              _InfoTile(
                title: '累计掌握',
                value: '${s.totalMastered} 个',
                subtitle: '已进入 mastered 的单词数',
              ),
              _InfoTile(
                title: '连续天数',
                value: '${s.streakDays} 天',
                subtitle: s.lastStudyDateKey == null
                    ? '尚未开始学习'
                    : '最近学习日：${s.lastStudyDateKey}',
              ),
              _InfoTile(
                title: '比昨天提升',
                value: s.deltaVsYesterday >= 0
                    ? '+${s.deltaVsYesterday}（掌握数）'
                    : '${s.deltaVsYesterday}（掌握数）',
                subtitle: '对比昨日快照的累计掌握增量',
              ),
              const SizedBox(height: 12),
              _GrowthBadgeCard(
                unlocked: s.unlockedBadges,
                next: s.nextBadge,
                totalMastered: s.totalMastered,
              ),
              const SizedBox(height: 12),
              _RewardCard(
                energy: s.energy,
                shards: s.shards,
                unlockedSkinLevel: s.unlockedSkinLevel,
                streakBonus: s.streakEnergyBonus,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 「成长里程」卡 — 勋章 emoji + 距下一勋章进度。
class _GrowthBadgeCard extends StatelessWidget {
  const _GrowthBadgeCard({
    required this.unlocked,
    required this.next,
    required this.totalMastered,
  });

  final List<GrowthBadge> unlocked;
  final GrowthBadge? next;
  final int totalMastered;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final String progressLine;
    if (next == null) {
      progressLine = '恭喜！全部 ${GrowthBadge.values.length} 档勋章已收齐。';
    } else {
      final int remaining = next!.threshold - totalMastered;
      progressLine =
          '距 ${next!.emoji} ${next!.label} 还差 $remaining 词（${next!.threshold} 词解锁）';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('成长里程', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: GrowthBadge.values.map((GrowthBadge b) {
                final bool got = unlocked.contains(b);
                return Tooltip(
                  message: '${b.label}（满 ${b.threshold} 词）',
                  child: Opacity(
                    opacity: got ? 1.0 : 0.3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(b.emoji, style: const TextStyle(fontSize: 32)),
                        Text(
                          b.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: got
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight:
                                got ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              progressLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 奖励卡：能量、碎片、皮肤档进度。
class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.energy,
    required this.shards,
    required this.unlockedSkinLevel,
    required this.streakBonus,
  });

  final int energy;
  final int shards;
  final int unlockedSkinLevel;
  final int streakBonus;

  static const List<int> _skinCost = <int>[10, 10, 10, 20, 25, 30];

  String _skinProgressText() {
    if (unlockedSkinLevel >= WordLiteRepository.skinLevels) {
      return '已解锁全部 ${WordLiteRepository.skinLevels} 档主题色';
    }
    final int cost = _skinCost[unlockedSkinLevel];
    final int remaining = cost - shards;
    return '已解锁主题：$unlockedSkinLevel / ${WordLiteRepository.skinLevels}'
        '（距下档还需 $remaining 碎片）';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('奖励进度', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('能量：$energy'),
            if (streakBonus > 0)
              Text(
                '连续学习加成：每词额外 +$streakBonus 能量',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                '连续学习满 7 / 14 / 21 天可获得 +1 / +2 / +3 能量加成',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            Text('碎片：$shards'),
            Text(
              '碎片在完成今日全部单词后获得（每会话 +1）',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(_skinProgressText()),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
