# WordLite PRD §4.4 家长观察 — 实现说明

## 1. 依据

- `WordLite_PRD.md` §4.4（今日学习、累计掌握、连续天数、比昨天提升）。
- 代码：`lib/models/user_stats.dart`（只读快照）、`lib/services/word_lite_repository.dart`（统计计算与换日）、`lib/screens/parent_screen.dart`（展示）。

## 2. 职责划分

| 内容 | 位置 |
|------|------|
| 今日完成词数、换日归零 | `_todayCompleted`，`_rollDailyIfNeeded`，四步成功时 `+1` |
| 累计掌握 | `_countMastered()`，`ReviewStage.mastered` 计数 |
| 连续天数、最近学习日 | `_touchStreak`、`_lastStudyDateKey`、`_streakDays` |
| 比昨天提升 | `UserStats.deltaVsYesterday` = `totalMastered - yesterdayMasteredSnapshot`；换日时快照写入 `_yesterdayMasteredSnapshot` |
| UI 只读列表 | `ParentScreen` + `Consumer<WordLiteRepository>` |

## 3. 与 PRD 条目映射

（PRD 正文 **§4.4.5** 为验收勾选清单，与本节一致。）

- **今日学习**：`UserStats.todayCompletedWords`，与「四步通关」计数同源（`_completeCurrentWord` 成功路径）。
- **累计掌握**：`UserStats.totalMastered`。
- **连续天数**：有学习行为（完成一词即 `_touchStreak`）的自然日链；同日多次 `max(1, _streakDays)` 不重复 +1；跨日差 1 天则 `+1`，否则重置为 1。
- **比昨天提升**：换日时把当前掌握数写入 `_yesterdayMasteredSnapshot`；展示用 `deltaVsYesterday`。

## 4. 换日口径

- `_rollDailyIfNeeded`：当持久化的 `_todayKey` 与今日自然日键不一致时，将 `_todayCompleted` 置 0，将 `_yesterdayMasteredSnapshot` 设为当前 `_countMastered()`，并更新 `_todayKey` 等（与 §4.1 当日会话边界一致）。

## 5. 单测

- `test/word_lite_repository_test.dart`：换日与昨日快照、连续日 streak、同日不重复 streak、间隔多日重置等。
- `test/parent_screen_test.dart`：`UserStats` 与 PRD 四维文案在界面上的只读展示。

## 6. 自检

- 无占位符；与 PRD 冲突时以 PRD 为准。
