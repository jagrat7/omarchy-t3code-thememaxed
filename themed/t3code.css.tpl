/* T3 Code styled after the Omarchy shell.

   bin/t3code-omarchy-plus fills in the {{ tokens }} with the active theme's
   values, the same ones Omarchy's own templates get (omarchy-theme-color),
   supplies the --omarchy-* values (system font, Hyprland rounding and
   borders, the menu and popup styling from shell.toml, the wallpapers) and
   publishes the result to T3 Code as the "Thememaxed" theme.

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
   feed all of T3 Code's interface, prose, composer and code text: every
   font-family in its stylesheet reads one of them. */
:root {
  --font-sans: var(--omarchy-font), ui-monospace, monospace !important;
  --font-mono: var(--omarchy-font), ui-monospace, monospace !important;
  --font-composer: var(--omarchy-font), ui-monospace, monospace !important;
}

/* Shape: Hyprland's window rounding. */
:root {
  --radius: var(--omarchy-radius) !important;
  --control-radius: var(--omarchy-radius) !important;
}

[data-user-message-bubble],
[data-slot="composer-host"],
[data-chat-composer-main-surface],
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
[class*="rounded-["],
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
   frame is an overlay cut to a border, so it follows the corners and the row
   keeps its size. */
[data-thread-item] [aria-current]:not([aria-current="false"]),
[data-slot="menu-popup"] [data-highlighted] {
  position: relative;
  background: linear-gradient(var(--omarchy-row-fill), var(--omarchy-row-fill)) !important;
  color: var(--omarchy-row-text) !important;
  border-radius: var(--omarchy-radius) !important;
}

