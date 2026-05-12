import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../data/word_bank.dart';
import '../models/word_entry.dart';
import '../services/word_lite_repository.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with WidgetsBindingObserver {
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const List<String> _stepTitles = <String>[
    '看图识词',
    '听音选词',
    '看词选图',
    '例句选择',
  ];

  /// Android 原生 TTS：`prepare` / `speak` / `stop` 在学习页使用；
  /// `getTtsEngines`、`openSystemTtsSettings` 等仍由插件实现，供日后「设置」页调用。
  static const MethodChannel _androidBuiltinTts =
      MethodChannel('com.wordlite.app/android_tts');

  FlutterTts? _tts;
  bool _ttsReady = false;
  /// Android：原生 `prepare` 是否已成功（与 [_ttsReady] 分离，按钮不依赖此项）。
  bool _androidTtsPrepared = false;

  String? _choiceKey;
  List<String>? _englishOptions;
  List<String>? _emojiOptions;
  List<String>? _meaningOptions;

  void _ensureChoices(WordEntry w, int step) {
    final String k = '${w.id}|$step';
    if (_choiceKey == k) {
      return;
    }
    _choiceKey = k;
    if (step <= 1) {
      _englishOptions = _buildEnglishChoices(w);
    } else if (step == 2) {
      _emojiOptions = _buildEmojiChoices(w);
    } else {
      _meaningOptions = _buildMeaningChoices(w);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_isAndroid) {
      _tts = FlutterTts();
    }
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (_isAndroid) {
        setState(() {
          _ttsReady = true;
        });
      }
      final WordLiteRepository r = context.read<WordLiteRepository>();
      if (r.checkpoint == null) {
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _initTts() async {
    if (_isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) {
        return;
      }
      bool ok = false;
      try {
        final dynamic raw = await _androidBuiltinTts
            .invokeMethod<dynamic>('prepare')
            .timeout(
              const Duration(seconds: 25),
              onTimeout: () {
                if (kDebugMode) {
                  debugPrint('WordLite TTS: prepare 超时');
                }
                return -2;
              },
            );
        ok = raw == 1;
        if (kDebugMode && !ok) {
          debugPrint('WordLite TTS: prepare 未成功 raw=$raw');
        }
      } on PlatformException catch (e) {
        if (kDebugMode) {
          debugPrint('WordLite TTS: prepare PlatformException $e');
        }
      } on Object catch (e) {
        if (kDebugMode) {
          debugPrint('WordLite TTS: prepare error $e');
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _androidTtsPrepared = ok;
      });
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '朗读引擎尚未连上，仍可点「播放读音」重试；或在系统设置里搜索「文字转语音」「无障碍」。',
            ),
          ),
        );
      }
      if (kDebugMode && !ok) {
        unawaited(_logAndroidTtsEnginesOnce());
      }
      return;
    }

    final FlutterTts tts = _tts!;
    tts.setErrorHandler((dynamic message) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('朗读失败：$message')),
      );
    });

    await tts.setVolume(1.0);
    await tts.setSpeechRate(0.45);
    try {
      await tts.setPitch(1.0);
    } on Object catch (_) {
      // 忽略。
    }

    if (kDebugMode) {
      tts.setStartHandler(() => debugPrint('WordLite TTS: onStart'));
      tts.setCompletionHandler(() => debugPrint('WordLite TTS: onComplete'));
    }

    final bool englishOk = await _configureEnglishTtsLanguage();
    if (!englishOk) {
      await _tryPickEnglishVoiceAfterLanguageFailed();
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _ttsReady = true;
    });
  }

  /// 调试：将 [getTtsEngines] 与当前默认包名打到日志。
  Future<void> _logAndroidTtsEnginesOnce() async {
    if (!_isAndroid) {
      return;
    }
    try {
      final dynamic engines = await _androidBuiltinTts.invokeMethod<dynamic>(
        'getTtsEngines',
      );
      final dynamic def = await _androidBuiltinTts.invokeMethod<dynamic>(
        'getDefaultTtsEnginePackage',
      );
      if (kDebugMode) {
        debugPrint('WordLite TTS: 系统已安装引擎 default=$def engines=$engines');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('WordLite TTS: getTtsEngines 日志失败 $e');
      }
    }
  }

  /// 在朗读前确保 Android 原生引擎已 [prepare]（可多次调用）。
  Future<void> _ensureAndroidTtsPrepared() async {
    if (!_isAndroid || _androidTtsPrepared) {
      return;
    }
    try {
      dynamic raw = await _androidBuiltinTts.invokeMethod<dynamic>('prepare').timeout(
        const Duration(seconds: 20),
        onTimeout: () => -2,
      );
      if (raw != 1 && raw != true) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        raw = await _androidBuiltinTts.invokeMethod<dynamic>('prepare').timeout(
          const Duration(seconds: 20),
          onTimeout: () => -2,
        );
      }
      if (!mounted) {
        return;
      }
      if (raw == 1 || raw == true) {
        setState(() {
          _androidTtsPrepared = true;
        });
      }
    } on PlatformException catch (e) {
      if (e.code == 'TTS_BUSY') {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        try {
          final dynamic raw2 = await _androidBuiltinTts
              .invokeMethod<dynamic>('prepare')
              .timeout(const Duration(seconds: 20), onTimeout: () => -2);
          if (mounted && (raw2 == 1 || raw2 == true)) {
            setState(() {
              _androidTtsPrepared = true;
            });
          }
        } on Object catch (_) {}
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('WordLite TTS: ensurePrepared $e');
      }
    }
  }

  /// 依次调用 [FlutterTts.setLanguage]，直到返回 1（成功）。
  ///
  /// 部分机型 [getLanguages] 含 `en-US`，但 [setLanguage] 仍返回 0（离线语音包未就绪等），
  /// 故不能仅凭列表选标签，必须实测返回值。
  Future<bool> _configureEnglishTtsLanguage() async {
    final FlutterTts tts = _tts!;
    final List<String> candidates = await _englishLanguageCandidates();
    for (final String tag in candidates) {
      final dynamic ok = await tts.setLanguage(tag);
      if (ok == 1) {
        if (kDebugMode) {
          debugPrint('WordLite TTS: setLanguage("$tag") ok');
        }
        return true;
      }
    }
    if (kDebugMode) {
      debugPrint(
        'WordLite TTS(flutter_tts): setLanguage 均未返回成功（已试 ${candidates.length} 个标签）。',
      );
    }
    return false;
  }

  /// 生成去重后的英语语言标签尝试顺序。
  ///
  /// **设备返回的 `en*` 优先**：与系统「文字转语音」里列出的语言更一致，再试固定 BCP47 标签。
  Future<List<String>> _englishLanguageCandidates() async {
    const List<String> preferred = <String>[
      'en-US',
      'en-GB',
      'en-AU',
      'en-IN',
      'en',
    ];
    final List<String> out = <String>[];
    void add(String t) {
      final String s = t.trim();
      if (s.isEmpty) {
        return;
      }
      if (!out.contains(s)) {
        out.add(s);
      }
      final String hyphen = s.replaceAll('_', '-');
      if (hyphen != s && !out.contains(hyphen)) {
        out.add(hyphen);
      }
      final String under = s.replaceAll('-', '_');
      if (under != s && !out.contains(under)) {
        out.add(under);
      }
    }

    try {
      final dynamic raw = await _tts!.getLanguages;
      if (raw is List) {
        final List<String> fromDevice = raw.map((dynamic e) => e.toString()).toList()
          ..sort();
        for (final String t in fromDevice) {
          if (t.toLowerCase().startsWith('en')) {
            add(t);
          }
        }
      }
    } on Object catch (_) {
      // 忽略。
    }

    for (final String p in preferred) {
      add(p);
    }
    return out;
  }

  /// 在 [setLanguage] 全部失败时，尝试从 [FlutterTts.getVoices] 中选一个 `en*` 声音。
  Future<void> _tryPickEnglishVoiceAfterLanguageFailed() async {
    try {
      final dynamic raw = await _tts!.getVoices;
      if (raw is! List) {
        return;
      }
      for (final dynamic item in raw) {
        if (item is! Map) {
          continue;
        }
        final Map<dynamic, dynamic> m = item;
        final String? loc = m['locale']?.toString();
        if (loc == null || !loc.toLowerCase().startsWith('en')) {
          continue;
        }
        final Map<String, String> voice = m.map(
          (dynamic k, dynamic v) => MapEntry(k.toString(), v.toString()),
        );
        final dynamic ok = await _tts!.setVoice(voice);
        if (kDebugMode) {
          debugPrint('WordLite TTS: setVoice fallback locale=$loc -> $ok');
        }
        return;
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('WordLite TTS: setVoice fallback skipped: $e');
      }
    }
  }

  /// Android：通过 [MethodChannel] 调用原生 [TextToSpeech] 朗读（与 iOS 的 [FlutterTts] 分离）。
  Future<int> _speakAndroidBuiltin(String text) async {
    try {
      final dynamic raw = await _androidBuiltinTts
          .invokeMethod<dynamic>('speak', <String, dynamic>{'text': text})
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              if (kDebugMode) {
                debugPrint('WordLite TTS: android_builtin speak 超时');
              }
              return -2;
            },
          );
      if (raw is int) {
        return raw;
      }
      if (raw == true) {
        return 1;
      }
      return int.tryParse('$raw') ?? 0;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('WordLite TTS: android_builtin PlatformException $e');
      }
      return -3;
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('WordLite TTS: android_builtin error $e');
      }
      return -3;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts?.stop();
    if (_isAndroid) {
      unawaited(_androidBuiltinTts.invokeMethod<void>('stop'));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused) {
      return;
    }
    if (!mounted) {
      return;
    }
    final WordLiteRepository repo = context.read<WordLiteRepository>();
    unawaited(repo.persistSnapshot());
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) {
      return;
    }
    if (_isAndroid) {
      await _ensureAndroidTtsPrepared();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } else {
      final FlutterTts tts = _tts!;
      await tts.stop();
    }

    if (_isAndroid) {
      final int r = await _speakAndroidBuiltin(text);
      if (kDebugMode && r != 1) {
        debugPrint('WordLite TTS: android_builtin -> $r text="$text"');
      }
      if (!mounted) {
        return;
      }
      if (r != 1) {
        final String msg = switch (r) {
          -2 => '朗读调用超时，请重试或重启应用',
          -3 => '朗读引擎未就绪，请稍后再试',
          _ => '系统无法朗读（请检查「文字转语音」是否含英语）',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } else {
      await _tts!.speak(text);
    }
  }

  List<String> _buildEnglishChoices(WordEntry correct) {
    final List<String> pool = WordBank.all
        .where((WordEntry e) => e.id != correct.id)
        .map((WordEntry e) => e.word)
        .toList();
    pool.shuffle(Random());
    final List<String> out = <String>[correct.word, ...pool.take(3)];
    out.shuffle(Random());
    return out;
  }

  List<String> _buildEmojiChoices(WordEntry correct) {
    final List<String> pool = WordBank.all
        .where((WordEntry e) => e.id != correct.id)
        .map((WordEntry e) => e.emoji)
        .toList();
    pool.shuffle(Random());
    final List<String> out = <String>[correct.emoji, ...pool.take(3)];
    out.shuffle(Random());
    return out;
  }

  List<String> _buildMeaningChoices(WordEntry correct) {
    final List<String> out = <String>[
      correct.meaningZh,
      ...correct.exampleWrongZh.take(3),
    ];
    out.shuffle(Random());
    return out;
  }

  Future<void> _onPick(
    BuildContext context,
    WordLiteRepository repo,
    bool isCorrect,
  ) async {
    if (!isCorrect) {
      await repo.onStepWrong();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('再想想～（记忆阶段已回退）')),
      );
      return;
    }
    await repo.onStepCorrect();
    if (!context.mounted) {
      return;
    }
    if (repo.checkpoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日学习完成，真棒！')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WordLiteRepository>(
      builder: (BuildContext context, WordLiteRepository repo, _) {
        final WordEntry? w = repo.currentWord();
        final cp = repo.checkpoint;
        if (w == null || cp == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final int step = cp.stepIndex.clamp(0, 3);
        final int total = cp.queueWordIds.length;
        final int idx = cp.wordIndex + 1;
        _ensureChoices(w, step);

        return Scaffold(
          appBar: AppBar(
            title: Text(_stepTitles[step]),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LinearProgressIndicator(
                  value: ((cp.wordIndex * 4 + step + 1) /
                          (total * 4).clamp(1, 999999))
                      .clamp(0.0, 1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  '第 $idx / $total 个词',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _StepBody(
                    step: step,
                    word: w,
                    ttsReady: _ttsReady,
                    onSpeak: _speak,
                    englishChoices: _englishOptions ?? _buildEnglishChoices(w),
                    emojiChoices: _emojiOptions ?? _buildEmojiChoices(w),
                    meaningChoices: _meaningOptions ?? _buildMeaningChoices(w),
                    onPick: (bool ok) => _onPick(context, repo, ok),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.word,
    required this.ttsReady,
    required this.onSpeak,
    required this.englishChoices,
    required this.emojiChoices,
    required this.meaningChoices,
    required this.onPick,
  });

  final int step;
  final WordEntry word;
  final bool ttsReady;
  final Future<void> Function(String text) onSpeak;
  final List<String> englishChoices;
  final List<String> emojiChoices;
  final List<String> meaningChoices;
  final Future<void> Function(bool isCorrect) onPick;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return _PictureStep(
          emoji: word.emoji,
          choices: englishChoices,
          correct: word.word,
          onPick: onPick,
        );
      case 1:
        return _ListenStep(
          word: word.word,
          ttsReady: ttsReady,
          onSpeak: onSpeak,
          choices: englishChoices,
          correct: word.word,
          onPick: onPick,
        );
      case 2:
        return _WordToPictureStep(
          word: word.word,
          choices: emojiChoices,
          correct: word.emoji,
          onPick: onPick,
        );
      default:
        return _SentenceStep(
          sentence: word.exampleEn,
          choices: meaningChoices,
          correct: word.meaningZh,
          onPick: onPick,
        );
    }
  }
}

class _PictureStep extends StatelessWidget {
  const _PictureStep({
    required this.emoji,
    required this.choices,
    required this.correct,
    required this.onPick,
  });

  final String emoji;
  final List<String> choices;
  final String correct;
  final Future<void> Function(bool isCorrect) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 96)),
          ),
        ),
        _ChoiceGrid(
          labels: choices,
          onTap: (String label) async {
            await onPick(label == correct);
          },
        ),
      ],
    );
  }
}

