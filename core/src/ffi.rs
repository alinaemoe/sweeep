//! C ABI for Dart FFI. All pixel buffers are 8-bit grayscale, row-major,
//! `w * h` bytes. Null or undersized inputs return 0 rather than panicking.

use crate::{hash, metrics};

unsafe fn gray<'a>(ptr: *const u8, w: u32, h: u32) -> Option<&'a [u8]> {
    if ptr.is_null() || w == 0 || h == 0 {
        return None;
    }
    Some(std::slice::from_raw_parts(ptr, (w as usize) * (h as usize)))
}

/// # Safety
/// `ptr` must point to at least `w * h` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sweeep_phash(ptr: *const u8, w: u32, h: u32) -> u64 {
    gray(ptr, w, h).map_or(0, |g| hash::phash(g, w as usize, h as usize))
}

/// # Safety
/// `ptr` must point to at least `w * h` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sweeep_dhash(ptr: *const u8, w: u32, h: u32) -> u64 {
    gray(ptr, w, h).map_or(0, |g| hash::dhash(g, w as usize, h as usize))
}

/// # Safety
/// `ptr` must point to at least `w * h` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sweeep_ahash(ptr: *const u8, w: u32, h: u32) -> u64 {
    gray(ptr, w, h).map_or(0, |g| hash::ahash(g, w as usize, h as usize))
}

/// # Safety
/// `ptr` must point to at least `w * h` readable bytes.
#[no_mangle]
pub unsafe extern "C" fn sweeep_laplacian_variance(ptr: *const u8, w: u32, h: u32) -> f64 {
    gray(ptr, w, h).map_or(0.0, |g| metrics::laplacian_variance(g, w as usize, h as usize))
}

/// Everything the scan pipeline needs from one thumbnail, in one call.
#[repr(C)]
#[derive(Debug, Default, Clone, Copy)]
pub struct SweeepAnalysis {
    pub phash: u64,
    pub dhash: u64,
    pub ahash: u64,
    pub laplacian_var: f64,
    pub median_brightness: u32,
}

/// Fills `out` with all hashes and metrics for a grayscale thumbnail.
/// Returns 0 on success, -1 for null/empty input.
///
/// # Safety
/// `ptr` must point to at least `w * h` readable bytes; `out` must be a
/// valid, writable `SweeepAnalysis`.
#[no_mangle]
pub unsafe extern "C" fn sweeep_analyze(ptr: *const u8, w: u32, h: u32, out: *mut SweeepAnalysis) -> i32 {
    let Some(g) = gray(ptr, w, h) else { return -1 };
    if out.is_null() {
        return -1;
    }
    let (w, h) = (w as usize, h as usize);
    *out = SweeepAnalysis {
        phash: hash::phash(g, w, h),
        dhash: hash::dhash(g, w, h),
        ahash: hash::ahash(g, w, h),
        laplacian_var: metrics::laplacian_variance(g, w, h),
        median_brightness: metrics::median_brightness(g) as u32,
    };
    0
}

/// Groups similar hashes. `labels[i]` receives the group number (0..) of
/// item i, or -1 if it is in no group. `window_ms < 0` disables the time
/// window. Returns the number of groups, or -1 on bad input.
///
/// # Safety
/// `hashes`, `ts_ms` and `labels` must each point to `n` valid elements.
#[no_mangle]
pub unsafe extern "C" fn sweeep_group_labels(
    hashes: *const u64,
    ts_ms: *const i64,
    n: usize,
    max_hamming: u32,
    window_ms: i64,
    labels: *mut i32,
) -> i32 {
    if n == 0 || hashes.is_null() || ts_ms.is_null() || labels.is_null() {
        return -1;
    }
    let hs = std::slice::from_raw_parts(hashes, n);
    let ts = std::slice::from_raw_parts(ts_ms, n);
    let out = std::slice::from_raw_parts_mut(labels, n);
    let items: Vec<crate::group::Item> = (0..n)
        .map(|i| crate::group::Item { id: i as u32, hash: hs[i], ts_ms: ts[i], sharpness: 0.0 })
        .collect();
    let params = crate::group::GroupParams {
        max_hamming,
        window_ms: if window_ms < 0 { None } else { Some(window_ms) },
        max_group: 8,
    };
    out.fill(-1);
    let groups = crate::group::group_similar(&items, &params);
    for (gi, g) in groups.iter().enumerate() {
        for &idx in g {
            out[idx as usize] = gi as i32;
        }
    }
    groups.len() as i32
}

#[no_mangle]
pub extern "C" fn sweeep_hamming(a: u64, b: u64) -> u32 {
    hash::hamming(a, b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn null_pointer_is_safe() {
        unsafe {
            assert_eq!(sweeep_phash(std::ptr::null(), 8, 8), 0);
            assert_eq!(sweeep_laplacian_variance(std::ptr::null(), 8, 8), 0.0);
        }
    }

    #[test]
    fn analyze_fills_struct() {
        let img: Vec<u8> = (0..64 * 64).map(|i| ((i * 7) % 251) as u8).collect();
        let mut out = SweeepAnalysis::default();
        unsafe {
            assert_eq!(sweeep_analyze(img.as_ptr(), 64, 64, &mut out), 0);
            assert_eq!(sweeep_analyze(std::ptr::null(), 64, 64, &mut out), -1);
        }
        assert_eq!(out.phash, hash::phash(&img, 64, 64));
        assert!(out.laplacian_var > 0.0);
    }

    #[test]
    fn group_labels_marks_members() {
        let hashes = [0u64, 0b11, u64::MAX, 0];
        let ts = [0i64, 1000, 2000, 90_000];
        let mut labels = [0i32; 4];
        let n = unsafe { sweeep_group_labels(hashes.as_ptr(), ts.as_ptr(), 4, 8, 5_000, labels.as_mut_ptr()) };
        assert_eq!(n, 1);
        assert_eq!(labels, [0, 0, -1, -1]);
    }

    #[test]
    fn ffi_matches_rust_api() {
        let img: Vec<u8> = (0..32 * 32).map(|i| (i % 251) as u8).collect();
        unsafe {
            assert_eq!(sweeep_phash(img.as_ptr(), 32, 32), hash::phash(&img, 32, 32));
        }
        assert_eq!(sweeep_hamming(0b11, 0b01), 1);
    }
}
