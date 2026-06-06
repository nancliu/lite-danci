import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/screens/widgets/cloze_rich_text.dart';

void main() {
  group('ClozeRichText', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: DefaultTextStyle(
            style: const TextStyle(fontSize: 16),
            child: child,
          ),
        ),
      );
    }

    testWidgets('未提供 filledText 时不显示答案，仅展示模板前后段', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const ClozeRichText(
            template: 'I eat an ___ every day.',
            blankMarker: '___',
            textStyle: TextStyle(fontSize: 16),
            blankColor: Colors.blue,
          ),
        ),
      );
      // 占位词不应出现在文本中（仅在 filledText 提供时才填回）。
      expect(find.textContaining('apple'), findsNothing);
      // 富文本本身存在（Text.rich 渲染为 RichText）。
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('提供 filledText 时把占位替换为该词并使用高亮样式', (WidgetTester tester) async {
      const Color highlight = Color(0xFF1976D2);
      await tester.pumpWidget(
        wrap(
          const ClozeRichText(
            template: 'I eat an ___ every day.',
            blankMarker: '___',
            textStyle: TextStyle(fontSize: 16),
            blankColor: highlight,
            filledText: 'apple',
          ),
        ),
      );
      // 在合成出的 RichText 中应能找到 "apple" 这一文本片段。
      final RichText rt = tester.widget<RichText>(find.byType(RichText).first);
      final InlineSpan span = rt.text;
      bool foundFilled = false;
      span.visitChildren((InlineSpan s) {
        if (s is TextSpan && s.text == 'apple') {
          foundFilled = true;
          final TextStyle? st = s.style;
          expect(st?.color, highlight);
          expect(st?.fontWeight, FontWeight.w700);
          expect(st?.decoration, TextDecoration.underline);
        }
        return true;
      });
      expect(foundFilled, isTrue, reason: '填充词应出现在 TextSpan 中');
    });

    testWidgets('模板不含占位时退化为纯 Text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const ClozeRichText(
            template: 'No blank here.',
            blankMarker: '___',
            textStyle: TextStyle(fontSize: 16),
            blankColor: Colors.red,
          ),
        ),
      );
      expect(find.text('No blank here.'), findsOneWidget);
    });
  });
}
