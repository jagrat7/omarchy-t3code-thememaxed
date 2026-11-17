# Full-alt loading skeleton

Full-alt's sharp wallpaper takes several seconds to encode the first time a
wallpaper is used. Until it is ready, T3 Code switches to the full-alt layout
straight away. It shows a small, soft copy of the coming wallpaper with a
shimmer sweeping across it, then swaps in the sharp picture. The bar panel's
chosen tile shimmers while the publish runs.

## Sub-features

- `loading-skeleton`: the shimmer and soft stand-in appear as soon as
  full-alt is chosen for a wallpaper that hasn't been encoded yet.
- `loading-same-picture`: the stand-in is the same wallpaper that the sharp
  picture shows afterwards.
- `loading-done`: the shimmer goes away once the sharp picture is in place.
- `loading-skip-cached`: a wallpaper that is already encoded goes straight to
  the sharp picture, with no shimmer.
- `loading-panel-tile`: the chosen tile in the bar panel shimmers while
  publishing (shell side only, not drivable here).

## How to get to it (user POV)

- Click the **Full alt** tile in the bar panel.
- Click **New wallpaper** while on full-alt, if it deals a wallpaper that
  hasn't been encoded yet.
- Switch the Omarchy theme while on full-alt.

## Driving it with verify-thememaxed

Preconditions:

- A fresh sandbox from `$V up` (style `full`). Its sharp cache is empty, so
  every wallpaper starts out unencoded.
- `avifenc` is installed. Without it the encode is shorter, but the skeleton
  still shows.

Steps:

- **Before.** Record the starting state: run `$V state loading-before`.
  Expect `skeleton: false` and `glass: "none"`.
- **Choose Full alt.**
  - Run `$V publish-bg --style full-alt`.
  - Then run
    `$V cdp wait '(() => { const c = document.querySelector("[data-workspace-area=conversation]"); return c && getComputedStyle(c, "::after").animationName === "omarchy-skeleton"; })()' 30`.
  - It should print `true` within about a second.
- **Skeleton showing.** Run `$V shot full-alt-loading` and
  `$V state full-alt-loading`. Expect:
  - `skeleton: true`
  - `glass: "blur(24px)"`
  - `wallpaperChars` under 3000 (the small stand-in)
  - a soft, blocky version of the wallpaper in the screenshot
- **Sharp picture arrives.**
  - Run
    `$V cdp wait '(() => { const c = document.querySelector("[data-workspace-area=conversation]"); return c && getComputedStyle(c, "::after").animationName !== "omarchy-skeleton"; })()' 90`.
  - Then run `$V shot full-alt-ready` and `$V state full-alt-ready`.
  - Expect `skeleton: false`, `wallpaperChars` in the tens of thousands, and
    `status.wallpaper` naming the same file the stand-in showed.
- **Cached, no skeleton.**
  - Run `$V publish --tint auto` (this keeps the wallpaper, which is now
    encoded), then `$V state full-alt-cached`.
  - Expect `skeleton: false` throughout. `$V cdp eval` for the `::after`
    animation never returns `omarchy-skeleton`.
- **Proof.** Keep `full-alt-loading.png` and `full-alt-ready.png` with their
  `state` files. `transcript.log` shows the `publish-bg` exit code 0.

## Gotchas

- The shimmer band moves. A screenshot can catch it off screen and look like
  a plain blurred picture. `skeleton: true` (the computed `animation-name`)
  is the proof.
- `status.json` is written only when the sharp picture is done. During the
  skeleton it still describes the previous publish, so don't read the
  skeleton phase's wallpaper from `status`.
- The publisher starts a background `--warm` encode of the theme's other
  wallpapers. After it finishes, later wallpapers are cached and show no
  skeleton. Use a fresh sandbox to see the skeleton again.
- The sweep stops by itself after about 90 seconds (56 runs of 1.6 s), so
  that a failed encode doesn't shimmer forever.
- With reduced motion turned on, the sweep is replaced by a still tint and
  `skeleton` reads false. Check the `::after` background instead.
