//! Similarity grouping (BK-tree candidates + union-find) and best-pick.

use crate::hash::hamming;

#[derive(Debug, Clone, Copy)]
pub struct Item {
    pub id: u32,
    pub hash: u64,
    /// Capture time, ms since epoch.
    pub ts_ms: i64,
    /// Laplacian variance; higher = sharper.
    pub sharpness: f64,
}

#[derive(Debug, Clone, Copy)]
pub struct GroupParams {
    /// Maximum Hamming distance to link two items (default 6 of 64).
    pub max_hamming: u32,
    /// If set, items are only linked when captured within this window.
    pub window_ms: Option<i64>,
    /// Maximum members per group. Components are split with complete
    /// linkage (every member within `max_hamming` of every other) and then
    /// capped at this size. 0 = unlimited.
    pub max_group: usize,
}

impl Default for GroupParams {
    fn default() -> Self {
        Self { max_hamming: 6, window_ms: None, max_group: 8 }
    }
}

struct Dsu(Vec<usize>);

impl Dsu {
    fn new(n: usize) -> Self {
        Self((0..n).collect())
    }
    fn find(&mut self, mut x: usize) -> usize {
        while self.0[x] != x {
            self.0[x] = self.0[self.0[x]];
            x = self.0[x];
        }
        x
    }
    fn union(&mut self, a: usize, b: usize) {
        let (ra, rb) = (self.find(a), self.find(b));
        if ra != rb {
            self.0[rb] = ra;
        }
    }
}

fn link_global(items: &[Item], max_hamming: u32, dsu: &mut Dsu) {
    // Identical hashes link immediately; search only over unique hashes.
    let mut first: std::collections::HashMap<u64, usize> = Default::default();
    let mut uniq: Vec<(u64, usize)> = Vec::new();
    for (i, it) in items.iter().enumerate() {
        match first.get(&it.hash) {
            Some(&f) => dsu.union(f, i),
            None => {
                first.insert(it.hash, i);
                uniq.push((it.hash, i));
            }
        }
    }
    if max_hamming == 0 {
        return;
    }
    let k = (max_hamming as usize + 1).min(64);
    for seg in 0..k {
        let lo = seg * 64 / k;
        let hi = (seg + 1) * 64 / k;
        let mask = if hi - lo >= 64 { u64::MAX } else { ((1u64 << (hi - lo)) - 1) << lo };
        let mut keyed: Vec<(u64, u64, usize)> = uniq.iter().map(|&(h, i)| (h & mask, h, i)).collect();
        keyed.sort_unstable_by_key(|t| t.0);
        let mut a = 0;
        while a < keyed.len() {
            let mut b = a + 1;
            while b < keyed.len() && keyed[b].0 == keyed[a].0 {
                b += 1;
            }
            for x in a..b {
                for y in x + 1..b {
                    if hamming(keyed[x].1, keyed[y].1) <= max_hamming {
                        dsu.union(keyed[x].2, keyed[y].2);
                    }
                }
            }
            a = b;
        }
    }
}

/// Groups similar items; returns groups of 2+ item ids, members ordered by
/// capture time, groups ordered by size (desc) then first member id.
/// Item ids must be unique.
pub fn group_similar(items: &[Item], params: &GroupParams) -> Vec<Vec<u32>> {
    let mut dsu = Dsu::new(items.len());
    match params.window_ms {
        // Time-windowed: sweep items in capture order and only compare
        // neighbours inside the window. Cost is O(n * photos per window).
        Some(win) => {
            let mut order: Vec<usize> = (0..items.len()).collect();
            order.sort_by_key(|&i| items[i].ts_ms);
            for a in 0..order.len() {
                let i = order[a];
                for &j in &order[a + 1..] {
                    if items[j].ts_ms - items[i].ts_ms > win {
                        break;
                    }
                    if hamming(items[i].hash, items[j].hash) <= params.max_hamming {
                        dsu.union(i, j);
                    }
                }
            }
        }
        // Global: multi-index hashing. With radius r, splitting the 64 bits
        // into r+1 segments guarantees two hashes within r differ in at most
        // r segments, so they agree exactly on at least one. Only items that
        // share a segment value are ever compared.
        None => link_global(items, params.max_hamming, &mut dsu),
    }
    let mut buckets: std::collections::HashMap<usize, Vec<usize>> = Default::default();
    for i in 0..items.len() {
        let r = dsu.find(i);
        buckets.entry(r).or_default().push(i);
    }
    let mut groups: Vec<Vec<u32>> = Vec::new();
    for (_, mut comp) in buckets.into_iter().filter(|(_, g)| g.len() > 1) {
        comp.sort_by_key(|&i| (items[i].ts_ms, items[i].id));
        groups.extend(split_complete(items, comp, params));
    }
    groups.sort_by(|a, b| b.len().cmp(&a.len()).then(a[0].cmp(&b[0])));
    groups
}

