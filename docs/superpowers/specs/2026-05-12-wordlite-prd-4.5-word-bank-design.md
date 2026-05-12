# WordLite PRD §4.5 词库与扩展 — 设计说明

## 1. 目标与范围

- **保留**：离线可用、学习四步所需字段齐全（英文、释义、例句、挖空、填空正误项等）。
- **新增**：
  - **嵌入式词包**：随应用打包的 JSON，启动时合并进词表，顺序为 **内置列表在前、词包在后**（与「固定顺序取新词」一致：先学完内置再学扩展）。
  - **年级标签**：每条词可选 `gradeTag`（如 `一年级`），供后续按年级筛选；**本期不实现**按年级过滤队列，仅存储与展示预留。
  - **外部文档 → 应用词表**：提供 **CSV→JSON** 命令行工具，编辑者用表格维护后生成词包 JSON，放入 `assets/word_packs/` 并在代码中登记路径即可参与合并。

**明确不在本期**：应用内文件选择器导入、云同步词库、运行时从任意路径加载（避免权限与 MVP 范围膨胀）。

## 2. 方案对比（摘要）

| 方案 | 优点 | 缺点 |
|------|------|------|
| A. 仅继续手写 Dart `WordEntry` | 类型安全、零解析 | 不符合「外部文档」工作流 |
| B. 嵌入式 JSON + 启动合并（**采用**） | 离线、可审可 diff、与现有 `WordBank.all` 兼容 | 发版才能换包；需规范校验 |
| C. 应用内任意文件导入 | 灵活 | 权限、UX、测试成本高 |

## 3. 数据模型

- **`WordEntry`**：在现有字段上增加可选 **`gradeTag`**（`String?`）；增加 **`toJson` / `fromJson`** 供词包解析与测试。
- **词包 JSON**（文件级）支持两种顶层形态：
  - 对象：`{ "version": 1, "entries": [ ... ] }`
  - 数组：`[ { ... }, ... ]`
- **单条 `entries[]` 对象**字段与 `WordEntry` 对齐：`id`, `word`, `meaningZh`, `emoji`（**可省略或空**，解析为占位符 `🔤`，用于无图单词）、`exampleEn`, `exampleClozeEn`, `exampleFillAnswer`, `exampleFillWrongEn`（字符串数组，**至少 3 个**）、`gradeTag`（可选）。
- **校验**：`exampleClozeEn` 必须包含子串 `___`；`id` 非空；与内置 **id 重复** 的扩展条目不合并（跳过，避免覆盖内置）。

## 4. 运行时行为

- **`WordBank.loadEmbeddedPacks()`**：在 `main` 中于 `WordLiteRepository.init()` **之前** `await` 完成；使用 `rootBundle` 读取已登记资源路径列表，解析成功后追加到内部列表并重建只读视图。
- **`WordBank.all` / `WordBank.byId`**：对外仍通过 `WordBank` 访问；合并后列表顺序见 §2。
- **测试**：提供 **`WordBank.resetForTest()`**，清空已合并的扩展词，仅保留内置，避免单测间互相污染。

## 5. 外部文档工作流（推荐）

1. 用 **管道分隔** 的 CSV（避免英文例句中的逗号歧义），列见 `tool/word_pack_csv_to_json.dart` 文件头注释。
2. 运行：`dart run tool/word_pack_csv_to_json.dart <输入.csv> <输出.json>`。
3. 将 `输出.json` 放入 `assets/word_packs/`，在 `lib/data/word_bank.dart` 的 **嵌入式路径常量列表** 中增加该资源路径，并在 `pubspec.yaml` 的 `flutter.assets` 中注册。

## 6. 与 PRD 的关系

- 原 PRD「内置静态词表」扩展为：**内置 + 可选嵌入式 JSON**；仍 **无后端**。
- 「典型小学年级词」：通过 **`gradeTag` + 分文件词包**（如按册/年级拆分多个 JSON）承载；队列策略后续迭代可加筛选。

## 7. 单测与验收

- 解析器单测：合法 JSON、缺字段、缺 `___`、干扰项不足 3 条等。
- `WordEntry` JSON 往返。
- 仓库单测 `setUp` 中调用 **`WordBank.resetForTest()`**，保证与既有用例兼容。
- 随包示例：`extra_grade1_sample.json`（4 词）、`elementary_grade1_more.json`（一年级常见词 12 条）；`word_bank_load_test` 校验合并后总数（内置 20 + 扩展 16）。

## 8. 自检

- 无 TBD；与 `WordLite_PRD.md` 冲突时以 PRD 为准（PRD §4.5 已同步扩展表述）。
