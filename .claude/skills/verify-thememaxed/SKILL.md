---
name: verify-thememaxed
description: Prove a T3 Code Thememaxed change in the real T3 Code app. Launches a sandboxed, hidden T3 Code (AppImage, own T3CODE_HOME and profile) on Hyprland, publishes this checkout's theme into it with bin/t3code-omarchy-plus, and reads what the app actually renders over CDP (screenshots plus computed styles). Use it after touching the publisher, the CSS template, or anything that changes what T3 Code shows: styles, full-alt's background file, tint, new wallpaper.
---

# Verify T3 Code Thememaxed

The plugin has three parts. The **publisher** (`bin/t3code-omarchy-plus`)
turns the Omarchy theme into `~/.t3/userdata/themes/omarchy-plus.json`.
**T3 Code** picks that file up live and renders it. The **bar panel**
(`Panel.qml`, `Service.qml`) runs the publisher with arguments. This skill
drives the first two for real: the repo's publisher writes into a sandboxed
T3 Code, and you check the pixels and computed CSS in that app.

`python3 -m unittest discover -s tests` is the fast check of the publisher's
output. This skill is the proof that T3 Code shows it.

```bash
V=.claude/skills/verify-thememaxed/scripts/verify
```

Run every command from the repo root.

## Launch

```bash
$V up            # about 15 s; prints "ready: T3 Code pid … on special:t3verify, CDP :9339, evidence …"
```

`up` does the following:

1. Builds a sandbox in `.verify/run/`. It has its own XDG config, state, cache
   and data folders, and its own `T3CODE_HOME`.
2. Symlinks the **real** Omarchy theme (`~/.local/state/omarchy/current`)
   and `~/.config/omarchy/backgrounds` into the sandbox. The sandbox only
   reads them.
3. Seeds T3 Code with `defaultTheme: omarchy-plus`, onboarding done, and the
   user's layout settings copied read-only from their own T3 Code (chat
   width, font sizes, glass). It then runs a first publish (`--style full`,
   or `T3V_STYLE=…`).
4. Points `CODEX_HOME` and `CLAUDE_CONFIG_DIR` at empty sandbox folders, so
   agents in the sandbox are signed out and nothing runs on the user's
   accounts.
5. Launches `~/AppImages/t3_code_nightly.appimage` (or `T3V_APP=…`, which
   the sandbox remembers for later commands) with
   `--remote-debugging-port=9339` (or `T3V_PORT=…`). The launch goes through
   Hyprland into the hidden `special:t3verify` workspace, so nothing appears
   on the user's screen.
6. Adds an empty git repo, `.verify/run/project`, the way a user does:
   **Add project → Local folder → type the path → Enter**. Then it closes the
   palette. A conversation view is now open.

Ready means a conversation view (`[data-workspace-area=conversation]`) exists
and the Thememaxed CSS is applied. A process that merely answers is not ready.

Requires Hyprland (Lua dispatch), Node 22 or later (built-in `WebSocket`),
`git` and ImageMagick. Full-alt's wallpaper is a background image file,
which needs T3 Code 0.1.10 (or a nightly from 16 November 2026) or newer. To
test with a build other than the user's, download its AppImage into
`.verify/apps/` (`gh release download <tag> -R pingdotgg/t3code -p 'T3-Code-Nightly-x86_64.AppImage' -D .verify/apps`)
and pass it as `T3V_APP`.

Isolation: the user's own T3 Code (`~/.t3`, `~/.config/t3code-v2`) is never
touched. Only one sandbox runs at a time per `T3V_RUN` and `T3V_PORT`. `up`
refuses to start if either is in use.

## Doctor

```bash
$V doctor
```

This is read-only. Every line must say `ok` before you trust a drive. It
checks that:

- the main PID is the one launch recorded;
- that window, and only it, is on `special:t3verify`;
- the CDP port is held by the sandbox;
- the sandbox processes use the sandbox `T3CODE_HOME`;
- the real `~/.t3` theme file is not newer than this run;
- the page is `t3code://` with the Thememaxed CSS applied;
- a conversation view is open;
- the last publish succeeded.

