import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_stats.dart';
import '../services/word_lite_repository.dart';
import 'learn_screen.dart';
import 'parent_screen.dart';

/// 首页：今日队列预览卡、统计、主学习入口与完成态（C）鼓励布局。
///
/// **「已完成 x / y」副文案**：仅当 [WordLiteRepository.hasActiveCheckpoint] 为 true
/// 时展示（与「当日检查点存在且队列为当日非空」等价）。无活动检查点时不展示该行，
/// 避免与「尚未开始今日会话」混淆。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordLiteRepository>(
      builder: (BuildContext context, WordLiteRepository r, _) {
        final bool hasCp = r.hasActiveCheckpoint;
        final bool celebrate = r.shouldShowHomeSessionCompleteCelebration;
        final UserStats s = r.stats;
        final ({int newCount, int reviewCount, int total}) counts =
            r.todayQueuePreviewCounts;

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

        final Widget queueRow = _QueuePreviewRow(counts: counts);
        final Widget statsCard = _HomeStatsCard(
          stats: s,
          emphasize: celebrate,
        );
        final String primaryLabel = hasCp ? '继续学习' : '开始学习';
        final IconData primaryIcon =
            hasCp ? Icons.play_arrow : Icons.school_outlined;

        final Widget? progressSubtitle = hasCp && r.checkpoint != null
            ? Text(
                '已完成 ${r.checkpoint!.wordIndex} / '
                '${r.checkpoint!.queueWordIds.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              )
            : null;

        final Widget learnButton = celebrate
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
        if (celebrate) {
          bodyChildren = <Widget>[
            statsCard,
            const SizedBox(height: 16),
            queueRow,
            const SizedBox(height: 20),
            learnButton,
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final bool? ok = await _confirmAbandon(context);
                if (ok == true) {
                  await r.abandonCheckpoint();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重置今日会话'),
            ),
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
            OutlinedButton.icon(
              onPressed: () async {
                final bool? ok = await _confirmAbandon(context);
                if (ok == true) {
                  await r.abandonCheckpoint();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重置今日会话'),
            ),
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

class _QueuePreviewRow extends StatelessWidget {
  const _QueuePreviewRow({required this.counts});

  final ({int newCount, int reviewCount, int total}) counts;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _CountInfoCard(
            title: '新词',
            value: counts.newCount,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CountInfoCard(
            title: '复习',
            value: counts.reviewCount,
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
