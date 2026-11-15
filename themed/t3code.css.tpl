/* T3 Code styled after the Omarchy shell.

   bin/t3code-omarchy-plus fills in the {{ tokens }} with the active theme's
   values, the same ones Omarchy's own templates get (omarchy-theme-color),
   supplies the --omarchy-* values (system font, Hyprland rounding and
   borders, the menu and popup styling from shell.toml, the wallpapers) and
   publishes the result to T3 Code as the "Omarchy+" theme.

   https://github.com/jagrat7/omarchy-t3code-thememaxed */

/* Palette: T3 Code's stock hues become the theme's terminal colours, so
   status text, badges and diff counts stay inside the theme. */
:root {
  --color-red-300: {{ bright_red }};
  --color-red-400: {{ bright_red }};
  --color-red-500: {{ red }};
  --color-red-600: {{ red }};
  --color-red-700: {{ red }};
  --color-rose-400: {{ bright_red }};
  --color-rose-500: {{ red }};
  --color-rose-600: {{ red }};
  --color-orange-400: {{ orange }};
  --color-orange-500: {{ orange }};
  --color-orange-600: {{ orange }};
  --color-amber-300: {{ bright_yellow }};
  --color-amber-400: {{ bright_yellow }};
  --color-amber-500: {{ yellow }};
  --color-amber-600: {{ yellow }};
  --color-amber-700: {{ yellow }};
  --color-yellow-400: {{ bright_yellow }};
  --color-yellow-500: {{ yellow }};
  --color-yellow-600: {{ yellow }};
  --color-lime-400: {{ bright_green }};
  --color-lime-500: {{ green }};
  --color-lime-600: {{ green }};
  --color-green-400: {{ bright_green }};
  --color-green-500: {{ green }};
  --color-green-600: {{ green }};
  --color-emerald-300: {{ bright_green }};
  --color-emerald-400: {{ bright_green }};
  --color-emerald-500: {{ green }};
  --color-emerald-600: {{ green }};
  --color-emerald-700: {{ green }};
  --color-teal-300: {{ bright_cyan }};
  --color-teal-400: {{ bright_cyan }};
  --color-teal-500: {{ cyan }};
  --color-teal-600: {{ cyan }};
  --color-cyan-400: {{ bright_cyan }};
  --color-cyan-500: {{ cyan }};
  --color-cyan-600: {{ cyan }};
  --color-sky-300: {{ bright_cyan }};
  --color-sky-400: {{ bright_cyan }};
  --color-sky-500: {{ cyan }};
  --color-sky-600: {{ cyan }};
  --color-blue-400: {{ bright_blue }};
  --color-blue-500: {{ blue }};
  --color-blue-600: {{ blue }};
  --color-blue-700: {{ blue }};
  --color-indigo-300: {{ bright_blue }};
  --color-indigo-400: {{ bright_blue }};
  --color-indigo-500: {{ blue }};
  --color-indigo-600: {{ blue }};
  --color-violet-300: {{ bright_magenta }};
  --color-violet-400: {{ bright_magenta }};
  --color-violet-500: {{ magenta }};
  --color-violet-600: {{ magenta }};
  --color-purple-400: {{ bright_magenta }};
  --color-purple-500: {{ magenta }};
  --color-purple-600: {{ magenta }};
  --color-fuchsia-300: {{ bright_magenta }};
  --color-fuchsia-400: {{ bright_magenta }};
  --color-fuchsia-500: {{ magenta }};
  --color-fuchsia-600: {{ magenta }};
  --color-pink-400: {{ bright_magenta }};
  --color-pink-500: {{ magenta }};
  --color-pink-600: {{ magenta }};
}

/* Links are the accent, as in the shell. */
.chat-markdown a:not(.chat-markdown-file-link),
[data-user-message-bubble] a {
  color: {{ accent }} !important;
}

::selection {
  background-color: {{ selection_background }} !important;
  color: {{ selection_foreground }} !important;
}

/* Type: one font everywhere, the Omarchy system font. These three variables
   feed all of T3 Code's interface, prose, composer and code text. */
:root {
  --font-sans: var(--omarchy-font), ui-monospace, monospace !important;
  --font-mono: var(--omarchy-font), ui-monospace, monospace !important;
  --font-composer: var(--omarchy-font), ui-monospace, monospace !important;
}

