# WordLite 首页入口（设计 spec 落地）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `docs/superpowers/specs/2026-05-12-wordlite-home-entry-design.md` 中的首页布局（B）、队列（B1）、主按钮与副文案（2+C）、完成态（C）落到 Flutter UI，并在 `WordLiteRepository` 中提供稳定、可测的数据口径。

**Architecture:** 在仓库层补齐「今日队列拆分（新词数/复习数）」「会话内进度 x/y」「当日整段会话刚结束」等与 UI 直接相关的只读状态；`buildTodayQueue` 的复习洗牌改为**按自然日稳定种子**，保证首页预览的 `y` 与随后 `startOrResumeSession` 生成的队列一致。`HomeScreen` 重组为信息卡 + 主按钮 + 完成态强调区，不改动四步学习与 SRS 核心算法。

**Tech Stack:** Flutter、`provider`（`Consumer<WordLiteRepository>`）、`shared_preferences`、现有 `WordLiteRepository` / `SessionCheckpoint` / `UserStats`。

**前置阅读：** `WordLite_PRD.md` 4.1、`RALPH_LOOP.md` 验收命令。

---

## 文件与职责（落地前锁定）

| 文件 | 职责 |
|------|------|
| `lib/services/word_lite_repository.dart` | 稳定洗牌种子；今日队列拆分 API；会话完成态持久化标志；对外 getter（见各 Task）。 |
| `lib/screens/home_screen.dart` | 双信息卡、主按钮主副标题、完成态 C 布局与可见性；字符串与 PRD 对齐。 |
| `test/word_lite_repository_test.dart` | 新行为单测：稳定队列、拆分计数、完成态标志读写。 |
| `test/home_screen_test.dart`（新建，可选若 widget 测成本高则先只做仓库单测） | 黄金路径：有检查点时副文案、完成态隐藏主按钮等（可用 `Provider` + `MaterialApp` 包裹测 `find.text`）。 |

---

### Task 1: 稳定「复习段」洗牌种子（保证预览 y 与真实会话一致）

**Files:**

- Modify: `lib/services/word_lite_repository.dart`（`buildTodayQueue` 内 `Random(...)`）
- Test: `test/word_lite_repository_test.dart`

**说明：** 将 `Random(now.millisecondsSinceEpoch)` 改为基于 **当日零点** 的确定性种子（例如 `Random(todayStart.millisecondsSinceEpoch)` 或对 `dayKey` 做固定 hash 再 `Random(seed)`），使同一自然日内多次调用 `buildTodayQueue()` 得到**相同**的复习词顺序与队列长度。

- [x] **Step 1: 写失败单测（同日两次 build 应一致）**

在 `test/word_lite_repository_test.dart` 的 `group('WordLiteRepository')` 内新增：

```dart
test('buildTodayQueue：同一自然日内多次调用复习顺序一致', () async {
  final Map<String, dynamic> progressJson = <String, dynamic>{
    for (final WordEntry e in WordBank.all)
      e.id: WordProgress(
        wordId: e.id,
        stage: ReviewStage.learning,
        nextReviewAt: null,
      ).toJson(),
  };
  SharedPreferences.setMockInitialValues(<String, Object>{
    _kProgress: jsonEncode(progressJson),
  });
  final WordLiteRepository repo = WordLiteRepository();
  await repo.init();
  final List<String> a = repo.buildTodayQueue();
  final List<String> b = repo.buildTodayQueue();
  expect(b, a);
});
```

- [x] **Step 2: 运行测试确认失败**

运行：

```text
flutter test test/word_lite_repository_test.dart --plain-name "同一自然日内多次调用复习顺序一致"
```

**预期：** 失败（当前实现用毫秒级 `Random`，连续两次调用几乎必然不同）。

- [x] **Step 3: 最小实现**

在 `buildTodayQueue` 中，将：

```dart
dueIds.shuffle(Random(now.millisecondsSinceEpoch));
```

替换为（示例，可等价调整命名）：

```dart
final int shuffleSeed = todayStart.millisecondsSinceEpoch;
dueIds.shuffle(Random(shuffleSeed));
```

