import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/models/daily_stats.dart';

void main() {
  group('DailyStats', () {
    test('默认构造所有计数为 0', () {
      final DailyStats s = DailyStats(dayKey: '2026-06-06');
      expect(s.dayKey, '2026-06-06');
      expect(s.completedWords, 0);
      expect(s.masteredDelta, 0);
      expect(s.sessionsCompleted, 0);
      expect(s.wrongCount, 0);
      expect(s.morningCount, 0);
      expect(s.afternoonCount, 0);
      expect(s.eveningCount, 0);
    });

    test('toJson + fromJson 往返保持所有字段', () {
      final DailyStats orig = DailyStats(
        dayKey: '2026-06-06',
        completedWords: 7,
        masteredDelta: 2,
        sessionsCompleted: 1,
        wrongCount: 3,
        morningCount: 2,
        afternoonCount: 3,
        eveningCount: 2,
      );
      final DailyStats round =
          DailyStats.fromJson(orig.toJson());
      expect(round.dayKey, orig.dayKey);
      expect(round.completedWords, orig.completedWords);
      expect(round.masteredDelta, orig.masteredDelta);
      expect(round.sessionsCompleted, orig.sessionsCompleted);
      expect(round.wrongCount, orig.wrongCount);
      expect(round.morningCount, orig.morningCount);
      expect(round.afternoonCount, orig.afternoonCount);
      expect(round.eveningCount, orig.eveningCount);
    });

    test('fromJson 缺字段时按 0 默认（向后兼容）', () {
      final DailyStats s = DailyStats.fromJson(<String, dynamic>{
        'dayKey': '2026-01-01',
        'completedWords': 5,
        // 其余字段缺失
      });
      expect(s.completedWords, 5);
      expect(s.masteredDelta, 0);
      expect(s.wrongCount, 0);
      expect(s.morningCount, 0);
    });
  });

  group('DayPeriodFromHour', () {
    test('小时映射到正确时段', () {
      expect(DayPeriodFromHour.fromHour(5), DayPeriod.morning);
      expect(DayPeriodFromHour.fromHour(11), DayPeriod.morning);
      expect(DayPeriodFromHour.fromHour(12), DayPeriod.afternoon);
      expect(DayPeriodFromHour.fromHour(17), DayPeriod.afternoon);
      expect(DayPeriodFromHour.fromHour(18), DayPeriod.evening);
      expect(DayPeriodFromHour.fromHour(23), DayPeriod.evening);
      expect(DayPeriodFromHour.fromHour(0), DayPeriod.evening);
      expect(DayPeriodFromHour.fromHour(4), DayPeriod.evening);
    });
  });
}
