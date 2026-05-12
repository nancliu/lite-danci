import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_bank.dart';
import '../models/review_stage.dart';
import '../models/session_checkpoint.dart';
import '../models/user_stats.dart';
import '../models/word_entry.dart';
import '../models/word_progress.dart';

/// 本地存储 + 业务规则（间隔重复、每日任务、奖励、统计）。
/// 碎片在「整段会话完成」时结算，见 [shardsPerSessionCompleted]。
class WordLiteRepository extends ChangeNotifier {
  WordLiteRepository();

  static const int newWordsPerDay = 5;
  static const int reviewMax = 8;
  /// 完成当日整段会话（队列内最后一词四步通关）时发放的碎片数。
  static const int shardsPerSessionCompleted = 1;
  static const int shardsPerSkin = 10;
  static const int skinLevels = 3;

  SharedPreferences? _prefs;
  Map<String, WordProgress> _progress = <String, WordProgress>{};
  SessionCheckpoint? _checkpoint;
  int _energy = 0;
  int _shards = 0;
  int _unlockedSkinLevel = 0;
  int _todayCompleted = 0;
  String? _todayKey;
  String? _lastStudyDateKey;
  int _streakDays = 0;
  int _yesterdayMasteredSnapshot = 0;
  /// 持久化：当日队列最后一词四步成功通关且检查点已清空后为 true。
  bool _sessionDoneHomeV1 = false;

  bool _loaded = false;

  bool get isLoaded => _loaded;

  UserStats get stats {
    final int mastered = _countMastered();
    return UserStats(
      energy: _energy,
      shards: _shards,
      unlockedSkinLevel: _unlockedSkinLevel,
      totalMastered: mastered,
      streakDays: _streakDays,
      lastStudyDateKey: _lastStudyDateKey,
      todayCompletedWords: _todayCompleted,
      yesterdayMasteredSnapshot: _yesterdayMasteredSnapshot,
    );
  }

  SessionCheckpoint? get checkpoint => _checkpoint;

  /// 今日是否已有未完成的会话检查点。
  bool get hasActiveCheckpoint {
    final String day = _dateKey(DateTime.now());
    final SessionCheckpoint? c = _checkpoint;
    return c != null && c.dayKey == day && c.queueWordIds.isNotEmpty;
  }

  /// 首页「整段会话刚完成」完成态（C）是否应展示。
  ///
  /// 仅在「当日队列最后一词四步成功通关」后置位 [_sessionDoneHomeV1]，故与
  /// 「暂无可学词」SnackBar 不冲突：会话已结束时队列可能因进度变为空，仍应
  /// 展示鼓励态；用户点「再学一组」后若仍无可学词，由 [startOrResumeSession]
  /// 走空队列分支提示。
  bool get shouldShowHomeSessionCompleteCelebration {
    return _sessionDoneHomeV1 && !hasActiveCheckpoint;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromPrefs();
    _rollDailyIfNeeded();
    _loaded = true;
    notifyListeners();
  }

  /// 将当前内存状态写入磁盘（切后台等场景下尽量保留学习检查点）。
  Future<void> persistSnapshot() async {
    if (!_loaded || _prefs == null) {
      return;
    }
    await _persist();
  }

  Future<void> _loadFromPrefs() async {
    final SharedPreferences p = _prefs!;
    final String? raw = p.getString(_kProgress);
    if (raw != null && raw.isNotEmpty) {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      _progress = map.map((String k, dynamic v) {
        return MapEntry(k, WordProgress.fromJson(v as Map<String, dynamic>));
      });
    }
    final String? cp = p.getString(_kCheckpoint);
    if (cp != null && cp.isNotEmpty) {
      _checkpoint = SessionCheckpoint.fromJson(
        jsonDecode(cp) as Map<String, dynamic>,
      );
    }
    _energy = p.getInt(_kEnergy) ?? 0;
    _shards = p.getInt(_kShards) ?? 0;
    _unlockedSkinLevel = p.getInt(_kSkin) ?? 0;
    _todayCompleted = p.getInt(_kTodayDone) ?? 0;
    _todayKey = p.getString(_kTodayKey);
    final String? lastStudy = p.getString(_kLastStudy);
    _lastStudyDateKey =
        (lastStudy == null || lastStudy.isEmpty) ? null : lastStudy;
    _streakDays = p.getInt(_kStreak) ?? 0;
    _yesterdayMasteredSnapshot = p.getInt(_kYesterdayMastered) ?? 0;
    _sessionDoneHomeV1 = p.getBool(_kSessionDoneHome) ?? false;
  }

