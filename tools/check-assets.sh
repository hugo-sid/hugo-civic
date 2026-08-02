#!/usr/bin/env bash
#
# Verifies that every asset the rendered HTML references was actually published.
#
# Fonts and icons are discovered automatically from the compiled CSS
# (uswds/stylesheet.html), but anything a PARTIAL hardcodes an <img src> for is
# invisible to that scan and has to be listed by hand in uswds/assets.html.
#
# This check exists because that failure is silent and misleading: the search
# button's icon went missing and the browser fell back to its alt text, so the
# button rendered as a truncated "Sea" and looked like a CSS width bug rather
# than a 404.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

cd exampleSite
rm -rf public resources
hugo --quiet -e production

missing=()
checked=0
while read -r url; do
  [ -n "$url" ] || continue
  checked=$((checked + 1))
  [ -f "public${url}" ] || missing+=("$url")
done < <(
  grep -rhoE '(src|href)="/(img|fonts)/[^"]+"' public --include='*.html' \
  | sed -E 's/^(src|href)="//; s/"$//' \
  | sort -u
)

echo "checked $checked referenced asset path(s)"
if [ ${#missing[@]} -gt 0 ]; then
  echo "FAIL: referenced but never published:"
  printf '  %s\n' "${missing[@]}"
  echo
  echo "If the reference comes from a partial's <img src>, add the filename to"
  echo "\$fromMarkup / \$fromMarkupBg in layouts/_partials/uswds/assets.html."
  exit 1
fi
echo "PASS: every referenced asset was published."
