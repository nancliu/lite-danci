import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_lite/app_theme.dart';
import 'package:word_lite/data/word_bank.dart';
import 'package:word_lite/models/word_entry.dart';
import 'package:word_lite/models/session_checkpoint.dart';
import 'package:word_lite/screens/home_screen.dart';
import 'package:word_lite/services/word_lite_repository.dart';

const String _kCheckpoint = 'wl_checkpoint_v1';
const String _kTodayKey = 'wl_today_key_v1';
const String _kSessionDoneHome = 'wl_session_done_home_v1';

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

Widget _wrapHome(WordLiteRepository repo) {
  return ChangeNotifierProvider<WordLiteRepository>.value(
    value: repo,
    child: MaterialApp(
      theme: buildWordLiteTheme(repo.stats.unlockedSkinLevel),
      home: const HomeScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('有当日检查点时显示继续学习与已完成 x/y', (WidgetTester tester) async {
    final String day = _dateKey(DateTime.now());
    final List<String> ids =
        WordBank.all.take(2).map((WordEntry e) => e.id).toList();
    final WordLiteRepository repo = await _repoFromPrefs(<String, Object>{
      _kTodayKey: day,
      _kCheckpoint: jsonEncode(
        SessionCheckpoint(
          dayKey: day,
          queueWordIds: ids,
          wordIndex: 0,
          stepIndex: 0,
        ).toJson(),
      ),
    });

    await tester.pumpWidget(_wrapHome(repo));
    await tester.pump();

    expect(find.text('继续学习'), findsOneWidget);
    expect(find.text('已完成 0 / 2'), findsOneWidget);
  });

  testWidgets('完成态 C 下主入口为 OutlinedButton 且突出今日成就', (WidgetTester tester) async {
    final String day = _dateKey(DateTime.now());
    final WordLiteRepository repo = await _repoFromPrefs(<String, Object>{
      _kTodayKey: day,
      _kSessionDoneHome: true,
    });

    expect(repo.shouldShowHomeSessionCompleteCelebration, isTrue);

    await tester.pumpWidget(_wrapHome(repo));
    await tester.pump();

    expect(find.text('今日成就'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '开始学习'), findsOneWidget);
  });

  testWidgets('无检查点时主入口为开始学习 FilledButton', (WidgetTester tester) async {
    final WordLiteRepository repo = await _repoFromPrefs(<String, Object>{});

    await tester.pumpWidget(_wrapHome(repo));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, '开始学习'), findsOneWidget);
    expect(find.text('已完成'), findsNothing);
  });
}
