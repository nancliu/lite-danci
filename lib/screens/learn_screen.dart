import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

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
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final WordLiteRepository r = context.read<WordLiteRepository>();
      if (r.checkpoint == null) {
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _initTts() async {
    _tts.setErrorHandler((dynamic message) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('朗读失败：$message')),
      );
    });

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);

    final String tag = await _pickEnglishLanguageTag();
    final dynamic langOk = await _tts.setLanguage(tag);
    if (langOk != 1 && kDebugMode) {
      debugPrint('WordLite TTS: setLanguage("$tag") returned $langOk');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _ttsReady = true;
    });
  }

  /// 优先 en-US，否则在设备已安装的语言中选首个英语变体。
  Future<String> _pickEnglishLanguageTag() async {
    const List<String> preferred = <String>[
      'en-US',
      'en-GB',
      'en-AU',
      'en-IN',
      'en',
    ];
    try {
      final dynamic raw = await _tts.getLanguages;
      if (raw is! List) {
        return 'en-US';
      }
      final Set<String> tags = raw.map((dynamic e) => e.toString()).toSet();
      for (final String p in preferred) {
        if (tags.contains(p)) {
          return p;
        }
      }
      for (final String t in tags) {
        if (t.toLowerCase().startsWith('en')) {
          return t;
        }
      }
    } on Object catch (_) {
      // 忽略枚举失败，回退默认标签。
    }
    return 'en-US';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
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
    await _tts.stop();
    // Android：speak 默认 focus=false 时不请求音频焦点，部分机型会无声或走错误音频路由。
    if (_isAndroid) {
      await _tts.speak(text, focus: true);
    } else {
      await _tts.speak(text);
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
