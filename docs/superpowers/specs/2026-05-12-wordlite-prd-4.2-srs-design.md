# WordLite PRD §4.2 复习系统（SRS）— 实现说明

## 1. 依据

- `WordLite_PRD.md` §4.2.1～4.2.4。
- 代码：`lib/services/review_srs.dart`（纯规则）、`lib/services/word_lite_repository.dart`（持久化、队列、会话）。

## 2. 职责划分

| 内容 | 位置 |
|------|------|
| 阶段正向链、答错回退、`nextReviewAt` 计算、到期判定 | `ReviewSrs` |
| 今日队列、检查点、奖励（§4.3）、换日与家长统计（§4.4） | `WordLiteRepository`；奖励见 `2026-05-12-wordlite-prd-4.3-rewards-design.md`，家长统计见 `2026-05-12-wordlite-prd-4.4-parent-stats-design.md` |

## 3. 与 PRD 条目映射

（PRD 正文 **§4.2.5** 为验收勾选清单，与本节一致。）

- **4.2.1**：`ReviewSrs.nextStageAfterSuccess` / `ReviewSrs.rollbackAfterWrong`。
- **4.2.2**：`ReviewSrs.nextReviewAtAfterSuccessStage`（通关日自然日 +1/+3/+7/+14）。
- **4.2.3 + 入队口径**：`ReviewSrs.nextReviewAtAfterWrongRollback`。
- **4.2.4**：`ReviewSrs.isDue`。
- **通关后进度对象**：`ReviewSrs.progressAfterWordSuccess`。

## 4. 单测

- `test/review_srs_test.dart`：纯规则表驱动。
- `test/word_lite_repository_test.dart`：仓库与持久化、队列组合场景。

## 5. 自检

- 无占位符；与 PRD 冲突时以 PRD 为准。
