#!/usr/bin/env bash
set -euo pipefail

# Update Zed's auto_install_extensions from the local extensions index using only jq.

INDEX="$HOME/Library/Application Support/Zed/extensions/index.json"
SETTINGS="$HOME/.config/zed/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$INDEX" ]]; then
  echo "Error: index not found: $INDEX" >&2
  exit 1
fi

if [[ ! -f "$SETTINGS" ]]; then
  echo "Error: settings not found: $SETTINGS" >&2
  exit 1
fi

tmp_file=$(mktemp)

# Note: This strips // comment lines from settings.json before parsing, since jq
# expects strict JSON. It then merges all extensions from index.json into
# .auto_install_extensions with value true and writes back the result.

# Build the extensions object once using jq
exts_json=$(jq -r '.extensions | keys | map({( . ): true}) | add' "$INDEX")

# Merge into settings; strip // comments before parsing
jq -n \
  --rawfile s "$SETTINGS" \
  --argjson exts "$exts_json" \
  '
    def strip_comments: gsub("(?m)^\\s*//.*$"; "");

    ($s | strip_comments | fromjson)
    | .auto_install_extensions = ((.auto_install_extensions // {}) + $exts)
  ' > "$tmp_file"

mv "$tmp_file" "$SETTINGS"
echo "Updated $SETTINGS from $INDEX"