  void _rollDailyIfNeeded() {
    final String today = _dateKey(DateTime.now());
    if (_todayKey != today) {
      _todayKey = today;
      _todayCompleted = 0;
      _yesterdayMasteredSnapshot = _countMastered();
      _sessionDoneHomeV1 = false;
      _prefs?.setString(_kTodayKey, today);
      _prefs?.setInt(_kTodayDone, _todayCompleted);
      _prefs?.setInt(_kYesterdayMastered, _yesterdayMasteredSnapshot);
      _prefs?.setBool(_kSessionDoneHome, false);
    }
  }

  int _countMastered() {
    int n = 0;
    for (final WordProgress w in _progress.values) {
      if (w.stage == ReviewStage.mastered) {
        n++;
      }
    }
    return n;
  }

  Future<void> _persist() async {
    final SharedPreferences p = _prefs!;
    final Map<String, dynamic> map = _progress.map(
      (String k, WordProgress v) => MapEntry(k, v.toJson()),
    );
    await p.setString(_kProgress, jsonEncode(map));
    if (_checkpoint == null) {
      await p.remove(_kCheckpoint);
    } else {
      await p.setString(_kCheckpoint, jsonEncode(_checkpoint!.toJson()));
    }
    await p.setInt(_kEnergy, _energy);
    await p.setInt(_kShards, _shards);
    await p.setInt(_kSkin, _unlockedSkinLevel);
    await p.setInt(_kTodayDone, _todayCompleted);
    if (_todayKey != null) {
      await p.setString(_kTodayKey, _todayKey!);
    }
    await p.setInt(_kStreak, _streakDays);
    await p.setInt(_kYesterdayMastered, _yesterdayMasteredSnapshot);
    if (_lastStudyDateKey != null && _lastStudyDateKey!.isNotEmpty) {
      await p.setString(_kLastStudy, _lastStudyDateKey!);
    } else {
      await p.remove(_kLastStudy);
    }
    await p.setBool(_kSessionDoneHome, _sessionDoneHomeV1);
  }

