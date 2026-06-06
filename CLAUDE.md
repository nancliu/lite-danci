# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WordLite（轻单词）— 小学生英语单词学习 Android 应用，Flutter 构建，完全离线、本地存储（SharedPreferences），无后端。产品需求唯一来源：`WordLite_PRD.md`。

## Commands

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze

# 运行全部测试
flutter test

# 运行单个测试
flutter test test/review_srs_test.dart

# Windows 桌面预览（快速看 UI，TTS 行为以平台为准）
flutter run -d windows

# Android 真机 / 模拟器
flutter run -d <device_id>

# Ralph Loop：自动多轮 analyze + test 直至全绿（最多 8 轮）
.\tools\ralph_loop.ps1

# 词包制作：CSV → JSON
dart run tool/word_pack_csv_to_json.dart input.csv output.json
```

## Architecture

### State Management — Provider + ChangeNotifier

`WordLiteRepository`（`lib/services/`）是唯一状态容器，在 `main.dart` 通过 `ChangeNotifierProvider` 注入。所有 UI 通过 `Consumer` / `Selector` / `context.read()` 访问。没有路由层；页面间直接 `Navigator.push`。

### Data Flow

```
main.dart → WordBank.loadEmbeddedPacks() → WordLiteRepository.init() → runApp
                                    ↓
HomeScreen ──→ startOrResumeSession() ──→ LearnScreen ──→ onStepCorrect/onStepWrong
                    ↓                                           ↓
            SessionCheckpoint                              ReviewSrs (pure)
            SharedPreferences                             (stage transitions)
```

### Key Layers

| Layer | Files | Role |
|-------|-------|------|
| **Models** | `lib/models/` | Immutable data classes: `WordEntry`, `WordProgress`, `ReviewStage`, `SessionCheckpoint`, `UserStats` |
| **Services** | `lib/services/` | `WordLiteRepository` (state + persistence + business rules), `ReviewSrs` (pure SRS math, no I/O) |
| **Data** | `lib/data/` | `WordBank` (built-in vocab + embedded pack merging), `WordPackLoader` (JSON parse + dedup) |
| **Screens** | `lib/screens/` | `HomeScreen`, `LearnScreen`, `ParentScreen` — all stateful/stateless widgets |
| **Android native** | `android/.../WordLiteAndroidTtsPlugin.kt` | Single `TextToSpeech` instance via MethodChannel `com.wordlite.app/android_tts` |

### Core Business Rules (PRD-aligned)

- **SRS stages**: `learning → review_1 → review_3 → review_7 → review_14 → mastered`
- **Review intervals**: +1, +3, +7, +14 days after stage advance; wrong answer regresses one stage
- **Daily queue**: up to 5 new words + up to 8 review words (no padding)
- **Rewards**: +1 energy per completed word; +1 shard when entire session completes; 10 shards → 1 skin unlock (3 levels)
- **Session checkpoint**: auto-saved on each step; survives app kill; "abandon checkpoint" resets uncompleted session

### TTS Architecture (Android-specific)

On Android, `LearnScreen` uses the native `WordLiteAndroidTtsPlugin` (singleton `TextToSpeech`) via MethodChannel — **not** `flutter_tts`. Using `FlutterTts()` on Android creates a second TTS instance that can hang on some ROMs. On non-Android platforms, `flutter_tts` is used as fallback.

### Word Pack System

- Built-in 20 words in `WordBank._builtInList`
- Extendable via JSON files in `assets/word_packs/` (registered in `pubspec.yaml` assets)
- `WordBank.loadEmbeddedPacks()` merges them at startup; duplicate IDs are skipped
- `WordEntry.emoji` is optional — missing/empty falls back to `🔤` placeholder

### Persistence Keys

All SharedPreferences keys are prefixed `wl_` and versioned `_v1` (e.g. `wl_progress_v1`, `wl_checkpoint_v1`). Changing key names or formats breaks existing user progress — maintain backward compatibility.

## Development Workflow

Follow the **Ralph Loop** convention (documented in `RALPH_LOOP.md`): implement → `flutter analyze` → `flutter test` → fix → repeat until zero errors and all tests green.

MVP completion definition: `flutter analyze` clean, `flutter test` green, all features aligned with `WordLite_PRD.md` §3–6.

## Design Specs

Detailed designs live in `docs/superpowers/specs/`:
- `2026-05-12-wordlite-home-entry-design.md` — home screen layout, progress copy, queue card read-only sheet
- `2026-05-12-wordlite-prd-4.2-srs-design.md` — SRS rules and stage transitions
- `2026-05-12-wordlite-prd-4.3-rewards-design.md` — energy, shards, skin unlock
- `2026-05-12-wordlite-prd-4.4-parent-stats-design.md` — parent statistics
- `2026-05-12-wordlite-prd-4.5-word-bank-design.md` — word pack format and loading

## Testing

Test files in `test/` mirror the source structure: `review_srs_test.dart`, `word_lite_repository_test.dart`, `word_bank_load_test.dart`, `word_pack_loader_test.dart`, `word_entry_json_test.dart`, `home_screen_test.dart`, `parent_screen_test.dart`, `widget_test.dart`.

`WordBank.resetForTest()` clears embedded pack entries for test isolation.
