import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/data/word_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(WordBank.resetForTest);

  test('loadEmbeddedPacks 合并示例 JSON 词包', () async {
    WordBank.resetForTest();
    expect(WordBank.all.length, 20);
    await WordBank.loadEmbeddedPacks();
    // 20 内置 + 4 (extra_grade1_sample) + 12 (elementary_grade1_more)
    //   + 45×5 一~五年级 + 40 六年级 = 301
    expect(WordBank.all.length, 301);
    expect(WordBank.byId('ext_pen_001')?.word, 'pen');
    expect(WordBank.byId('ext_pen_001')?.gradeTag, '一年级');
    // 抽样验证新词包加载成功
    expect(WordBank.byId('g1_black')?.word, 'black');
    expect(WordBank.byId('g1_black')?.gradeTag, '一年级');
    expect(WordBank.byId('g6_peace')?.word, 'peace');
    expect(WordBank.byId('g6_peace')?.gradeTag, '六年级');
  });
}
