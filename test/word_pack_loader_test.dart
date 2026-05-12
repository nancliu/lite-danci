import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/data/word_pack_loader.dart';
import 'package:word_lite/models/word_entry.dart';

void main() {
  test('解析对象顶层 entries', () {
    const String json = '''
{"version":1,"entries":[
  {"id":"x1","word":"a","meaningZh":"一","emoji":"⭐","exampleEn":"A.","exampleClozeEn":"___ here.","exampleFillAnswer":"a","exampleFillWrongEn":["b","c","d"]}
]}''';
    final WordPackLoadResult r = WordPackLoader.parsePackJson(json);
    expect(r.entries, hasLength(1));
    expect(r.entries.single.id, 'x1');
    expect(r.parseErrors, isEmpty);
  });

  test('解析顶层数组', () {
    const String json = '''
[{"id":"x2","word":"b","meaningZh":"二","emoji":"🌟","exampleEn":"B.","exampleClozeEn":"___ there.","exampleFillAnswer":"b","exampleFillWrongEn":["c","d","e"]}]''';
    final WordPackLoadResult r = WordPackLoader.parsePackJson(json);
    expect(r.entries.single.id, 'x2');
  });

  test('缺 emoji 键时使用占位符', () {
    final String json = jsonEncode(<String, dynamic>{
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'x_no_emoji',
          'word': 'test',
          'meaningZh': '测',
          'exampleEn': 'A test.',
          'exampleClozeEn': 'A ___.',
          'exampleFillAnswer': 'test',
          'exampleFillWrongEn': <String>['best', 'rest', 'nest'],
        },
      ],
    });
    final WordPackLoadResult r = WordPackLoader.parsePackJson(json);
    expect(r.entries.single.emoji, WordEntry.missingEmojiPlaceholder);
    expect(r.parseErrors, isEmpty);
  });

  test('缺 ___ 时记入 parseErrors', () {
    final String json = jsonEncode(<String, dynamic>{
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'bad',
          'word': 'bad',
          'meaningZh': '错',
          'emoji': '❌',
          'exampleEn': 'Bad.',
          'exampleClozeEn': 'No placeholder here.',
          'exampleFillAnswer': 'bad',
          'exampleFillWrongEn': <String>['a', 'b', 'c'],
        },
      ],
    });
    final WordPackLoadResult r = WordPackLoader.parsePackJson(json);
    expect(r.entries, isEmpty);
    expect(r.parseErrors, isNotEmpty);
  });

  test('干扰项不足 3 条时报错', () {
    final String json = jsonEncode(<String, dynamic>{
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'bad2',
          'word': 'bad2',
          'meaningZh': '错',
          'emoji': '❌',
          'exampleEn': 'Bad.',
          'exampleClozeEn': '___ .',
          'exampleFillAnswer': 'bad2',
          'exampleFillWrongEn': <String>['a'],
        },
      ],
    });
    final WordPackLoadResult r = WordPackLoader.parsePackJson(json);
    expect(r.entries, isEmpty);
    expect(r.parseErrors, isNotEmpty);
  });

  test('与 reservedIds 重复时跳过', () {
    final String json = jsonEncode(<String, dynamic>{
      'entries': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'w_apple',
          'word': 'apple',
          'meaningZh': '苹果',
          'emoji': '🍎',
          'exampleEn': 'I eat an apple every day.',
          'exampleClozeEn': 'I eat an ___ every day.',
          'exampleFillAnswer': 'apple',
          'exampleFillWrongEn': <String>['apples', 'banana', 'orange'],
        },
        <String, dynamic>{
          'id': 'ext_only',
          'word': 'only',
          'meaningZh': '仅',
          'emoji': '1️⃣',
          'exampleEn': 'Only one.',
          'exampleClozeEn': '___ one.',
          'exampleFillAnswer': 'Only',
          'exampleFillWrongEn': <String>['One', 'Two', 'Three'],
        },
      ],
    });
    final WordPackLoadResult r = WordPackLoader.parsePackJson(
      json,
      reservedIds: <String>{'w_apple'},
    );
    expect(r.entries, hasLength(1));
    expect(r.entries.single.id, 'ext_only');
    expect(r.skippedDuplicateIds, contains('w_apple'));
  });
}
