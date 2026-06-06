import 'package:flutter/material.dart';

/// 第四步「例句填空」的句子展示组件。
///
/// 默认（[filledText] 为 null）渲染含下划线占位的句子；当 [filledText] 非空时，
/// 占位位置改为以高亮样式（[blankColor] + 粗体 + 下划线）显示该词，
/// 用作答对后的视觉反馈。
///
/// 模板不含 [blankMarker] 时退化为纯 [Text] 展示。
class ClozeRichText extends StatelessWidget {
  const ClozeRichText({
    super.key,
    required this.template,
    required this.blankMarker,
    required this.textStyle,
    required this.blankColor,
    this.filledText,
  });

  final String template;
  final String blankMarker;
  final TextStyle? textStyle;
  final Color blankColor;

  /// 非空时把 [blankMarker] 替换为该词并以高亮样式展示。
  final String? filledText;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = textStyle ?? Theme.of(context).textTheme.titleMedium!;
    if (!template.contains(blankMarker)) {
      return Text(template, style: base);
    }
    final List<String> parts = template.split(blankMarker);
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: base));
      }
      if (i < parts.length - 1) {
        if (filledText != null && filledText!.isNotEmpty) {
          spans.add(
            TextSpan(
              text: filledText!,
              style: base.copyWith(
                color: blankColor,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: blankColor,
                decorationThickness: 2.0,
              ),
            ),
          );
        } else {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: blankColor, width: 2.5),
                    ),
                  ),
                  child: Text(
                    '        ',
                    style: base.copyWith(
                      color: blankColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
