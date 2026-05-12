import 'dart:convert';

import '../models/word_entry.dart';

/// 词包 JSON 解析结果。
class WordPackLoadResult {
  WordPackLoadResult({
    required this.entries,
    required this.skippedDuplicateIds,
    required this.parseErrors,
  });

  final List<WordEntry> entries;
  final List<String> skippedDuplicateIds;
  final List<String> parseErrors;
}

/// 解析随应用打包的词包 JSON。
///
/// 支持顶层为 **对象**（`entries` 数组）或 **数组**。单条解析失败记入 [WordPackLoadResult.parseErrors] 并跳过该条。
class WordPackLoader {
  WordPackLoader._();

  /// [reservedIds]：已占用 id（如内置词表），命中则跳过并记入 [WordPackLoadResult.skippedDuplicateIds]。
  static WordPackLoadResult parsePackJson(
    String json, {
    Set<String>? reservedIds,
  }) {
    final Set<String> taken = <String>{...?reservedIds};
    final List<WordEntry> entries = <WordEntry>[];
    final List<String> skipped = <String>[];
    final List<String> errors = <String>[];

    final Object? decoded = jsonDecode(json);
    final List<Object?> rawList;
    if (decoded is List<dynamic>) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final Object? e = decoded['entries'];
      if (e is! List<dynamic>) {
        return WordPackLoadResult(
          entries: <WordEntry>[],
          skippedDuplicateIds: skipped,
          parseErrors: <String>['顶层须为数组或含 entries 数组的对象'],
        );
      }
      rawList = e;
    } else {
      return WordPackLoadResult(
        entries: <WordEntry>[],
        skippedDuplicateIds: skipped,
        parseErrors: <String>['JSON 顶层类型无效'],
      );
    }

    int index = 0;
    for (final Object? item in rawList) {
      index++;
      if (item is! Map<String, dynamic>) {
        errors.add('第 $index 条：须为对象');
        continue;
      }
      try {
        final WordEntry w = WordEntry.fromJson(item);
        if (taken.contains(w.id)) {
          skipped.add(w.id);
          continue;
        }
        taken.add(w.id);
        entries.add(w);
      } on FormatException catch (e) {
        errors.add('第 $index 条：${e.message}');
      } catch (e) {
        errors.add('第 $index 条：$e');
      }
    }

    return WordPackLoadResult(
      entries: entries,
      skippedDuplicateIds: skipped,
      parseErrors: errors,
    );
  }
}
