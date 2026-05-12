# WordLite PRD §4.4 家长观察 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 §4.4 家长观察与仓库统计的映射固化为设计文档与验收清单，并补齐 streak / 家长页展示的自动化测试。

**Architecture:** 不改变业务规则；在既有 `WordLiteRepository` + `ParentScreen` 上增加文档、PRD/Issue 勾选与测试覆盖。

**Tech Stack:** Flutter、`shared_preferences` 测试桩、`flutter_test`、`provider`。

---

### Task 1: 规格与 PRD / Issue / 代码锚点

**Files:**

- Create: `docs/superpowers/specs/2026-05-12-wordlite-prd-4.4-parent-stats-design.md`
- Modify: `WordLite_PRD.md`（§4.4 增加实现说明链接与 **§4.4.5 验收勾选**）
- Modify: `.github/prd_tracking_issue_body.md`（新增 **PRD §4.4 家长观察验收**）
- Modify: `lib/services/word_lite_repository.dart`（类文档增加 **§4.4** 一行）
- Modify: `docs/superpowers/specs/2026-05-12-wordlite-prd-4.2-srs-design.md`（职责表指向 §4.4 文档，若尚未提及家长统计）

- [x] **Step 1:** 写入上述文件内容并自检无 TBD。
- [x] **Step 2:** `flutter analyze` 无错误。

---

### Task 2: 仓库层 streak 单测

**Files:**

- Modify: `test/word_lite_repository_test.dart`

**新增用例（要点）：**

- 昨日 `wl_last_study_v1`、已有 `wl_streak_v1`，今日完成一词四步 → streak +1，`lastStudyDateKey` 为今日。
- 当日队列连续两词均完成 → streak 第二次不递增。
- `lastStudy` 早于今日超过 1 天 → 再完成一词 streak 重置为 1。

- [x] **Step 1:** 增加常量 `_kLastStudy`、`_kStreak`（与仓库键一致）。
- [x] **Step 2:** 编写上述三个 `test(...)`。
- [x] **Step 3:** `flutter test test/word_lite_repository_test.dart`

---

### Task 3: ParentScreen 展示单测

**Files:**

- Create: `test/parent_screen_test.dart`

**要点：** `ChangeNotifierProvider` + `MaterialApp` + `ParentScreen`；用 `SharedPreferences.setMockInitialValues` + `WordLiteRepository.init()` 构造已知 `UserStats`，`find.text` 断言「今日学习」「累计掌握」「连续天数」「比昨天提升」及数值子串。

- [x] **Step 1:** 实现 `testWidgets` 至少 1 条（覆盖四维展示）。
- [x] **Step 2:** `flutter test`

---

### Task 4: 收尾

- [x] **Step 1:** 全量 `flutter test`。
- [x] **Step 2:**（可选）`git add` / `commit` 由发布流程执行；本计划其余步骤已落地。

---

## Plan self-review

- §4.4 四条展示均有映射：Task 1（文档）+ Task 2（streak/换日已有单测补充）+ Task 3（UI）。
- 无占位符步骤。

**Plan complete.** 执行方式：本会话内联执行（等同 Inline Execution）。
