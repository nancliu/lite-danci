# Ralph Loop（本项目约定）

Ralph Loop 指：**执行 → 用命令与验收标准评估 → 修复 → 重复**，直到「完成定义」满足为止，而不是单次生成就结束。

## 一轮循环里建议做的事

1. **执行**：实现或修改需求（小步提交）。
2. **评估**：在项目根目录运行（需已安装 Flutter）：
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
3. **修复**：根据报错与测试失败改代码。
4. **重复**：回到步骤 1，直到分析零报错、测试全绿。

## Windows 一键脚本

在 PowerShell 中（项目根目录）：

```powershell
.\tools\ralph_loop.ps1
```

脚本会最多循环 8 轮，每轮执行 `pub get`、`analyze`、对 `test/*_test.dart` 的显式聚合测试（`widget_test.dart` 排在最后，避免部分环境下漏跑），全部通过则退出 0。

## 本 MVP 的完成定义（可随时补充）

- `flutter analyze` 无错误。
- `flutter test` 通过。
- 学习四步、间隔重复、每日队列、检查点、奖励与家长页与 `WordLite_PRD.md` 一致且无已知逻辑冲突。

## 初版（MVP）提交前自检

在宣称「初版可交付」或打 tag / 发版前，建议逐项确认（可与 Ralph Loop 最后一轮合并执行）：

1. **命令**：项目根目录执行 `flutter pub get`、`flutter analyze`、`flutter test`（或使用 `.\tools\ralph_loop.ps1`），结果零报错、测试全绿。
2. **PRD**：对照 `WordLite_PRD.md` 第 3～6 节与 MVP 验收标准，核心路径（当日队列 → 四步 → 答错回退/答对进阶 → 检查点恢复 → 奖励与家长只读统计）无已知偏差。
3. **首页设计**：对照 `docs/superpowers/specs/2026-05-12-wordlite-home-entry-design.md`（含 4.3 进度文案、**队列卡片只读弹层**、5.2 完成态 / 空队列口径），与 `lib/screens/home_screen.dart` 表现一致。
4. **词库与 SRS 设计文档**：与 `docs/superpowers/specs/2026-05-12-wordlite-prd-4.5-word-bank-design.md`、`2026-05-12-wordlite-prd-4.2-srs-design.md` 等及实现对齐（扩展词包、复习规则、家长统计等）。
5. **仓库与持久化**：关键键名与 `WordLiteRepository` 行为未破坏既有学习进度（必要时在真机或干净安装上做一次冒烟：安装 → 学一词 → 杀进程 → 再开 → 检查点仍在）。
6. **Git**：`.gitignore` 已排除 `build/`、`.dart_tool/`、`android/.gradle/`、`.superpowers/` 等，勿将密钥或本地缓存提交进仓库。
7. **Android 听音**：学习页「播放读音」可正常发声；实现上 Android 仅用 `WordLiteAndroidTtsPlugin` 单路 TTS，勿在 `LearnScreen` 再 `FlutterTts()`，以免双实例在部分机型上无声或挂起。系统 TTS 相关入口宜放在独立「设置」页（需求草案见 `WordLite_PRD.md` **3.3**），学习页保持简洁。