  String _dateKey(DateTime d) {
    final DateTime t = DateTime(d.year, d.month, d.day);
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  DateTime _startOfDay(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  bool _isDue(WordProgress w, DateTime todayStart) {
    if (w.stage == ReviewStage.mastered) {
      return false;
    }
    if (w.nextReviewAt == null) {
      return w.stage == ReviewStage.learning;
    }
    return !_startOfDay(w.nextReviewAt!).isAfter(todayStart);
  }

  /// 今日队列中「新词段 / 复习段 / 总长」的只读预览。
  ///
  /// 有当日未空检查点时以 [SessionCheckpoint.queueWordIds] 为准；否则以
  /// [buildTodayQueue] 为准。新词段长度为「队列头部与 [_computeNewIdsForToday]
  /// 的最长等值前缀」长度（与 [buildTodayQueue] 拼接顺序一致）。
  ({int newCount, int reviewCount, int total}) get todayQueuePreviewCounts {
    _rollDailyIfNeeded();
    final String day = _dateKey(DateTime.now());
    final SessionCheckpoint? c = _checkpoint;
    final List<String> queue;
    if (c != null && c.dayKey == day && c.queueWordIds.isNotEmpty) {
      queue = c.queueWordIds;
    } else {
      queue = buildTodayQueue();
    }
    final List<String> newIds = _computeNewIdsForToday();
    int newCount = 0;
    while (newCount < newIds.length &&
        newCount < queue.length &&
        queue[newCount] == newIds[newCount]) {
      newCount++;
    }
    final int total = queue.length;
    final int reviewCount = total - newCount;
    return (
      newCount: newCount,
      reviewCount: reviewCount,
      total: total,
    );
  }

  List<String> _computeNewIdsForToday() {
    final List<String> newIds = <String>[];
    for (final WordEntry e in WordBank.all) {
      if (newIds.length >= newWordsPerDay) {
        break;
      }
      if (!_progress.containsKey(e.id)) {
        newIds.add(e.id);
      }
    }
    return newIds;
  }

  List<String> _computeReviewPickForToday() {
    final DateTime now = DateTime.now();
    final DateTime todayStart = _startOfDay(now);
    final List<String> dueIds = <String>[];
    for (final MapEntry<String, WordProgress> e in _progress.entries) {
      if (_isDue(e.value, todayStart)) {
        dueIds.add(e.key);
      }
    }
    final int shuffleSeed = todayStart.millisecondsSinceEpoch;
    dueIds.shuffle(Random(shuffleSeed));
    final int take = min(reviewMax, dueIds.length);
    return dueIds.take(take).toList();
  }

  /// 生成今日学习队列：新词至多 [newWordsPerDay]；复习为当日到期词随机抽取，至多 [reviewMax] 个（不硬凑条数）。
  List<String> buildTodayQueue() {
    _rollDailyIfNeeded();
    final List<String> newIds = _computeNewIdsForToday();
    final List<String> reviewPick = _computeReviewPickForToday();
    return <String>[...newIds, ...reviewPick];
  }

  Future<void> startOrResumeSession() async {
    _rollDailyIfNeeded();
    _sessionDoneHomeV1 = false;
    final String day = _dateKey(DateTime.now());
    if (_checkpoint != null &&
        _checkpoint!.dayKey == day &&
        _checkpoint!.queueWordIds.isNotEmpty) {
      await _persist();
      notifyListeners();
      return;
    }
    final List<String> q = buildTodayQueue();
    if (q.isEmpty) {
      _checkpoint = null;
      await _persist();
      notifyListeners();
      return;
    }
    _checkpoint = SessionCheckpoint(
      dayKey: day,
      queueWordIds: q,
      wordIndex: 0,
      stepIndex: 0,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> abandonCheckpoint() async {
    _checkpoint = null;
    _sessionDoneHomeV1 = false;
    await _persist();
    notifyListeners();
  }

  Future<void> saveProgress({
    required int wordIndex,
    required int stepIndex,
  }) async {
    final SessionCheckpoint? c = _checkpoint;
    if (c == null) {
      return;
    }
    _checkpoint = SessionCheckpoint(
      dayKey: c.dayKey,
      queueWordIds: c.queueWordIds,
      wordIndex: wordIndex,
      stepIndex: stepIndex,
    );
    await _persist();
    notifyListeners();
  }

  WordEntry? currentWord() {
    final SessionCheckpoint? c = _checkpoint;
    if (c == null || c.queueWordIds.isEmpty) {
      return null;
    }
    if (c.wordIndex < 0 || c.wordIndex >= c.queueWordIds.length) {
      return null;
    }
    return WordBank.byId(c.queueWordIds[c.wordIndex]);
  }

  /// 答对当前步骤：若完成该词四步，则结算 SRS 与奖励。
  Future<void> onStepCorrect() async {
    final SessionCheckpoint? c = _checkpoint;
    if (c == null) {
      return;
    }
    final int nextStep = c.stepIndex + 1;
    if (nextStep >= 4) {
      await _completeCurrentWord(success: true);
    } else {
      _checkpoint = SessionCheckpoint(
        dayKey: c.dayKey,
        queueWordIds: c.queueWordIds,
        wordIndex: c.wordIndex,
        stepIndex: nextStep,
      );
      await _persist();
    }
    notifyListeners();
  }

  /// 答错：按 PRD 回退阶段；仍停留在当前步骤直到答对。
  Future<void> onStepWrong() async {
    final WordEntry? w = currentWord();
    if (w == null) {
      return;
    }
    final WordProgress? existing = _progress[w.id];
    final ReviewStage base =
        existing?.stage ?? ReviewStage.learning;
    final ReviewStage rolled = _rollback(base);
    _progress[w.id] = WordProgress(
      wordId: w.id,
      stage: rolled,
      nextReviewAt: existing?.nextReviewAt,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _completeCurrentWord({required bool success}) async {
    final SessionCheckpoint? c = _checkpoint;
    if (c == null) {
      return;
    }
    final WordEntry? w = currentWord();
    if (w == null) {
      return;
    }
    if (success) {
      final WordProgress? before = _progress[w.id];
      final WordProgress next =
          _advanceAfterSuccess(w.id, before, DateTime.now());
      _progress[w.id] = next;
      _energy += 1;
      _todayCompleted += 1;
      _touchStreak();
      await _prefs?.setInt(_kTodayDone, _todayCompleted);
    }

    final int nextWordIndex = c.wordIndex + 1;
    if (nextWordIndex >= c.queueWordIds.length) {
      _checkpoint = null;
      if (success) {
        _shards += shardsPerSessionCompleted;
        _tryUnlockSkin();
        _sessionDoneHomeV1 = true;
      }
    } else {
      _checkpoint = SessionCheckpoint(
        dayKey: c.dayKey,
        queueWordIds: c.queueWordIds,
        wordIndex: nextWordIndex,
        stepIndex: 0,
      );
    }
    await _persist();
  }

  void _touchStreak() {
    final String today = _dateKey(DateTime.now());
    final String? last = _lastStudyDateKey;
    if (last == null || last.isEmpty) {
      _streakDays = 1;
    } else if (last == today) {
      // 同一天多次学习不重复增加。
      _streakDays = max(1, _streakDays);
    } else {
      final DateTime? lastD = _tryParseDay(last);
      final DateTime todayD = _startOfDay(DateTime.now());
      if (lastD != null) {
        final int diff = todayD.difference(_startOfDay(lastD)).inDays;
        if (diff == 1) {
          _streakDays += 1;
        } else {
          _streakDays = 1;
        }
      } else {
        _streakDays = 1;
      }
    }
    _lastStudyDateKey = today;
  }

  DateTime? _tryParseDay(String key) {
    final List<String> p = key.split('-');
    if (p.length != 3) {
      return null;
    }
    final int? y = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    final int? d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) {
      return null;
    }
    return DateTime(y, m, d);
  }

  void _tryUnlockSkin() {
    while (_unlockedSkinLevel < skinLevels && _shards >= shardsPerSkin) {
      _shards -= shardsPerSkin;
      _unlockedSkinLevel += 1;
    }
  }

  ReviewStage _rollback(ReviewStage s) {
    switch (s) {
      case ReviewStage.mastered:
        return ReviewStage.review_14;
      case ReviewStage.review_14:
        return ReviewStage.review_7;
      case ReviewStage.review_7:
        return ReviewStage.review_3;
      case ReviewStage.review_3:
        return ReviewStage.review_1;
      case ReviewStage.review_1:
      case ReviewStage.learning:
        return ReviewStage.learning;
    }
  }

  WordProgress _advanceAfterSuccess(
    String wordId,
    WordProgress? before,
    DateTime now,
  ) {
    final ReviewStage current = before?.stage ?? ReviewStage.learning;
    final ReviewStage nextStage = _nextStage(current);
    final DateTime? nextAt = _nextReviewTime(nextStage, now);
    return WordProgress(
      wordId: wordId,
      stage: nextStage,
      nextReviewAt: nextAt,
    );
  }

  ReviewStage _nextStage(ReviewStage s) {
    switch (s) {
      case ReviewStage.learning:
        return ReviewStage.review_1;
      case ReviewStage.review_1:
        return ReviewStage.review_3;
      case ReviewStage.review_3:
        return ReviewStage.review_7;
      case ReviewStage.review_7:
        return ReviewStage.review_14;
      case ReviewStage.review_14:
        return ReviewStage.mastered;
      case ReviewStage.mastered:
        return ReviewStage.mastered;
    }
  }

  DateTime? _nextReviewTime(ReviewStage stage, DateTime now) {
    final DateTime start = _startOfDay(now);
    switch (stage) {
      case ReviewStage.learning:
        return null;
      case ReviewStage.review_1:
        return start.add(const Duration(days: 1));
      case ReviewStage.review_3:
        return start.add(const Duration(days: 3));
      case ReviewStage.review_7:
        return start.add(const Duration(days: 7));
      case ReviewStage.review_14:
        return start.add(const Duration(days: 14));
      case ReviewStage.mastered:
        return null;
    }
  }

  static const String _kProgress = 'wl_progress_v1';
  static const String _kCheckpoint = 'wl_checkpoint_v1';
  static const String _kEnergy = 'wl_energy_v1';
  static const String _kShards = 'wl_shards_v1';
  static const String _kSkin = 'wl_skin_v1';
  static const String _kTodayDone = 'wl_today_done_v1';
  static const String _kTodayKey = 'wl_today_key_v1';
  static const String _kLastStudy = 'wl_last_study_v1';
  static const String _kStreak = 'wl_streak_v1';
  static const String _kYesterdayMastered = 'wl_yesterday_mastered_v1';
  static const String _kSessionDoneHome = 'wl_session_done_home_v1';
}
