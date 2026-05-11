import 'review_stage.dart';

/// 单个单词的学习进度。
class WordProgress {
  const WordProgress({
    required this.wordId,
    required this.stage,
    this.nextReviewAt,
  });

  final String wordId;
  final ReviewStage stage;
  final DateTime? nextReviewAt;

  WordProgress copyWith({
    String? wordId,
    ReviewStage? stage,
    DateTime? nextReviewAt,
  }) {
    return WordProgress(
      wordId: wordId ?? this.wordId,
      stage: stage ?? this.stage,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'wordId': wordId,
      'stage': stage.name,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
    };
  }

  static WordProgress fromJson(Map<String, dynamic> json) {
    return WordProgress(
      wordId: json['wordId'] as String,
      stage: ReviewStageCodec.fromName(json['stage'] as String?),
      nextReviewAt: json['nextReviewAt'] == null
          ? null
          : DateTime.tryParse(json['nextReviewAt'] as String),
    );
  }
}
