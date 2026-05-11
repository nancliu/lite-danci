/// 单词复习阶段（与 PRD 一致）。
enum ReviewStage {
  learning,
  review_1,
  review_3,
  review_7,
  review_14,
  mastered,
}

extension ReviewStageCodec on ReviewStage {
  static ReviewStage fromName(String? value) {
    if (value == null) {
      return ReviewStage.learning;
    }
    return ReviewStage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReviewStage.learning,
    );
  }
}
