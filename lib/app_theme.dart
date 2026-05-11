import 'package:flutter/material.dart';

/// 根据已解锁皮肤档位返回主题色。
ThemeData buildWordLiteTheme(int skinLevel) {
  final Color seed = switch (skinLevel) {
    0 => const Color(0xFF2E7D32),
    1 => const Color(0xFF1565C0),
    2 => const Color(0xFF6A1B9A),
    _ => const Color(0xFFE65100),
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
