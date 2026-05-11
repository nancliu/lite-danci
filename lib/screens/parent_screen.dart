import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '奖励进度',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('能量：${s.energy}'),
                      Text('碎片：${s.shards}（每 10 个可解锁一档主题色）'),
                      Text(
                        '碎片在完成今日全部单词后获得',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      Text('已解锁主题：${s.unlockedSkinLevel} / ${WordLiteRepository.skinLevels}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
