/// 单词条目（内置词库）。
class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    required this.meaningZh,
    required this.emoji,
    required this.exampleEn,
    required this.exampleWrongZh,
  });

  final String id;
  final String word;
  final String meaningZh;
  final String emoji;
  final String exampleEn;

  /// 例句选择时的错误中文释义（用于干扰项）。
  final List<String> exampleWrongZh;
}
