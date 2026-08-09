#!/usr/bin/env bash
# Size budgets, per preset. A budget you do not enforce is a wish, so this
# fails the build.
#
# Numbers are measured, not aspirational — they sit ~10% above what the theme
# currently produces so that a real regression trips them but normal drift does
# not. Re-measure with tools/check-build.sh after a USWDS upgrade.
#
# Baseline for comparison, USWDS 3.13.0 stock dist:
#   CSS 522 KB raw / 61.1 KB gzip     JS 82 KB raw / 25.9 KB gzip
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

# preset:css-gzip-budget
BUDGETS="minimal:24576 standard:44032 full:66560"
JS_BUDGET_GZ=${JS_BUDGET_GZ:-8192}      # core tier, loaded on every page
FONT_BUDGET_KB=${FONT_BUDGET_KB:-400}   # one family, woff2 only
SEARCH_BUDGET_GZ=${SEARCH_BUDGET_GZ:-110592}  # first query on /search/, on the wire

fail=0
for entry in $BUDGETS; do
  preset=${entry%%:*}; budget=${entry##*:}
  (cd exampleSite && rm -rf public resources && \
     HUGO_PARAMS_USWDS_PRESET="$preset" hugo --quiet -e production)
  css=$(find exampleSite/public/css -name '*.css' | head -1)
  gz=$(gzip -c "$css" | wc -c)
  printf 'CSS  %-9s %6s B gzip  budget %6s B  (%s%%)  ' \
    "$preset" "$gz" "$budget" "$(( gz * 100 / budget ))"
  if [ "$gz" -gt "$budget" ]; then echo "FAIL"; fail=1; else echo "ok"; fi
done

js=$(find exampleSite/public/js -name 'uswds-core*.js' | head -1)
gz=$(gzip -c "$js" | wc -c)
printf 'JS   %-9s %6s B gzip  budget %6s B  (%s%%)  ' \
  "core" "$gz" "$JS_BUDGET_GZ" "$(( gz * 100 / JS_BUDGET_GZ ))"
if [ "$gz" -gt "$JS_BUDGET_GZ" ]; then echo "FAIL"; fail=1; else echo "ok"; fi

# Search.
#
# The three budgets above cover what loads on EVERY page. Pagefind's runtime and
# index land in public/pagefind/ and are invisible to them — which is defensible
# (nothing here is fetched until someone opens /search/ and types) but a theme
# that enforces budgets should not have a blind spot in it.
#
# What is measured is a first query: the client, Pagefind's loader, the wasm,
# the entry file, the language meta and the index chunks. Deliberately NOT the
# whole directory — over half of public/pagefind/ is pagefind-ui.js,
# pagefind-component-ui.* and pagefind-highlight.js, which Pagefind writes
# unconditionally and this theme never requests, so a du(1) budget would be
# dominated by files nobody downloads and would move when Pagefind's UI moved
# rather than when this site's index did.
#
# Two conservative choices: every index chunk is counted, though a query fetches
# only the ones it needs, and the largest wasm is counted, though a page fetches
# only its own language's. Result fragments are excluded — they are per-result,
# not per-search, and around 700 B each.
#
# The wasm and the index chunks are written already-gzipped, so they are counted
# at their on-disk size; the rest is gzipped here as a CDN would.
if command -v pagefind >/dev/null; then
  (cd exampleSite && pagefind --site public >/dev/null)
  search=0
  for f in exampleSite/public/pagefind/pagefind.js \
           exampleSite/public/pagefind/pagefind-entry.json \
           exampleSite/public/js/uswds-search*.js; do
    [ -f "$f" ] && search=$(( search + $(gzip -c "$f" | wc -c) ))
  done
  for f in exampleSite/public/pagefind/*.pf_meta exampleSite/public/pagefind/index/*.pf_index; do
    [ -f "$f" ] && search=$(( search + $(stat -c%s "$f") ))
  done
  wasm=$(find exampleSite/public/pagefind -maxdepth 1 -name 'wasm.*.pagefind' -printf '%s\n' | sort -n | tail -1)
  search=$(( search + ${wasm:-0} ))

  printf 'SRCH %-9s %6s B gzip  budget %6s B  (%s%%)  ' \
    "1st query" "$search" "$SEARCH_BUDGET_GZ" "$(( search * 100 / SEARCH_BUDGET_GZ ))"
  if [ "$search" -gt "$SEARCH_BUDGET_GZ" ]; then echo "FAIL"; fail=1; else echo "ok"; fi
else
  echo "SRCH        skipped — pagefind is not installed (npm install)"
fi

fonts=$(du -sk exampleSite/public/fonts 2>/dev/null | cut -f1 || echo 0)
printf 'FONT %-9s %6s KB on disk  budget %6s KB       ' "woff2" "$fonts" "$FONT_BUDGET_KB"
if [ "$fonts" -gt "$FONT_BUDGET_KB" ]; then
  echo "FAIL (expected one family — check fontTypeSerif / fontTypeMono)"
  fail=1
else
  echo "ok"
fi
exit "$fail"
