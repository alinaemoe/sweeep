//! Grayscale helpers.

/// Area-average (box) resize of an 8-bit grayscale image into `dw x dh`
/// floating point samples. Averaging makes hashes stable against the
/// platform's thumbnail resampler.
pub fn resize_area(src: &[u8], sw: usize, sh: usize, dw: usize, dh: usize) -> Vec<f32> {
    assert!(sw > 0 && sh > 0 && dw > 0 && dh > 0, "empty dimensions");
    assert!(src.len() >= sw * sh, "buffer smaller than sw*sh");
    let mut out = vec![0f32; dw * dh];
    for dy in 0..dh {
        let y0 = dy * sh / dh;
        let y1 = (((dy + 1) * sh) / dh).max(y0 + 1).min(sh);
        for dx in 0..dw {
            let x0 = dx * sw / dw;
            let x1 = (((dx + 1) * sw) / dw).max(x0 + 1).min(sw);
            let mut sum = 0u32;
            for y in y0..y1 {
                let row = &src[y * sw..y * sw + sw];
                for &v in &row[x0..x1] {
                    sum += v as u32;
                }
            }
            let n = ((y1 - y0) * (x1 - x0)) as f32;
            out[dy * dw + dx] = sum as f32 / n;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn constant_image_stays_constant() {
        let img = vec![100u8; 64 * 48];
        let out = resize_area(&img, 64, 48, 8, 8);
        assert!(out.iter().all(|&v| (v - 100.0).abs() < 1e-4));
    }

    #[test]
    fn upscale_does_not_panic() {
        let img = vec![10u8, 20, 30, 40];
        let out = resize_area(&img, 2, 2, 8, 8);
        assert_eq!(out.len(), 64);
    }
}