- [x] **Step 4: 运行测试确认通过**

同上 `flutter test ...`，**预期：** PASS。

- [x] **Step 5: 提交**

```bash
git add lib/services/word_lite_repository.dart test/word_lite_repository_test.dart
git commit -m "fix: stabilize daily review shuffle seed for queue preview"
```

---

### Task 2: 暴露「新词数 / 复习数 / 队列总长」只读 API

**Files:**

- Modify: `lib/services/word_lite_repository.dart`
- Test: `test/word_lite_repository_test.dart`

**说明：** 在**不写入检查点**的前提下，复用 `buildTodayQueue()` 的结果拆分：前缀为按词库顺序截取的新词 id，后缀为复习抽样。可新增私有方法 `_splitNewAndReview(List<String> queue)`：从 `WordBank.all` 顺序扫描「尚未出现在 `_progress`」的 id 作为新词前缀，其余为复习段；或根据 `buildTodayQueue` 构造逻辑用「最长前缀且每个 id 均无进度记录」拆分（与当前实现一致）。对外例如：

```dart
({int newCount, int reviewCount, int total}) get todayQueuePreviewCounts {
  final List<String> q = buildTodayQueue();
  ...
}
```

以及在有 `checkpoint` 且 `dayKey` 为今日时，优先用 `checkpoint.queueWordIds` 做拆分（与已开始会话一致）。

- [x] **Step 1: 单测 — 无进度时 preview 新词为 5、复习为 0**

```dart
test('todayQueuePreviewCounts：无进度时仅新词段', () async {
  final WordLiteRepository repo = WordLiteRepository();
  await repo.init();
  final ({int newCount, int reviewCount, int total}) c =
      repo.todayQueuePreviewCounts;
  expect(c.newCount, WordLiteRepository.newWordsPerDay);
  expect(c.reviewCount, 0);
  expect(c.total, WordLiteRepository.newWordsPerDay);
});
```

（若 getter 命名不同，在实现 Task 中同步改名。）

- [x] **Step 2: 运行失败 → Step 3 实现 getter → Step 4 通过 → Step 5 commit**（命令同 Task 1 模式，`flutter test test/word_lite_repository_test.dart` 相关用例）。

---

### Task 3: 「整段会话刚结束」标志（完成态 C）

**Files:**

- Modify: `lib/services/word_lite_repository.dart`（`_completeCurrentWord` 末支、`startOrResumeSession`、`abandonCheckpoint`、`_rollDailyIfNeeded`、`_persist`、`_loadFromPrefs`）
- Test: `test/word_lite_repository_test.dart`

**行为定义：**

- 当 `_completeCurrentWord` 在 **成功** 完成 **当日队列最后一个词** 并将 `_checkpoint` 置 `null` 时，将持久化标志 **`wl_session_done_home_v1`**（示例键名，可调整但须单测覆盖）设为 `true`。
- 当用户调用 `startOrResumeSession()` 并**新建**或**沿用**当日检查点时，将该标志置 `false`。
- 当 `abandonCheckpoint()` 时置 `false`（避免误显示完成态）。
- `_rollDailyIfNeeded` 换日时置 `false`。
- 对外：`bool get shouldShowHomeSessionCompleteCelebration`（或更短命名）为 `true` 当且仅当标志为 `true` 且 `!hasActiveCheckpoint`。

- [x] **Step 1: 单测「多词队列整段完成后标志为 true，再 start 后变 false」**

伪代码级断言（实现时写成合法 Dart）：

```dart
test('整段会话完成后首页完成态为 true，重新开始后为 false', () async {
  // 预置进度使 buildTodayQueue 长度 >= 2（可参考现有「多词队列」测试的造数方式）
  // await repo.startOrResumeSession();
  // 循环 onStepCorrect 直到 checkpoint == null 且 shards 增加
  // expect(repo.shouldShowHomeSessionCompleteCelebration, isTrue);
  // await repo.startOrResumeSession();
  // expect(repo.shouldShowHomeSessionCompleteCelebration, isFalse);
});
```

