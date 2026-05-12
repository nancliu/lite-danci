# WordLite

面向小学生的英语单词学习应用（Flutter / Android），本地存储、离线可用。

## 环境要求

- [Flutter](https://docs.flutter.cn/get-started/install) 稳定版（建议 3.22+）
- Android SDK（目标设备为安卓手机）

## 运行

```bash
cd 项目根目录
flutter pub get
flutter run
```

**在本机快速看界面（Windows 桌面）**：已包含 `windows/` 目标，可在开发机直接弹出窗口预览 UI（与真机布局接近，TTS 等行为以平台为准）：

```bash
flutter run -d windows
```

**在安卓手机 / 模拟器上运行**（与产品目标一致）：连接设备或启动模拟器后执行 `flutter devices`，再 `flutter run -d <设备 id>`。

若已安装 **Android Emulator** 并创建过 AVD，可在项目根用 PowerShell 启动默认模拟器：

```powershell
.\tools\start_android_emulator.ps1
```

指定 AVD 名称：`.\tools\start_android_emulator.ps1 -AvdName "你的AVD名"`。

若缺少 `android/gradlew` 或 Gradle Wrapper 等文件，可在项目根目录执行 `flutter create .`（会补齐平台工程，不覆盖已有 `lib/`）。

首次构建前请在本机安装 Flutter，并确保 `android/local.properties` 中 `flutter.sdk` 指向你的 Flutter 安装目录（通常由 `flutter` 工具自动生成）。

## 功能概要

- 每日任务：新词 5 个、复习词 5～8 个
- 学习四步：看图识词 → 听音选词 → 看词选图 → 例句填空（挖空选英文词）
- 间隔重复：`learning → review_1 → … → mastered`，答错按 PRD 回退
- 中断恢复：自动保存当前进度
- 奖励：能量、碎片与皮肤解锁
- 家长页：今日学习、累计掌握、连续天数、较昨日变化

详细需求见根目录 `WordLite_PRD.md`。

## 持续迭代（Ralph Loop）

开发与自检流程见 `RALPH_LOOP.md`；Windows 下可运行 `.\tools\ralph_loop.ps1` 自动多轮执行 `analyze` / `test` 直至通过。
