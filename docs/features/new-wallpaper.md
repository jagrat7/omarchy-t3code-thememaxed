# New wallpaper

**New wallpaper** puts a different one of the theme's wallpapers inside
T3 Code. It never changes the wallpaper on the desktop. Each publish deals
one that avoids the desktop's wallpaper, the header's (the theme's first) and
the one shown now, as far as the theme has others.

## Sub-features

- `new-wallpaper-changes`: each publish with no arguments shows a different
  picture.
- `new-wallpaper-avoids`: the dealt picture is not the desktop's, not the
  header's, and not the previous one.
- `new-wallpaper-desktop-untouched`: the desktop's wallpaper symlink is
  unchanged.

## How to get to it (user POV)

- Click **New wallpaper** in the bar panel. On minimal it reads
  **Publish again** and has no inside picture to change.
- Middle-click the bar icon.
- Run `t3code-omarchy-plus` with no arguments.

## Driving it with verify-thememaxed

Preconditions:

- `$V doctor` shows only `ok` lines.
- The style is full or full-alt.
- The theme has at least four wallpapers, so there is always one that avoids
  all three.

Steps:

- **Before.** Run `$V state wallpaper-1`, and record
  `readlink -f ~/.local/state/omarchy/current/background`.
- **New wallpaper.** Click **New wallpaper**: run `$V publish`, then
  `$V state wallpaper-2`.
  - `wallpaperHash` and `status.wallpaper` differ from `wallpaper-1`.
  - `status.wallpaper` is not the desktop's file, and not the first file in
    the theme's `backgrounds/`.
- **Again.** Run `$V publish`, then `$V state wallpaper-3` and
  `$V shot wallpaper-3`. The hash differs from `wallpaper-2`.
- **Desktop untouched.** Run
  `readlink -f ~/.local/state/omarchy/current/background` again. It prints
  the same file as in **Before**.
- **Proof.** Three `state` files with three different hashes, plus the two
  identical `readlink` outputs noted with `$V note`.

## Gotchas

- On full-alt, a wallpaper that hasn't been encoded yet shows the loading
  skeleton first. Wait for `skeleton: false` before you take its state.
- A theme with only one or two wallpapers runs out of choices, so a repeat
  or the desktop's own wallpaper is correct there.
- The sandbox reads the user's real theme, so the set of wallpapers is
  whatever that theme ships plus `~/.config/omarchy/backgrounds/<theme>`.
