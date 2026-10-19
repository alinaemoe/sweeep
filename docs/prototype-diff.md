# Prototype vs app — what differs

Source: the design canvas linked in `CLAUDE.md` (boards Main, D2 Swipe, D3 Trash, D4 Scan, D6 Tools, D7 Paywall, D9 Pager, D10 Groups).

## Fixed
- **Fonts.** The app used `google_fonts`, which loaded only the 400 file; every bold text (500–800) was a *synthetic* bold of the regular face: wrong weight, smudged shapes, looked flatter. Plus Jakarta Sans 400/500/600/700/800 are now bundled (`assets/fonts`, checked against the google_fonts hashes) and the network dependency is gone.
- **Soft background orbs** (`GlowOrb`): Home (lavender, top-left), Swipe (red/lime/white follows the drag, was a hard-edged circle), Trash (coral sphere on the right edge, was missing), Home while scanning (lavender behind the oval, from the Scan board).
- **Jelly letters** (translateY + scaleY, 70–80 ms stagger) on every CLEAAAN and the intro hop.
- **Neon glow** under lavender buttons and the lime Keep button.
- Tools tab icon is the speaker from the prototype; app is portrait-only like the design.

## Still different
| Where | Prototype | App |
|---|---|---|
| Scan (D4) | full screen: SCANNING jelly word, oval %, 4-step checklist, counters, "Nothing is uploaded", Pause button | progress lives inside the Home oval only |
| Swipe (D2) | header "March 2025 · 34 of 212" (swipe by month), file name in the info pill | "All photos · 1 of 500", date + size |
| Pager (D9) | neighbour cards peek in from both sides, "All groups" button, 2-tone segmented progress | full-width pages, no peek, no button |
| Groups grid (D10) | filter chips (Biggest saving / Newest / Videos), multi-select, "Clean N groups" button | plain grid, tap opens pager |
| Tools (D6), Paywall (D7) | designed | not built |
| Glass pills / nav | live `backdrop-filter: blur(12px)` | flat dark translucent (live blurs cost ~20 % dropped frames) |
| Nav | active "Clean" pill = text only | active pill = icon + text, animated |
| BEST pill | 22 px | 24 px |
