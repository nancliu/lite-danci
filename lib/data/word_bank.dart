import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/word_entry.dart';
import 'word_pack_loader.dart';

/// 词库：内置词条 + 可选嵌入式 JSON 词包（离线）。
///
/// 启动时请先 `await WordBank.loadEmbeddedPacks()`，再初始化 [WordLiteRepository]。
class WordBank {
  WordBank._();

  /// 随应用打包、启动时依次加载并合并的 JSON 资源路径。
  static const List<String> embeddedPackAssetPaths = <String>[
    'assets/word_packs/extra_grade1_sample.json',
    'assets/word_packs/elementary_grade1_more.json',
  ];

  static final List<WordEntry> _builtInList = <WordEntry>[
    const WordEntry(
      id: 'w_apple',
      word: 'apple',
      meaningZh: '苹果',
      emoji: '🍎',
      exampleEn: 'I eat an apple every day.',
      exampleClozeEn: 'I eat an ___ every day.',
      exampleFillAnswer: 'apple',
      exampleFillWrongEn: <String>['apples', 'banana', 'orange'],
    ),
    const WordEntry(
      id: 'w_cat',
      word: 'cat',
      meaningZh: '猫',
      emoji: '🐱',
      exampleEn: 'The cat is sleeping.',
      exampleClozeEn: 'The ___ is sleeping.',
      exampleFillAnswer: 'cat',
      exampleFillWrongEn: <String>['cats', 'dog', 'bird'],
    ),
    const WordEntry(
      id: 'w_dog',
      word: 'dog',
      meaningZh: '狗',
      emoji: '🐶',
      exampleEn: 'My dog likes running.',
      exampleClozeEn: 'My ___ likes running.',
      exampleFillAnswer: 'dog',
      exampleFillWrongEn: <String>['dogs', 'cat', 'rabbit'],
    ),
    const WordEntry(
      id: 'w_book',
      word: 'book',
      meaningZh: '书',
      emoji: '📚',
      exampleEn: 'I read a book at night.',
      exampleClozeEn: 'I read a ___ at night.',
      exampleFillAnswer: 'book',
      exampleFillWrongEn: <String>['books', 'pen', 'paper'],
    ),
    const WordEntry(
      id: 'w_sun',
      word: 'sun',
      meaningZh: '太阳',
      emoji: '☀️',
      exampleEn: 'The sun is bright today.',
      exampleClozeEn: 'The ___ is bright today.',
      exampleFillAnswer: 'sun',
      exampleFillWrongEn: <String>['sunny', 'moon', 'cloud'],
    ),
    const WordEntry(
      id: 'w_moon',
      word: 'moon',
      meaningZh: '月亮',
      emoji: '🌙',
      exampleEn: 'The moon is round.',
      exampleClozeEn: 'The ___ is round.',
      exampleFillAnswer: 'moon',
      exampleFillWrongEn: <String>['moons', 'sun', 'star'],
    ),
    const WordEntry(
      id: 'w_water',
      word: 'water',
      meaningZh: '水',
      emoji: '💧',
      exampleEn: 'Please drink water.',
      exampleClozeEn: 'Please drink ___.',
      exampleFillAnswer: 'water',
      exampleFillWrongEn: <String>['milk', 'juice', 'tea'],
    ),
    const WordEntry(
      id: 'w_bird',
      word: 'bird',
      meaningZh: '鸟',
      emoji: '🐦',
      exampleEn: 'A bird is singing.',
      exampleClozeEn: 'A ___ is singing.',
      exampleFillAnswer: 'bird',
      exampleFillWrongEn: <String>['birds', 'fish', 'cat'],
    ),
    const WordEntry(
      id: 'w_fish',
      word: 'fish',
      meaningZh: '鱼',
      emoji: '🐟',
      exampleEn: 'Fish swim in the river.',
      exampleClozeEn: 'Many ___ live in the river.',
      exampleFillAnswer: 'fish',
      exampleFillWrongEn: <String>['cats', 'birds', 'frogs'],
    ),
    const WordEntry(
      id: 'w_tree',
      word: 'tree',
      meaningZh: '树',
      emoji: '🌳',
      exampleEn: 'The tree is tall.',
      exampleClozeEn: 'The ___ is very tall.',
      exampleFillAnswer: 'tree',
      exampleFillWrongEn: <String>['trees', 'flower', 'grass'],
    ),
    const WordEntry(
      id: 'w_car',
      word: 'car',
      meaningZh: '汽车',
      emoji: '🚗',
      exampleEn: 'My dad drives a car.',
      exampleClozeEn: 'My dad drives a ___.',
      exampleFillAnswer: 'car',
      exampleFillWrongEn: <String>['cars', 'bus', 'bike'],
    ),
    const WordEntry(
      id: 'w_ball',
      word: 'ball',
      meaningZh: '球',
      emoji: '⚽',
      exampleEn: 'We play with a ball.',
      exampleClozeEn: 'We play with a ___.',
      exampleFillAnswer: 'ball',
      exampleFillWrongEn: <String>['balls', 'kite', 'rope'],
    ),
    const WordEntry(
      id: 'w_star',
      word: 'star',
      meaningZh: '星星',
      emoji: '⭐',
      exampleEn: 'I see a star in the sky.',
      exampleClozeEn: 'I see a ___ in the sky.',
      exampleFillAnswer: 'star',
      exampleFillWrongEn: <String>['stars', 'moon', 'plane'],
    ),
    const WordEntry(
      id: 'w_rain',
      word: 'rain',
      meaningZh: '雨',
      emoji: '🌧️',
      exampleEn: 'It will rain tomorrow.',
      exampleClozeEn: 'It will ___ tomorrow.',
      exampleFillAnswer: 'rain',
      exampleFillWrongEn: <String>['snow', 'wind', 'hail'],
    ),
    const WordEntry(
      id: 'w_school',
      word: 'school',
      meaningZh: '学校',
      emoji: '🏫',
      exampleEn: 'I go to school on Monday.',
      exampleClozeEn: 'I go to ___ on Monday.',
      exampleFillAnswer: 'school',
      exampleFillWrongEn: <String>['park', 'shop', 'home'],
    ),
    const WordEntry(
      id: 'w_milk',
      word: 'milk',
      meaningZh: '牛奶',
      emoji: '🥛',
      exampleEn: 'I like milk in the morning.',
      exampleClozeEn: 'I like ___ in the morning.',
      exampleFillAnswer: 'milk',
      exampleFillWrongEn: <String>['water', 'juice', 'soup'],
    ),
    const WordEntry(
      id: 'w_egg',
      word: 'egg',
      meaningZh: '鸡蛋',
      emoji: '🥚',
      exampleEn: 'I eat an egg for breakfast.',
      exampleClozeEn: 'I eat an ___ for breakfast.',
      exampleFillAnswer: 'egg',
      exampleFillWrongEn: <String>['eggs', 'bread', 'rice'],
    ),
    const WordEntry(
      id: 'w_hand',
      word: 'hand',
      meaningZh: '手',
      emoji: '✋',
      exampleEn: 'Wash your hands before eating.',
      exampleClozeEn: 'Wash your ___ before eating.',
      exampleFillAnswer: 'hands',
      exampleFillWrongEn: <String>['hand', 'foot', 'head'],
    ),
    const WordEntry(
      id: 'w_heart',
      word: 'heart',
      meaningZh: '心',
      emoji: '❤️',
      exampleEn: 'Thank you from my heart.',
      exampleClozeEn: 'Thank you from my ___.',
      exampleFillAnswer: 'heart',
      exampleFillWrongEn: <String>['hearts', 'head', 'mind'],
    ),
    const WordEntry(
      id: 'w_happy',
      word: 'happy',
      meaningZh: '开心的',
      emoji: '😊',
      exampleEn: 'I feel happy today.',
      exampleClozeEn: 'I feel ___ today.',
      exampleFillAnswer: 'happy',
      exampleFillWrongEn: <String>['happier', 'sadly', 'angry'],
    ),
  ];