（具体造数可直接复制 `test/word_lite_repository_test.dart` 中 `多词队列` 相关用例的 `SharedPreferences` 初始 JSON 并补全循环。）

- [x] **Step 2–5:** 红 → 绿 → `flutter test test/word_lite_repository_test.dart` → commit。

---

### Task 4: `HomeScreen` UI — 信息卡 B、主按钮 2+C、完成态 C、文案对齐 spec

**Files:**

- Modify: `lib/screens/home_screen.dart`
- Test（推荐）: `test/home_screen_test.dart` 新建；若时间紧，至少保留 Task 1–3 仓库单测全绿。

**UI 规则（对照 spec）：**

1. **双卡片**：只读展示「新词 · N」「复习 · M」，数据来自 `todayQueuePreviewCounts`；若 `hasActiveCheckpoint`，拆分应以 `checkpoint.queueWordIds` 为准（与 Task 2 的 getter 设计一致）。
2. **主按钮**：非完成态用 `FilledButton`：`hasActiveCheckpoint ? '继续学习' : '开始学习'`。完成态（C）用 `OutlinedButton` 文案 **「再学一组」**（见 `docs/superpowers/specs/2026-05-12-wordlite-home-entry-design.md` 4.3 / 5.2）。
3. **进度副文案**：有检查点 → `本会话：已完成 x / y`；无检查点且非完成态 → `进度：今日已通关 t / 计划 y 个词`（`t` 与统计卡「今日完成」一致）；完成态 → 总结行「今日已通关 … · 本日计划共 …」。
4. **完成态 C**：当 `shouldShowHomeSessionCompleteCelebration` 为 `true` 时：主入口为次要 `OutlinedButton`「再学一组」；统计 `Card` 前置并强化为「今日成就」区块；保留 AppBar 家长入口。
5. **重置今日会话**：在完成态下仍可显示；点击后调用 `abandonCheckpoint()`（并依赖 Task 3 清除完成态标志）。

- [x] **Step 1（可选 widget 测）:** `pumpWidget` 带 `ChangeNotifierProvider`，断言 `本会话：已完成 0 / 2`、完成态 `再学一组`、`进度：今日已通关` 等（见 `test/home_screen_test.dart`）。

- [x] **Step 2:** `flutter analyze` 无新增问题。

- [x] **Step 3:** `flutter test` 全绿。

- [x] **Step 4:** commit message 示例：`feat(home): align home entry with superpowers design spec`。

---

## 计划自检（writing-plans Self-Review）

**1. Spec coverage**

| Spec 章节 | 对应 Task |
|-----------|-----------|
| 双信息卡只读（B） | Task 2 + Task 4 |
| 同队列 B1、主按钮 2 | Task 4 |
| 主标题 + 副文案 C + 完成态「再学一组」 | Task 4 |
| 完成态 C + 5.2 空队列口径 | Task 3 + Task 4 |
| y 与真实队列一致 | Task 1 + Task 2 |

**2. Placeholder 扫描：** 无 TBD；单测中「造数」步骤要求从现有测试复制可运行 JSON。

**3. 类型与命名一致性：** `todayQueuePreviewCounts` 若改为类或 `HomeQueuePreview` record，全计划统一一名称。

4. **已知产品边角（随实现修订，以 design spec 5.2 为准）：**

- 进度副文案已拆为 **本会话** / **今日已通关 + 计划** 两行口径，与放弃会话后的统计卡一致。
- **完成态** 与「暂无可学单词」SnackBar：**不**在仓库层用 `buildTodayQueue` 为空压制完成态；用户点「再学一组」且仍无队列时再 SnackBar（见 design spec 5.2）。

---

## 执行交接

**计划已保存至：** `docs/superpowers/plans/2026-05-12-wordlite-home-entry.md`

**两种执行方式：**

1. **Subagent-Driven（推荐）** — 每个 Task 派生子代理，任务间人工快速验收。  
2. **Inline Execution** — 本会话按 Task 顺序执行，配合 `executing-plans` 的检查点节奏。

请回复 **1** 或 **2** 开始落地实现；若先自行实现，以 `RALPH_LOOP.md` 的 `flutter analyze` / `flutter test` 为完成定义。
