# WordLite PRD §4.5 词库扩展 — Implementation Plan

> **For agentic workers:** 可按任务顺序执行；步骤使用 `- [ ]` 勾选。

**Goal:** 支持嵌入式 JSON 词包合并、可选年级标签、CSV→JSON 工具链；启动加载；测试可重置词表。

**Architecture:** `WordPackLoader` 纯解析；`WordBank` 内置列表 + 扩展列表合并；`main` 在 `repo.init` 前 `await WordBank.loadEmbeddedPacks()`。

**Tech Stack:** Flutter `rootBundle`、`dart:convert`；可选 `gradeTag` 于 `WordEntry`。

---

### Task 1: 模型与解析器

**Files:**

- Modify: `lib/models/word_entry.dart`
- Create: `lib/data/word_pack_loader.dart`

- [x] `WordEntry`：可选 `gradeTag`；`toJson` / `fromJson`；校验 `exampleFillWrongEn.length >= 3`、`exampleClozeEn.contains('___')`。
- [x] `WordPackLoader.parsePackJson(String json)` 返回带 `errors` 的结果类型；支持顶层 `{entries:[]}` 与 `[]`。

---

### Task 2: WordBank 合并与加载

**Files:**

- Modify: `lib/data/word_bank.dart`
- Modify: `lib/main.dart`

- [x] 抽出内置 `_builtInList`；`_extraEntries`；`resetForTest()`；`loadEmbeddedPacks()` 读资源列表、去重 id。
- [x] `pubspec.yaml` 注册 `assets/word_packs/`
- [x] `main.dart`：`await WordBank.loadEmbeddedPacks()` 于 `repo.init()` 前。

---

### Task 3: 示例词包与工具

**Files:**

- Create: `assets/word_packs/extra_grade1_sample.json`
- Create: `assets/word_packs/elementary_grade1_more.json`（一年级补充 12 词）
- Create: `tool/word_pack_csv_to_json.dart`（`|` 分隔，列顺序见脚本注释）

---

### Task 4: 文档与 PRD / Issue

**Files:**

- Modify: `WordLite_PRD.md` §4.5 + §4.5.5 验收勾选
- Modify: `.github/prd_tracking_issue_body.md`
- Create: `docs/superpowers/specs/2026-05-12-wordlite-prd-4.5-word-bank-design.md`（已完成）
- Create: `assets/word_packs/README.md`（简短：如何加包、如何跑 CSV 工具）

---

### Task 5: 测试

**Files:**

- Create: `test/word_pack_loader_test.dart`
- Create: `test/word_entry_json_test.dart`（或与上合并）
- Modify: `test/word_lite_repository_test.dart`：`setUp` 首行 `WordBank.resetForTest()`；检查点恢复用例

- [x] `flutter analyze` / `flutter test`

---

## Plan self-review

- 覆盖：JSON 合并、CSV 工具、年级字段预留、测试隔离。
- 无 TBD 占位。
