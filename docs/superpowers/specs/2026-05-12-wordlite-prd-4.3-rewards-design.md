# WordLite PRD §4.3 奖励系统 — 实现说明

## 1. 依据

- `WordLite_PRD.md` §4.3（能量、碎片、皮肤档位）。
- 代码：`lib/services/word_lite_repository.dart`（结算与持久化）、`lib/app_theme.dart`（主题种子色）、`lib/models/user_stats.dart`（对外统计快照）。

## 2. 职责划分

| 内容 | 位置 |
|------|------|
| 能量 +1、整段会话碎片、皮肤解锁与扣减碎片、持久化键 | `WordLiteRepository`（`_completeCurrentWord`、`_tryUnlockSkin`、常量） |
| 主题表现（种子色） | `buildWordLiteTheme(int skinLevel)` |
| 首页 / 家长页展示字段 | `UserStats`、`home_screen.dart`、`parent_screen.dart` |

## 3. 与 PRD 条目映射

（PRD 正文 **§4.3.5** 为验收勾选清单，与本节一致。）

- **能量**：某词四步全部答对并进入 `_completeCurrentWord(success: true)` 时 `_energy += 1`；与「完成一词」定义一致。
- **碎片**：仅当该词为**当日队列最后一词**且四步成功通关时 `_shards += shardsPerSessionCompleted`（当前为 **1**）；此前词完成不发放。检查点清空与会话结束一致。
- **皮肤**：`shardsPerSkin = 10`；`_tryUnlockSkin` 在碎片入账后执行：在已解锁档数 `< skinLevels`（**3**）且 `_shards >= 10` 时循环扣 10 碎片并 `+1` 档。主题色由 `unlockedSkinLevel`（0～3）驱动 `buildWordLiteTheme`。

## 4. 可调参数（与 backlog 对齐）

- `WordLiteRepository.shardsPerSessionCompleted`、`shardsPerSkin`、`skinLevels` 为集中常量；每会话碎片数值调参见仓库 backlog / `WordLite_PRD.md` §7。

## 5. 单测

- `test/word_lite_repository_test.dart`：能量、多词队列不提前发碎片、整段完成发碎片、9+1 解锁皮肤与扣减等。

## 6. 自检

- 无占位符；与 PRD 冲突时以 PRD 为准。
