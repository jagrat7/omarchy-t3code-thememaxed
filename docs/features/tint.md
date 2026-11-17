# Backdrop tint

On full-alt, the tint sets how much of the theme's background covers the
wallpaper behind the chat column. The sides of the scene get a third of it.
**Auto** picks the tint from the wallpaper's brightness, and the slider fixes
it between 0 and 1. Changing the tint only changes the tint: the same
wallpaper stays inside T3 Code.

## Sub-features

- `tint-fixed`: a slider value becomes the scene tint's alpha.
- `tint-auto`: **Auto** derives the alpha from the wallpaper, clamped to
  0.1–0.65.
- `tint-keeps-wallpaper`: changing the tint never deals a new wallpaper.
- `tint-persist`: the tint is saved as `backdrop_tint` in the config.

## How to get to it (user POV)

- Open the bar panel on full-alt. Drag the slider under **CHAT COLUMN TINT**,
  or click **Auto**.
- Set `backdrop_tint` in the config (from **Edit config**).
- Run `t3code-omarchy-plus --tint <0-1|auto>`.

## Driving it with verify-thememaxed

Preconditions:

- `$V doctor` shows only `ok` lines.
- The style is full-alt and its picture has loaded: `$V publish --style full-alt`,
  then `$V state` shows a `backgroundUrl`.

Steps:

- **Starting picture.** Run `$V state tint-before` and note
  `app.wallpaperHash` and `status.wallpaper`.
- **Fixed tint.** Release the slider at 0.3: run `$V publish --tint 0.3`,
  then `$V state tint-0.3`.
  - Expect `sceneTint` ending in `/ 0.3)` and `status.tint` 0.3.
  - Expect the same `wallpaperHash` and `status.wallpaper` as
    `tint-before`.
- **Another value.** Run `$V publish --tint 0.8`, then `$V state tint-0.8`.
  Expect `sceneTint` ending in `/ 0.8)`, with the hash and file unchanged.
- **Auto.** Click **Auto**: run `$V publish --tint auto`, then
  `$V state tint-auto` and `$V shot tint-auto`.
  - Expect `status.backdropTint: "auto"` and `status.tint` between 0.1
    and 0.65.
  - Expect the hash and file unchanged.
- **Persist.** Run `grep backdrop_tint .verify/run/config/omarchy-t3code-plus/config.toml`.
  It shows `backdrop_tint = "auto"`.
- **Proof.** The four `state` files show one `wallpaperHash` across every
  tint change.

## Gotchas

- On full-alt, also compare `backgroundUrl` before and after. A new `blob:`
  URL means T3 Code downloaded the picture again, and it blinks while that
  happens.

- Before this was fixed, every tint change dealt a new random wallpaper. A
  different `wallpaperHash` after `--tint` is that regression.
- The tint is kept even on styles other than full-alt, but it only shows on
  full-alt. Prove it on full-alt.
- `--style` together with `--tint` in one call deals a new wallpaper, because
  the style changed. The panel never sends both at once.
- If the shown wallpaper has left the theme (for example after a theme
  switch), a tint change deals a new one. That is expected.
