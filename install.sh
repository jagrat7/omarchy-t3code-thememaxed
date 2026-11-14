#!/usr/bin/env bash
# Install the Omarchy theme for T3 Code.
#
#   ./install.sh [minimal|full|too-much]
#
# Works from a checkout, or piped from curl (it then clones the repo itself).
# https://github.com/jagrat7/omarchy-t3code-theme

set -euo pipefail

REPO_URL="https://github.com/jagrat7/omarchy-t3code-theme.git"
STYLE="${1:-}"

OMARCHY_CONFIG="$HOME/.config/omarchy"
PUBLISHER="$HOME/.local/bin/sync-t3code-omarchy-theme"
CONFIG="$OMARCHY_CONFIG/t3code-theme.toml"
T3CODE_STATE="${T3CODE_HOME:-$HOME/.t3}/userdata"

# Repo file -> where it is installed.
declare -A FILES=(
  [bin/sync-t3code-omarchy-theme]="$PUBLISHER"
  [themed/t3code.json.tpl]="$OMARCHY_CONFIG/themed/t3code.json.tpl"
  [themed/t3code.css.tpl]="$OMARCHY_CONFIG/themed/t3code.css.tpl"
  [hooks/theme-set]="$OMARCHY_CONFIG/hooks/theme-set.d/05-sync-t3code-omarchy-theme"
  [hooks/font-set]="$OMARCHY_CONFIG/hooks/font-set.d/sync-t3code-omarchy-theme"
)

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: install.sh [minimal|full|too-much]

  minimal   the desktop wallpaper behind the sidebar's header
  full      the header, plus a random theme wallpaper behind the conversation
  too-much  the header and conversation, plus the wallpaper down the sidebar

Without a style, a new install gets "full" and an update keeps its style.
EOF
}

case $STYLE in
  "" | minimal | full | too-much) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

# Requirements.
command -v omarchy-theme-set-t3code >/dev/null ||
  die "this needs Omarchy with its T3 Code integration (omarchy-theme-set-t3code was not found)."
python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null ||
  die "this needs Python 3.11 or newer."
if ! command -v magick >/dev/null || ! magick -list format 2>/dev/null | grep -qE '^\s*AVIF\s.*\brw'; then
  warn "ImageMagick with AVIF support was not found, so the wallpaper will be left out."
  warn "Install it with: omarchy pkg add imagemagick libheif"
fi

# The files: from this checkout, or a fresh clone when piped from curl.
source_dir=""
if [[ -n ${BASH_SOURCE[0]:-} && -f "$(dirname -- "${BASH_SOURCE[0]}")/themed/t3code.css.tpl" ]]; then
  source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
else
  command -v git >/dev/null || die "this needs git to download the theme."
  source_dir="$(mktemp -d)"
  trap 'rm -rf -- "$source_dir"' EXIT
  git clone --quiet --depth 1 "$REPO_URL" "$source_dir"
fi

# Keep a copy of anything this replaces that differs from the new version.
backup="$OMARCHY_CONFIG/backups/t3code-theme-$(date +%Y%m%d-%H%M%S)"
for file in "${!FILES[@]}"; do
  target="${FILES[$file]}"
  if [[ -e $target ]] && ! cmp -s "$source_dir/$file" "$target"; then
    relative="${target#"$HOME"/}"
    mkdir -p "$backup/$(dirname -- "$relative")"
    cp -a -- "$target" "$backup/$relative"
  fi
done
[[ -d $backup ]] && say "Replaced files were saved in ${backup/#$HOME/\~}"

for file in "${!FILES[@]}"; do
  mode=755
  [[ $file == themed/* ]] && mode=644
  install -Dm"$mode" -- "$source_dir/$file" "${FILES[$file]}"
done

# Record the style (a new install defaults to full).
if [[ -n $STYLE || ! -f $CONFIG ]]; then
  "$PUBLISHER" --style "${STYLE:-full}"
fi
style=$(sed -n 's/^style *= *"\(.*\)".*/\1/p' "$CONFIG" | head -1)

# Render the templates for the current theme; the theme-set hook publishes.
say "Applying the current theme..."
omarchy theme refresh >/dev/null 2>&1 || "$PUBLISHER" || true

say ""
say "Installed, style: ${style:-full}."
if [[ -d $T3CODE_STATE ]]; then
  say "In T3 Code, choose Settings > Appearance > Omarchy."
else
  say "T3 Code has not been run yet. Open it once, run sync-t3code-omarchy-theme,"
  say "then choose Settings > Appearance > Omarchy."
fi
say ""
say "  Switch style:      sync-t3code-omarchy-theme --style minimal|full|too-much"
say "  Another wallpaper: sync-t3code-omarchy-theme"
say "  Settings:          ~/.config/omarchy/t3code-theme.toml"
