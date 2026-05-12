import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/models/word_entry.dart';

void main() {
  test('JSON 省略 emoji 时使用占位符', () {
    final WordEntry r = WordEntry.fromJson(<String, dynamic>{
      'id': 't2',
      'word': 'run',
      'meaningZh': '跑',
      'exampleEn': 'I can run fast.',
      'exampleClozeEn': 'I can ___ fast.',
      'exampleFillAnswer': 'run',
      'exampleFillWrongEn': <String>['runs', 'walk', 'jump'],
    });
    expect(r.emoji, WordEntry.missingEmojiPlaceholder);
  });

  test('JSON 中 emoji 为空字符串时使用占位符', () {
    final WordEntry r = WordEntry.fromJson(<String, dynamic>{
      'id': 't3',
      'word': 'walk',
      'meaningZh': '走',
      'emoji': '   ',
      'exampleEn': 'We walk to school.',
      'exampleClozeEn': 'We ___ to school.',
      'exampleFillAnswer': 'walk',
      'exampleFillWrongEn': <String>['walks', 'run', 'talk'],
    });
    expect(r.emoji, WordEntry.missingEmojiPlaceholder);
  });

  test('WordEntry JSON 往返', () {
    const WordEntry w = WordEntry(
      id: 't1',
      word: 'hello',
      meaningZh: '你好',
      emoji: '👋',
      exampleEn: 'Say hello to me.',
      exampleClozeEn: 'Say ___ to me.',
      exampleFillAnswer: 'hello',
      exampleFillWrongEn: <String>['hi', 'hey', 'bye'],
      gradeTag: '二年级',
    );
    final WordEntry r = WordEntry.fromJson(w.toJson());
    expect(r.id, w.id);
    expect(r.word, w.word);
    expect(r.meaningZh, w.meaningZh);
    expect(r.emoji, w.emoji);
    expect(r.exampleEn, w.exampleEn);
    expect(r.exampleClozeEn, w.exampleClozeEn);
    expect(r.exampleFillAnswer, w.exampleFillAnswer);
    expect(r.exampleFillWrongEn, w.exampleFillWrongEn);
    expect(r.gradeTag, w.gradeTag);
  });
}
