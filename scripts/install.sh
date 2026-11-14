#!/usr/bin/env bash
# Install Omarchy+ for T3 Code without the plugin: Omarchy hooks republish the
# theme on theme and font changes. Use either this or the plugin, not both.
#
#   bash scripts/install.sh [minimal|full|too-much]
#
# Works from a checkout, or piped from curl (it then clones the repo itself).
# https://github.com/jagrat7/omarchy-t3code-theme

set -euo pipefail

REPO_URL="https://github.com/jagrat7/omarchy-t3code-theme.git"
PLUGIN_ID="io.github.jagrat7.omarchy-t3code-theme"
STYLE="${1:-}"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-t3code-theme"
COMMAND="$HOME/.local/bin/t3code-omarchy-theme"
HOOKS="$CONFIG_HOME/omarchy/hooks"
BACKUPS="$CONFIG_HOME/omarchy/backups"
T3CODE_STATE="${T3CODE_HOME:-$HOME/.t3}/userdata"

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash scripts/install.sh [minimal|full|too-much]

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

[[ -e $CONFIG_HOME/omarchy/plugins/$PLUGIN_ID ]] &&
  die "the T3 Code Theme plugin is installed and already does this. Remove it first (omarchy plugin remove $PLUGIN_ID) to use the hooks instead."
command -v omarchy-theme-set-t3code >/dev/null ||
  die "this needs Omarchy with its T3 Code integration (omarchy-theme-set-t3code was not found)."
command -v omarchy-theme-color >/dev/null ||
  die "this needs omarchy-theme-color, from Omarchy 4."
python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null ||
  die "this needs Python 3.11 or newer."
if ! command -v magick >/dev/null || ! magick -list format 2>/dev/null | grep -qE '^\s*AVIF\s.*\brw'; then
  warn "ImageMagick with AVIF support was not found, so the wallpaper will be left out."
  warn "Install it with: omarchy pkg add imagemagick libheif"
fi

# The files: from this checkout, or a fresh clone when piped from curl.
source_dir=""
script="${BASH_SOURCE[0]:-}"
if [[ -n $script && -f "$(dirname -- "$script")/../themed/t3code.css.tpl" ]]; then
  source_dir="$(cd -- "$(dirname -- "$script")/.." && pwd)"
else
  command -v git >/dev/null || die "this needs git to download the theme."
  source_dir="$(mktemp -d)"
  trap 'rm -rf -- "$source_dir"' EXIT
  git clone --quiet --depth 1 "$REPO_URL" "$source_dir"
fi

# The first version of this repo overrode Omarchy's t3code.json.tpl and wrote
# over Omarchy's own theme. Move its files aside: they would stop Omarchy from
# publishing the palette this builds on.
legacy=(
  "$HOME/.local/bin/sync-t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy/themed/t3code.json.tpl"
  "$CONFIG_HOME/omarchy/themed/t3code.css.tpl"
  "$HOOKS/theme-set.d/05-sync-t3code-omarchy-theme"
  "$HOOKS/font-set.d/sync-t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy/t3code-theme.toml"
)
legacy_backup="$BACKUPS/t3code-theme-legacy-$(date +%Y%m%d-%H%M%S)"
for file in "${legacy[@]}"; do
  [[ -e $file ]] || continue
  if [[ $file == */t3code.json.tpl ]] && ! grep -q 't3code_css' "$file"; then
    continue
  fi
  relative="${file#"$HOME"/}"
  mkdir -p "$legacy_backup/$(dirname -- "$relative")"
  mv -- "$file" "$legacy_backup/$relative"
done
[[ -d $legacy_backup ]] && say "Moved the earlier version's files to ${legacy_backup/#$HOME/\~}"

install -Dm755 -- "$source_dir/bin/t3code-omarchy-theme" "$SHARE/bin/t3code-omarchy-theme"
install -Dm644 -- "$source_dir/themed/t3code.css.tpl" "$SHARE/themed/t3code.css.tpl"
mkdir -p "$(dirname -- "$COMMAND")"
ln -sfn -- "$SHARE/bin/t3code-omarchy-theme" "$COMMAND"
install -Dm755 -- "$source_dir/hooks/theme-set" "$HOOKS/theme-set.d/t3code-omarchy-theme"
install -Dm755 -- "$source_dir/hooks/font-set" "$HOOKS/font-set.d/t3code-omarchy-theme"

# Record the style (a new install defaults to full) and publish. With a
# legacy install moved aside, Omarchy has to render its own palette again.
config="$CONFIG_HOME/omarchy-t3code-theme/config.toml"
if [[ -d $legacy_backup ]]; then
  say "Applying the current theme..."
  omarchy theme refresh >/dev/null 2>&1 || true
fi
if [[ -n $STYLE || ! -f $config ]]; then
  "$COMMAND" --style "${STYLE:-full}"
else
  "$COMMAND"
fi
style=$(sed -n 's/^style *= *"\(.*\)".*/\1/p' "$config" | head -1)

say ""
say "Installed, style: ${style:-full}."
if [[ -d $T3CODE_STATE ]]; then
  say "In T3 Code, choose Settings > Appearance > Omarchy+."
else
  say "T3 Code has not been run yet. Open it once, run t3code-omarchy-theme,"
  say "then choose Settings > Appearance > Omarchy+."
fi
say ""
say "  Switch style:          t3code-omarchy-theme --style minimal|full|too-much"
say "  After a new wallpaper: t3code-omarchy-theme"
say "  Settings:              ${config/#$HOME/\~}"
