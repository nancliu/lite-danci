import 'package:flutter_test/flutter_test.dart';
import 'package:word_lite/models/review_stage.dart';
import 'package:word_lite/models/word_progress.dart';
import 'package:word_lite/services/review_srs.dart';

void main() {
  group('ReviewSrs PRD 4.2', () {
    test('nextStageAfterSuccess 正向链', () {
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.learning),
        ReviewStage.review_1,
      );
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.review_1),
        ReviewStage.review_3,
      );
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.review_3),
        ReviewStage.review_7,
      );
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.review_7),
        ReviewStage.review_14,
      );
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.review_14),
        ReviewStage.mastered,
      );
      expect(
        ReviewSrs.nextStageAfterSuccess(ReviewStage.mastered),
        ReviewStage.mastered,
      );
    });

    test('rollbackAfterWrong 回退链含 mastered', () {
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.mastered),
        ReviewStage.review_14,
      );
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.review_14),
        ReviewStage.review_7,
      );
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.review_7),
        ReviewStage.review_3,
      );
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.review_3),
        ReviewStage.review_1,
      );
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.review_1),
        ReviewStage.learning,
      );
      expect(
        ReviewSrs.rollbackAfterWrong(ReviewStage.learning),
        ReviewStage.learning,
      );
    });

    test('nextReviewAtAfterSuccessStage 自然日间隔', () {
      final DateTime now = DateTime(2026, 5, 10, 15, 30);
      final DateTime d0 = ReviewSrs.startOfDay(now);
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.review_1, now),
        d0.add(const Duration(days: 1)),
      );
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.review_3, now),
        d0.add(const Duration(days: 3)),
      );
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.review_7, now),
        d0.add(const Duration(days: 7)),
      );
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.review_14, now),
        d0.add(const Duration(days: 14)),
      );
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.learning, now),
        isNull,
      );
      expect(
        ReviewSrs.nextReviewAtAfterSuccessStage(ReviewStage.mastered, now),
        isNull,
      );
    });

    test('nextReviewAtAfterWrongRollback', () {
      final DateTime now = DateTime(2026, 6, 1, 8);
      expect(
        ReviewSrs.nextReviewAtAfterWrongRollback(ReviewStage.learning, now),
        isNull,
      );
      expect(
        ReviewSrs.nextReviewAtAfterWrongRollback(ReviewStage.review_1, now),
        ReviewSrs.startOfDay(now),
      );
    });

    test('isDue 4.2.4', () {
      final DateTime today = DateTime(2026, 4, 20);
      final DateTime todayStart = ReviewSrs.startOfDay(today);
      expect(
        ReviewSrs.isDue(
          const WordProgress(
            wordId: 'w',
            stage: ReviewStage.mastered,
            nextReviewAt: null,
          ),
          todayStart,
        ),
        isFalse,
      );
      expect(
        ReviewSrs.isDue(
          const WordProgress(
            wordId: 'w',
            stage: ReviewStage.learning,
            nextReviewAt: null,
          ),
          todayStart,
        ),
        isTrue,
      );
      expect(
        ReviewSrs.isDue(
          WordProgress(
            wordId: 'w',
            stage: ReviewStage.review_1,
            nextReviewAt: todayStart.subtract(const Duration(days: 1)),
          ),
          todayStart,
        ),
        isTrue,
      );
      expect(
        ReviewSrs.isDue(
          WordProgress(
            wordId: 'w',
            stage: ReviewStage.review_1,
            nextReviewAt: todayStart.add(const Duration(days: 1)),
          ),
          todayStart,
        ),
        isFalse,
      );
    });
  });
}
