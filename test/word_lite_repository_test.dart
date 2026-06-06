import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_lite/data/word_bank.dart';
import 'package:word_lite/models/review_stage.dart';
import 'package:word_lite/models/session_checkpoint.dart';
import 'package:word_lite/models/word_entry.dart';
import 'package:word_lite/models/word_progress.dart';
import 'package:word_lite/services/word_lite_repository.dart';

/// 与 [WordLiteRepository] 持久化键保持一致，便于在测试中预置/读取 SharedPreferences。
const String _kProgress = 'wl_progress_v1';
const String _kCheckpoint = 'wl_checkpoint_v1';
const String _kEnergy = 'wl_energy_v1';
const String _kShards = 'wl_shards_v1';
const String _kTodayKey = 'wl_today_key_v1';
const String _kSessionDoneHome = 'wl_session_done_home_v1';
const String _kTodayDone = 'wl_today_done_v1';
const String _kYesterdayMastered = 'wl_yesterday_mastered_v1';
const String _kSkin = 'wl_skin_v1';
const String _kLastStudy = 'wl_last_study_v1';
const String _kStreak = 'wl_streak_v1';

String _dateKey(DateTime d) {
  final DateTime t = DateTime(d.year, d.month, d.day);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _readProgressJson(SharedPreferences prefs) {
  final String? raw = prefs.getString(_kProgress);
  if (raw == null || raw.isEmpty) {
    return <String, dynamic>{};
  }
  return jsonDecode(raw) as Map<String, dynamic>;
}

ReviewStage _stageForWord(Map<String, dynamic> progress, String wordId) {
  final Object? entry = progress[wordId];
  if (entry is! Map<String, dynamic>) {
    return ReviewStage.learning;
  }
  return ReviewStageCodec.fromName(entry['stage'] as String?);
}

DateTime? _nextReviewAtForWord(Map<String, dynamic> progress, String wordId) {
  final Object? entry = progress[wordId];
  if (entry is! Map<String, dynamic>) {
    return null;
  }
  final String? raw = entry['nextReviewAt'] as String?;
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    WordBank.resetForTest();
  });

  group('WordLiteRepository', () {
    test('init 后 isLoaded 为 true', () async {
      final WordLiteRepository repo = WordLiteRepository();
      expect(repo.isLoaded, isFalse);
      await repo.init();
      expect(repo.isLoaded, isTrue);
    });

    test('从 SharedPreferences 加载能量等业务状态', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kEnergy: 7,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.stats.energy, 7);
    });

    test('每日新词与复习上限常量', () {
      expect(WordLiteRepository.newWordsPerDay, 5);
      expect(WordLiteRepository.reviewMax, 8);
    });

    test('buildTodayQueue：无进度时仅包含最多 5 个新词（与词库顺序一致）', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final List<String> q = repo.buildTodayQueue();
      final List<String> expectedNew =
          WordBank.all.take(WordLiteRepository.newWordsPerDay).map((e) => e.id).toList();
      expect(q, expectedNew);
      expect(q.length, WordLiteRepository.newWordsPerDay);
    });

    test('buildTodayQueue：全词处于可复习的 learning 时复习段不超过 reviewMax', () async {
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in WordBank.all)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.learning,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final List<String> q = repo.buildTodayQueue();
      expect(q.length, lessThanOrEqualTo(WordLiteRepository.reviewMax));
      expect(q.length, WordBank.all.length <= WordLiteRepository.reviewMax
          ? WordBank.all.length
          : WordLiteRepository.reviewMax);
      for (final String id in q) {
        expect(WordBank.byId(id), isNotNull);
      }
    });

    test('todayQueuePreviewCounts：无进度时仅新词段', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final ({int newCount, int reviewCount, int total}) c =
          repo.todayQueuePreviewCounts;
      expect(c.newCount, WordLiteRepository.newWordsPerDay);
      expect(c.reviewCount, 0);
      expect(c.total, WordLiteRepository.newWordsPerDay);
    });

    test(
        'todayQueuePreviewCounts：当日检查点下 total 与拆分之和等于队列长度',
        () async {
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in WordBank.all)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.learning,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.startOrResumeSession();
      final List<String> q = repo.checkpoint!.queueWordIds;
      final ({int newCount, int reviewCount, int total}) c =
          repo.todayQueuePreviewCounts;
      expect(c.total, q.length);
      expect(c.newCount + c.reviewCount, c.total);
      expect(c.newCount, 0);
      expect(c.reviewCount, q.length);
    });

    test('todayQueuePreviewCounts：startOrResumeSession 后与无检查点一致',
        () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final ({int newCount, int reviewCount, int total}) before =
          repo.todayQueuePreviewCounts;
      await repo.startOrResumeSession();
      final ({int newCount, int reviewCount, int total}) after =
          repo.todayQueuePreviewCounts;
      expect(after.newCount, before.newCount);
      expect(after.reviewCount, before.reviewCount);
      expect(after.total, before.total);
      expect(repo.checkpoint?.queueWordIds.length, before.total);
    });

    test('buildTodayQueue：同一自然日内多次调用复习顺序一致', () async {
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in WordBank.all)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.learning,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final List<String> a = repo.buildTodayQueue();
      final List<String> b = repo.buildTodayQueue();
      expect(b, a);
    });

    test('答对四步后进度从 learning 进入 review_1（经持久化验证）', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.startOrResumeSession();
      expect(repo.currentWord(), isNotNull);
      final String wordId = repo.currentWord()!.id;
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.review_1);
      expect(repo.stats.energy, greaterThanOrEqualTo(1));
      expect(repo.stats.shards, 0);
    });

    test('多词队列仅完成首词时不发放碎片（整段会话未完成）', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.startOrResumeSession();
      expect(repo.checkpoint?.queueWordIds.length, greaterThan(1));
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.shards, 0);
      expect(repo.checkpoint, isNotNull);
    });

    test('整段会话完成后首页完成态为 true，重新开始后为 false', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.startOrResumeSession();
      final int n = repo.checkpoint!.queueWordIds.length;
      expect(n, greaterThan(1));
      for (int w = 0; w < n; w++) {
        for (int s = 0; s < 4; s++) {
          await repo.onStepCorrect();
        }
      }
      expect(repo.checkpoint, isNull);
      expect(repo.shouldShowHomeSessionCompleteCelebration, isTrue);
      final SharedPreferences pMid = await SharedPreferences.getInstance();
      expect(pMid.getBool(_kSessionDoneHome), isTrue);
      await repo.startOrResumeSession();
      expect(repo.shouldShowHomeSessionCompleteCelebration, isFalse);
      final SharedPreferences pAfter = await SharedPreferences.getInstance();
      expect(pAfter.getBool(_kSessionDoneHome), isFalse);
    });

    test('完成态为 true 时允许当日 buildTodayQueue 为空（词库已全部掌握）', () async {
      final String day = _dateKey(DateTime.now());
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in WordBank.all)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.mastered,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kTodayKey: day,
        _kSessionDoneHome: true,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.buildTodayQueue(), isEmpty);
      expect(repo.shouldShowHomeSessionCompleteCelebration, isTrue);
    });

    test('整段会话完成时发放碎片（单词队列即一次会话）', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.currentWord()?.id, wordId);
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.shards, WordLiteRepository.shardsPerSessionCompleted);
      expect(repo.checkpoint, isNull);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getInt(_kShards), WordLiteRepository.shardsPerSessionCompleted);
    });

    test('答错时从 review_3 回退到 review_1（经持久化验证）', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: WordProgress(
          wordId: wordId,
          stage: ReviewStage.review_3,
          nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.currentWord()?.id, wordId);
      await repo.onStepWrong();
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.review_1);
      final DateTime? nr = _nextReviewAtForWord(map, wordId);
      expect(nr, isNotNull);
      final DateTime n = DateTime.now();
      expect(nr!.year, n.year);
      expect(nr.month, n.month);
      expect(nr.day, n.day);
    });

    test('答对四步后 review_1 进阶 review_3 且 nextReviewAt 为通关日起 +3 自然日', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: WordProgress(
          wordId: wordId,
          stage: ReviewStage.review_1,
          nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.review_3);
      final DateTime? nr = _nextReviewAtForWord(map, wordId);
      expect(nr, isNotNull);
      final DateTime today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final DateTime want = today.add(const Duration(days: 3));
      expect(nr!.year, want.year);
      expect(nr.month, want.month);
      expect(nr.day, want.day);
    });

    test('答错时从 mastered 回退到 review_14（PRD 4.2.3 补充）', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.mastered,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.onStepWrong();
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.review_14);
      final DateTime? nr = _nextReviewAtForWord(map, wordId);
      expect(nr, isNotNull);
      final DateTime n = DateTime.now();
      expect(nr!.year, n.year);
      expect(nr.month, n.month);
      expect(nr.day, n.day);
    });

    test('答错回退后 review_* 的 nextReviewAt 为当日（未来日期不保留）', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final DateTime farFuture =
          DateTime.now().add(const Duration(days: 60));
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: WordProgress(
          wordId: wordId,
          stage: ReviewStage.review_7,
          nextReviewAt: farFuture,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.onStepWrong();
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.review_3);
      final DateTime? nr = _nextReviewAtForWord(map, wordId);
      expect(nr, isNotNull);
      final DateTime n = DateTime.now();
      expect(nr!.year, n.year);
      expect(nr.month, n.month);
      expect(nr.day, n.day);
    });

    test('答错回退到 learning 时 nextReviewAt 清空', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: WordProgress(
          wordId: wordId,
          stage: ReviewStage.review_1,
          nextReviewAt: DateTime.now(),
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      await repo.onStepWrong();
      final SharedPreferences p = await SharedPreferences.getInstance();
      final Map<String, dynamic> map = _readProgressJson(p);
      expect(_stageForWord(map, wordId), ReviewStage.learning);
      expect(_nextReviewAtForWord(map, wordId), isNull);
    });

    test('换日后今日完成数归零，昨日掌握快照更新为换日时的掌握数', () async {
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      final String yesterdayKey = _dateKey(yesterday);
      final List<WordEntry> masteredTwo = WordBank.all.take(2).toList();
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in masteredTwo)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.mastered,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kTodayKey: yesterdayKey,
        _kTodayDone: 99,
        _kYesterdayMastered: 0,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.stats.todayCompletedWords, 0);
      expect(repo.stats.totalMastered, 2);
      expect(repo.stats.yesterdayMasteredSnapshot, 2);
      expect(repo.stats.deltaVsYesterday, 0);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getInt(_kTodayDone), 0);
      expect(p.getInt(_kYesterdayMastered), 2);
    });

    test('整段会话完成时 9+1 碎片触发解锁一档皮肤并扣减碎片', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kShards: 9,
        _kSkin: 0,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.shards, 0);
      expect(repo.stats.unlockedSkinLevel, 1);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getInt(_kShards), 0);
      expect(p.getInt(_kSkin), 1);
    });

    test('皮肤档 4 阶梯（20 碎片）：预置 skin=3 + 19 碎片 → 整段会话+1 解锁 4 档', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kShards: 19,
        _kSkin: 3,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      // 19 + 1 = 20，4 档成本是 20 → 解锁后 shards 归 0
      expect(repo.stats.shards, 0);
      expect(repo.stats.unlockedSkinLevel, 4);
    });

    test('皮肤档已满 6 时不再扣减；碎片继续累计', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kShards: 50,
        _kSkin: WordLiteRepository.skinLevels, // 已满档
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      // 满档后 _tryUnlockSkin 不再处理；碎片 50+1=51
      expect(repo.stats.shards, 51);
      expect(repo.stats.unlockedSkinLevel, WordLiteRepository.skinLevels);
    });

    test('连续学习 ≥7 天每词额外 +1 能量（基础 1 + 加成 1 = 2）', () async {
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final String yesterdayKey = _dateKey(yesterday);
      final String todayKey = _dateKey(DateTime.now());
      const String wordId = 'w_apple';
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: todayKey,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.learning,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: todayKey,
        _kLastStudy: yesterdayKey,
        _kStreak: 6, // 完成一词后 streak 升至 7，触发 +1 加成
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      final int energyBefore = repo.stats.energy;
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 7);
      // 基础 +1 + 连续 ≥7 加成 +1 = +2
      expect(repo.stats.energy - energyBefore, 2);
    });

    test('连续学习 ≥21 天能量加成达 +3（基础 1 + 加成 3 = 4）', () async {
      final DateTime yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final String yesterdayKey = _dateKey(yesterday);
      final String todayKey = _dateKey(DateTime.now());
      const String wordId = 'w_apple';
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: todayKey,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.learning,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: todayKey,
        _kLastStudy: yesterdayKey,
        _kStreak: 20, // 完成后 21，命中 +3
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 21);
      expect(repo.stats.energy, 4);
    });

    test('勋章按累计 mastered 自动解锁：预置 50 个 mastered 即获学徒勋章',
        () async {
      // 用前 50 个内置/已加载词条造一个全 mastered 进度。
      WordBank.resetForTest();
      await WordBank.loadEmbeddedPacks();
      final List<WordEntry> first50 = WordBank.all.take(50).toList();
      final Map<String, dynamic> progressJson = <String, dynamic>{
        for (final WordEntry e in first50)
          e.id: WordProgress(
            wordId: e.id,
            stage: ReviewStage.mastered,
            nextReviewAt: null,
          ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.stats.totalMastered, 50);
      expect(repo.stats.unlockedBadges.length, 1);
      expect(repo.stats.unlockedBadges.first.label, '学徒');
      // 距下一勋章「学子」（阈值 200）还差 150 词
      expect(repo.stats.nextBadge?.label, '学子');
    });

    test('未达任何勋章时 unlockedBadges 为空，nextBadge 是学徒', () async {
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.stats.unlockedBadges, isEmpty);
      expect(repo.stats.nextBadge?.label, '学徒');
    });

    test('连续自然日学习：昨日 lastStudy 时完成一词 streak+1', () async {
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      final String yesterdayKey = _dateKey(yesterday);
      final String todayKey = _dateKey(DateTime.now());
      const String wordId = 'w_apple';
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: todayKey,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.learning,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: todayKey,
        _kLastStudy: yesterdayKey,
        _kStreak: 4,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.stats.streakDays, 4);
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 5);
      expect(repo.stats.lastStudyDateKey, todayKey);
    });

    test('同日完成第二词 streak 不递增', () async {
      final String todayKey = _dateKey(DateTime.now());
      final List<String> ids =
          WordBank.all.take(2).map((WordEntry e) => e.id).toList();
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: todayKey,
        queueWordIds: ids,
        wordIndex: 0,
        stepIndex: 0,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: todayKey,
        _kLastStudy: todayKey,
        _kStreak: 6,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 6);
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 6);
    });

    test('间隔超过一天再学 streak 重置为 1', () async {
      final DateTime fourDaysAgo =
          DateTime.now().subtract(const Duration(days: 4));
      final String oldKey = _dateKey(fourDaysAgo);
      final String todayKey = _dateKey(DateTime.now());
      const String wordId = 'w_apple';
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: todayKey,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 0,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.learning,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: todayKey,
        _kLastStudy: oldKey,
        _kStreak: 20,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      for (int i = 0; i < 4; i++) {
        await repo.onStepCorrect();
      }
      expect(repo.stats.streakDays, 1);
    });

    test('从 SharedPreferences 恢复当日检查点后可继续答对并结算', () async {
      const String wordId = 'w_apple';
      final String day = _dateKey(DateTime.now());
      final SessionCheckpoint cp = SessionCheckpoint(
        dayKey: day,
        queueWordIds: <String>[wordId],
        wordIndex: 0,
        stepIndex: 2,
      );
      final Map<String, dynamic> progressJson = <String, dynamic>{
        wordId: const WordProgress(
          wordId: wordId,
          stage: ReviewStage.learning,
          nextReviewAt: null,
        ).toJson(),
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        _kProgress: jsonEncode(progressJson),
        _kCheckpoint: jsonEncode(cp.toJson()),
        _kTodayKey: day,
      });
      final WordLiteRepository repo = WordLiteRepository();
      await repo.init();
      expect(repo.checkpoint?.stepIndex, 2);
      expect(repo.currentWord()?.id, wordId);
      await repo.onStepCorrect();
      expect(repo.checkpoint?.stepIndex, 3);
      await repo.onStepCorrect();
      expect(repo.checkpoint, isNull);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(_stageForWord(_readProgressJson(p), wordId), ReviewStage.review_1);
    });
  });
}
