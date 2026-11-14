#!/usr/bin/env bash
# Remove the standalone install of Omarchy+ for T3 Code (scripts/install.sh).
# The plugin is removed with: omarchy plugin remove io.github.jagrat7.omarchy-t3code-theme
# Files are moved aside, not deleted. Omarchy's own "Omarchy" theme for T3 Code
# is untouched either way.
# https://github.com/jagrat7/omarchy-t3code-theme

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGETS=(
  "$HOME/.local/bin/t3code-omarchy-theme"
  "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-t3code-theme"
  "$CONFIG_HOME/omarchy/hooks/theme-set.d/t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy/hooks/font-set.d/t3code-omarchy-theme"
  "$CONFIG_HOME/omarchy-t3code-theme"
  "${T3CODE_HOME:-$HOME/.t3}/userdata/themes/omarchy-plus.json"
)

backup="$CONFIG_HOME/omarchy/backups/t3code-theme-uninstalled-$(date +%Y%m%d-%H%M%S)"
for target in "${TARGETS[@]}"; do
  [[ -e $target || -L $target ]] || continue
  relative="${target#"$HOME"/}"
  mkdir -p "$backup/$(dirname -- "$relative")"
  mv -- "$target" "$backup/$relative"
done

if [[ -d $backup ]]; then
  echo "Removed. The files were moved to ${backup/#$HOME/\~}"
  echo "If T3 Code was set to Omarchy+, pick Settings > Appearance > Omarchy."
else
  echo "Nothing to remove."
fi
