# Thememaxed verification map

This folder is the maintained source for checking what users of T3 Code
Thememaxed see. Read this index before you drive the app, then follow the
matching feature file as the recipe. The harness is the `verify-thememaxed`
skill (`.agents/skills/verify-thememaxed/`). Every command below assumes this
is set:

```bash
V=.agents/skills/verify-thememaxed/scripts/verify
```

## Baseline preconditions

- Hyprland session, with the T3 Code AppImage at
  `~/AppImages/t3_code_nightly.appimage` (or set `T3V_APP`).
- An Omarchy theme with at least three still wallpapers. The sandbox renders
  the user's current theme, read only.
- `$V up` has printed `ready:` and `$V doctor` shows only `ok` lines.
- The sandbox starts on the `full` style, in a new thread of the empty
  `project` repo.
- Never drive the user's own T3 Code (`~/.t3`). Only drive the sandbox that
  `$V up` started.

## Driving conventions

- Drive the panel's actions through the publisher arguments the panel sends:
  a style tile is `--style`, the tint slider and **Auto** are `--tint`, and
  **New wallpaper** is a publish with no arguments.
- Read results from the app with `$V state <name>` and `$V shot <name>`.
  Read the publisher's side effects from the `status` half of `state`.
- Wait on conditions (`$V cdp wait`), not on fixed sleeps. Full-alt
  publishes take seconds.
- A style persists in the sandbox config. Put the style back after a recipe
  that changes it.

## Proof and skip reporting

- Take a `state` before and after each action, and a screenshot of the
  moment that matters.
- Name every evidence file after its feature and step (for example
  `tint-0.3`).
- Prove a change that is meant to be visible in the app (`state.app`), not
  only in `status.json`.
- The bar panel UI can't be driven in the sandbox. Report it as not
  verified, rather than counting the publisher arguments as proof of the
  panel.
- Report an unreachable step with the command tried and the precondition
  that failed.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph that describes
what the user sees. It then has exactly four H2 sections, in this order:

1. `Sub-features`
2. `How to get to it (user POV)`
3. `Driving it with verify-thememaxed`
4. `Gotchas`

## Features

- [Styles](./styles.md): minimal, full, max and full-alt, and what each puts
  behind the sidebar and the conversation.
- [Full-alt background file](./full-alt-background.md): full-alt's wallpaper
  as a full-size file beside the theme, shown at once.
- [Backdrop tint](./tint.md): full-alt's chat-column tint, and that changing
  it keeps the wallpaper.
- [New wallpaper](./new-wallpaper.md): deals a different theme wallpaper
  inside T3 Code.
