#!/bin/sh
set -eu

base_url="${1:-http://127.0.0.1:5173}"

curl --fail --silent --show-error "$base_url/" | grep -qi 'tscircuit'
curl --fail --silent --show-error "$base_url/api/_fake/render_demo" | grep -qi 'tscircuit'
printf 'tscircuit web and fake API smoke checks passed at %s\n' "$base_url"
