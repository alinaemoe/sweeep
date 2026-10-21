# Sweeep — project context (read first)

Mobile photo/video cleaner. UI text in English; docs/chat with the owner in Russian. 100% local analysis (hashes, metadata, heuristics) — NO AI, NO external APIs, nothing uploaded.
Full spec: `docs/SPECIFICATION.md`. Dev instructions + per-phase status: `README.md`. Read both before planning.

## Stack
- Flutter 3.47.7 at `D:\tools\flutter` (NOT on PATH). Git Bash: `export PATH="/d/tools/flutter/bin:$PATH"; export CI=true`.
- Riverpod 3.x, Drift (SQLite), Pigeon (Kotlin/Swift bridge), Plus Jakarta Sans (+ Manrope for Cyrillic) bundled in assets/fonts (no google_fonts).
- Rust core `core/` (sweeep_core) via dart:ffi: aHash/dHash/pHash, Laplacian blur, SHA-256, grouping. Android build: `bash scripts/build_core_android.sh` (arm64-v8a, armeabi-v7a, x86_64, x86; needs `rustup target add` for each) -> jniLibs (git-ignored). `cd core && cargo test`.
- Android: minSdk 26, NDK forced to 27.1.12297006 (empty broken 28.2 folder; hook in app/android/build.gradle.kts).
- Dev phone: Samsung SM-S911B, adb serial RZCX92BMXPW, `$ANDROID_HOME/platform-tools/adb.exe`, screen 1080x2340 (screenshots shown at 923 wide: multiply coords by 1.17 for `input tap`). Build/install: `cd app && flutter build apk --debug`, `adb -s RZCX92BMXPW install -r build/app/outputs/flutter-apk/app-debug.apk`.
- NEVER tap "Trash"/delete on the owner's real photos during tests.

## Design (final)
Obsidian + Lavender: bg #0F1015, card #181920, brand lavender #B8A6FF, lime #D4F563 ONLY for keep/best pick, coral #FF5A5A for trash/delete. Stretchy-letter wordmark SW**EEE**P; SWIIIIPE stretches with swipe distance; CLEAAAN waves on delete; KEEEEP ONE in group pager. Home = feed of carousels with collapsing oval. Stacks are fanned frames. Tokens in `app/lib/core/theme.dart`.
Prototypes live in a private design-canvas artifact (13 boards, incl. D1 Timeline, D11 Storage map, D12 Cleanup session, D13 Session done): https://claude.ai/artifact/QbAi2ndjg5exNgcQUi35sq — read it with the Artifact tool (action "read") when building UI screens.

## Pipeline (implemented)
MediaStore enumerate (keyset paging) -> delta index in Drift `assets` -> 128px gray thumbs -> hashes (checkpointed in `hashes`, `analysisVersion`) -> exact dups (SHA-256 only for same-size files) -> groups persisted -> review UI (Groups grid + GroupPager). Soft trash (`trash_items`/`decisions`, 30 days); real delete via createDeleteRequest in chunks of 1000 (one system dialog per chunk). Sideload-only switch `sweeep.directDelete=true` in app/android/gradle.properties adds MANAGE_EXTERNAL_STORAGE and deletes without the dialog; keep it false for Play.
Similar grouping: pHash Hamming <= 6, 5 s time window, single-link components split by complete-linkage, max 8 per group (core/src/group.rs). Pager: similar groups default KEEP all; exact dups default trash extras.

## Done
Phase 0 skeleton; Phase 1 permissions/enumeration/delta index/gray thumbs; 1b Rust core + FFI + hashing with resume; Phase 2 duplicates + similar review UI; similar-grouping tightening (verified on phone: 601 groups, max x8). Tests: 24+9 Rust, 20 Flutter, all green. Home/Swipe/Trash/system delete/category lists/intro/nav shell done and verified on phone (test delete only with a throwaway file pushed via adb, MSYS_NO_PATHCONV=1).

## Planned next (in rough order)
1. (done) Home feed, Swipe, Trash, system delete via createDeleteRequest + CLEAAAN overlay.
4. (done) Categories; Tools tab = Water/Dust/Sound test tone generator (TonePlugin.kt AudioTrack).
5. (done) Foreground service `ScanService` keeps a scan alive in the background (swiping the app from recents still stops it; checkpoints resume next launch), all Android ABIs, groups diffed instead of rebuilt, thumbnail cache is autoDispose. Limited access (Android 14 "selected photos") shows a banner on Home with "Allow all" (re-requests the permission, re-syncs on grant and when the app resumes); checked on the emulator with `pm revoke READ_MEDIA_IMAGES/VIDEO` + `pm grant READ_MEDIA_VISUAL_USER_SELECTED`. Still open: iOS (Swift) untested.
6. Benchmarks: Dart/SQLite side done (`BENCH=1 flutter test test/bench`, results in docs/benchmarks.md; Home/Timeline/queue fast at 100k). Still open: phone-side peak memory, fps and cold start with 50k+ photos, v1->v2 DB upgrade check on the phone (schema is 2 now, index on assets).
7. (done) RU/EN localization via gen-l10n (app/lib/l10n: app_en.arb is the source, app_ru.arb; strings through the global `l10n`, dates/numbers via `fmtNum/fmtDate/fmtMonth`). Language follows the phone. Russian copy stays short and casual. Brand words stay English (SWEEEP, SWIPE, CLEAAAN, KEEEEP ONE); Cyrillic uses Manrope as fallback because Plus Jakarta Sans has none. The dev screen library_screen.dart is English only. Add a key to both ARBs (and `flutter gen-l10n`), test/l10n_test.dart checks parity.
8. (done) Storage map (D11) + Quick wins: `lib/index/storage_service.dart` (SQL rules, `safeWhere` is the number in the Home oval too), `lib/features/storage/*` (treemap with 8 gliding slots, Months/Types/Sources from `assets.bucket`/`chat_source`). Clean opens the filtered grid/Swipe (CategoryKind.quickWin / SwipeSource.quickWin), never trashes in one tap. Owner decisions for D11-D13 are in `docs/IDEAS.md` section 5.
8b. (done) Cleanup session (D12) + Session done (D13): `lib/index/session_service.dart` (streak from `decisions` with one forgiven day a week, week dots, month progress, deck = lookalikes first), `lib/features/session/*`, `SwipeScreen.session`. Entry card on the Swipe tab. Table `sessions` (schema v3). Daily reminder: `Reminder.kt` + `ReminderPlugin.kt` (inexact alarm re-armed after each fire and boot, stays quiet if a decision was made today by reading the app DB), settings in the bell sheet (`reminder_sheet.dart`), keys `reminder_on`/`reminder_minutes` in scan_state.
8c. (done) Month wrap (D14): `lib/index/month_wrap_service.dart` + `lib/features/wrap/month_wrap_screen.dart`. Shown once per month right after the last decision of a month in Swipe (flag `wrap_shown_YYYY-MM` in scan_state); reopens from a finished month on the Timeline. 'Save image' = RepaintBoundary -> PNG -> `ImageSaverPlugin.kt` -> Pictures/Sweeep (never shared). Test builds: `--dart-define=WRAP_DEMO=true` + long-press the Timeline headline opens the newest month's wrap. Full re-index (`sync(full: true)`) is needed whenever the visible library widens, because the delta sync only sees files modified since the last sync.
8d. NEXT ideas: widget, 'free by goal' (see docs/IDEAS.md).
9. Postponed: Email/App Cleaner; monetization/paywall decision.
Also: add a Phase 2 status line to docs/SPECIFICATION.md (only README has it).
