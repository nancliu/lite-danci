# 词包（`assets/word_packs/`）

## 增加一批词

1. 按 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.5-word-bank-design.md` 的 JSON 字段写好文件（`exampleClozeEn` 须含 `___`，`exampleFillWrongEn` 至少 3 条）。
2. 在 `pubspec.yaml` 的 `flutter.assets` 中注册该文件路径。
3. 在 `lib/data/word_bank.dart` 的 `embeddedPackAssetPaths` 中加入同一路径。
4. 重新运行应用；单测环境若未加载资源，词表仍为内置列表。

仓库已内置示例：`extra_grade1_sample.json`（文具/教室 4 词）与 `elementary_grade1_more.json`（颜色与家庭成员等 12 词，均带 `gradeTag: 一年级`）。

## 用 CSV 生成 JSON

管道符 `|` 分隔，首行为表头（须与脚本内列名一致）。示例见 `tool/word_pack_csv_to_json.dart` 顶部注释。

```bash
dart run tool/word_pack_csv_to_json.dart 词表.csv 词表.json
```

将生成的 `词表.json` 复制到本目录并完成上述 2～3 步。
