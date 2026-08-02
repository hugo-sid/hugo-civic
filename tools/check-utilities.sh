#!/usr/bin/env bash
#
# Verifies that every USWDS utility class the rendered HTML uses actually
# exists in the compiled CSS.
#
# This matters because $output-these-utilities fails SILENTLY. There is no
# "all" or "none" keyword and no error for an unrecognised name — a typo, or a
# family upstream renamed, simply emits nothing and the page loses its styling
# with no build warning. The names are also easy to get wrong: they are the map
# keys in packages/uswds-utilities/src/styles/rules/*.scss, and upstream is
# inconsistent (`padding` includes its -top/-x modifiers, `margin` splits them
# into `margin-vertical` and `margin-horizontal`).
#
# Running this is also what makes TRIMMING the utility list safe: shrink the
# set in sass-vars.html, run this, and it tells you exactly what you broke.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

cd exampleSite
rm -rf public resources
hugo --quiet -e production

CSS=$(find public/css -name '*.css' | head -1)
[ -n "$CSS" ] || { echo "no CSS built"; exit 1; }

# Collect class tokens from the rendered HTML, drop component and grid classes
# (those come from component styles, not the utility builder), and strip any
# responsive prefix — `desktop:display-block` is emitted by the `display`
# family as an escaped `.desktop\:display-block` selector.
#
# The second filter drops classes Goldmark and Chroma put in the markup
# themselves — `highlight`, `language-*`, and the footnote set. They are
# markdown renderer output, not utilities, and nothing is expected to emit a
# rule for them, so leaving them in reports a missing utility for every page
# that contains a code block or a footnote.
mapfile -t used < <(
  grep -rhoE 'class="[^"]*"' public --include='*.html' \
  | sed 's/class="//; s/"$//' \
  | tr ' ' '\n' \
  | grep -vE '^(usa-|grid-|is-|type-|no-js|icon-lock|$)' \
  | grep -vE '^(highlight|chroma|language-|footnote)' \
  | sort -u
)

missing=()
for cls in "${used[@]}"; do
  bare=${cls#*:}                       # strip responsive prefix if present
  esc=$(printf '%s' "$cls" | sed 's/:/\\\\:/')
  if ! grep -qF ".$esc" "$CSS" && ! grep -qF ".$bare" "$CSS"; then
    missing+=("$cls")
  fi
done

echo "checked ${#used[@]} non-component class(es) against $(basename "$CSS")"
if [ ${#missing[@]} -gt 0 ]; then
  echo "FAIL: these classes are used but never emitted:"
  printf '  %s\n' "${missing[@]}"
  echo
  echo "Add the owning family to \$utilityDefaults in"
  echo "layouts/_partials/uswds/sass-vars.html. The family name is the MAP KEY in"
  echo "node_modules/@uswds/uswds/packages/uswds-utilities/src/styles/rules/*.scss."
  exit 1
fi
echo "PASS: every utility class used is present in the CSS."
