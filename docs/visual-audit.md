# Visual audit (Home, Swipe, Trash, Category lists) — proposals

Checked on SM-S911B. Groups grid and GroupPager were NOT re-reviewed visually this round.

1. Cold start: ~1.2 s of an empty dark screen. Add a native splash + short stretchy SWEEEP intro.
2. Oval: busy -> done switch is a hard cut. Animate the count-up of the GB number and sweep the lavender arc in.
3. Home: ~100 px of dead space between the CTA and the first section (oval area is reserved at 260 px).
4. Carousels: no skeleton while data loads (shimmer cards in the final shapes).
5. Page transitions are the default Material push. Use fade-through / shared-axis; hero from a carousel stack into the pager.
6. Haptics: add on trash / keep / delete-forever success (only the swipe threshold has one now).
7. Trash screen: show days left per item (30-day expiry), an "Empty all" shortcut, and dim already-expiring items.
8. Nav bar: Swipe/Trash/Tools are pushes, not tabs; active pill does not animate. Make it a real shell with an animated pill.
9. Touch targets: filter chips are 40 px (< 44 px); some glass pills on photos have weak contrast on bright images.
10. Semantics labels missing on carousel cards, tiles, stamps (a11y).
11. thumbProvider is non-autoDispose: memory grows while scrolling big grids (also noted in CLAUDE.md).
12. Swipe: first-run hint overlay, optional swipe-up = "decide later".
