//! Behavioural tests on synthetic "photos": the hashes must survive the
//! edits real duplicates go through (resize, brightness, mild recompression
//! noise) and must separate genuinely different images.

use sweeep_core::gray::resize_area;
use sweeep_core::*;

fn scene(w: usize, h: usize, a: f64, b: f64, c: f64) -> Vec<u8> {
    let mut v = Vec::with_capacity(w * h);
    for y in 0..h {
        for x in 0..w {
            let (fx, fy) = (x as f64 / w as f64, y as f64 / h as f64);
            let mut p = 128.0
                + 70.0 * (fx * a * 6.28).sin() * (fy * b * 6.28).cos()
                + 45.0 * ((fx + fy) * c * 6.28).sin();
            // a sharp-edged "object" so there is high-frequency content
            if (fx - 0.5).abs() < 0.18 && (fy - 0.45).abs() < 0.22 {
                p += 40.0;
            }
            v.push(p.clamp(0.0, 255.0) as u8);
        }
    }
    v
}

fn box_blur(src: &[u8], w: usize, h: usize, passes: usize) -> Vec<u8> {
    let mut cur = src.to_vec();
    for _ in 0..passes {
        let mut next = cur.clone();
        for y in 1..h - 1 {
            for x in 1..w - 1 {
                let mut s = 0u32;
                for dy in 0..3 {
                    for dx in 0..3 {
                        s += cur[(y + dy - 1) * w + x + dx - 1] as u32;
                    }
                }
                next[y * w + x] = (s / 9) as u8;
            }
        }
        cur = next;
    }
    cur
}

fn to_u8(f: &[f32]) -> Vec<u8> {
    f.iter().map(|v| v.round().clamp(0.0, 255.0) as u8).collect()
}

#[test]
fn phash_survives_resize() {
    let big = scene(256, 192, 1.0, 1.0, 2.0);
    let small = to_u8(&resize_area(&big, 256, 192, 128, 96));
    assert!(hamming(phash(&big, 256, 192), phash(&small, 128, 96)) <= 6);
}

#[test]
fn phash_survives_brightness_shift() {
    let a = scene(128, 96, 1.0, 1.0, 2.0);
    let b: Vec<u8> = a.iter().map(|&v| v.saturating_add(18)).collect();
    assert!(hamming(phash(&a, 128, 96), phash(&b, 128, 96)) <= 6);
}

#[test]
fn phash_survives_light_noise() {
    let a = scene(128, 96, 1.0, 1.0, 2.0);
    let mut seed = 7u32;
    let b: Vec<u8> = a
        .iter()
        .map(|&v| {
            seed = seed.wrapping_mul(1664525).wrapping_add(1013904223);
            let n = ((seed >> 24) % 5) as i32 - 2;
            (v as i32 + n).clamp(0, 255) as u8
        })
        .collect();
    assert!(hamming(phash(&a, 128, 96), phash(&b, 128, 96)) <= 6);
}

#[test]
fn phash_separates_different_scenes() {
    let a = scene(128, 96, 1.0, 1.0, 2.0);
    let b = scene(128, 96, 3.0, 2.0, 5.0);
    assert!(hamming(phash(&a, 128, 96), phash(&b, 128, 96)) >= 16);
}

#[test]
fn dhash_and_ahash_track_pphash_on_resize() {
    let big = scene(256, 192, 1.0, 1.0, 2.0);
    let small = to_u8(&resize_area(&big, 256, 192, 128, 96));
    assert!(hamming(dhash(&big, 256, 192), dhash(&small, 128, 96)) <= 8);
    assert!(hamming(ahash(&big, 256, 192), ahash(&small, 128, 96)) <= 8);
}

#[test]
fn blur_lowers_laplacian_variance() {
    let sharp = scene(128, 96, 1.0, 1.0, 2.0);
    let blurry = box_blur(&sharp, 128, 96, 3);
    let (s, b) = (laplacian_variance(&sharp, 128, 96), laplacian_variance(&blurry, 128, 96));
    assert!(s > b * 2.0, "sharp {s} vs blurry {b}");
}

#[test]
fn dark_frame_detected_by_median() {
    let bright = scene(64, 64, 1.0, 1.0, 2.0);
    let dark: Vec<u8> = bright.iter().map(|&v| v / 8).collect();
    assert!(median_brightness(&bright) > 80);
    assert!(median_brightness(&dark) < 25);
}

#[test]
fn burst_is_grouped_and_best_pick_is_sharpest() {
    let sharp = scene(128, 96, 1.0, 1.0, 2.0);
    let soft = box_blur(&sharp, 128, 96, 1);
    let other = scene(128, 96, 3.0, 2.0, 5.0);
    let mk = |id: u32, img: &[u8], ts: i64| Item {
        id,
        hash: phash(img, 128, 96),
        ts_ms: ts,
        sharpness: laplacian_variance(img, 128, 96),
    };
    let items = vec![mk(1, &soft, 0), mk(2, &sharp, 1_500), mk(3, &other, 2_000)];
    let groups = group_similar(&items, &GroupParams { max_hamming: 10, window_ms: Some(5_000), max_group: 8 });
    assert_eq!(groups, vec![vec![1, 2]]);
    assert_eq!(best_pick(&items, &groups[0]), Some(2));
}

#[test]
fn exact_duplicates_are_found_by_sha256() {
    let a = scene(64, 64, 1.0, 1.0, 2.0);
    let b = a.clone();
    let mut c = a.clone();
    c[10] ^= 1;
    let entries = [(1, exact::sha256(&a)), (2, exact::sha256(&b)), (3, exact::sha256(&c))];
    assert_eq!(exact::group_exact(&entries), vec![vec![1, 2]]);
}
