//! 64-bit perceptual hashes (aHash, dHash, pHash) and Hamming distance.

use crate::gray::resize_area;

/// Average hash: 8x8 thumbnail, bit set where pixel > mean.
pub fn ahash(gray: &[u8], w: usize, h: usize) -> u64 {
    let px = resize_area(gray, w, h, 8, 8);
    let mean = px.iter().sum::<f32>() / 64.0;
    let mut bits = 0u64;
    for (i, &v) in px.iter().enumerate() {
        if v > mean {
            bits |= 1 << i;
        }
    }
    bits
}

/// Difference hash: 9x8 thumbnail, bit set where left pixel < right pixel.
pub fn dhash(gray: &[u8], w: usize, h: usize) -> u64 {
    let px = resize_area(gray, w, h, 9, 8);
    let mut bits = 0u64;
    for y in 0..8 {
        for x in 0..8 {
            if px[y * 9 + x] < px[y * 9 + x + 1] {
                bits |= 1 << (y * 8 + x);
            }
        }
    }
    bits
}

const N: usize = 32;

fn dct_table() -> [[f64; N]; N] {
    let mut t = [[0f64; N]; N];
    for (k, row) in t.iter_mut().enumerate() {
        for (n, cell) in row.iter_mut().enumerate() {
            *cell = (std::f64::consts::PI * (2 * n + 1) as f64 * k as f64 / (2 * N) as f64).cos();
        }
    }
    t
}

/// Perceptual hash: 32x32 thumbnail, 2-D DCT-II, keep the 8x8 low-frequency
/// block, bit set where a coefficient exceeds the median (DC excluded).
pub fn phash(gray: &[u8], w: usize, h: usize) -> u64 {
    let px = resize_area(gray, w, h, N, N);
    let t = dct_table();
    // rows
    let mut tmp = [[0f64; N]; N];
    for y in 0..N {
        for k in 0..8 {
            let mut s = 0.0;
            for x in 0..N {
                s += px[y * N + x] as f64 * t[k][x];
            }
            tmp[y][k] = s;
        }
    }
    // columns, only the 8x8 block we need
    let mut coef = [0f64; 64];
    for k in 0..8 {
        for l in 0..8 {
            let mut s = 0.0;
            for y in 0..N {
                s += tmp[y][l] * t[k][y];
            }
            coef[k * 8 + l] = s;
        }
    }
    let mut sorted: Vec<f64> = coef[1..].to_vec();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let median = sorted[sorted.len() / 2];
    let mut bits = 0u64;
    for (i, &c) in coef.iter().enumerate() {
        if i != 0 && c > median {
            bits |= 1 << i;
        }
    }
    bits
}

#[inline]
pub fn hamming(a: u64, b: u64) -> u32 {
    (a ^ b).count_ones()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hamming_basics() {
        assert_eq!(hamming(0, 0), 0);
        assert_eq!(hamming(0, u64::MAX), 64);
        assert_eq!(hamming(0b1010, 0b0110), 2);
    }

    #[test]
    fn identical_images_hash_identically() {
        let img: Vec<u8> = (0..64 * 64).map(|i| ((i * 31) % 251) as u8).collect();
        assert_eq!(phash(&img, 64, 64), phash(&img, 64, 64));
        assert_eq!(dhash(&img, 64, 64), dhash(&img, 64, 64));
        assert_eq!(ahash(&img, 64, 64), ahash(&img, 64, 64));
    }
}