/// Splits a single-linkage component (ordered by time) into cliques: a
/// member joins a group only if it is within the threshold of ALL members,
/// so chains of slowly changing frames cannot snowball. Deterministic greedy.
fn split_complete(items: &[Item], comp: Vec<usize>, params: &GroupParams) -> Vec<Vec<u32>> {
    let mut left = comp;
    let mut out = Vec::new();
    while left.len() > 1 {
        let mut group = vec![left[0]];
        let mut rest = Vec::new();
        for &c in &left[1..] {
            let full = params.max_group != 0 && group.len() >= params.max_group;
            let fits = !full && group.iter().all(|&m| hamming(items[m].hash, items[c].hash) <= params.max_hamming);
            if fits {
                group.push(c);
            } else {
                rest.push(c);
            }
        }
        if group.len() > 1 {
            out.push(group.into_iter().map(|i| items[i].id).collect());
        }
        left = rest;
    }
    out
}

/// Picks the best frame of a group: sharpest, ties broken by lowest id.
pub fn best_pick(items: &[Item], group: &[u32]) -> Option<u32> {
    group
        .iter()
        .filter_map(|id| items.iter().find(|it| it.id == *id))
        .max_by(|a, b| {
            a.sharpness
                .partial_cmp(&b.sharpness)
                .unwrap_or(std::cmp::Ordering::Equal)
                .then(b.id.cmp(&a.id))
        })
        .map(|it| it.id)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn it(id: u32, hash: u64, ts: i64, sharp: f64) -> Item {
        Item { id, hash, ts_ms: ts, sharpness: sharp }
    }

    #[test]
    fn links_near_hashes_and_ignores_far_ones() {
        let items = [it(1, 0, 0, 1.0), it(2, 0b111, 1000, 2.0), it(3, u64::MAX, 2000, 3.0)];
        let g = group_similar(&items, &GroupParams::default());
        assert_eq!(g, vec![vec![1, 2]]);
    }

    #[test]
    fn chains_do_not_snowball() {
        // 1~2 and 2~3 within 8 bits, but 1 and 3 are 16 apart: 3 must not join.
        let items = [it(1, 0, 0, 1.0), it(2, 0xFF, 1, 1.0), it(3, 0xFFFF, 2, 1.0)];
        let g = group_similar(&items, &GroupParams { max_hamming: 8, window_ms: None, max_group: 0 });
        assert_eq!(g, vec![vec![1, 2]]);
    }

    #[test]
    fn group_size_is_capped() {
        let items: Vec<Item> = (0..10).map(|i| it(i, 0, i as i64, 1.0)).collect();
        let g = group_similar(&items, &GroupParams { max_hamming: 6, window_ms: None, max_group: 4 });
        assert_eq!(g.iter().map(|x| x.len()).collect::<Vec<_>>(), vec![4, 4, 2]);
    }

    #[test]
    fn time_window_splits_groups() {
        let items = [it(1, 0, 0, 1.0), it(2, 0, 3_000, 1.0), it(3, 0, 60_000, 1.0)];
        let g = group_similar(&items, &GroupParams { max_hamming: 8, window_ms: Some(5_000), max_group: 0 });
        assert_eq!(g, vec![vec![1, 2]]);
    }

    #[test]
    fn windowed_and_global_agree_when_window_is_huge() {
        let mut s = 99u64;
        let mut next = || {
            s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            s
        };
        let mut items = Vec::new();
        for i in 0..300u32 {
            let base = next();
            items.push(it(i * 2, base, (i as i64) * 10, 1.0));
            items.push(it(i * 2 + 1, base ^ (1 << (next() % 64)), (i as i64) * 10 + 1, 1.0));
        }
        let global = group_similar(&items, &GroupParams { max_hamming: 4, window_ms: None, max_group: 0 });
        let windowed = group_similar(&items, &GroupParams { max_hamming: 4, window_ms: Some(i64::MAX / 4), max_group: 0 });
        assert_eq!(global, windowed);
        assert!(global.len() >= 300);
    }

    #[test]
    fn global_matches_brute_force() {
        let mut s = 5u64;
        let mut next = || {
            s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            s
        };
        let mut items: Vec<Item> = Vec::new();
        for i in 0..400u32 {
            let h = if i % 3 == 2 {
                let p: u64 = items[(i - 1) as usize].hash;
                p ^ (1 << (next() % 64)) ^ (1 << (next() % 64))
            } else {
                next()
            };
            items.push(it(i, h, i as i64, 1.0));
        }
        for max in [0u32, 3, 8] {
            let got = group_similar(&items, &GroupParams { max_hamming: max, window_ms: None, max_group: 0 });
            // brute force reference using the windowed path with a huge window
            let want = group_similar(&items, &GroupParams { max_hamming: max, window_ms: Some(i64::MAX / 4), max_group: 0 });
            assert_eq!(got, want, "max {max}");
        }
    }

    #[test]
    fn best_pick_prefers_sharpest_then_lowest_id() {
        let items = [it(1, 0, 0, 5.0), it(2, 0, 1, 9.0), it(3, 0, 2, 9.0)];
        assert_eq!(best_pick(&items, &[1, 2, 3]), Some(2));
        assert_eq!(best_pick(&items, &[]), None);
    }
}
