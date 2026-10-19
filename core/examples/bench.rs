//! Rough throughput check for the 50k-photo target:
//! `cargo run --release --example bench`
//!
//! Hashes are pseudo-random 64-bit values (like real pHashes), with every
//! 5th photo a near-duplicate (3 flipped bits) of the previous one, shot
//! ~700 ms apart.

use std::time::Instant;
use sweeep_core::*;

fn main() {
    let (w, h) = (128usize, 128usize);
    let img: Vec<u8> = (0..w * h).map(|i| ((i * 37 + (i / w) * 11) % 251) as u8).collect();
    let n = 50_000usize;

    let t = Instant::now();
    let mut sink = 0u64;
    for i in 0..n {
        let mut v = img.clone();
        v[(i * 131) % (w * h)] = (i % 255) as u8;
        sink ^= laplacian_variance(&v, w, h) as u64;
        sink ^= phash(&v, w, h);
    }
    println!("phash + laplacian, {n} thumbs ({w}x{h}): {:?} (sink {sink})", t.elapsed());

    let mut s = 12345u64;
    let mut next = || {
        s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        s
    };
    let mut items: Vec<Item> = Vec::with_capacity(n);
    for i in 0..n {
        let hash = if i % 5 == 4 {
            let prev = items[i - 1].hash;
            prev ^ (1 << (next() % 64)) ^ (1 << (next() % 64)) ^ (1 << (next() % 64))
        } else {
            next()
        };
        items.push(Item { id: i as u32, hash, ts_ms: i as i64 * 700, sharpness: 1.0 });
    }

    let t = Instant::now();
    let g = group_similar(&items, &GroupParams { max_hamming: 8, window_ms: Some(5_000), max_group: 8 });
    println!("group_similar (5 s window): {:?} ({} groups)", t.elapsed(), g.len());

    let t = Instant::now();
    let g = group_similar(&items, &GroupParams { max_hamming: 8, window_ms: None, max_group: 8 });
    println!("group_similar (global, multi-index): {:?} ({} groups)", t.elapsed(), g.len());
}
