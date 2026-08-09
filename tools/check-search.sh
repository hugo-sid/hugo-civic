#!/usr/bin/env bash
#
# Verifies the Pagefind index: that it contains exactly the site's regular
# pages, and that the metadata the results page renders actually made it in.
#
# Both failures this catches are SILENT, and both are silent in the same
# unhelpful way — the site builds, the search page loads, queries return
# something, and what comes back is wrong.
#
#   1. Scope. `data-pagefind-body` is all-or-nothing: the moment ONE page in a
#      build carries it, every page without it is dropped. Move that attribute
#      to a shared partial, or add it to list.html "for completeness", and the
#      index quietly fills with section indexes and term pages — each a list of
#      titles that are all themselves results, so every page in a section
#      starts appearing twice in every result set.
#
#   2. Metadata. Pagefind's own documentation says several `key:value` pairs
#      can share one attribute if they are comma-separated. In 1.5.2 they
#      cannot: `data-pagefind-meta="date:2026-06-30, section:News"` indexes one
#      key, `date`, whose value is that entire string. Nothing warns. The build
#      passes. The results page then renders "2026-06-30, section:News" as a
#      date, or a tag literally named "Accessibility, tags:Performance".
#      layouts/single.html emits one span per pair because of this, and the
#      only way to know it is still true after an upgrade is to read the
#      metadata back out of the generated fragments — which is what this does.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

command -v pagefind >/dev/null || {
  echo "FAIL: pagefind is not installed. Run: npm install"
  exit 1
}

cd exampleSite
rm -rf public resources
hugo --quiet -e production
pagefind --site public >/dev/null

fail=0

# --- 1. Scope -------------------------------------------------------------
#
# The expected set is Hugo's own list of REGULAR pages (`hugo list all` emits
# kind=page only), minus any that opted out with `search = false`. Deriving it
# from Hugo rather than from the markup is the point: counting the pages that
# carry the attribute and then checking that the same number came out would
# pass just as happily with the attribute on every list page in the site.
#
# The permalink, kind and section columns are the last three, so awk reads them
# from the end — a title containing a comma shifts the leading fields but never
# these.
mapfile -t expected < <(
  hugo list all \
  | awk -F, 'NR > 1 && $(NF-1) == "page" { print $(NF-2) }' \
  | sed -E 's#^https?://[^/]+##' \
  | sort
)

mapfile -t indexed < <(
  python3 - <<'PY'
import glob, gzip, json, re
for path in sorted(glob.glob("public/pagefind/fragment/*.pf_fragment")):
    # Fragments are gzipped JSON behind a short magic string.
    raw = gzip.decompress(open(path, "rb").read()).decode("utf-8")
    print(json.loads(raw[raw.index("{"):])["url"])
PY
)

printf 'indexed %s page(s); hugo reports %s regular page(s)\n' \
  "${#indexed[@]}" "${#expected[@]}"

# Every indexed URL must be a regular page. This is the assertion that catches
# a list, taxonomy, term, 404 or search page having crept in.
for url in "${indexed[@]}"; do
  found=0
  for want in "${expected[@]}"; do
    [ "$url" = "$want" ] && { found=1; break; }
  done
  if [ "$found" -eq 0 ]; then
    echo "FAIL: indexed a page that is not a regular page: $url"
    fail=1
  fi
done

# And the search page must never index itself: it is a page of results, so
# indexing it makes every query match it.
for url in "${indexed[@]}"; do
  case "$url" in
    */search/) echo "FAIL: the search page indexed itself: $url"; fail=1 ;;
  esac
done

# The opposite failure — the attribute falling off single.html entirely — shows
# up as an index far smaller than the site. One page is a legitimate opt-out;
# half of them is a bug.
if [ "${#indexed[@]}" -lt $(( ${#expected[@]} - 5 )) ]; then
  echo "FAIL: ${#indexed[@]} of ${#expected[@]} regular pages were indexed."
  echo "      Check that data-pagefind-body is still on <main> in layouts/single.html."
  fail=1
fi

# --- 2. Metadata ----------------------------------------------------------
#
# A value that still contains "key:" is the comma-separation failure described
# above: two pairs went in and one came out with the other embedded in it.
if ! python3 - <<'PY'
import glob, gzip, json, sys

bad = []
dated = sections = tagged = 0
for path in sorted(glob.glob("public/pagefind/fragment/*.pf_fragment")):
    raw = gzip.decompress(open(path, "rb").read()).decode("utf-8")
    frag = json.loads(raw[raw.index("{"):])
    meta = frag.get("meta", {})
    filters = frag.get("filters", {})

    values = list(meta.items())
    for key, vals in filters.items():
        values += [(key, v) for v in vals]

    for key, value in values:
        if ":" in str(value):
            bad.append(f"{frag['url']}  {key} = {value!r}")

    if meta.get("date"):
        dated += 1
        if len(meta["date"]) != 10:
            bad.append(f"{frag['url']}  date is not YYYY-MM-DD: {meta['date']!r}")
    if meta.get("section"):
        sections += 1
    tagged += len(filters.get("tags", []))

print(f"metadata: {dated} dated, {sections} with a section, {tagged} tag value(s)")
if not dated or not sections or not tagged:
    print("FAIL: expected the example site to produce all three. One of")
    print("      date, section or tags stopped being indexed.")
    sys.exit(1)
if bad:
    print("FAIL: a metadata value contains a 'key:' pair, which means two pairs")
    print("      shared one attribute and Pagefind did not split them:")
    for line in bad:
        print(f"  {line}")
    sys.exit(1)
PY
then
  fail=1
fi

# --- 3. The client's contract with the template ---------------------------
#
# assets/uswds/js/search.js reaches for these by id. A rename on either side is
# a page that loads, does nothing, and reports nothing.
for id in js-search search-field-page search-status search-results search-unavailable; do
  if ! grep -q "id=\"$id\"" public/search/index.html; then
    echo "FAIL: #$id is missing from the rendered search page."
    echo "      assets/uswds/js/search.js looks it up by that id."
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the index holds the site's regular pages, and nothing else."
fi
exit "$fail"
