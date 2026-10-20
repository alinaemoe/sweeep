# Prototype vs app — what differs

Source: the design canvas linked in `CLAUDE.md` (boards Main, D2 Swipe, D3 Trash, D4 Scan, D6 Tools, D7 Paywall, D9 Pager, D10 Groups).

## Fixed
- **Fonts.** The app used `google_fonts`, which loaded only the 400 file; every bold text (500–800) was a *synthetic* bold of the regular face: wrong weight, smudged shapes, looked flatter. Plus Jakarta Sans 400/500/600/700/800 are now bundled (`assets/fonts`, checked against the google_fonts hashes) and the network dependency is gone.
- **Soft background orbs** (`GlowOrb`): Home (lavender, top-left), Swipe (red/lime/white follows the drag, was a hard-edged circle), Trash (coral sphere on the right edge, was missing), Home while scanning (lavender behind the oval, from the Scan board).
- **Jelly letters** (translateY + scaleY, 70–80 ms stagger) on every CLEAAAN and the intro hop.
- **Neon glow** under lavender buttons and the lime Keep button.
- **Tools (D6)** built: Water / Dust / Sound test, local tone generator.
- **Groups (D10)**: sort chips (Biggest saving / Newest / Copies; no Videos chip, groups are photos only), multi-select, Clean N groups.
- **Pager (D9)**: neighbour cards peek in, All groups button; BEST pill is 22 px.
- **Timeline (D1)**: the Swipe tab is a month-by-month feed with progress, preview strips, Continue; a month opens the deck for just that month.
- Tools tab icon is the speaker from the prototype; app is portrait-only like the design.

## Still different
| Where | Prototype | App |
|---|---|---|
| Scan (D4) | full screen: SCANNING jelly word, oval %, 4-step checklist, counters, Pause | dropped on purpose (tried, owner preferred it): progress stays inside the Home oval |
| Swipe (D2) | file name in the info pill | date + size |
| Paywall (D7) | designed | not built (decision postponed) |
| Glass pills / nav | live `backdrop-filter: blur(12px)` | flat dark translucent (live blurs cost ~20 % dropped frames) |
| Nav | active "Clean" pill = text only | active pill = icon + text, animated |
