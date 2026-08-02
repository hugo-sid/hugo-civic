#!/usr/bin/env bash
# Builds exampleSite at every preset. Catches manifest breakage (a @forward
# path that a USWDS release renamed), mount breakage, and template errors.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

fail=0
for preset in minimal standard full; do
  printf 'building preset=%-9s ... ' "$preset"
  # Hugo has no CLI flag for arbitrary params; HUGO_PARAMS_* is the supported
  # override path (params.uswds.preset -> HUGO_PARAMS_USWDS_PRESET).
  if out=$(cd exampleSite && rm -rf public resources && \
           HUGO_PARAMS_USWDS_PRESET="$preset" \
           hugo --quiet --logLevel warn -e production 2>&1); then
    css=$(find exampleSite/public/css -name '*.css' | head -1)
    printf 'ok   css=%sK gz=%sK\n' \
      "$(( $(stat -c%s "$css") / 1024 ))" \
      "$(( $(gzip -c "$css" | wc -c) / 1024 ))"
  else
    printf 'FAIL\n%s\n' "$out"
    fail=1
  fi
  # Warnings are build signals, not noise — an unresolved asset or a missing
  # identifier link shows up here.
  if echo "$out" | grep -q 'WARN'; then
    echo "$out" | grep 'WARN' | sed 's/^/  /'
    fail=1
  fi
done
exit "$fail"
