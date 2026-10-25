# Sweeep

**Clean your phone's photo library without sending a single photo anywhere.**

Sweeep finds duplicate, near-identical, blurry and dark photos, screenshots and oversized videos, then
lets you review them in a swipe-and-delete flow. All analysis runs **on the device**: no AI, no cloud,
no uploads, no account. Fingerprinting is done by a native **Rust core**; the UI is **Flutter**.

<p align="center"><img src="docs/screenshots/hero.png" alt="Sweeep: home feed, swipe, hub and storage map" width="100%"></p>

<p align="center">
  <img src="docs/screenshots/swipe.gif" alt="Swipe to trash: the SWIIIIPE headline stretches, then CLEAAAN" width="260">
  &nbsp;&nbsp;
  <img src="docs/screenshots/home-scroll.gif" alt="Home feed: the reclaimable-space oval collapses into a chip on scroll" width="260">
</p>

<sub>Screens above are the interactive design prototype the app is built from; the Flutter app on a real phone is shown further down.</sub>

> Status: Android is working end to end (scan -> groups -> review -> swipe -> trash -> system delete).
> iOS is designed but not implemented. Product spec: [`docs/SPECIFICATION.md`](docs/SPECIFICATION.md).

## Features

- **Duplicates and similar photos.** Exact copies by SHA-256 (only files that share a size are hashed),
  look-alikes by perceptual hashes (pHash / dHash / aHash) with a Hamming threshold, grouped with
  complete linkage and a size cap so a park full of dog photos doesn't snowball into one giant group.
  The sharpest frame is preselected as the best pick.
- **Blurry and dark frames** from Laplacian variance and median brightness.
- **Home feed** with a glowing "reclaimable space" ring that collapses into a chip on scroll, and
  carousels for Duplicates, Similar, Screenshots, Videos and Blurry & dark.
- **Group pager.** Swipe through groups, tap a copy to flip it between KEEP and TRASH. Similar groups
  default to *keep all*; exact duplicates default to trashing the extras.
- **Swipe mode.** Left = trash, right = keep, with Undo and a stretchy "SWIIIIPE" headline that grows
  with the gesture.
- **Safe deletion.** Everything goes to an in-app soft trash first. "Delete forever" uses Android's
  `MediaStore.createDeleteRequest` (one system confirmation per batch) and only forgets assets the
  system really deleted. Nothing is ever deleted automatically.
- **Resumable and incremental.** Hash results are checkpointed (kill the app mid-scan and it resumes),
  and a delta re-sync after the first scan touches only what changed.
- English, Russian and Italian UI, dark "Obsidian + Lavender" design with a defined colour role per action.

## On a real phone

<p>
  <img src="docs/p1-onboarding.png" alt="Onboarding on device" width="220">
  <img src="docs/p1-dialog.png" alt="Android permission dialog" width="220">
  <img src="docs/p1-resync-crop.png" alt="Index and re-sync on device" width="220">
</p>

Early device captures (Samsung S23). More captures: [`docs/goal-shots`](docs/goal-shots), [`docs/nav-shots`](docs/nav-shots), [`docs/wrap-shots`](docs/wrap-shots).

## More screens

<p>
  <img src="docs/screenshots/groups.png" alt="All groups" width="190">
  <img src="docs/screenshots/pager.png" alt="Group pager" width="190">
  <img src="docs/screenshots/session.png" alt="Cleanup session" width="190">
  <img src="docs/screenshots/week.png" alt="Weekly report" width="190">
</p>
## Numbers (measured on a Samsung S23, Android 15, 10,658 files)

| Step | Result |
|---|---|
| MediaStore full index | 2.2 s |
| Delta re-sync (no changes) | 0.2 s |
| Thumbnails (128 px) | ~22 ms each |
| Perceptual hashing, Rust core | 34.5 s total (~3.2 ms/file) |
| Found | 12 exact-duplicate groups, 766 similar groups |

More in [`docs/benchmarks.md`](docs/benchmarks.md): 100k-photo synthetic library benchmarks for the
queries behind Home, Timeline and Swipe.

## Architecture

```
core/   Rust analysis core: pHash/dHash/aHash, Laplacian, SHA-256, grouping (24 tests, benchmark example)
app/    Flutter app: Riverpod, go_router, Drift (SQLite) schema, Pigeon contract to Kotlin/Swift,
        dart:ffi bridge to the Rust library
```

- **Why Rust for analysis:** a BK-tree on 64-bit hashes took ~44 s for 50k photos; multi-index hashing
  in the Rust core does it in ~0.27 s.
- **Platform layer:** Kotlin (MediaStore, delete requests) behind a Pigeon-generated contract;
  Swift/PhotoKit is specified for iOS.
- **Storage:** Drift tables for assets, hashes, groups, decisions, trash and scan state.
- 14 Flutter test files plus the Rust tests.

## Build

Rust core and Android library:

```bash
cd core
cargo test
cargo run --release --example bench      # 50k-thumbnail throughput check
rustup target add aarch64-linux-android
bash scripts/build_core_android.sh       # copies libsweeep_core.so into the Android project
```

Flutter app:

```bash
cd app
flutter pub get
dart run pigeon --input pigeon/media_api.dart   # regenerate Dart/Kotlin/Swift messages
dart run build_runner build                      # regenerate the Drift code
flutter analyze && flutter test
flutter build apk --debug
```

Generated files (`*.g.dart`, `Messages.g.*`) are git-ignored; regenerate after a fresh clone.

## Docs

[`SPECIFICATION.md`](docs/SPECIFICATION.md) (Russian) - [`DEVLOG.md`](docs/DEVLOG.md) (phase-by-phase notes
and device measurements) - [`benchmarks.md`](docs/benchmarks.md) - [`visual-audit.md`](docs/visual-audit.md)