body,
button,
input,
textarea,
select,
.chat-markdown,
.composer-tiptap {
  font-family: var(--font-sans) !important;
}

/* Shape: Hyprland's window rounding. */
:root {
  --radius: var(--omarchy-radius) !important;
  --control-radius: var(--omarchy-radius) !important;
}

[data-user-message-bubble],
[data-slot="composer-host"],
[data-thread-details-card],
.chat-markdown-codeblock,
.chat-markdown :is(pre, code, blockquote, img),
[data-slot="scroll-area-thumb"] {
  border-radius: var(--omarchy-radius) !important;
}

::-webkit-scrollbar-thumb {
  border-radius: var(--omarchy-radius);
}

/* @square: kept only while Hyprland rounding is 0. T3 Code's larger radii sit
   a fixed step above --radius, so they need flattening by hand. Circles
   (rounded-full) are left alone. */
[class*="rounded-xl"],
[class*="rounded-2xl"],
[class*="rounded-3xl"],
[class*="rounded-["]:not([class*="rounded-[50"], [class*="rounded-[99"]),
[class*="before:rounded-"]:not([class*="before:rounded-full"])::before,
[class*="after:rounded-"]:not([class*="after:rounded-full"])::after {
  border-radius: 0 !important;
}
/* @end */

/* Floating surfaces are Omarchy popups: the theme's ground, framed by the
   popup border (the Hyprland active border unless the theme says otherwise). */
[data-slot="menu-popup"],
[data-slot="dialog-popup"],
[data-slot="popover-popup"]:not([class*="bg-transparent"]) {
  border: var(--omarchy-border-width) solid transparent !important;
  background:
    linear-gradient({{ background }}, {{ background }}) padding-box,
    var(--omarchy-popup-border) border-box !important;
  box-shadow: none !important;
}

[data-slot="tooltip-popup"] {
  border: 1px solid transparent !important;
  background:
    linear-gradient({{ background }}, {{ background }}) padding-box,
    var(--omarchy-tooltip-border) border-box !important;
  box-shadow: none !important;
  color: {{ foreground }} !important;
}

/* The row you are on is drawn like the selected row of the Omarchy menu. The
   frame is painted as background strips so the row keeps its size. */
[data-thread-item] [aria-current]:not([aria-current="false"]),
[data-slot="menu-popup"] [data-highlighted] {
  background:
    var(--omarchy-row-border) left / var(--omarchy-row-border-left) 100% no-repeat,
    var(--omarchy-row-border) right / var(--omarchy-row-border-right) 100% no-repeat,
    linear-gradient(var(--omarchy-row-edge-top), var(--omarchy-row-edge-top)) top / 100% var(--omarchy-row-border-top) no-repeat,
    linear-gradient(var(--omarchy-row-edge-bottom), var(--omarchy-row-edge-bottom)) bottom / 100% var(--omarchy-row-border-bottom) no-repeat,
    linear-gradient(var(--omarchy-row-fill), var(--omarchy-row-fill)) !important;
  color: var(--omarchy-row-text) !important;
  border-radius: var(--omarchy-radius) !important;
}

[data-thread-item] [aria-current]:not([aria-current="false"]) {
  background-color: {{ dark_background }} !important;
}

[data-slot="menu-popup"] [data-highlighted] {
  background-color: {{ background }} !important;
}

/* Wallpaper. The sync hook supplies two pictures, blurred and tinted with
   floors that keep text readable: --omarchy-header-wallpaper is the
   wallpaper on the desktop, --omarchy-wallpaper a random one of the theme's.
   The chosen style keeps some of the @part blocks below: minimal keeps the
   header, full adds the background, too-much adds the sidebar, and backdrop
   keeps only its own. */

/* @part header (minimal, full, too-much): the desktop wallpaper sits behind the sidebar's
   header row. The picture is scaled to the sidebar's width and the row shows
   a band from its middle, fading into the sidebar below. The header holds
   only a few labels, so it carries 55% of the tint. Change 0.45 to slice the
   picture higher or lower. */
:root {
  --omarchy-header-tint: color-mix(in srgb, var(--omarchy-tint) 55%, transparent);
}

