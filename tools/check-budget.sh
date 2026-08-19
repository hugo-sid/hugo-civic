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
#
# minimal and standard both moved when usa-language-selector became chrome that
# every preset styles, because the theme renders the control on any site with a
# second language and a control it renders is a control it has to style:
#
#   minimal   22823 -> 23538 B  (+715: the selector, plus usa-accordion, whose
#                                list reset .usa-language__primary needs)
#   standard  40024 -> 40349 B  (+325: the selector alone)
#   full      unchanged — it already carried the component
#
# Raising a budget alongside a deliberate addition is the point of the ~10%
# rule above; left where they were, both presets would sit at 91-96% of budget
# on the day they shipped and the next legitimate component would trip a check
# that exists to catch regressions.
BUDGETS="minimal:26624 standard:45056 full:66560"
JS_BUDGET_GZ=${JS_BUDGET_GZ:-8192}      # core tier, loaded on every page
SEARCH_BUDGET_GZ=${SEARCH_BUDGET_GZ:-110592}  # first query, one language, on the wire

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
# (nothing here is fetched until someone opens the search page and types) but a
# theme that enforces budgets should not have a blind spot in it.
#
# What is measured is ONE first query in ONE language: the client, Pagefind's
# loader and entry file, then that language's wasm, meta and index chunks.
# Pagefind partitions its index by language, and a reader on /es/ fetches the
# es-es wasm and the es-es chunks and never the English ones — so summing every
# partition, as this line used to, prices a page nobody loads. The language with
# the largest partition is the one held to the budget; every language is
# reported, so a second language reads as its own figure rather than as a
# regression in a check that exists to catch regressions.
#
# Worth being honest about the size of that correction: it is 1523 B today
# (101188 -> 99665), because the old line already counted only the LARGEST wasm
# and the wasm is ~85% of a partition. What the rework buys is not today's
# number but that the number stays a page load — under the old arithmetic each
# language added its whole index to a figure describing a single visitor, so the
# error grew with every language a site added.
#
# Still deliberately NOT the whole directory: over half of public/pagefind/ is
# pagefind-ui.js, pagefind-component-ui.* and pagefind-highlight.js, which
# Pagefind writes unconditionally and this theme never requests, so a du(1)
# budget would be dominated by files nobody downloads and would move when
# Pagefind's UI moved rather than when this site's index did. Result fragments
# are excluded too — they are per-result, not per-search, and around 700 B each.
#
# One conservative choice is left: every index chunk of the budgeted language is
# counted, though a query fetches only the ones it needs.
#
# The wasm and the index chunks are written already-gzipped, so they are counted
# at their on-disk size; the rest is gzipped here as a CDN would.
if command -v pagefind >/dev/null; then
  (cd exampleSite && pagefind --site public >/dev/null)

  # Fetched on a first query whatever the language, so it belongs to every
  # partition's total rather than to any one of them.
  shared=0
  for f in exampleSite/public/pagefind/pagefind.js \
           exampleSite/public/pagefind/pagefind-entry.json \
           exampleSite/public/js/uswds-search*.js; do
    [ -f "$f" ] && shared=$(( shared + $(gzip -c "$f" | wc -c) ))
  done

  # pagefind-entry.json is the authority on which partitions exist: it names
  # each language's meta hash, the wasm build it loads, and how many pages it
  # holds. Deriving that from the filenames instead would guess at all three,
  # and the client reads this same file to decide what to fetch.
  partitions=$(python3 - <<'PY'
import json

with open("exampleSite/public/pagefind/pagefind-entry.json") as fh:
    entry = json.load(fh)

for lang, meta in sorted(entry["languages"].items()):
    print(lang, meta["hash"], meta["wasm"], meta["page_count"])
PY
)

  # A here-doc, not a pipe: `while read` in a pipeline runs in a subshell and
  # the winning language would not survive the loop.
  largest=0
  largest_lang=""
  while read -r lang hash wasm pages; do
    [ -n "$lang" ] || continue
    part=0
    for f in "exampleSite/public/pagefind/pagefind.$hash.pf_meta" \
             "exampleSite/public/pagefind/wasm.$wasm.pagefind" \
             exampleSite/public/pagefind/index/"$lang"_*.pf_index; do
      [ -f "$f" ] && part=$(( part + $(stat -c%s "$f") ))
    done
    printf '     %-9s %6s B on the wire  %3s page(s)\n' \
      "$lang" "$(( shared + part ))" "$pages"
    if [ "$part" -gt "$largest" ]; then
      largest=$part
      largest_lang=$lang
    fi
  done <<EOF
$partitions
EOF

  search=$(( shared + largest ))
  printf 'SRCH %-9s %6s B gzip  budget %6s B  (%s%%)  ' \
    "$largest_lang" "$search" "$SEARCH_BUDGET_GZ" "$(( search * 100 / SEARCH_BUDGET_GZ ))"
  if [ "$search" -gt "$SEARCH_BUDGET_GZ" ]; then echo "FAIL"; fail=1; else echo "ok"; fi
else
  echo "SRCH        skipped — pagefind is not installed (npm install)"
fi

exit "$fail"
