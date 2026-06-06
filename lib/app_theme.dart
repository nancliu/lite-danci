import 'package:flutter/material.dart';

/// 根据已解锁皮肤档位返回主题色。
///
/// 档位映射（与 [WordLiteRepository._skinShardCost] 对齐）：
/// 0=绿（默认）、1=蓝、2=紫、3=橙、4=粉红、5=青、6=金。
/// 兜底分支保留以防进度异常（如老用户回退）。
ThemeData buildWordLiteTheme(int skinLevel) {
  final Color seed = switch (skinLevel) {
    0 => const Color(0xFF2E7D32), // 绿（起步）
    1 => const Color(0xFF1565C0), // 蓝
    2 => const Color(0xFF6A1B9A), // 紫
    3 => const Color(0xFFE65100), // 橙
    4 => const Color(0xFFC2185B), // 粉红
    5 => const Color(0xFF00838F), // 青
    6 => const Color(0xFFF57F17), // 金（最终档）
    _ => const Color(0xFF2E7D32), // 兜底回到绿色
  };
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
