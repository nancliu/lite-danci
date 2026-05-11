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
