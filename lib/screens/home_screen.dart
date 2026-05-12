import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_stats.dart';
import '../services/word_lite_repository.dart';
import 'learn_screen.dart';
import 'parent_screen.dart';

/// 首页：今日队列预览卡、统计、主学习入口与完成态（C）鼓励布局。
///
/// **进度副文案**
/// - 有当日活动检查点：`本会话：已完成 x / y`（本会话队列内进度）。
/// - 无活动检查点且非完成态：`进度：今日已通关 x / 计划 y 个词`（与统计卡
///   「今日完成」口径一致，避免放弃会话后出现 0/y 与今日完成数矛盾）。
/// - 完成态（C）：单独一行总结今日通关与本日计划词数。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WordLiteRepository, _HomeSlice>(
      selector: (_, WordLiteRepository r) => _HomeSlice.from(r),
      shouldRebuild: (_HomeSlice prev, _HomeSlice next) => prev != next,
      builder: (BuildContext context, _HomeSlice slice, _) {
        final WordLiteRepository r = context.read<WordLiteRepository>();
        final UserStats s = slice.stats;

        Future<void> startOrResumeStudy() async {
          await r.startOrResumeSession();
          if (!context.mounted) {
            return;
          }
          if (r.checkpoint == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('暂无可学单词（新词与复习都已清空）'),
              ),
            );
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext ctx) => const LearnScreen(),
            ),
          );
        }

        final Widget queueRow = _QueuePreviewRow(
          newCount: slice.newCount,
          reviewCount: slice.reviewCount,
        );
        final Widget statsCard = _HomeStatsCard(
          stats: s,
          emphasize: slice.celebrate,
        );

        final String primaryLabel;
        final IconData primaryIcon;
        if (slice.celebrate) {
          primaryLabel = '再学一组';
          primaryIcon = Icons.replay_outlined;
        } else {
          primaryLabel = slice.hasActiveCp ? '继续学习' : '开始学习';
          primaryIcon =
              slice.hasActiveCp ? Icons.play_arrow : Icons.school_outlined;
        }

        final Widget? progressSubtitle = _progressSubtitle(context, slice);

        final Widget learnButton = slice.celebrate
            ? OutlinedButton.icon(
                onPressed: startOrResumeStudy,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
              )
            : FilledButton.icon(
                onPressed: startOrResumeStudy,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
              );

        final List<Widget> bodyChildren;
        if (slice.celebrate) {
          bodyChildren = <Widget>[
            statsCard,
            const SizedBox(height: 16),
            queueRow,
            if (progressSubtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              progressSubtitle,
            ],
            const SizedBox(height: 20),
            learnButton,
            const SizedBox(height: 12),
            const _AbandonSessionButton(),
          ];
        } else {
          bodyChildren = <Widget>[
            queueRow,
            const SizedBox(height: 16),
            statsCard,
            const SizedBox(height: 20),
            learnButton,
            if (progressSubtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              progressSubtitle,
            ],
            const SizedBox(height: 12),
            const _AbandonSessionButton(),
          ];
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('WordLite'),
            actions: <Widget>[
              IconButton(
                tooltip: '家长',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext ctx) => const ParentScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.family_restroom_outlined),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...bodyChildren,
                const Spacer(),
                Text(
                  '提示：每天约 5 分钟，完成四步即可推进记忆。',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget? _progressSubtitle(BuildContext context, _HomeSlice slice) {
  final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
  if (slice.celebrate) {
    return Text(
      '今日已通关 ${slice.stats.todayCompletedWords} 词 · '
      '本日计划共 ${slice.queueTotal} 个词',
      style: style,
      textAlign: TextAlign.center,
    );
  }
  if (slice.hasActiveCp) {
    return Text(
      '本会话：已完成 ${slice.cpWordIndex} / ${slice.cpQueueLen}',
      style: style,
      textAlign: TextAlign.center,
    );
  }
  return Text(
    '进度：今日已通关 ${slice.stats.todayCompletedWords} / '
    '计划 ${slice.queueTotal} 个词',
    style: style,
    textAlign: TextAlign.center,
  );
}

Future<bool?> _confirmAbandon(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('放弃当前进度？'),
        content: const Text(
          '将清除未完成的会话，下次会重新生成队列。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('放弃'),
          ),
        ],
      );
    },
  );
}