It also prints the app's Chromium version and whether the repo has
uncommitted publisher or template changes, which tells you what you are
testing. Run it first whenever anything looks off.

## Drive

The bar panel can't run in the sandbox (see "Not covered"). Each panel action
maps one-to-one to publisher arguments (`Service.qml`), so you drive those
arguments:

| User action in the bar panel | Drive command |
| --- | --- |
| Click a style tile (Minimal, Full, Max, Full alt) | `$V publish --style minimal\|full\|max\|full-alt` |
| Drag the tint slider / click **Auto** | `$V publish --tint 0.35` / `$V publish --tint auto` |
| **New wallpaper** button, middle-click on the bar icon, theme, font or wallpaper change | `$V publish` |
| Same, but watch the app while the publish is still running | `$V publish-bg <args>` |

Read back what the app renders:

```bash
$V state [name]            # JSON: in-app CSS facts plus the publisher's status.json; saved to evidence when named
$V shot <name>             # screenshot of the app window into evidence
$V thread '<message>'      # start a thread with that message (T3 Code's own `t3 thread start`) and open it
$V cdp wait '<js>' [secs]  # block until a condition holds in the app
$V cdp eval '<js>'
$V cdp click '<text>'      # real mouse click on a button, menu item or option, by text, first line, or aria-label
$V cdp type '<text>'; $V cdp key Enter|Escape|Tab|Backspace
$V note '<text>'           # add a line to the evidence transcript
```

`state` reports these fields under `app`:

