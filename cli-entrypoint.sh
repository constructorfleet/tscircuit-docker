#!/bin/sh
set -eu

if [ ! -f package.json ] && [ ! -f index.circuit.tsx ] && [ ! -f index.tsx ]; then
  tsci init --yes
fi

exec tsci dev "$@"
