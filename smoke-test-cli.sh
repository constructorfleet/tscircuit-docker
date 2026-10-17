#!/bin/sh
set -eu

base_url="${1:-http://127.0.0.1:3020}"

curl --fail --silent --show-error "$base_url/" | grep -qi 'tscircuit'
printf 'tscircuit CLI browser preview smoke check passed at %s\n' "$base_url"
