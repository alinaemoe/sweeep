//! Sharpness and brightness metrics (no AI).

/// Variance of the 3x3 Laplacian response. Low = blurry.
/// Returns 0.0 when the image is smaller than 3x3.
pub fn laplacian_variance(gray: &[u8], w: usize, h: usize) -> f64 {
    if w < 3 || h < 3 || gray.len() < w * h {
        return 0.0;
    }
    let mut sum = 0f64;
    let mut sum_sq = 0f64;
    let mut n = 0f64;
    for y in 1..h - 1 {
        for x in 1..w - 1 {
            let c = gray[y * w + x] as f64;
            let lap = gray[(y - 1) * w + x] as f64
                + gray[(y + 1) * w + x] as f64
                + gray[y * w + x - 1] as f64
                + gray[y * w + x + 1] as f64
                - 4.0 * c;
            sum += lap;
            sum_sq += lap * lap;
            n += 1.0;
        }
    }
    let mean = sum / n;
    sum_sq / n - mean * mean
}

/// Median pixel value (0..=255). Low = dark / pocket shot.
pub fn median_brightness(gray: &[u8]) -> u8 {
    if gray.is_empty() {
        return 0;
    }
    let mut hist = [0u32; 256];
    for &v in gray {
        hist[v as usize] += 1;
    }
    let half = (gray.len() as u32).div_ceil(2);
    let mut acc = 0u32;
    for (v, &c) in hist.iter().enumerate() {
        acc += c;
        if acc >= half {
            return v as u8;
        }
    }
    255
}

/// Rec. 601 luma from an RGBA buffer.
pub fn rgba_to_gray(rgba: &[u8]) -> Vec<u8> {
    rgba.chunks_exact(4)
        .map(|p| ((p[0] as u32 * 299 + p[1] as u32 * 587 + p[2] as u32 * 114) / 1000) as u8)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn flat_image_has_zero_laplacian_variance() {
        assert_eq!(laplacian_variance(&vec![90u8; 20 * 20], 20, 20), 0.0);
    }

    #[test]
    fn tiny_image_returns_zero() {
        assert_eq!(laplacian_variance(&[1, 2, 3, 4], 2, 2), 0.0);
    }

    #[test]
    fn median_of_known_values() {
        assert_eq!(median_brightness(&[0, 0, 0, 255, 255]), 0);
        assert_eq!(median_brightness(&[10, 20, 30]), 20);
        assert_eq!(median_brightness(&[]), 0);
    }

    #[test]
    fn rgba_gray_conversion() {
        let g = rgba_to_gray(&[255, 255, 255, 255, 0, 0, 0, 255]);
        assert_eq!(g, vec![255, 0]);
    }
}
