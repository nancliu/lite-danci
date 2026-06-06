import 'package:flutter/material.dart';

import '../../models/daily_stats.dart';

/// 最近 N 天每日完成词数的柱状图（用 CustomPaint，无外部依赖）。
///
/// 没有数据的日期柱子按 0 渲染；最高柱按当前数据集 max 自适配 y 轴。
/// 顶部右侧显示窗口内总计与平均值。
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    super.key,
    required this.daily,
    this.days = 7,
    this.height = 140,
  });

  /// dayKey -> DailyStats（升序），可有空缺；按 [days] 窗口补齐。
  final Map<String, DailyStats> daily;

  /// 显示天数（默认 7）。
  final int days;

  /// 图表高度（不含外 padding）。
  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_Bar> bars = _buildBars();
    final int total = bars.fold<int>(0, (int s, _Bar b) => s + b.value);
    final double avg = days > 0 ? total / days : 0;
    final int maxVal = bars.fold<int>(0, (int m, _Bar b) => b.value > m ? b.value : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '近 $days 天完成',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '合计 $total 词 · 日均 ${avg.toStringAsFixed(1)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarsPainter(
              bars: bars,
              maxVal: maxVal,
              barColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.onSurfaceVariant,
              gridColor:
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  List<_Bar> _buildBars() {
    // 取出最后 N 天，按时间升序。daily 已经是过滤后的 map。
    final List<_Bar> out = <_Bar>[];
    final DateTime today = _today();
    for (int i = days - 1; i >= 0; i--) {
      final DateTime d = today.subtract(Duration(days: i));
      final String k = _dateKey(d);
      final int v = daily[k]?.completedWords ?? 0;
      // 简短日标签：周一 -> "一"
      out.add(_Bar(label: _weekdayShort(d.weekday), value: v));
    }
    return out;
  }

  static DateTime _today() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _weekdayShort(int w) {
    // DateTime.weekday: Mon=1..Sun=7
    const List<String> wn = <String>['一', '二', '三', '四', '五', '六', '日'];
    return wn[(w - 1).clamp(0, 6)];
  }
}

class _Bar {
  const _Bar({required this.label, required this.value});
  final String label;
  final int value;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.bars,
    required this.maxVal,
    required this.barColor,
    required this.labelColor,
    required this.gridColor,
  });

  final List<_Bar> bars;
  final int maxVal;
  final Color barColor;
  final Color labelColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) {
      return;
    }
    const double labelH = 18; // 底部日标签高度
    const double valueH = 12; // 柱顶数值文字高度
    final double chartH = size.height - labelH - valueH;
    final double slotW = size.width / bars.length;
    final double barW = slotW * 0.55;
    final int effMax = maxVal <= 0 ? 1 : maxVal;

    final Paint gridP = Paint()..color = gridColor..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, valueH + chartH),
      Offset(size.width, valueH + chartH),
      gridP,
    );

    final Paint barP = Paint()..color = barColor;
    final TextPainter tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < bars.length; i++) {
      final _Bar b = bars[i];
      final double ratio = b.value / effMax;
      final double bh = ratio * chartH;
      final double x = slotW * i + (slotW - barW) / 2;
      final double y = valueH + chartH - bh;
      final RRect rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, bh),
        const Radius.circular(4),
      );
      canvas.drawRRect(rr, barP);

      // 柱顶数值
      if (b.value > 0) {
        tp.text = TextSpan(
          text: '${b.value}',
          style: TextStyle(color: labelColor, fontSize: 10),
        );
        tp.layout(minWidth: slotW, maxWidth: slotW);
        tp.paint(canvas, Offset(slotW * i, y - valueH));
      }

      // 底部日标签
      tp.text = TextSpan(
        text: b.label,
        style: TextStyle(color: labelColor, fontSize: 11),
      );
      tp.layout(minWidth: slotW, maxWidth: slotW);
      tp.paint(canvas, Offset(slotW * i, valueH + chartH + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) {
    return old.maxVal != maxVal ||
        old.barColor != barColor ||
        old.labelColor != labelColor ||
        old.gridColor != gridColor ||
        old.bars.length != bars.length ||
        !_listEq(old.bars, bars);
  }

  static bool _listEq(List<_Bar> a, List<_Bar> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }
}
