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

fonts=$(du -sk exampleSite/public/fonts 2>/dev/null | cut -f1 || echo 0)
printf 'FONT %-9s %6s KB on disk  budget %6s KB       ' "woff2" "$fonts" "$FONT_BUDGET_KB"
if [ "$fonts" -gt "$FONT_BUDGET_KB" ]; then
  echo "FAIL (expected one family — check fontTypeSerif / fontTypeMono)"
  fail=1
else
  echo "ok"
fi
exit "$fail"
