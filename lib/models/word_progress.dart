import 'review_stage.dart';

/// 单个单词的学习进度。
class WordProgress {
  const WordProgress({
    required this.wordId,
    required this.stage,
    this.nextReviewAt,
    this.wrongCount = 0,
  });

  final String wordId;
  final ReviewStage stage;
  final DateTime? nextReviewAt;

  /// 累计答错次数（每次 onStepWrong 触发 +1）；用于家长页错题排行。
  /// 旧存档无此字段时按 0 解析（向后兼容）。
  final int wrongCount;

  WordProgress copyWith({
    String? wordId,
    ReviewStage? stage,
    DateTime? nextReviewAt,
    int? wrongCount,
  }) {
    return WordProgress(
      wordId: wordId ?? this.wordId,
      stage: stage ?? this.stage,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      wrongCount: wrongCount ?? this.wrongCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'wordId': wordId,
      'stage': stage.name,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
      'wrongCount': wrongCount,
    };
  }

  static WordProgress fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['wordId'] as String,
      stage: ReviewStageCodec.fromName(json['stage'] as String?),
      nextReviewAt: json['nextReviewAt'] == null
          ? null
          : DateTime.tryParse(json['nextReviewAt'] as String),
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
    );
  }
}
