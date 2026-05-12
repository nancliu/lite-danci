/// 单词条目（内置或词包 JSON）。
class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    required this.meaningZh,
    required this.emoji,
    required this.exampleEn,
    required this.exampleClozeEn,
    required this.exampleFillAnswer,
    required this.exampleFillWrongEn,
    this.gradeTag,
  });

  final String id;
  final String word;
  final String meaningZh;
  final String emoji;
  final String exampleEn;

  /// 第四步例句填空：含占位 `___` 的英文例句。
  final String exampleClozeEn;

  /// 第四步唯一正确答案（可与 [word] 不同，如单复数、时态）。
  final String exampleFillAnswer;

  /// 第四步英文干扰项（可含不同时态或近形词）。
  final List<String> exampleFillWrongEn;

  /// 可选：年级/分册标签（如「一年级」）；队列筛选见产品迭代。
  final String? gradeTag;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'word': word,
      'meaningZh': meaningZh,
      'emoji': emoji,
      'exampleEn': exampleEn,
      'exampleClozeEn': exampleClozeEn,
      'exampleFillAnswer': exampleFillAnswer,
      'exampleFillWrongEn': exampleFillWrongEn,
      if (gradeTag != null) 'gradeTag': gradeTag,
    };
  }

  /// 解析词包单条；字段不合法时抛出 [FormatException]。
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    final Object? idRaw = json['id'];
    final Object? wordRaw = json['word'];
    if (idRaw is! String || idRaw.isEmpty) {
      throw const FormatException('WordEntry.id 须为非空字符串');
    }
    if (wordRaw is! String || wordRaw.isEmpty) {
      throw const FormatException('WordEntry.word 须为非空字符串');
    }
    final String meaningZh = _reqString(json, 'meaningZh');
    final String emoji = _reqString(json, 'emoji');
    final String exampleEn = _reqString(json, 'exampleEn');
    final String exampleClozeEn = _reqString(json, 'exampleClozeEn');
    if (!exampleClozeEn.contains('___')) {
      throw const FormatException('exampleClozeEn 须包含占位符 ___');
    }
    final String exampleFillAnswer = _reqString(json, 'exampleFillAnswer');
    final List<String> wrong = _reqStringList(json, 'exampleFillWrongEn');
    if (wrong.length < 3) {
      throw const FormatException('exampleFillWrongEn 至少 3 条');
    }
    final String? gradeTag = json['gradeTag'] is String
        ? (json['gradeTag'] as String).trim().isEmpty
            ? null
            : (json['gradeTag'] as String).trim()
        : null;
    return WordEntry(
      id: idRaw,
      word: wordRaw,
      meaningZh: meaningZh,
      emoji: emoji,
      exampleEn: exampleEn,
      exampleClozeEn: exampleClozeEn,
      exampleFillAnswer: exampleFillAnswer,
      exampleFillWrongEn: wrong,
      gradeTag: gradeTag,
    );
  }

  static String _reqString(Map<String, dynamic> json, String key) {
    final Object? v = json[key];
    if (v is! String || v.isEmpty) {
      throw FormatException('WordEntry.$key 须为非空字符串');
    }
    return v;
  }

  static List<String> _reqStringList(Map<String, dynamic> json, String key) {
    final Object? v = json[key];
    if (v is! List<dynamic>) {
      throw FormatException('WordEntry.$key 须为字符串数组');
    }
    final List<String> out = <String>[];
    for (final Object? e in v) {
      if (e is! String || e.isEmpty) {
        throw FormatException('WordEntry.$key 元素须为非空字符串');
      }
      out.add(e);
    }
    return out;
  }
}
