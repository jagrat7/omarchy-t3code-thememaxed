#!/usr/bin/env bash
# Install T3 Code Thememaxed without the plugin: Omarchy hooks republish the
# theme on theme and font changes. Use either this or the plugin, not both.
#
#   bash scripts/install.sh [minimal|full|max|full-alt]
#
# Works from a checkout, or piped from curl (it then clones the repo itself).
# https://github.com/jagrat7/omarchy-t3code-thememaxed

set -euo pipefail

REPO_URL="https://github.com/jagrat7/omarchy-t3code-thememaxed.git"
PLUGIN_ID="io.github.jagrat7.omarchy-t3code-plus"
STYLE="${1:-}"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-t3code-plus"
COMMAND="$HOME/.local/bin/t3code-omarchy-plus"
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
Usage: bash scripts/install.sh [minimal|full|max|full-alt]

  minimal   the desktop wallpaper behind the sidebar's header
  full      the header, plus a random theme wallpaper behind the conversation
  max       the header and conversation, plus the wallpaper down the sidebar
  full-alt  the desktop wallpaper, sharp, behind a frosted chat column

Without a style, a new install gets "full" and an update keeps its style.
EOF
}

case $STYLE in
  "" | minimal | full | max | full-alt) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

for id in "$PLUGIN_ID" io.github.jagrat7.omarchy-t3code-theme; do
  if [[ -e $CONFIG_HOME/omarchy/plugins/$id ]]; then
    die "the T3 Code Thememaxed plugin is installed and already does this. Remove it first (omarchy plugin remove $id) to use the hooks instead."
  fi
done
command -v omarchy-theme-set-t3code >/dev/null ||
  die "this needs Omarchy with its T3 Code integration (omarchy-theme-set-t3code was not found)."
command -v omarchy-theme-color >/dev/null ||
  die "this needs omarchy-theme-color, from Omarchy 4."
python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null ||
  die "this needs Python 3.11 or newer."
# Read the whole list first: grep -q stops early, and under pipefail the
# SIGPIPE that gives magick would read as a failure.
formats=$(command -v magick >/dev/null && magick -list format 2>/dev/null || true)
if ! grep -qE '^\s*AVIF\s.*\brw' <<<"$formats"; then
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

# Earlier versions of this repo: the first overrode Omarchy's t3code.json.tpl
# and wrote over Omarchy's own theme, and the second was named
# omarchy-t3code-theme (a name Omarchy keeps for themes). Move their files
# aside, and keep the config of the second.
legacy=(
  "$HOME/.local/bin/sync-t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy/themed/t3code.json.tpl"
  "$CONFIG_HOME/omarchy/themed/t3code.css.tpl"
  "$HOOKS/theme-set.d/05-sync-t3code-omarchy-theme"
  "$HOOKS/font-set.d/sync-t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy/t3code-theme.toml"
  "$HOME/.local/bin/t3code-omarchy-theme"
  "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-t3code-theme"
  "$HOOKS/theme-set.d/t3code-omarchy-theme"
  "$HOOKS/font-set.d/t3code-omarchy-theme"
)
legacy_backup="$BACKUPS/t3code-plus-legacy-$(date +%Y%m%d-%H%M%S)"
rerender=false
for file in "${legacy[@]}"; do
  [[ -e $file || -L $file ]] || continue
  if [[ $file == */t3code.json.tpl ]]; then
    grep -q 't3code_css' "$file" || continue
    rerender=true
  fi
  relative="${file#"$HOME"/}"
  mkdir -p "$legacy_backup/$(dirname -- "$relative")"
  mv -- "$file" "$legacy_backup/$relative"
done
[[ -d $legacy_backup ]] && say "Moved the earlier version's files to ${legacy_backup/#$HOME/\~}"
old_config="$CONFIG_HOME/omarchy-t3code-theme"
if [[ -d $old_config && ! -e $CONFIG_HOME/omarchy-t3code-plus ]]; then
  mv -- "$old_config" "$CONFIG_HOME/omarchy-t3code-plus"
fi

install -Dm755 -- "$source_dir/bin/t3code-omarchy-plus" "$SHARE/bin/t3code-omarchy-plus"
install -Dm644 -- "$source_dir/themed/t3code.css.tpl" "$SHARE/themed/t3code.css.tpl"
mkdir -p "$(dirname -- "$COMMAND")"
ln -sfn -- "$SHARE/bin/t3code-omarchy-plus" "$COMMAND"
install -Dm755 -- "$source_dir/hooks/theme-set" "$HOOKS/theme-set.d/t3code-omarchy-plus"
install -Dm755 -- "$source_dir/hooks/font-set" "$HOOKS/font-set.d/t3code-omarchy-plus"

# Record the style (a new install defaults to full) and publish. With the
# first version's palette template gone, Omarchy has to render its own again.
config="$CONFIG_HOME/omarchy-t3code-plus/config.toml"
if [[ $rerender == true ]]; then
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
  say "In T3 Code, choose Settings > Appearance > Thememaxed."
else
  say "T3 Code has not been run yet. Open it once, run t3code-omarchy-plus,"
  say "then choose Settings > Appearance > Thememaxed."
fi
say ""
say "  Switch style:          t3code-omarchy-plus --style minimal|full|max|full-alt"
say "  After a new wallpaper: t3code-omarchy-plus"
say "  Settings:              ${config/#$HOME/\~}"