[data-thread-item] [aria-current]:not([aria-current="false"])::after,
[data-slot="menu-popup"] [data-highlighted]::after {
  content: "";
  position: absolute;
  inset: 0;
  border: solid transparent;
  border-width: var(--omarchy-row-border-top) var(--omarchy-row-border-right) var(--omarchy-row-border-bottom) var(--omarchy-row-border-left);
  border-radius: inherit;
  background: var(--omarchy-row-border) border-box;
  mask: linear-gradient(#000 0 0) padding-box exclude, linear-gradient(#000 0 0);
  pointer-events: none;
}

[data-thread-item] [aria-current]:not([aria-current="false"]) {
  background-color: {{ dark_background }} !important;
}

[data-slot="menu-popup"] [data-highlighted] {
  background-color: {{ background }} !important;
}

/* Wallpaper. The publisher supplies two pictures, blurred and tinted with
   floors that keep text readable: --omarchy-header-wallpaper is the
   theme's first wallpaper, --omarchy-wallpaper a random one of the theme's.
   full-alt instead shows a random one whole, as the theme's background
   image (--theme-background-image, from a file beside the theme).
   The chosen style keeps some of the @part blocks below: minimal keeps the
   header, full adds the background, max adds the sidebar, and full-alt
   keeps only its own. */

/* @part header (minimal, full, max): the theme's first wallpaper sits behind the sidebar's
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

/* @part background (full, max): a random wallpaper of the theme lies
   behind the conversation, centred and tinted evenly. */
[data-workspace-area="conversation"] {
  background-image:
    linear-gradient(var(--omarchy-tint), var(--omarchy-tint)),
    var(--omarchy-wallpaper) !important;
  background-size: cover !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
}

/* A new thread has no messages to keep readable, only the heading and the
   composer, so the wallpaper shows through at half the tint, darker in the
   middle where they sit. T3 Code marks no new-thread state; its composer then
   fills the conversation (inset-0) instead of sitting at the bottom. */
[data-workspace-area="conversation"]:has(~ [data-chat-composer-overlay].inset-0) {
  background-image:
    radial-gradient(50% 40% at 50% 50%, var(--omarchy-tint), transparent),
    linear-gradient(color-mix(in srgb, var(--omarchy-tint) 50%, transparent), color-mix(in srgb, var(--omarchy-tint) 50%, transparent)),
    var(--omarchy-wallpaper) !important;
}

/* On a new thread, and while a thread loads, T3 Code fills the empty
   timeline with a solid placeholder that hides the wallpaper. */
[data-timeline-loading] {
  background: transparent !important;
}
/* @end */

/* @part sidebar (max): the theme's first wallpaper runs down the whole
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

/* @part backdrop (full-alt): a theme wallpaper at full size as a scene behind
   the conversation, sharp at the sides. T3 Code 0.1.10 and later serve it from
   the file beside the theme as --theme-background-image; until it has loaded,
   or in an older T3 Code, the theme's ground shows instead. The chat column is frosted glass: the
   picture behind it blurred and tinted only as much as the wallpaper's
   brightness needs, fading out at its edges. The glass sits behind the
   messages, between the conversation's background and its content. */
[data-workspace-area="conversation"] {
  background:
    linear-gradient(var(--omarchy-scene-edge), var(--omarchy-scene-edge)),
    var(--theme-background-image, none) center / cover no-repeat,
    {{ background }} !important;
  isolation: isolate;
  /* The glass reaches 6rem past the column even where the window is too
     narrow for it; the part outside the conversation is cut off, so the
     soft edge never lands under the text. */
  overflow: clip;
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
  transition: opacity 0.3s ease;
}

/* The chat column is not always centred in the conversation: T3 Code can pad
   the timeline on the right to clear the thread details panel, and the
   column moves left. The glass is anchored to the column
   itself, 6rem wider on each side, so it follows wherever the column goes. Without a column (a new thread) it falls
   back to the full width, where it is hidden anyway. */
[data-timeline-root].chat-content-lane {
  anchor-name: --omarchy-chat-lane;
}

@supports (anchor-name: --omarchy-chat-lane) {
  [data-workspace-area="conversation"]::before {
    margin: 0;
    width: auto;
    left: calc(anchor(--omarchy-chat-lane left, 6rem) - 6rem);
    right: calc(anchor(--omarchy-chat-lane right, 6rem) - 6rem);
  }
}

/* A new thread (see the background part) has no chat column: the whole
   scene shows, lightly tinted, with a glow of the tint behind the heading
   and composer to keep them readable. */
[data-workspace-area="conversation"]:has(~ [data-chat-composer-overlay].inset-0) {
  background:
    radial-gradient(45% 40% at 50% 50%, var(--omarchy-scene-tint), transparent),
    linear-gradient(var(--omarchy-scene-edge), var(--omarchy-scene-edge)),
    var(--theme-background-image, none) center / cover no-repeat,
    {{ background }} !important;
}

[data-workspace-area="conversation"]:has(~ [data-chat-composer-overlay].inset-0)::before {
  opacity: 0;
}

[data-timeline-loading] {
  background: transparent !important;
}

[data-user-message-bubble] {
  background-color: var(--omarchy-scene-bubble) !important;
  box-shadow: inset 0 0 0 1px var(--omarchy-scene-line) !important;
}

:root,
[data-slot="composer-shell"] {
  --glass-blur: 0px !important;
  --glass-opacity: 100% !important;
  --chat-composer-glass-surface: var(--omarchy-scene-card) !important;
}

/* The composer is frosted: always on a new thread, and on an open thread
   while messages are scrolled up behind it. T3 Code gives the composer a
   view-transition-name, which stops any blur inside it from seeing the
   page behind, so the frost is a layer one level up, on the composer stack,
   pinned to the composer card. The stash tab docked on the card gets its
   own layer, so the gap beside the tab stays clear. The open-thread frost
   follows the message list's scroll position; without scroll-driven
   animations it stays off. */
[data-chat-composer-main-surface] {
  anchor-name: --omarchy-composer;
}

[data-composer-shoulder-tab] {
  anchor-name: --omarchy-composer-tab;
}

[class~="group/composer-stack"]::before {
  content: "";
  position: absolute;
  z-index: -1;
  top: anchor(--omarchy-composer top);
  left: anchor(--omarchy-composer left);
  right: anchor(--omarchy-composer right);
  bottom: anchor(--omarchy-composer bottom);
  border-radius: var(--omarchy-radius);
  pointer-events: none;
}

[class~="group/composer-stack"]:has([data-composer-shoulder-tab])::after {
  content: "";
  position: absolute;
  z-index: -1;
  top: anchor(--omarchy-composer-tab top);
  left: anchor(--omarchy-composer-tab left);
  right: anchor(--omarchy-composer-tab right);
  bottom: anchor(--omarchy-composer top);
  border-radius: var(--omarchy-radius) var(--omarchy-radius) 0 0;
  pointer-events: none;
}

[data-chat-composer-overlay].inset-0 [class~="group/composer-stack"]::before,
[data-chat-composer-overlay].inset-0 [class~="group/composer-stack"]::after {
  backdrop-filter: blur(24px);
}

.messages-timeline-scroll {
  scroll-timeline: --omarchy-messages y;
}

:has(> [data-chat-composer-overlay]) {
  timeline-scope: --omarchy-messages;
}

[data-chat-composer-overlay]:not(.inset-0) [class~="group/composer-stack"]::before,
[data-chat-composer-overlay]:not(.inset-0) [class~="group/composer-stack"]::after {
  animation: omarchy-composer-frost linear both;
  animation-timeline: --omarchy-messages;
  animation-range: calc(100% - 2rem) 100%;
}

@keyframes omarchy-composer-frost {
  from { backdrop-filter: blur(24px); }
  to { backdrop-filter: none; }
}
/* @end */

/* The row under the composer (machine, checkout, branch, access) is just
   text, without the page-coloured glass T3 Code puts behind it. */
[data-slot="composer-context-strip"] {
  background: transparent !important;
  backdrop-filter: none !important;
}

/* The composer is framed by the inactive window border, at rest and in focus.
   T3 Code draws the outline on the card, or on its main surface while a
   banner (such as the stash tab) is attached, so both are covered. */
[data-slot="composer-host"]::after,
[data-chat-composer-main-surface]::after {
  border-color: var(--omarchy-inactive-border) !important;
  box-shadow: none !important;
}

/* The composer's glass fill is drawn on ::before layers that T3 Code rounds
   a step more than the card. Inside the card's frame that left a crescent of
   the background at every corner, so the fill takes the frame's corners.
   Banners docked on the composer (such as the stash tab) follow suit. */
[data-slot="composer-host"]::before,
[data-slot="composer-shell"]::before,
[data-composer-banner-surface="detached"]::before {
  border-radius: var(--omarchy-radius) !important;
}

[data-composer-banner-surface="attached"]::before {
  border-top-left-radius: var(--omarchy-radius) !important;
  border-top-right-radius: var(--omarchy-radius) !important;
}

/* Banners docked on the composer draw their outline from the composer's
   outline colour, so they share its inactive border. Error and warning
   banners keep their own. */
[data-slot="composer-shell"] {
  --chat-composer-outline: var(--omarchy-inactive-border) !important;
}

/* The stash tab is part of the composer window: the composer's own fill,
   instead of T3 Code's raised surface. */
[data-composer-shoulder-tab] {
  --chat-composer-attached-surface: var(--chat-composer-glass-surface) !important;
}

