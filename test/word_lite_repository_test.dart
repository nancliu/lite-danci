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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
  });
}