  static final List<WordEntry> _extraEntries = <WordEntry>[];
  static List<WordEntry> _allView =
      List<WordEntry>.unmodifiable(_builtInList);

  /// 合并内置与扩展后的只读列表（内置在前）。
  static List<WordEntry> get all => _allView;

  static void _rebuildAllView() {
    if (_extraEntries.isEmpty) {
      _allView = List<WordEntry>.unmodifiable(_builtInList);
    } else {
      _allView = List<WordEntry>.unmodifiable(
        <WordEntry>[..._builtInList, ..._extraEntries],
      );
    }
  }

  /// 从 [embeddedPackAssetPaths] 加载 JSON 并合并；失败时上报 Flutter 错误但不中断应用。
  static Future<void> loadEmbeddedPacks() async {
    _extraEntries.clear();
    final Set<String> reserved = <String>{
      for (final WordEntry e in _builtInList) e.id,
    };
    for (final String path in embeddedPackAssetPaths) {
      try {
        final String raw = await rootBundle.loadString(path);
        final WordPackLoadResult r = WordPackLoader.parsePackJson(
          raw,
          reservedIds: reserved,
        );
        for (final String msg in r.parseErrors) {
          debugPrint('WordPack $path: $msg');
        }
        for (final String id in r.skippedDuplicateIds) {
          debugPrint('WordPack $path: 跳过与内置重复的 id=$id');
        }
        for (final WordEntry e in r.entries) {
          _extraEntries.add(e);
          reserved.add(e.id);
        }
      } catch (e, st) {
        FlutterError.presentError(
          FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'WordBank.loadEmbeddedPacks',
            context: ErrorDescription('path=$path'),
          ),
        );
      }
    }
    _rebuildAllView();
  }

  /// 单测用：清空扩展词，恢复为仅内置列表。
  static void resetForTest() {
    _extraEntries.clear();
    _rebuildAllView();
  }

  static WordEntry? byId(String id) {
    for (final WordEntry e in all) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }
}