[data-slot="sidebar-inner"] {
  --strip: var(--workspace-topbar-height, 52px);
  background-image:
    linear-gradient(transparent 55%, {{ dark_background }}),
    linear-gradient(var(--omarchy-header-tint), var(--omarchy-header-tint)),
    linear-gradient({{ dark_background }}, {{ dark_background }}),
    var(--omarchy-header-wallpaper) !important;
  background-size: 100% var(--strip), 100% var(--strip), 100% calc(100% - var(--strip)), 100% auto !important;
  background-position: 0 0, 0 0, 0 var(--strip), center calc(var(--strip) / 2 - 0.45 * 0.5625 * var(--sidebar-width, 18rem)) !important;
  background-repeat: no-repeat !important;
}
/* @end */

/* @part background (full, too-much): a random wallpaper of the theme lies
   behind the conversation, centred and tinted evenly. */
[data-workspace-area="conversation"] {
  background-image:
    linear-gradient(var(--omarchy-tint), var(--omarchy-tint)),
    var(--omarchy-wallpaper) !important;
  background-size: cover !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
}
/* @end */

/* @part sidebar (too-much): the desktop wallpaper runs down the whole
   sidebar. The header row keeps its lighter tint and the threads below take
   the full one. */
[data-slot="sidebar-inner"] {
  background-image:
    linear-gradient(var(--omarchy-header-tint), var(--omarchy-header-tint) var(--strip), var(--omarchy-tint) calc(var(--strip) * 2)),
    var(--omarchy-header-wallpaper) !important;
  background-size: 100% 100%, cover !important;
  background-position: 0 0, center !important;
}
/* @end */

/* @part backdrop (backdrop): the desktop wallpaper as a scene behind the
   conversation, sharp at the sides. The chat column is frosted glass: the
   picture behind it blurred and tinted only as much as the wallpaper's
   brightness needs, fading out at its edges. The picture is centred on the
   conversation, so its middle, which the publisher softens to save room for
   the sides, stays behind the glass. The glass sits behind the messages,
   between the conversation's background and its content. */
[data-workspace-area="conversation"] {
  background:
    linear-gradient(var(--omarchy-scene-edge), var(--omarchy-scene-edge)),
    var(--omarchy-wallpaper) center / cover no-repeat,
    {{ background }} !important;
  image-rendering: var(--omarchy-wallpaper-rendering);
  isolation: isolate;
}

[data-workspace-area="conversation"] > * {
  image-rendering: auto;
}

[data-workspace-area="conversation"]::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: -1;
  margin: 0 auto;
  width: min(100%, calc(var(--chat-content-max-width) + 12rem));
  background: var(--omarchy-scene-tint);
  backdrop-filter: blur(24px);
  mask-image: linear-gradient(90deg, transparent, #000 6rem, #000 calc(100% - 6rem), transparent);
  pointer-events: none;
}

[data-user-message-bubble] {
  background-color: var(--omarchy-scene-bubble) !important;
  box-shadow: inset 0 0 0 1px var(--omarchy-scene-line) !important;
}

:root {
  --glass-blur: 0px !important;
  --glass-opacity: 100% !important;
  --chat-composer-glass-surface: var(--omarchy-scene-card) !important;
}

[data-slot="composer-host"] {
  background-color: var(--omarchy-scene-card) !important;
  backdrop-filter: none !important;
}
/* @end */

/* The composer is a window: inactive border at rest, active border in focus.
   T3 Code draws the outline on the card, or on its main surface while a
   banner (such as the stash tab) is attached, so both are covered. */
[data-slot="composer-host"]::after,
[data-chat-composer-main-surface]::after {
  border-color: var(--omarchy-inactive-border) !important;
  box-shadow: none !important;
}

[data-chat-composer-form]:focus-within [data-slot="composer-host"]::after,
[data-chat-composer-form]:focus-within [data-chat-composer-main-surface]::after {
  border: var(--omarchy-border-width) solid transparent !important;
  background: var(--omarchy-active-border) border-box !important;
  mask-image: linear-gradient(#000, #000), linear-gradient(#000, #000);
  mask-clip: padding-box, border-box;
  mask-composite: exclude;
}
