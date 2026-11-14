<h1 align="center">T3 Code Theme</h1>

<p align="center">
  <a href="https://github.com/jagrat7/omarchy-t3code-theme/commits/main"><img src="https://img.shields.io/github/manifest-json/v/jagrat7/omarchy-t3code-theme?style=flat-square&label=version&labelColor=1c1d25&color=34c8cb" alt="Version"></a>
  <a href="https://omarchy.org/"><img src="https://img.shields.io/badge/Omarchy-Quattro-34c8cb?style=flat-square&labelColor=1c1d25&logo=archlinux&logoColor=white" alt="Omarchy Quattro"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jagrat7/omarchy-t3code-theme?style=flat-square&labelColor=1c1d25&color=34c8cb" alt="MIT license"></a>
</p>

An Omarchy plugin that gives [T3 Code](https://github.com/pingdotgg/t3code) the
rest of the desktop's look, not just its colours: the system font, Hyprland's
corners and borders, the shell's menus and popups, and the theme's wallpaper
behind the app. It follows every theme switch, font change and new wallpaper
on its own.

Omarchy already publishes a colours-only T3 Code theme called **Omarchy**.
This plugin leaves that one alone and publishes a second theme, **Omarchy+**,
built on the same palette.

## Install

```bash
omarchy plugin add https://github.com/jagrat7/omarchy-t3code-theme.git --enable
```

Then in T3 Code choose **Settings > Appearance > Omarchy+**. That's all: the
plugin runs in the Omarchy shell and republishes the theme whenever the
desktop changes.

## Styles

The wallpaper comes in three strengths:

| Style | Sidebar header | Conversation | Sidebar |
| --- | --- | --- | --- |
| `minimal` | Desktop wallpaper | Plain | Plain |
| `full` (default) | Desktop wallpaper | Random theme wallpaper | Plain |
| `too-much` | Desktop wallpaper | Random theme wallpaper | Desktop wallpaper |

The header shows the wallpaper on your desktop and changes with it. The
conversation gets a random one of the theme's wallpapers each time the theme
is republished. Every picture is blurred and tinted enough to keep text
readable, more if the theme's own blur or scrim is stronger.

Pick a style in `~/.config/omarchy-t3code-theme/config.toml`. The plugin
applies the file as soon as it is saved:

```toml
style = "full"     # minimal, full or too-much
min_blur = 20      # least blur, as a Gaussian sigma in screen pixels
min_tint = 0.75    # least opacity of the theme background over the picture
```

Or from a terminal, which also deals a new random wallpaper:

```bash
~/.config/omarchy/plugins/io.github.jagrat7.omarchy-t3code-theme/bin/t3code-omarchy-theme --style too-much
```

## What changes

- **Colours.** T3 Code's stock reds, greens, blues and so on become the theme's
  terminal colours, so badges, diff counts and status text stay on theme.
  Links take the accent; selections the theme's selection colours.
- **One font.** Interface, chat, composer and code use the Omarchy system font.
- **Shape.** Corners follow Hyprland's window rounding, square included.
- **Borders.** The composer is drawn like a window: inactive border at rest,
  active border (gradient and all) while you type. Menus, dialogs and
  popovers use the shell's popup border; tooltips its tooltip border.
- **Selected rows.** The current thread and the highlighted menu item look
  like the selected row in the Omarchy menu.
- **Wallpaper.** As the style says.

## Update and remove

```bash
omarchy plugin update io.github.jagrat7.omarchy-t3code-theme
omarchy plugin remove io.github.jagrat7.omarchy-t3code-theme
```

After removing it, choose **Omarchy** in T3 Code again. The settings stay in
`~/.config/omarchy-t3code-theme/` and the last published theme in
`~/.t3/userdata/themes/omarchy-plus.json`; delete them if you like.

## Without the plugin

The same publisher can run from Omarchy hooks instead of the shell. Use one
or the other, not both.

```bash
git clone https://github.com/jagrat7/omarchy-t3code-theme.git
bash omarchy-t3code-theme/scripts/install.sh full    # or minimal, or too-much
```

This puts `t3code-omarchy-theme` in `~/.local/bin` and adds `theme-set` and
`font-set` hooks. Omarchy has no hook for a new wallpaper, so after
`omarchy theme bg next` run `t3code-omarchy-theme` yourself. Remove it with
`bash scripts/uninstall.sh`, which moves its files to
`~/.config/omarchy/backups/`.

## Requirements

- Omarchy 4 (Quattro), which publishes T3 Code's palette
  (`omarchy-theme-set-t3code`) and resolves theme colours
  (`omarchy-theme-color`).
- A T3 Code build with theme CSS support.
- Python 3.11 or newer, which Omarchy ships.
- ImageMagick with AVIF support for the wallpaper (`omarchy pkg add
  imagemagick libheif`). Without it, everything but the wallpaper applies.

Tested with Omarchy 4.5 and T3 Code 0.1.10 (nightly, November 2026).

## How it works

`Service.qml` is a `service` plugin, so one copy runs in the shell. It runs
[`bin/t3code-omarchy-theme`](bin/t3code-omarchy-theme) when it starts and
again when `omarchy theme set` writes `theme.generation`, when `omarchy font
set` rewrites `fonts.conf`, when the wallpaper link in
`~/.local/state/omarchy/current/` changes, and when the config is saved.

The publisher:

1. reads the palette Omarchy rendered for T3 Code
   (`~/.local/state/omarchy/current/theme/t3code.json`), or the one the theme
   ships, as Omarchy's own template convention has it;
2. renders [`themed/t3code.css.tpl`](themed/t3code.css.tpl) with the theme's
   values from `omarchy-theme-color`, the resolver Omarchy's templates use, so
   `{{ accent }}`, `{{ accent_strip }}` and `{{ accent_rgb }}` work as in
   any Omarchy template;
3. adds what a template can't know as `--omarchy-*` variables: the system
   font, Hyprland's rounding, border size and blur, the shell's popup,
   tooltip and selected-row styling from `shell.toml`, and the wallpapers as
   small blurred AVIF images;
4. writes `~/.t3/userdata/themes/omarchy-plus.json`, which T3 Code watches.

### Customising

Every block of `themed/t3code.css.tpl` says what it does. Blocks between
`/* @part background */` or `/* @part sidebar */` and `/* @end */` are kept
only by the styles that use them. A plugin update replaces the template, so
keep your changes in a fork, or clone the plugin into place and edit there:
saving republishes.

### Limits

- T3 Code takes at most 20,000 characters of theme CSS, pictures included. The
  publisher shrinks the wallpapers to fit and leaves them out, then the CSS,
  rather than publish a theme T3 Code would reject.
- Syntax colours in T3 Code's file viewer and diffs can't be themed: they are
  drawn in shadow DOM with a fixed scheme that theme CSS cannot reach.
- The CSS uses T3 Code's documented `data-*` selectors. The square-corner
  rules also match Tailwind class names, which a T3 Code update may rename.

## Development

```bash
python3 -m unittest discover -s tests -v
omarchy plugin validate .
```

Symlink a clone into the plugin directory to work on it live:

```bash
git clone https://github.com/jagrat7/omarchy-t3code-theme.git
ln -s "$PWD/omarchy-t3code-theme" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/io.github.jagrat7.omarchy-t3code-theme"
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.jagrat7.omarchy-t3code-theme
```

## License

[MIT](LICENSE). Not affiliated with Omarchy or T3 Code.
