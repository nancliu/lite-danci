/// 单日学习汇总（按自然日聚合的统计）。
///
/// 与 [UserStats] 不同：UserStats 是"当下"快照；DailyStats 是"某日"
/// 不变记录，用于家长页趋势图、错题分析、时段分布等长期视角。
///
/// 持久化在 [WordLiteRepository] 的 `wl_daily_stats_v1` 键里，
/// 序列化为 `Map<dayKey, DailyStats.toJson()>`。
class DailyStats {
  DailyStats({
    required this.dayKey,
    this.completedWords = 0,
    this.masteredDelta = 0,
    this.sessionsCompleted = 0,
    this.wrongCount = 0,
    this.morningCount = 0,
    this.afternoonCount = 0,
    this.eveningCount = 0,
  });

  /// 自然日键，格式 "YYYY-MM-DD"；与 [SessionCheckpoint.dayKey] 同源。
  final String dayKey;

  /// 当日通过四步通关的词数。
  int completedWords;

  /// 当日新进入 `mastered` 阶段的词数。
  int masteredDelta;

  /// 当日完成"整段会话"次数（最后一词四步通关计 1）。
  int sessionsCompleted;

  /// 当日累计答错次数（每一次 onStepWrong 触发 +1）。
  int wrongCount;

  /// 当日在 5:00-12:00 之间完成的词数。
  int morningCount;

  /// 当日在 12:00-18:00 之间完成的词数。
  int afternoonCount;

  /// 当日在 18:00-次日 5:00 之间完成的词数。
  int eveningCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayKey': dayKey,
      'completedWords': completedWords,
      'masteredDelta': masteredDelta,
      'sessionsCompleted': sessionsCompleted,
      'wrongCount': wrongCount,
      'morningCount': morningCount,
      'afternoonCount': afternoonCount,
      'eveningCount': eveningCount,
    };
  }

  /// 解析；缺字段按默认 0 处理（向后兼容旧记录）。
  static DailyStats fromJson(Map<String, dynamic> json) {
    return DailyStats(
      dayKey: json['dayKey'] as String? ?? '',
      completedWords: (json['completedWords'] as num?)?.toInt() ?? 0,
      masteredDelta: (json['masteredDelta'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      morningCount: (json['morningCount'] as num?)?.toInt() ?? 0,
      afternoonCount: (json['afternoonCount'] as num?)?.toInt() ?? 0,
      eveningCount: (json['eveningCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 一天内的时段划分（用于 [DailyStats] 三段计数）。
enum DayPeriod {
  morning,   // 5:00-12:00
  afternoon, // 12:00-18:00
  evening,   // 18:00-5:00 (含跨夜)
}

extension DayPeriodFromHour on DayPeriod {
  /// 给定 0-23 的小时返回对应时段。
  static DayPeriod fromHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return DayPeriod.morning;
    }
    if (hour >= 12 && hour < 18) {
      return DayPeriod.afternoon;
    }
    return DayPeriod.evening;
  }
}
