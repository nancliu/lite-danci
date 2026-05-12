追踪基准：`WordLite_PRD.md`（MVP **§3.1**、验收 **§6**、范围外 **§3.2**、迭代 **§7**）。

## MVP 功能（§3.1）

> 代码锚点便于复查：`lib/services/word_lite_repository.dart`、`lib/data/word_bank.dart`、`lib/data/word_pack_loader.dart`、`lib/services/review_srs.dart`、`lib/screens/learn_screen.dart`、`lib/screens/parent_screen.dart`、`test/word_lite_repository_test.dart`、`test/word_bank_load_test.dart`、`test/word_pack_loader_test.dart`、`test/parent_screen_test.dart` 与 `test/review_srs_test.dart`。

- [x] 单词学习流程（四步）
- [x] 间隔重复复习系统（阶段 + 复习日）
- [x] 每日任务生成（新词 + 复习队列）
- [x] 学习中断恢复（会话检查点 + 切后台落盘）
- [x] 奖励系统（能量、碎片、皮肤档位）
- [x] 家长观察页面（统计只读展示）
- [x] 本地存储（离线可用）
- [x] 可扩展词库（嵌入式 JSON 词包 + `tool/word_pack_csv_to_json.dart`）

## PRD §4.2 复习系统验收

> 与 `WordLite_PRD.md` **§4.2.5** 同步；规则实现见 `review_srs.dart` 与设计说明 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.2-srs-design.md`。

- [x] **4.2.1** 阶段正向链（`ReviewSrs.nextStageAfterSuccess` / `progressAfterWordSuccess`）
- [x] **4.2.2** 复习日 +1 / +3 / +7 / +14 自然日零点；`mastered` 不排期（`nextReviewAtAfterSuccessStage`）
- [x] **4.2.3** 答错回退链与 `mastered` → `review_14`（`rollbackAfterWrong`）
- [x] **4.2.3 入队** 答错后 `nextReviewAt` 校准（`nextReviewAtAfterWrongRollback` + 仓库持久化单测）
- [x] **4.2.4** 到期判定与复习抽样（`isDue` + `buildTodayQueue` 复习段）
- [ ] **手测（可选）** 多阶段词答错、换日后队列与统计观感符合 PRD

## PRD §4.3 奖励系统验收

> 与 `WordLite_PRD.md` **§4.3.5** 同步；设计说明 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.3-rewards-design.md`。

- [x] **能量** 每完成一词（四步通关）+1（仓库 `_completeCurrentWord`）
- [x] **碎片** 仅整段会话完成发放；多词中途不发放（`word_lite_repository_test.dart`）
- [x] **皮肤** 10 碎片 / 档、共 3 档，解锁扣减碎片（单测「9+1」）
- [ ] **手测（可选）** 首页与家长页展示与换日后再学一组观感

> **§4.3 复查结论**（对照 `word_lite_repository.dart` / `app_theme.dart` / `UserStats`）：能量仅在四步通关结算路径 +1；碎片仅在当日队列最后一词成功通关后按 `shardsPerSessionCompleted` 发放；皮肤在入账后 `_tryUnlockSkin` 按 10 碎片 / 档循环解锁至多 3 档。与 `WordLite_PRD.md` §4.3 及 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.3-rewards-design.md` 一致；`flutter test`（含 `word_lite_repository_test` 相关用例）已通过。可选手测仍以真机确认为准。

## PRD §4.4 家长观察验收

> 与 `WordLite_PRD.md` **§4.4.5** 同步；设计说明 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.4-parent-stats-design.md`。

- [x] **今日学习** 四步通关计数 + 换日归零（`word_lite_repository_test`）
- [x] **累计掌握** `mastered` 计数（`UserStats.totalMastered`）
- [x] **连续天数** 连续日 +1、同日不重复、间隔重置（`word_lite_repository_test`）
- [x] **比昨天提升** `deltaVsYesterday` 与换日快照（`word_lite_repository_test`）
- [x] **家长页只读展示** 四维与 `UserStats` 一致（`parent_screen_test.dart`）
- [ ] **手测（可选）** 换日后家长页观感与 §4.1、§4.4 叙述一致

## PRD §4.5 词库与扩展验收

> 与 `WordLite_PRD.md` **§4.5.5** 同步；设计说明 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.5-word-bank-design.md`。

- [x] **内置 + JSON 合并** `WordBank.loadEmbeddedPacks` + `embeddedPackAssetPaths`
- [x] **解析与去重** `WordPackLoader` + 与内置 id 冲突跳过（`word_pack_loader_test`）
- [x] **WordEntry JSON** 往返（`word_entry_json_test`）
- [x] **示例词包加载** `word_bank_load_test.dart`
- [x] **CSV→JSON 工具** `tool/word_pack_csv_to_json.dart`
- [ ] **手测（可选）** 掌握内置 20 词后新词出现扩展词；四步与 TTS 正常

## 明确不在 MVP（§3.2，勿在本 Issue 当「未完成 MVP」）

- 账号登录、云同步、多设备
- **应用内**从用户设备任意路径**选择文件导入词库**、教师端（随包 JSON / 发版更新词库不在此列）
- 推送提醒、社交排行
- 独立「设置」页（草案见 §3.3）

## 验收自检（§6）

本地执行：

```bash
flutter analyze
flutter test
```

- [x] `flutter analyze` 无错误
- [x] `flutter test` 全绿（含仓库层关键业务单测）
- [x] 检查点同日恢复（`word_lite_repository_test`：预置检查点 stepIndex 后继续答对并结算）
- [ ] 真机/模拟器手测：当日队列 → 四步 → 错/对 SRS → 同日恢复检查点（可与自动化互补）
- [ ] 真机手测：家长页与换日后「今日 / 连续天数」体感符合 §4.1、§4.4

## 后续迭代（§7，可另开 Issue 并链到本 Issue）

以下单独建 Issue 时打上 `backlog`，并在本列表贴链接：

- [ ] 复习抽样策略优化
- [ ] 每会话碎片数值调参
- [x] 词库扩展（随包 JSON 多文件 + `tool/word_pack_csv_to_json.dart`；应用内文件导入仍属 §3.2 backlog）
- [ ] 埋点与完成率看板
- [ ] 无障碍与国际化
- [ ] 应用设置页（§3.3）

---

**维护约定**：MVP 代码有变更时，同步更新本节勾选与锚点说明；大范围需求变更先改 `WordLite_PRD.md`，再改本 Issue。
