import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_lite/app_theme.dart';
import 'package:word_lite/data/word_bank.dart';
import 'package:word_lite/models/review_stage.dart';
import 'package:word_lite/models/word_entry.dart';
import 'package:word_lite/models/word_progress.dart';
import 'package:word_lite/screens/parent_screen.dart';
import 'package:word_lite/services/word_lite_repository.dart';

const String _kProgress = 'wl_progress_v1';
const String _kTodayKey = 'wl_today_key_v1';
const String _kTodayDone = 'wl_today_done_v1';
const String _kYesterdayMastered = 'wl_yesterday_mastered_v1';
const String _kLastStudy = 'wl_last_study_v1';
const String _kStreak = 'wl_streak_v1';

String _dateKey(DateTime d) {
  final DateTime t = DateTime(d.year, d.month, d.day);
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}

Future<WordLiteRepository> _repoFromPrefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final WordLiteRepository repo = WordLiteRepository();
  await repo.init();
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('家长观察页展示 §4.4 四维与 UserStats 一致', (WidgetTester tester) async {
    final String day = _dateKey(DateTime.now());
    final List<WordEntry> mastered = WordBank.all.take(3).toList();
    final Map<String, dynamic> progressJson = <String, dynamic>{
      for (final WordEntry e in mastered)
        e.id: WordProgress(
          wordId: e.id,
          stage: ReviewStage.mastered,
          nextReviewAt: null,
        ).toJson(),
    };
    final WordLiteRepository repo = await _repoFromPrefs(<String, Object>{
      _kProgress: jsonEncode(progressJson),
      _kTodayKey: day,
      _kTodayDone: 2,
      _kYesterdayMastered: 1,
      _kLastStudy: day,
      _kStreak: 7,
    });

    expect(repo.stats.todayCompletedWords, 2);
    expect(repo.stats.totalMastered, 3);
    expect(repo.stats.streakDays, 7);
    expect(repo.stats.deltaVsYesterday, 2);

    await tester.pumpWidget(
      ChangeNotifierProvider<WordLiteRepository>.value(
        value: repo,
        child: MaterialApp(
          theme: buildWordLiteTheme(repo.stats.unlockedSkinLevel),
          home: const ParentScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.text('2 个词'), findsOneWidget);
    expect(find.text('累计掌握'), findsOneWidget);
    expect(find.text('3 个'), findsOneWidget);
    expect(find.text('连续天数'), findsOneWidget);
    expect(find.text('7 天'), findsOneWidget);
    expect(find.text('比昨天提升'), findsOneWidget);
    expect(find.text('+2（掌握数）'), findsOneWidget);
  });
}
