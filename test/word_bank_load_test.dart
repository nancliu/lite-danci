import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/data/word_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(WordBank.resetForTest);

  test('loadEmbeddedPacks 合并示例 JSON 词包', () async {
    WordBank.resetForTest();
    expect(WordBank.all.length, 20);
    await WordBank.loadEmbeddedPacks();
    // 20 内置 + 16 示例（4+12）+ 265 年级（45×5+40）+ 473 主题与短语 = 774
    expect(WordBank.all.length, 774);
    expect(WordBank.byId('ext_pen_001')?.word, 'pen');
    expect(WordBank.byId('ext_pen_001')?.gradeTag, '一年级');
    // 抽样验证年级词包
    expect(WordBank.byId('g1_black')?.word, 'black');
    expect(WordBank.byId('g1_black')?.gradeTag, '一年级');
    expect(WordBank.byId('g6_peace')?.word, 'peace');
    expect(WordBank.byId('g6_peace')?.gradeTag, '六年级');
    // 抽样验证通用主题词包
    expect(WordBank.byId('cal_monday')?.word, 'Monday');
    expect(WordBank.byId('cal_monday')?.gradeTag, '二年级');
    expect(WordBank.byId('clo_jeans')?.word, 'jeans');
    expect(WordBank.byId('clo_jeans')?.gradeTag, '三年级');
    // 抽样验证多词短语词包
    expect(WordBank.byId('act_get_up')?.word, 'get up');
    expect(WordBank.byId('act_get_up')?.gradeTag, '三年级');
    expect(WordBank.byId('ill_have_a_cold')?.word, 'have a cold');
    expect(WordBank.byId('ill_have_a_cold')?.gradeTag, '五年级');
  });
}
