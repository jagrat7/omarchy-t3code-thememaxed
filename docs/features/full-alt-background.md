# Full-alt background file

On full-alt, the wallpaper behind the conversation is the theme wallpaper
itself, at full size. The publisher copies the file beside the theme, and
T3 Code shows it right away. There is no encode to wait for and no
size-limited copy.

## Sub-features

- `background-file`: the chosen wallpaper is published as
  `~/.t3/userdata/themes/omarchy-plus.<jpg|png|webp>`. It is a real file
  (T3 Code skips symlinks), byte for byte the wallpaper.
- `background-full-size`: T3 Code shows that picture at the wallpaper's own
  size, for example 3840×2160.
- `background-instant`: choosing full-alt publishes in well under a second.
- `background-convert`: a wallpaper in a format T3 Code cannot take (AVIF,
  GIF, BMP) or over 16 MB is converted to WebP first.
- `background-kept`: a tint change does not rewrite the file, so T3 Code does
  not download it again and the picture never blinks.
- `background-removed`: leaving full-alt deletes the file, and T3 Code shows
  no background image.

## How to get to it (user POV)

- Click the **Full alt** tile in the bar panel.
- Click **New wallpaper** while on full-alt.
- Set `style = "full-alt"` in the config.

## Driving it with verify-thememaxed

Preconditions:

- The sandbox runs T3 Code 0.1.10 or newer:
  `T3V_APP=<path to a recent AppImage> $V up`. An older build ignores the
  file and full-alt shows no wallpaper.
- `$V doctor` shows only `ok` lines.

Steps:

- **Before.** Run `$V state fullalt-before`. Expect `glass: "none"` and
  `backgroundUrl: null`.
- **Choose Full alt.**
  - Run `time $V publish --style full-alt`. It finishes in well under a
    second.
  - Then run
    `$V cdp wait 'document.documentElement.style.getPropertyValue("--theme-background-image").length > 0' 15`.
- **Full-size picture.** Run `$V state full-alt-ready` and
  `$V shot full-alt-ready`. Expect:
  - `wallpaper.from: "file"`
  - `wallpaper.size` equal to the wallpaper's own size
    (`magick identify -ping -format '%w %h' <status.wallpaper>`)
  - `glass: "blur(24px)"` and `conversationHasPicture: true`
- **The file.**
  - `cmp <status.wallpaper> .verify/run/t3/userdata/themes/omarchy-plus.<ext>`
    reports no difference.
  - `test ! -L` on that path succeeds (it is not a symlink).
- **Tint keeps it.** Run `$V publish --tint 0.3`, then
  `$V state fullalt-tint`. Expect the same `wallpaperHash` and the same
  `backgroundUrl`: the same `blob:` URL means T3 Code did not download it
  again.
- **Leave full-alt.** Run `$V publish --style full`, then
  `$V state fullalt-left`.
  - Expect `backgroundUrl: null`.
  - `ls .verify/run/t3/userdata/themes/` shows only `omarchy-plus.json`.
- **Proof.** `full-alt-ready.png` and the `state` files, with
  `transcript.log` showing each publish's exit code 0.

## Gotchas

- T3 Code loads the file asynchronously after the theme changes. Wait for
  `--theme-background-image` before you take a `state`, and give a publish
  about a second to be noticed before you wait, or you will read the
  previous picture.
- Every new file is a new revision, which T3 Code downloads again with no
  picture in between. That is why an unchanged picture must not be
  rewritten. A changed `backgroundUrl` after a tint change is that
  regression.
- T3 Code takes the first of `.webp`, `.png`, `.jpg`, `.jpeg` it finds. A
  stale file in another format would shadow the new one, so the publisher
  removes the others.
- The file is not in the theme CSS, so `status.chars` no longer includes the
  picture.