class _ListenStep extends StatelessWidget {
  const _ListenStep({
    required this.word,
    required this.ttsReady,
    required this.onSpeak,
    required this.choices,
    required this.correct,
    required this.onPick,
  });

  final String word;
  final bool ttsReady;
  final Future<void> Function(String text) onSpeak;
  final List<String> choices;
  final String correct;
  final Future<void> Function(bool isCorrect) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: ttsReady
              ? () async {
                  await onSpeak(word);
                }
              : null,
          icon: const Icon(Icons.volume_up),
          label: const Text('播放读音'),
        ),
        const SizedBox(height: 12),
        Text(
          '请选出你听到的单词',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        _ChoiceGrid(
          labels: choices,
          onTap: (String label) async {
            await onPick(label == correct);
          },
        ),
      ],
    );
  }
}

class _WordToPictureStep extends StatelessWidget {
  const _WordToPictureStep({
    required this.word,
    required this.choices,
    required this.correct,
    required this.onPick,
  });

  final String word;
  final List<String> choices;
  final String correct;
  final Future<void> Function(bool isCorrect) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          word,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        _EmojiChoiceGrid(
          emojis: choices,
          onTap: (String e) async {
            await onPick(e == correct);
          },
        ),
      ],
    );
  }
}

class _SentenceStep extends StatelessWidget {
  const _SentenceStep({
    required this.sentence,
    required this.choices,
    required this.correct,
    required this.onPick,
  });

  final String sentence;
  final List<String> choices;
  final String correct;
  final Future<void> Function(bool isCorrect) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              sentence,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const Spacer(),
        _ChoiceGrid(
          labels: choices,
          onTap: (String label) async {
            await onPick(label == correct);
          },
        ),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.labels,
    required this.onTap,
  });

  final List<String> labels;
  final Future<void> Function(String label) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: labels
          .map(
            (String s) => FilledButton(
              onPressed: () async {
                await onTap(s);
              },
              child: Text(
                s,
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmojiChoiceGrid extends StatelessWidget {
  const _EmojiChoiceGrid({
    required this.emojis,
    required this.onTap,
  });

  final List<String> emojis;
  final Future<void> Function(String emoji) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: emojis
          .map(
            (String s) => FilledButton(
              onPressed: () async {
                await onTap(s);
              },
              child: Text(s, style: const TextStyle(fontSize: 44)),
            ),
          )
          .toList(),
    );
  }
}
