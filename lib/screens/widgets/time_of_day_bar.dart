import 'package:flutter/material.dart';

/// 学习时段分布水平条：早 / 午 / 晚 三段比例。
///
/// 接收三段计数，按比例渲染彩色段并显示数字。
class TimeOfDayBar extends StatelessWidget {
  const TimeOfDayBar({
    super.key,
    required this.morning,
    required this.afternoon,
    required this.evening,
    this.barHeight = 18,
  });

  final int morning;
  final int afternoon;
  final int evening;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int total = morning + afternoon + evening;

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '尚无学习时段数据',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final double mFlex = morning.toDouble();
    final double aFlex = afternoon.toDouble();
    final double eFlex = evening.toDouble();

    // 三段配色：morning 暖橙、afternoon 浅蓝、evening 深紫
    const Color morningColor = Color(0xFFFFB74D);
    const Color afternoonColor = Color(0xFF64B5F6);
    const Color eveningColor = Color(0xFF9575CD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: SizedBox(
            height: barHeight,
            width: double.infinity,
            child: Row(
              children: <Widget>[
                if (mFlex > 0)
                  Expanded(
                    flex: mFlex.toInt(),
                    child: Container(color: morningColor),
                  ),
                if (aFlex > 0)
                  Expanded(
                    flex: aFlex.toInt(),
                    child: Container(color: afternoonColor),
                  ),
                if (eFlex > 0)
                  Expanded(
                    flex: eFlex.toInt(),
                    child: Container(color: eveningColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: <Widget>[
            _LegendDot(
              color: morningColor,
              label: '早 $morning',
            ),
            _LegendDot(
              color: afternoonColor,
              label: '午 $afternoon',
            ),
            _LegendDot(
              color: eveningColor,
              label: '晚 $evening',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
