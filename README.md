<h1 align="center">Omarchy theme for T3 Code</h1>

<p align="center">
  <a href="https://omarchy.org/"><img src="https://img.shields.io/badge/Omarchy-4-34c8cb?style=flat-square&labelColor=1c1d25&logo=archlinux&logoColor=white" alt="Omarchy 4"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jagrat7/omarchy-t3code-theme?style=flat-square&labelColor=1c1d25&color=34c8cb" alt="MIT license"></a>
</p>

Makes [T3 Code](https://github.com/pingdotgg/t3code) look like the rest of your Omarchy desktop,
and keeps it that way on every theme switch. Omarchy already gives T3 Code the
theme's colours. This adds the look: the system font, Hyprland's corners and
borders, the shell's menus and popups, and the theme's wallpaper behind the
app.

## What changes

- **Colours.** T3 Code's stock reds, greens, blues and so on become the theme's
  terminal colours, so badges, diff counts and status text stay on theme.
  Links take the accent; selections take the theme's selection colours.
- **One font.** Interface, chat, composer and code all use the Omarchy system
  font (`omarchy font set` updates T3 Code too).
- **Shape.** Corners follow Hyprland's window rounding, square included.
- **Borders.** The composer is drawn like a window: inactive border at rest,
  active border (gradient and all) while you type. Menus, dialogs and
  popovers use the shell's popup border; tooltips its tooltip border.
- **Selected rows.** The current thread and the highlighted menu item look
  like the selected row in the Omarchy menu.
- **Wallpaper.** Pick a style below. The picture is blurred and tinted so text
  stays readable on any wallpaper, more if the theme's own blur or scrim is
  stronger.

## Styles

| Style | Sidebar header | Conversation | Sidebar |
| --- | --- | --- | --- |
| `minimal` | Desktop wallpaper | Plain | Plain |
| `full` (default) | Desktop wallpaper | Random theme wallpaper | Plain |
| `too-much` | Desktop wallpaper | Random theme wallpaper | Desktop wallpaper |

The header always shows the wallpaper that is on your desktop. The
conversation gets a random one of the theme's wallpapers each time the theme
is published.

## Requirements

- Omarchy 4 with its T3 Code integration (`omarchy-theme-set-t3code`).
- A T3 Code build that supports theme CSS.
- Python 3.11 or newer, which Omarchy ships.
- ImageMagick with AVIF support for the wallpaper (`omarchy pkg add
  imagemagick libheif`). Without it, everything but the wallpaper still
  applies.

Tested with Omarchy 4.5 and T3 Code 0.1.10 (nightly, November 2026).

## Install

```bash
git clone https://github.com/jagrat7/omarchy-t3code-theme.git
cd omarchy-t3code-theme
./install.sh full        # or minimal, or too-much
```

Or in one line:

```bash
curl -fsSL https://raw.githubusercontent.com/jagrat7/omarchy-t3code-theme/main/install.sh | bash -s -- full
```

Then in T3 Code choose **Settings > Appearance > Omarchy**. From then on T3
Code follows every `omarchy theme set` and `omarchy font set` by itself.

Running the installer again updates the files and keeps your style unless you
name a new one. Any file it replaces is first copied to
`~/.config/omarchy/backups/t3code-theme-<date>/`.

## Use

```bash
sync-t3code-omarchy-theme --style too-much   # switch style
sync-t3code-omarchy-theme                    # republish: a new random wallpaper
```

Omarchy has no hook for wallpaper changes, so after `omarchy theme bg next` or
picking a new wallpaper, run `sync-t3code-omarchy-theme` to move the header to
it. The same goes for changes to Hyprland's rounding, border size or blur.

Settings live in `~/.config/omarchy/t3code-theme.toml`:

```toml
style = "full"     # minimal, full or too-much
min_blur = 20      # least blur, as a Gaussian sigma in screen pixels
min_tint = 0.75    # least opacity of the theme background over the picture
```

The theme's own blur (Hyprland's `decoration:blur`) and tint (the scrim behind
the shell's menu and launcher) win when they are stronger.

## How it works

The installer puts these in place:

| File | Role |
| --- | --- |
| `~/.config/omarchy/themed/t3code.json.tpl` | Palette template (T3 Code's colour roles). Replaces Omarchy's built-in one. |
| `~/.config/omarchy/themed/t3code.css.tpl` | CSS template. Omarchy fills in the colours. |
| `~/.local/bin/sync-t3code-omarchy-theme` | Publisher: adds the font, Hyprland and shell values and the wallpapers, then writes the theme. |
| `~/.config/omarchy/hooks/theme-set.d/05-sync-t3code-omarchy-theme` | Runs the publisher on theme changes. |
| `~/.config/omarchy/hooks/font-set.d/sync-t3code-omarchy-theme` | Runs it on font changes. |

On `omarchy theme set`, Omarchy renders both templates into
`~/.local/state/omarchy/current/theme/`. The hook then builds the CSS, embeds
the wallpapers as small blurred AVIF images, and writes
`~/.t3/userdata/themes/omarchy.json`, which T3 Code watches and applies live.

The palette template ends with `"css": "{{ t3code_css }}"`, a placeholder only
the publisher fills in. Omarchy's own publisher sees it as unresolved and
stands aside, so T3 Code gets the theme once, complete. That is why
`~/.local/state/omarchy/theme-set.log` says *Skipping T3 Code theme:
t3code.json has unresolved colors*. It is expected.

### Customising

Edit `~/.config/omarchy/themed/t3code.css.tpl`; every block says what it
does. Apply it with `omarchy theme refresh`. Colours are written as Omarchy
template tokens (`{{ accent }}`, `{{ dark_background }}`), and the publisher
supplies `--omarchy-*` variables for the rest. Blocks between
`/* @part background */` and `/* @end */` (or `@part sidebar`) are kept only by
the styles that use them. A reinstall overwrites the template, after backing
it up.

### Limits

- T3 Code takes at most 20,000 characters of theme CSS, pictures included. The
  publisher shrinks the wallpapers to fit and leaves them out, then the CSS,
  rather than publish a theme T3 Code would reject.
- Syntax colours in T3 Code's file viewer and diffs can't be themed. They are
  drawn in shadow DOM with a fixed scheme that theme CSS cannot reach.
- The CSS relies on T3 Code's `data-*` attributes where it can. The square
  corners also match Tailwind class names, which a T3 Code update may rename.

## Uninstall

```bash
./uninstall.sh
```

This moves the files aside (to `~/.config/omarchy/backups/`) and reapplies the
theme, so Omarchy's own colours-only T3 Code theme takes over again.

## License

[MIT](LICENSE). Not affiliated with Omarchy or T3 Code.
