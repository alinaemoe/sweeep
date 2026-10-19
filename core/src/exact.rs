//! Exact-duplicate detection: SHA-256 of file bytes, grouped by digest.

use sha2::{Digest, Sha256};
use std::collections::HashMap;

pub type Digest32 = [u8; 32];

pub fn sha256(bytes: &[u8]) -> Digest32 {
    let mut h = Sha256::new();
    h.update(bytes);
    h.finalize().into()
}

/// Groups ids that share a digest. Only groups of 2+ are returned, members
/// and groups sorted by id for stable output.
pub fn group_exact(entries: &[(u32, Digest32)]) -> Vec<Vec<u32>> {
    let mut map: HashMap<Digest32, Vec<u32>> = HashMap::new();
    for &(id, d) in entries {
        map.entry(d).or_default().push(id);
    }
    let mut groups: Vec<Vec<u32>> = map.into_values().filter(|g| g.len() > 1).collect();
    for g in &mut groups {
        g.sort();
    }
    groups.sort_by_key(|g| g[0]);
    groups
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha256_known_vector() {
        let d = sha256(b"abc");
        assert_eq!(d[0], 0xba);
        assert_eq!(d[1], 0x78);
        assert_eq!(d[31], 0xad);
    }

    #[test]
    fn groups_only_real_duplicates() {
        let a = sha256(b"a");
        let b = sha256(b"b");
        let g = group_exact(&[(3, a), (1, a), (2, b), (5, a)]);
        assert_eq!(g, vec![vec![1, 3, 5]]);
    }
}
