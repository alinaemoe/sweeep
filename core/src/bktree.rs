//! BK-tree over 64-bit hashes with Hamming distance, for sub-quadratic
//! near-duplicate search on large libraries.

use crate::hash::hamming;

struct Node {
    hash: u64,
    ids: Vec<u32>,
    children: Vec<(u32, usize)>,
}

#[derive(Default)]
pub struct BkTree {
    nodes: Vec<Node>,
}

impl BkTree {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn len(&self) -> usize {
        self.nodes.iter().map(|n| n.ids.len()).sum()
    }

    pub fn is_empty(&self) -> bool {
        self.nodes.is_empty()
    }

    pub fn insert(&mut self, hash: u64, id: u32) {
        if self.nodes.is_empty() {
            self.nodes.push(Node { hash, ids: vec![id], children: Vec::new() });
            return;
        }
        let mut cur = 0usize;
        loop {
            let d = hamming(self.nodes[cur].hash, hash);
            if d == 0 {
                self.nodes[cur].ids.push(id);
                return;
            }
            match self.nodes[cur].children.iter().find(|(cd, _)| *cd == d) {
                Some(&(_, next)) => cur = next,
                None => {
                    let idx = self.nodes.len();
                    self.nodes.push(Node { hash, ids: vec![id], children: Vec::new() });
                    self.nodes[cur].children.push((d, idx));
                    return;
                }
            }
        }
    }

    /// All `(id, distance)` with `distance <= max_dist` from `hash`.
    pub fn query(&self, hash: u64, max_dist: u32) -> Vec<(u32, u32)> {
        let mut out = Vec::new();
        if self.nodes.is_empty() {
            return out;
        }
        let mut stack = vec![0usize];
        while let Some(i) = stack.pop() {
            let node = &self.nodes[i];
            let d = hamming(node.hash, hash);
            if d <= max_dist {
                out.extend(node.ids.iter().map(|&id| (id, d)));
            }
            let lo = d.saturating_sub(max_dist);
            let hi = d + max_dist;
            for &(cd, child) in &node.children {
                if cd >= lo && cd <= hi {
                    stack.push(child);
                }
            }
        }
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lcg(seed: &mut u64) -> u64 {
        *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        *seed
    }

    #[test]
    fn query_matches_brute_force() {
        let mut seed = 42u64;
        let hashes: Vec<u64> = (0..500).map(|_| lcg(&mut seed)).collect();
        let mut tree = BkTree::new();
        for (i, &h) in hashes.iter().enumerate() {
            tree.insert(h, i as u32);
        }
        for q in 0..20 {
            let probe = hashes[q] ^ (lcg(&mut seed) & 0b111); // flip up to 3 bits
            for max in [0u32, 4, 10, 20] {
                let mut got: Vec<u32> = tree.query(probe, max).into_iter().map(|(id, _)| id).collect();
                let mut want: Vec<u32> = hashes
                    .iter()
                    .enumerate()
                    .filter(|(_, &h)| hamming(h, probe) <= max)
                    .map(|(i, _)| i as u32)
                    .collect();
                got.sort();
                want.sort();
                assert_eq!(got, want, "probe {q} max {max}");
            }
        }
    }

    #[test]
    fn identical_hashes_share_a_node() {
        let mut t = BkTree::new();
        t.insert(7, 1);
        t.insert(7, 2);
        assert_eq!(t.len(), 2);
        let mut ids: Vec<u32> = t.query(7, 0).into_iter().map(|(i, _)| i).collect();
        ids.sort();
        assert_eq!(ids, vec![1, 2]);
    }

    #[test]
    fn empty_tree_query() {
        assert!(BkTree::new().query(1, 64).is_empty());
    }
}
