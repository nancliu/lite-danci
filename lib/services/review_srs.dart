import '../models/review_stage.dart';
import '../models/word_progress.dart';

/// PRD §4.2 间隔重复（SRS）规则：阶段链、复习日、答错回退、到期判定。
///
/// 与 [WordLiteRepository] 分工：本类仅纯计算与状态转移，不含持久化或队列业务。
abstract final class ReviewSrs {
  /// PRD 4.2.1：答对通关后进入的下一阶段。
  static ReviewStage nextStageAfterSuccess(ReviewStage current) {
    switch (current) {
      case ReviewStage.learning:
        return ReviewStage.review_1;
      case ReviewStage.review_1:
        return ReviewStage.review_3;
      case ReviewStage.review_3:
        return ReviewStage.review_7;
      case ReviewStage.review_7:
        return ReviewStage.review_14;
      case ReviewStage.review_14:
        return ReviewStage.mastered;
      case ReviewStage.mastered:
        return ReviewStage.mastered;
    }
  }

  /// PRD 4.2.3（含 mastered → review_14 补充）。
  static ReviewStage rollbackAfterWrong(ReviewStage current) {
    switch (current) {
      case ReviewStage.mastered:
        return ReviewStage.review_14;
      case ReviewStage.review_14:
        return ReviewStage.review_7;
      case ReviewStage.review_7:
        return ReviewStage.review_3;
      case ReviewStage.review_3:
        return ReviewStage.review_1;
      case ReviewStage.review_1:
      case ReviewStage.learning:
        return ReviewStage.learning;
    }
  }

  /// 自然日零点（与仓库 [_startOfDay] 一致）。
  static DateTime startOfDay(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  /// PRD 4.2.2：通关后已进入的 [stageAfterSuccess] 对应的下一次可复习日；`learning` / `mastered` 无安排。
  static DateTime? nextReviewAtAfterSuccessStage(
    ReviewStage stageAfterSuccess,
    DateTime now,
  ) {
    final DateTime start = startOfDay(now);
    switch (stageAfterSuccess) {
      case ReviewStage.learning:
        return null;
      case ReviewStage.review_1:
        return start.add(const Duration(days: 1));
      case ReviewStage.review_3:
        return start.add(const Duration(days: 3));
      case ReviewStage.review_7:
        return start.add(const Duration(days: 7));
      case ReviewStage.review_14:
        return start.add(const Duration(days: 14));
      case ReviewStage.mastered:
        return null;
    }
  }

  /// PRD 4.2.3 入队口径：回退到 `learning` 则清空；否则当日视为已到期。
  static DateTime? nextReviewAtAfterWrongRollback(
    ReviewStage rolledStage,
    DateTime now,
  ) {
    if (rolledStage == ReviewStage.learning) {
      return null;
    }
    return startOfDay(now);
  }

  /// PRD 4.2.4：是否可进入当日复习抽样（`mastered` 永不进复习段）。
  static bool isDue(WordProgress w, DateTime todayStart) {
    if (w.stage == ReviewStage.mastered) {
      return false;
    }
    if (w.nextReviewAt == null) {
      return w.stage == ReviewStage.learning;
    }
    return !startOfDay(w.nextReviewAt!).isAfter(todayStart);
  }

  /// 答对四步通关后的进度（仅 SRS 字段）。
  static WordProgress progressAfterWordSuccess(
    String wordId,
    WordProgress? before,
    DateTime now,
  ) {
    final ReviewStage current = before?.stage ?? ReviewStage.learning;
    final ReviewStage nextStage = nextStageAfterSuccess(current);
    final DateTime? nextAt = nextReviewAtAfterSuccessStage(nextStage, now);
    return WordProgress(
      wordId: wordId,
      stage: nextStage,
      nextReviewAt: nextAt,
    );
  }
}
