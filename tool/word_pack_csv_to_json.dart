// CSV → JSON 词包（供放入 assets/word_packs/）。
//
// 使用 **管道符 `|`** 分隔。
//
// **首行表头**（须完全一致）：
// id|word|meaningZh|emoji|exampleEn|exampleClozeEn|exampleFillAnswer|wrong1|wrong2|wrong3|gradeTag
//
// gradeTag 可留空。emoji 可留空（看图步骤用默认占位）。数据行须为 11 列。

import 'dart:convert';
import 'dart:io';

import 'package:word_lite/models/word_entry.dart';

const String _expectedHeader =
    'id|word|meaningZh|emoji|exampleEn|exampleClozeEn|exampleFillAnswer|wrong1|wrong2|wrong3|gradeTag';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      '用法: dart run tool/word_pack_csv_to_json.dart <输入.csv> <输出.json>',
    );
    exitCode = 64;
    return;
  }
  final File inFile = File(args[0]);
  final File outFile = File(args[1]);
  if (!inFile.existsSync()) {
    stderr.writeln('找不到文件: ${inFile.path}');
    exitCode = 66;
    return;
  }
  final String raw = inFile.readAsStringSync(encoding: utf8);
  final List<String> lines = const LineSplitter().convert(raw);
  final List<Map<String, dynamic>> entries = <Map<String, dynamic>>[];
  bool headerOk = false;
  int lineNo = 0;
  for (final String line in lines) {
    lineNo++;
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final List<String> cells = trimmed.split('|');
    if (!headerOk) {
      if (cells.join('|') != _expectedHeader) {
        stderr.writeln('第 $lineNo 行：表头须为\n$_expectedHeader');
        exitCode = 65;
        return;
      }
      headerOk = true;
      continue;
    }
    if (cells.length != 11) {
      stderr.writeln('第 $lineNo 行：须 11 列（当前 ${cells.length}）');
      exitCode = 65;
      return;
    }
    final String grade = cells[10].trim();
    final Map<String, dynamic> row = <String, dynamic>{
      'id': cells[0].trim(),
      'word': cells[1].trim(),
      'meaningZh': cells[2].trim(),
      'emoji': cells[3].trim(),
      'exampleEn': cells[4].trim(),
      'exampleClozeEn': cells[5].trim(),
      'exampleFillAnswer': cells[6].trim(),
      'exampleFillWrongEn': <String>[
        cells[7].trim(),
        cells[8].trim(),
        cells[9].trim(),
      ],
      if (grade.isNotEmpty) 'gradeTag': grade,
    };
    try {
      entries.add(WordEntry.fromJson(row).toJson());
    } on FormatException catch (e) {
      stderr.writeln('第 $lineNo 行校验失败: ${e.message}');
      exitCode = 65;
      return;
    }
  }
  if (!headerOk) {
    stderr.writeln('未找到表头');
    exitCode = 65;
    return;
  }
  final Map<String, Object> out = <String, Object>{
    'version': 1,
    'entries': entries,
  };
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(out),
    encoding: utf8,
  );
  stdout.writeln('已写入 ${outFile.path}，共 ${entries.length} 条');
}
