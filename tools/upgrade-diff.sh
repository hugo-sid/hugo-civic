#!/usr/bin/env bash
#
# Reports what a USWDS upgrade actually changes, as a review checklist.
#
# The risk in this theme is narrow and specific: USWDS changes a component's
# MARKUP and our partial drifts out of contract. Styles and settings take care
# of themselves — we compile from source and configure rather than fork — but a
# renamed class or a new ARIA attribute is invisible until something breaks.
#
# So this diffs the .twig contracts between two USWDS versions and maps each
# changed file to the partial that owns it, using the 1:1 naming convention
# (usa-<name>.twig -> layouts/_partials/**/<name>.html). That convention is
# load-bearing; see DESIGN.md §8.2.
#
# Usage: tools/upgrade-diff.sh <from-version> <to-version>
#        tools/upgrade-diff.sh v3.13.0 v3.14.0
set -euo pipefail
cd "$(dirname "$0")/.."

FROM=${1:-}
TO=${2:-}
if [ -z "$FROM" ] || [ -z "$TO" ]; then
  echo "usage: $0 <from-version> <to-version>   e.g. $0 v3.13.0 v3.14.0" >&2
  exit 2
fi

UPSTREAM=tools/upstream
if [ ! -d "$UPSTREAM/.git" ]; then
  echo "Fetching the USWDS reference checkout (gitignored, used only here)..."
  git clone --quiet --filter=blob:none https://github.com/uswds/uswds.git "$UPSTREAM"
fi
git -C "$UPSTREAM" fetch --quiet --tags origin

echo
echo "==============================================================="
echo " USWDS $FROM -> $TO"
echo "==============================================================="

echo
echo "--- Markup contracts changed (review the matching partial) ----"
changed=$(git -C "$UPSTREAM" diff --name-only "$FROM".."$TO" -- \
  'packages/**/*.twig' 'packages/**/content/*.json' 2>/dev/null || true)

if [ -z "$changed" ]; then
  echo "  none — no partial can have drifted out of contract."
else
  echo "$changed" | while read -r f; do
    [ -n "$f" ] || continue
    base=$(basename "$f" .twig); base=${base%.json}
    name=${base#usa-}; name=${name%%~*}; name=${name%%--*}
    owner=$(find layouts/_partials -name "$name.html" 2>/dev/null | head -1)
    printf '  %-62s -> %s\n' "$f" "${owner:-NO PARTIAL (component not implemented yet)}"
  done
fi

echo
echo "--- Component inventory (presets reference these paths) -------"
git -C "$UPSTREAM" diff "$FROM".."$TO" -- packages/uswds/_index.scss \
  | grep -E '^[+-]@forward' || echo "  no components added or removed."

echo
echo "--- Settings added or removed (new knobs worth exposing) ------"
for f in color components general spacing typography utilities; do
  d=$(git -C "$UPSTREAM" diff "$FROM".."$TO" \
        -- "packages/uswds-core/src/styles/settings/_settings-$f.scss" \
      | grep -E '^[+-]\$[a-z-]+.*!default' || true)
  [ -n "$d" ] && { echo "  [$f]"; echo "$d" | sed 's/^/    /'; }
done

echo
echo "--- JS behaviours added or removed ---------------------------"
git -C "$UPSTREAM" diff "$FROM".."$TO" -- packages/uswds-core/src/js/index.js \
  | grep -E '^[+-]const ' || echo "  no behaviour changes."
echo
echo "Reminder: after upgrading, re-run tools/check-build.sh — a @forward path"
echo "that upstream renamed fails the build loudly, which is what we want."
