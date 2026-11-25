#!/bin/sh
set -eu

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

metadata="$temp_dir/latest.json"
archive="$temp_dir/archive.zip"

curl -fsSL --retry 3 https://raw.githubusercontent.com/bangumi/Archive/master/aux/latest.json -o "$metadata"
url=$(jq -er '.browser_download_url' "$metadata")
digest=$(jq -er '.digest | sub("^sha256:"; "")' "$metadata")
curl -fL --retry 3 "$url" -o "$archive"
printf '%s  %s\n' "$digest" "$archive" | sha256sum -c -

python3 "$(dirname "$0")/build.py" "$archive" "$1"
