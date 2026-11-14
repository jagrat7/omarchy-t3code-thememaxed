#!/usr/bin/env bash
# Remove the Omarchy theme for T3 Code. Omarchy's own integration takes over
# again, with colours only. The removed files are moved aside, not deleted.
# https://github.com/jagrat7/omarchy-t3code-theme

set -euo pipefail

OMARCHY_CONFIG="$HOME/.config/omarchy"
TARGETS=(
  "$HOME/.local/bin/sync-t3code-omarchy-theme"
  "$OMARCHY_CONFIG/themed/t3code.json.tpl"
  "$OMARCHY_CONFIG/themed/t3code.css.tpl"
  "$OMARCHY_CONFIG/hooks/theme-set.d/05-sync-t3code-omarchy-theme"
  "$OMARCHY_CONFIG/hooks/font-set.d/sync-t3code-omarchy-theme"
  "$OMARCHY_CONFIG/t3code-theme.toml"
)

backup="$OMARCHY_CONFIG/backups/t3code-theme-uninstalled-$(date +%Y%m%d-%H%M%S)"
for target in "${TARGETS[@]}"; do
  [[ -e $target ]] || continue
  relative="${target#"$HOME"/}"
  mkdir -p "$backup/$(dirname -- "$relative")"
  mv -- "$target" "$backup/$relative"
done

if [[ -d $backup ]]; then
  echo "Removed. The files were moved to ${backup/#$HOME/\~}"
else
  echo "Nothing to remove."
  exit 0
fi

# Omarchy's colours-only theme for T3 Code replaces this one.
echo "Applying the current theme..."
omarchy theme refresh >/dev/null 2>&1 || true
