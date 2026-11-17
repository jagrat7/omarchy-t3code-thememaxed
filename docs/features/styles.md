# Styles

The style decides where the theme's wallpapers appear in T3 Code:

- **minimal** puts the theme's first wallpaper behind the sidebar header.
- **full** keeps that header and adds a random theme wallpaper, blurred and
  tinted, behind the conversation.
- **max** adds the wallpaper down the whole sidebar.
- **full-alt** shows one wallpaper sharp behind a frosted chat column, with a
  plain sidebar.

## Sub-features

- `style-minimal`: the header picture only, with a plain conversation.
- `style-full`: the header picture plus a conversation picture.
- `style-max`: the header, the conversation, and the sidebar picture sized
  to cover.
- `style-full-alt`: a sharp conversation picture with the `blur(24px)` glass
  column, and no sidebar picture.
- `style-full-alt-glass`: the frosted glass covers the chat column wherever
  the column sits, including in a narrow window where T3 Code shifts it left
  to clear the thread details panel.
- `style-persist`: the chosen style survives later publishes that have no
  arguments.

## How to get to it (user POV)

- Click the bar icon and choose a tile: **Minimal**, **Full**, **Max** or
  **Full alt**.
- Set `style = "…"` in `~/.config/omarchy-t3code-plus/config.toml` (from
  **Edit config** in the panel).
- Run `t3code-omarchy-plus --style <name>` (the script install).

## Driving it with verify-thememaxed

Preconditions:

- `$V doctor` shows only `ok` lines.

Steps:

- **Minimal.**
  - Choose the Minimal tile: run `$V publish --style minimal`, then
    `$V state style-minimal`.
  - Expect `sidebarHasPicture: true` and `conversationHasPicture: false`.
- **Full.**
  - Choose the Full tile: run `$V publish --style full`, then
    `$V state style-full` and `$V shot style-full`.
  - Expect `sidebarHasPicture: true`, `conversationHasPicture: true`, and
    `glass: "none"`.
- **Max.**
  - Choose the Max tile: run `$V publish --style max`, then
    `$V state style-max`.
  - Expect `sidebarHasPicture: true`, `sidebarBackgroundSize` ending in
    `cover`, and `conversationHasPicture: true`.
- **Full alt.**
  - Choose the Full alt tile: run `$V publish --style full-alt`, then
    `$V state style-full-alt` and `$V shot style-full-alt`.
  - Expect `glass: "blur(24px)"`, `conversationHasPicture: true`,
    `skeleton: false` and `sidebarHasPicture: false`.
  - In `status`, `picture.width` should be at least 960 when `avifenc` is
    installed.
- **Full alt glass follows the text.**
  - Open a thread with messages: run
    `$V thread "A message long enough to wrap the chat column across several lines so both edges show."`.
  - At full window width and at a narrow one, run `$V state glass-wide` and
    `T3V_VIEWPORT=1500x900 $V cdp eval '<the laneSpan/glassSpan code from verify state>'`,
    or `T3V_VIEWPORT=1500x900 $V cdp shot <path>`.
  - Expect `glassSpan` to be `laneSpan` widened by 96px (6rem) on each
    side, trimmed to the conversation's edges.
  - The broken version shows the glass centered on the whole conversation,
    up to about 140px to the right of the column (half the details panel's
    280px).
- **Persist.**
  - Republish with no arguments: run `$V publish`, then
    `$V state style-persist`.
  - Expect `status.style` to still be `full-alt`, and the same
    glass and picture flags as the Full alt step.
- **Proof.** The evidence folder holds one `state` file for each style and
  screenshots of `full` and `full-alt`.

## Gotchas

- A style tile that is already chosen does nothing, because
  `Service.setStyle` ignores a repeat. `--style` with the same value still
  republishes and deals a new wallpaper.
- The header picture is drawn with a band of the sidebar background over it,
  so `sidebarHasPicture` is true for minimal, full and max alike. Use
  `sidebarBackgroundSize` to tell max apart.
- The first switch to full-alt on a wallpaper shows the loading skeleton
  for a few seconds. Wait for `skeleton: false` before you take its state
  (see [Full-alt loading skeleton](./full-alt-loading.md)).
- T3 Code only shifts the column sometimes. It depends on the thread
  details panel and the window width: at the sandbox's full 2536px width,
  one run had the column centered and another had it 138px left. Always
  check a narrow `T3V_VIEWPORT` as well. A centered column at full width
  proves nothing about the glass.
- The sandbox opens on a new thread, where the conversation has no chat
  column. Full-alt then shows the whole scene with a soft glow, and the glass
  column is hidden (`::before` opacity 0) even though `glass` still reads
  `blur(24px)`.
