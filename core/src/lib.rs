//! Sweeep analysis core.
//!
//! Everything here is deterministic and runs on-device: perceptual hashes,
//! sharpness / brightness metrics, exact-duplicate hashing and similarity
//! grouping. Inputs are 8-bit grayscale buffers (row-major), already
//! decoded from a thumbnail by the platform layer.

pub mod bktree;
pub mod exact;
pub mod ffi;
pub mod gray;
pub mod group;
pub mod hash;
pub mod metrics;

pub use bktree::BkTree;
pub use group::{best_pick, group_similar, GroupParams, Item};
pub use hash::{ahash, dhash, hamming, phash};
pub use metrics::{laplacian_variance, median_brightness, rgba_to_gray};
