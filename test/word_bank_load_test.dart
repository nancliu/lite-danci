import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/data/word_bank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(WordBank.resetForTest);

  test('loadEmbeddedPacks 合并示例 JSON 词包', () async {
    WordBank.resetForTest();
    expect(WordBank.all.length, 20);
    await WordBank.loadEmbeddedPacks();
    expect(WordBank.all.length, 36);
    expect(WordBank.byId('ext_pen_001')?.word, 'pen');
    expect(WordBank.byId('ext_pen_001')?.gradeTag, '一年级');
  });
}