| Field | Meaning |
| --- | --- |
| `themeApplied` | The theme's CSS is applied. |
| `wallpaper` | The picture inside T3 Code: `from` (`css` for a data URI in the theme, `file` for full-alt's background file), its type, bytes, pixel `size` and `hash`. |
| `wallpaperHash` | The same hash. Equal hashes mean the same picture. |
| `backgroundUrl` | The `blob:` URL T3 Code loaded the background file into, or null. A new URL means T3 Code downloaded it again. |
| `glass` | Full-alt's frosted column (`blur(24px)`). |
| `sceneTint` | The tint the backdrop uses. |
| `laneSpan`, `glassSpan` | Viewport x ranges of the chat column and of the glass behind it. |
| `conversationHasPicture` | The conversation area shows a wallpaper. |
| `sidebarHasPicture`, `sidebarBackgroundSize` | The sidebar shows a wallpaper, and how it is sized. |

`status` (from the publisher) names the wallpaper file, tint and picture size.

The stable handles in T3 Code:

- `[data-workspace-area=conversation]`: the conversation area. Its
  `::before` is full-alt's glass. The theme's background file arrives as
  `--theme-background-image` on `<html>`, set by T3 Code once it has loaded.
- `[data-slot=sidebar-inner]`: the sidebar, which carries the header and
  max-style wallpaper.
- `.chat-content-lane` (`[data-timeline-root]`): the chat column, one per
  timeline row. It only exists once a thread has messages.
- `[data-thread-details-panel]`: the details card at the top right. T3 Code
  sometimes pads the timeline on the right to clear it (often in narrower
  windows), which moves the chat column left of center.
- The theme's CSS sits in `document.adoptedStyleSheets`, not in a `<style>`
  tag.

**Before and after.** To show the old behavior next to the new one, check out
the base commit in a worktree (`git worktree add .verify/before main`), then
prefix a command with
`T3V_PUBLISHER=$PWD/.verify/before/bin/t3code-omarchy-plus`. That command
publishes with the old publisher and template into the same sandbox. Remove
the worktree afterwards (`git worktree remove .verify/before`).

**Messages and window sizes.** A new thread has no messages, so anything drawn
behind messages (full-alt's glass, bubbles) needs `$V thread '<long message>'`.
The turn then fails with an auth error banner, which is expected. To see
layouts that depend on window width, prefix any `cdp` command with
`T3V_VIEWPORT=1500x900`. The size lasts only for that one command, so take
the measurement or shot in that same command.

JS passed to `cdp eval`/`wait`, and the JS inside `scripts/verify`, sits in
single shell quotes. An apostrophe anywhere in it, even in a comment, breaks
it with `SyntaxError: Unexpected end of input`.

Use browser automation (the `cdp` commands) whenever `publish` and `state`
can't test a change, or leave gaps in the evidence. Examples are a new
selector, a hover or focus state, or a different view such as a thread with
messages. It replaces only the UI driving: keep using `verify publish` and
the same sandbox to change the theme.

The feature map in `docs/features/` holds the recipe for each feature. Read
`docs/features/README.md` first.

## Evidence

Everything lands in `.verify/evidence/<run-id>/`. `up` prints the path.

- `transcript.log` gets a line for every publish (with its exit code and
  `status.json`), every `state`, every shot and every note.
- `<name>.json` holds `state` snapshots and `<name>.png` holds screenshots.

The proof standards:

- **Use the user's path.** Drive the publisher with the panel's arguments,
  and click in the app with the mouse. Never write the theme JSON by hand.
- **Capture the action and the result.** Take a `state` before and after,
  and a screenshot of the moment that matters.
- **Check side effects as well as pixels.** That means `status.json`
  (wallpaper, style, tint, `published`) and the in-app `wallpaperHash`.
- **Wait for asynchronous pictures.** T3 Code loads full-alt's background
  file after the theme changes. Give a publish a second, then wait for
  `--theme-background-image`, or `state` reads the previous picture.

## Cleanup

```bash
$V down
```

`down` kills only what this sandbox started:

- the recorded T3 Code main PID, confirmed by its pid file and the CDP port
  in its command line (Electron blanks its own environ);
- every process whose environ carries `T3V_SANDBOX=<sandbox>`, including
  any publisher run still going.

It stops them in a fixed order:

1. The T3 Code main process gets SIGTERM, and `down` waits up to 30 s while
   it quits and closes its own renderers and backend.
2. Any leftover helpers come next.
3. The AppImage's own process (the one whose `/proc/<pid>/exe` is the
   AppImage file) goes last. It serves the FUSE mount every other T3 Code
   process runs from, and it exits by itself once they are gone.

Then `down` removes `.verify/run/`. `.verify/evidence/` is kept. A full
`down` takes about 7 s.

Never kill everything at once. If the mount goes first, every Electron
process still running dies with SIGBUS. Each one leaves a core dump, and the
user gets a "Process crashed: t3code" notification. Check with
`coredumpctl list --since "-10 min"`: a clean `down` adds nothing.

Never kill by process name: the user's own T3 Code is running alongside,
and this agent may be running inside it. Run `down` after every failed `up`
too.

## Helpers

- `scripts/verify`: the CLI above. Running it with no arguments prints usage.
- `scripts/cdp.mjs`: a dependency-free CDP client (Node's `fetch` and
  `WebSocket`) used by `verify cdp`. It also runs directly as
  `T3V_PORT=9339 node .claude/skills/verify-thememaxed/scripts/cdp.mjs eval 'document.title'`.

## Not covered

- **The bar panel UI** (`Panel.qml`, `StylePreview.qml`, `BarWidget.qml`)
  lives in the user's running Omarchy shell. It can't be sandboxed, and the
  installed plugin (`~/.config/omarchy/plugins/io.github.jagrat7.omarchy-t3code-plus`)
  is a separate copy, not this checkout. Check QML syntax with
  `qmllint <file>`. Seeing it live means installing the checkout into the
  user's shell, which changes their desktop, so ask first.
- **Reacting to desktop changes** (`Service.qml` watching `theme.generation`,
  `fonts.conf` and the wallpaper symlink) is also shell-side. The publisher's
  half of that reaction is `$V publish`.
- The sandbox renders the user's **current** Omarchy theme. To test another
  theme, the user has to switch themes, or you point
  `.verify/run/state/omarchy/current` at a copy of a theme folder that
  includes a rendered `t3code.json`.
