# Sweeep — project context (read first)

Mobile photo/video cleaner. UI text in English; docs/chat with the owner in Russian. 100% local analysis (hashes, metadata, heuristics) — NO AI, NO external APIs, nothing uploaded.
Full spec: `docs/SPECIFICATION.md`. Dev instructions + per-phase status: `README.md`. Read both before planning.

## Stack
- Flutter 3.47.7 at `D:\tools\flutter` (NOT on PATH). Git Bash: `export PATH="/d/tools/flutter/bin:$PATH"; export CI=true`.
- Riverpod 3.x, Drift (SQLite), Pigeon (Kotlin/Swift bridge), google_fonts pinned ^6.3.3 (^9 breaks), Plus Jakarta Sans.
- Rust core `core/` (sweeep_core) via dart:ffi: aHash/dHash/pHash, Laplacian blur, SHA-256, grouping. Android build: `bash scripts/build_core_android.sh` (arm64 only) -> jniLibs (git-ignored). `cd core && cargo test`.
- Android: minSdk 26, NDK forced to 27.1.12297006 (empty broken 28.2 folder; hook in app/android/build.gradle.kts).
- Dev phone: Samsung SM-S911B, adb serial RZCX92BMXPW, `$ANDROID_HOME/platform-tools/adb.exe`, screen 1080x2340 (screenshots shown at 923 wide: multiply coords by 1.17 for `input tap`). Build/install: `cd app && flutter build apk --debug`, `adb -s RZCX92BMXPW install -r build/app/outputs/flutter-apk/app-debug.apk`.
- NEVER tap "Trash"/delete on the owner's real photos during tests.

## Design (final)
Obsidian + Lavender: bg #0F1015, card #181920, brand lavender #B8A6FF, lime #D4F563 ONLY for keep/best pick, coral #FF5A5A for trash/delete. Stretchy-letter wordmark SW**EEE**P; SWIIIIPE stretches with swipe distance; CLEAAAN waves on delete; KEEEEP ONE in group pager. Home = feed of carousels with collapsing oval. Stacks are fanned frames. Tokens in `app/lib/core/theme.dart`.
Prototypes live in a private design-canvas artifact (8 boards): https://claude.ai/artifact/QbAi2ndjg5exNgcQUi35sq — read it with the Artifact tool (action "read") when building UI screens.

## Pipeline (implemented)
MediaStore enumerate (keyset paging) -> delta index in Drift `assets` -> 128px gray thumbs -> hashes (checkpointed in `hashes`, `analysisVersion`) -> exact dups (SHA-256 only for same-size files) -> groups persisted -> review UI (Groups grid + GroupPager). Soft trash only (`trash_items`/`decisions`, 30 days); no system delete yet.
Similar grouping: pHash Hamming <= 6, 5 s time window, single-link components split by complete-linkage, max 8 per group (core/src/group.rs). Pager: similar groups default KEEP all; exact dups default trash extras.

## Done
Phase 0 skeleton; Phase 1 permissions/enumeration/delta index/gray thumbs; 1b Rust core + FFI + hashing with resume; Phase 2 duplicates + similar review UI; similar-grouping tightening (verified on phone: 601 groups, max x8). Tests: 24+9 Rust, 20 Flutter, all green. Home/Swipe/Trash/system delete/category lists/intro/nav shell done and verified on phone (test delete only with a throwaway file pushed via adb, MSYS_NO_PATHCONV=1).

## Planned next (in rough order)
1. (done) Home feed, Swipe, Trash, system delete via createDeleteRequest + CLEAAAN overlay.
4. Categories: screenshots, videos, chat media, blur/dark; Dust & Water + Sound tools.
5. Foreground service (hashing stops if app is killed); arm64-only .so -> add other ABIs; iOS (Swift) untested; "limited access" permission path untested; groups rebuilt from scratch each run; thumbnail cache is unbounded (non-autoDispose family).
6. Postponed: Email/App Cleaner; monetization/paywall decision.
Also: add a Phase 2 status line to docs/SPECIFICATION.md (only README has it).
