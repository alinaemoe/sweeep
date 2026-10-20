# Benchmarks

Targets are from `SPECIFICATION.md` section 10: first scan of 50k photos <= 15 min, rescan <= 1 min, peak memory <= 300 MB, 60 fps, cold start <= 2 s.

## Dart / SQLite on a synthetic library

`BENCH=1 flutter test test/bench` (PowerShell: `$env:BENCH=1; flutter test test/bench`). Builds 50k and 100k fake photos in an in-memory Drift DB (bursts, exact copies, screenshots, videos, chat media over 6 years) and times the queries behind Home, Timeline, Swipe and group building. Dev machine; a phone is about 3-5x slower.

100k photos, ms:

| Step | Before | After |
|---|---:|---:|
| Home load | 262 | 145 |
| Timeline `months()` | 372 | 92 |
| Swipe `queue(all)` | 16 | 0 |
| Swipe `queue(month)` | 54 | 0 |
| rebuild groups, cold | 1079 | ~870 |
| rebuild groups, nothing changed | 465 | ~460 |
| groups(similar), all | 108 | 87 |
| categories (videos / screenshots / chat) | 29 / 27 / 16 | 7 / 51 / 8 |

What changed: index on `assets(media_type, created_at_ms)` (DB schema 2), Timeline previews by range scan instead of a window function, Home loads only the first 30 groups per kind plus SQL totals instead of every group with all members.

50k photos is about half of every number. Everything grows linearly, nothing blows up.

## On the phone (Samsung SM-S911B, 10.6k photos, release build)

| Step | Measured | 50k projection |
|---|---|---|
| MediaStore enumerate | 2.2 s | ~11 s |
| Delta rescan | 0.2 s | ~1 s |
| Gray thumbnail | ~22 ms each | |
| Hashing all (Rust FFI) | 34.5 s | ~2.9 min |
| Cold start slow raster frames | 15 -> 2 | |
| Scroll slow raster frames | ~0 | |

Rust core (desktop): 50k thumbs hashed in 3.7 s, grouping 50k in 16 ms (5 s window) / 0.27 s (global).

## Not measured yet

- Peak memory on the phone with 50k+ photos (needs a big library or synthetic MediaStore fill).
- fps and cold start with a 50k+ library.
- Upgrade of an existing v1 database to v2 on a device (index creation). Fresh installs are covered by the tests.
- Foreground service battery cost on a long scan.
