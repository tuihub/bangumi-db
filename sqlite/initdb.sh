#!/bin/sh
set -eu

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

archive="$temp_dir/archive.zip"

if [ -n "${ASSET_DOWNLOAD_URL:-}" ]; then
    curl -fL --retry 3 -o "$archive" -- "$ASSET_DOWNLOAD_URL"
else
    metadata=${2:-"$temp_dir/latest.json"}
    curl -fsSL --retry 3 https://raw.githubusercontent.com/bangumi/Archive/master/aux/latest.json -o "$metadata"
    url=$(jq -er '.browser_download_url' "$metadata")
    digest=$(jq -er '.digest | sub("^sha256:"; "")' "$metadata")
    curl -fL --retry 3 -o "$archive" -- "$url"
    printf '%s  %s\n' "$digest" "$archive" | sha256sum -c -
fi

python3 "$(dirname "$0")/build.py" "$archive" "$1"
