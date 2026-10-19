# Sweeep

On-device photo and video cleaner. No AI, no uploads. Full product spec: [`docs/SPECIFICATION.md`](../SPECIFICATION.md).

```
core/   Rust analysis core (pHash/dHash/aHash, Laplacian, SHA-256, grouping)
app/    Flutter app (theme tokens, Drift schema, Pigeon contract, placeholder home)
```

## Core

Android build: `bash scripts/build_core_android.sh` (needs `rustup target add aarch64-linux-android`);
copies `libsweeep_core.so` into `app/android/app/src/main/jniLibs/arm64-v8a/` (git-ignored, arm64 only for now).

```bash
cd core
cargo test
cargo run --release --example bench   # 50k-thumbnail throughput check
```

## App

Flutter 3.47.7 (stable) lives in `D:\tools\flutter` (not on PATH). From Git Bash:

```bash
export PATH="/d/tools/flutter/bin:$PATH"
cd app
flutter pub get
dart run pigeon --input pigeon/media_api.dart          # regenerates Dart/Kotlin/Swift messages
dart run build_runner build                             # regenerates lib/data/database.g.dart
flutter analyze && flutter test
```

Generated files (`*.g.dart`, `Messages.g.*`) are git-ignored; regenerate after a fresh clone.

Android: `flutter build apk --debug` works and the app was installed and launched via adb on a
Samsung SM-S911B (Impeller/Vulkan, no errors in logcat; screenshot in `docs/device-home.png`).
Not yet verified: iOS (needs a Mac). `flutter doctor` still warns about missing Android cmdline-tools.

NDK workaround: the SDK's `ndk/28.2.13676358` folder is empty (broken download), so
`android/build.gradle.kts` forces NDK 27.1.12297006 for all modules. Reinstall NDK 28.2 via
Android Studio SDK Manager and remove the workaround when convenient.

Known follow-ups: `sqlite3_flutter_libs` is end-of-life, switch to `drift_flutter` before shipping;
Kotlin package for Pigeon is `app.sweeep` while the generated `MainActivity` is `app.sweeep.sweeep`, align them.

## Phase 1 status (Android)

Verified on a Samsung SM-S911B (Android 15, API 35): onboarding → native "Allow all / Allow limited" dialog →
MediaStore full index of 10,658 files in 2.2 s → delta re-sync (0 changes) in 0.2 s →
128 px grayscale thumbnails at ~22 ms each. Unit tests cover paging, delta sync, removals and stats
against a fake media source (`flutter test`). Not yet covered: "Allow limited access" path on device,
delete flow (Phase 3), iOS.

## Phase 1b: Rust FFI + hashing (Android, verified on device)

`NativeCore` (dart:ffi) calls `sweeep_analyze` (pHash/dHash/aHash/Laplacian/median in one call) and
`sweeep_group_labels`. `AnalysisService` hashes 128 px gray thumbnails in batches of 64 (8 concurrent
thumbnail fetches); the `hashes` table is the checkpoint. On the SM-S911B: 10,658 files hashed in 34.5 s
(~3.2 ms/file), 3 unreadable, 771 burst groups (pHash <= 8, 5 s window) holding 1,899 files.
Killed the app at 2,432 hashed, relaunch resumed from 2,432. Laplacian variance p10/p50/p90 on 128 px
thumbnails: 537 / 1406 / 3431 (use for the blur threshold). Not yet: persisting groups, SHA-256 exact
duplicates, foreground service (hashing stops if the app is killed), armv7/x86 .so builds.

## Phase 2 (in progress): groups + review screens

Added: streaming SHA-256 on the Kotlin side (only for files that share a size), color JPEG thumbnails,
`GroupService` (exact groups keep the oldest copy, similar groups keep the sharpest; persisted in Drift;
soft-trash into `trash_items`), `GroupsScreen` (grid of stacks) and `GroupPager` (swipe through groups, tap
copies to flip TRASH/KEEP). On the SM-S911B the pipeline found 13 exact-duplicate groups (66.3 MB) and
766 similar groups (3.4 GB) from 10,658 files. 15 unit tests pass.

Verified on device: Groups grid and Group pager render real photo stacks and the pager works.
Found and fixed: MediaStore labels `.djvu` files as images (undecodable, 52 MB of fake "duplicates"),
now filtered (`image/vnd.*`, `image/svg*`). After the fix: 12 exact-duplicate groups (14.2 MB),
766 similar groups (3.4 GB), 1 unreadable file.

Known issue to calibrate: similar groups are chained (union-find), so a loose group of 15 dog photos
in the same park appears as one group and "Trash 14" is preselected. Needs a stricter rule (lower
Hamming threshold, complete-linkage or a max group size) and probably "keep all" as the default for
big similar groups. Nothing is deleted from the device yet; "Trash" only records ids in the app trash.

## Similar grouping tightened

- Default Hamming threshold 8 → 6.
- Single-linkage components are split with complete linkage (a photo joins only if close to every member) and capped at 8 per group, so chains of different poses no longer snowball. Max group on the test phone is now ×8 (was ×15–18).
- Review pager: Similar groups default to KEEP for every copy (button says "Keep all · next"); the user taps a copy to flip it to TRASH. Exact duplicates still default to TRASH for the extra copies.

## Home feed (done, verified on device)

`features/home/home_screen.dart`: pinned wordmark, oval with the reclaimable size (duplicates + similar savings of the library) that collapses into a compact chip with an inline "Free up" button on scroll, and carousels: Duplicates, Similar (fanned stacks), Screenshots, Videos (largest first), Blurry & dark (Laplacian < 250 or median brightness < 40). Data comes from `HomeService` (`homeProvider`, invalidated after group rebuild/trash). "Free up" opens the Duplicates/Similar list; Swipe / Videos / Tools / Trash entries show a "coming soon" snackbar until those screens exist. The old index screen is reachable from the gear button. Tests: `home_service_test.dart`.

## Swipe, Trash and system delete (done, verified on device)

`SwipeScreen` (drag left = soft trash, right = keep, Undo, stretchy SWIIIIPE) and `TrashScreen` (restore, select all, CLEAAAN overlay after a real delete). `ReviewService.deleteForever` calls `MediaStore.createDeleteRequest` (Android 11+, one system dialog per chunk of 200) and only forgets assets the system really deleted. Verified with a throwaway test file pushed via adb; the owner's photos were not touched. Android < 11 and iOS: not implemented.