class _AbandonSessionButton extends StatelessWidget {
  const _AbandonSessionButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final bool? ok = await _confirmAbandon(context);
        if (ok == true && context.mounted) {
          await context.read<WordLiteRepository>().abandonCheckpoint();
        }
      },
      icon: const Icon(Icons.refresh),
      label: const Text('重置今日会话'),
    );
  }
}

/// 供 [Selector] 比较；仅包含影响首页重建的字段。
class _HomeSlice {
  const _HomeSlice({
    required this.hasActiveCp,
    required this.celebrate,
    required this.stats,
    required this.newCount,
    required this.reviewCount,
    required this.queueTotal,
    required this.cpWordIndex,
    required this.cpQueueLen,
  });

  factory _HomeSlice.from(WordLiteRepository r) {
    final UserStats st = r.stats;
    final ({int newCount, int reviewCount, int total}) c =
        r.todayQueuePreviewCounts;
    int cpWordIndex = 0;
    int cpQueueLen = 0;
    if (r.hasActiveCheckpoint && r.checkpoint != null) {
      cpWordIndex = r.checkpoint!.wordIndex;
      cpQueueLen = r.checkpoint!.queueWordIds.length;
    }
    return _HomeSlice(
      hasActiveCp: r.hasActiveCheckpoint,
      celebrate: r.shouldShowHomeSessionCompleteCelebration,
      stats: st,
      newCount: c.newCount,
      reviewCount: c.reviewCount,
      queueTotal: c.total,
      cpWordIndex: cpWordIndex,
      cpQueueLen: cpQueueLen,
    );
  }

  final bool hasActiveCp;
  final bool celebrate;
  final UserStats stats;
  final int newCount;
  final int reviewCount;
  final int queueTotal;
  final int cpWordIndex;
  final int cpQueueLen;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _HomeSlice &&
        other.hasActiveCp == hasActiveCp &&
        other.celebrate == celebrate &&
        other.stats.energy == stats.energy &&
        other.stats.shards == stats.shards &&
        other.stats.unlockedSkinLevel == stats.unlockedSkinLevel &&
        other.stats.totalMastered == stats.totalMastered &&
        other.stats.streakDays == stats.streakDays &&
        other.stats.lastStudyDateKey == stats.lastStudyDateKey &&
        other.stats.todayCompletedWords == stats.todayCompletedWords &&
        other.stats.yesterdayMasteredSnapshot ==
            stats.yesterdayMasteredSnapshot &&
        other.newCount == newCount &&
        other.reviewCount == reviewCount &&
        other.queueTotal == queueTotal &&
        other.cpWordIndex == cpWordIndex &&
        other.cpQueueLen == cpQueueLen;
  }

  @override
  int get hashCode => Object.hash(
        hasActiveCp,
        celebrate,
        stats.energy,
        stats.shards,
        stats.unlockedSkinLevel,
        stats.totalMastered,
        stats.streakDays,
        stats.lastStudyDateKey,
        stats.todayCompletedWords,
        stats.yesterdayMasteredSnapshot,
        newCount,
        reviewCount,
        queueTotal,
        cpWordIndex,
        cpQueueLen,
      );
}

class _QueuePreviewRow extends StatelessWidget {
  const _QueuePreviewRow({
    required this.newCount,
    required this.reviewCount,
  });

  final int newCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _CountInfoCard(
            title: '新词',
            value: newCount,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CountInfoCard(
            title: '复习',
            value: reviewCount,
          ),
        ),
      ],
    );
  }
}

class _CountInfoCard extends StatelessWidget {
  const _CountInfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStatsCard extends StatelessWidget {
  const _HomeStatsCard({
    required this.stats,
    required this.emphasize,
  });

  final UserStats stats;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      elevation: emphasize ? 3 : 1,
      color: emphasize
          ? Color.alphaBlend(
              scheme.primaryContainer.withValues(alpha: 0.35),
              scheme.surface,
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(emphasize ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (emphasize) ...<Widget>[
              Text(
                '今日成就',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '今天的学习任务都完成啦，继续保持！',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ] else ...<Widget>[
              Text(
                '今日进度',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '今日完成：${stats.todayCompletedWords} 个词',
              style: emphasize
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '能量 ${stats.energy} · 碎片 ${stats.shards} · '
              '连续 ${stats.streakDays} 天',
              style: emphasize
                  ? theme.textTheme.bodyLarge
                  : theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '碎片在完成今日全部单词后获得',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
