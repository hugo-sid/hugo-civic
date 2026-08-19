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

# --- 0. Languages, and where each one's search page actually is -----------
#
# params.uswds.search.page is a STRING, and chrome/search.html resolves the
# masthead form's action as ($s.page | relLangURL). That is correct only while
# every language uses the same slug. Localise the Spanish page to /es/buscar/
# and the masthead posts at /es/search/ — silently, on every Spanish page, in
# the one control every page carries.
#
# So the page is resolved here the way the template resolves it, per language,
# and everything below that used to match the literal "/search/" uses the
# result. `hugo config --lang` reports the MERGED configuration, which is why
# one overridden key in [languages.es.params] is visible here without this
# script knowing anything about how language params inherit.
#
# The prefix is derived, not read: it is "/" for the default language unless
# defaultContentLanguageInSubdir moves it, and "/<code>/" otherwise. That
# derivation is checked immediately below against a built page rather than
# trusted, so a site that moves a language somewhere else fails loudly here
# instead of silently skipping every assertion that follows.
mapfile -t languages < <(
  python3 - <<'PY'
import json, subprocess


def config(*args):
    out = subprocess.run(
        ["hugo", "config", "--format", "json", "-e", "production", *args],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out)


root = config()
codes = list(root.get("languages") or {})
default = root.get("defaultcontentlanguage") or "en"
in_subdir = bool(root.get("defaultcontentlanguageinsubdir"))

for code in codes or [default]:
    cfg = config("--lang", code) if codes else root
    search = ((cfg.get("params") or {}).get("uswds") or {}).get("search") or {}
    page = search.get("page") or "/search/"
    prefix = "/" if (code == default and not in_subdir) else f"/{code}/"
    print("\t".join([code, prefix, prefix + page.lstrip("/")]))
PY
)

search_urls=()
for row in "${languages[@]}"; do
  IFS=$'\t' read -r code prefix search_url <<<"$row"

  if [ ! -f "public${prefix}index.html" ]; then
    echo "FAIL: language '$code' has no home page at ${prefix}."
    echo "      Every assertion below resolves paths from that prefix, so a"
    echo "      site that publishes a language elsewhere must fix this first."
    fail=1
    continue
  fi

  # 0a. The configured page has to exist in this language. This is the trap
  #     itself: a localised slug with no matching per-language param.
  if [ -f "public${search_url}index.html" ]; then
    printf 'search page %-16s %s\n' "$code" "$search_url"
  else
    echo "FAIL: language '$code' configures its search page as ${search_url},"
    echo "      which was not built. Set it per language:"
    echo "        [languages.${code}.params.uswds.search]"
    echo "          page = \"/<this language's slug>/\""
    fail=1
  fi
  search_urls+=("$search_url")

  # 0b. And whatever the masthead actually posts to has to exist too. Not the
  #     same assertion: params.uswds.header.searchAction overrides the page
  #     entirely, so a site can satisfy 0a and still ship a form aimed at a
  #     404. Off-site actions (Search.gov and the like) are the point of that
  #     override, so only site-relative ones are resolved.
  while read -r action; do
    case "$action" in
      /*) [ -f "public${action}index.html" ] || [ -f "public${action}" ] || {
            echo "FAIL: the ${code} masthead posts to ${action}, which was not built."
            fail=1
          } ;;
    esac
  done < <(
    grep -oE 'action="[^"]*"|action=[^ >]+' "public${prefix}index.html" \
    | sed -E 's/^action=//; s/^"//; s/"$//' \
    | sort -u
  )
done

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
#
# Matched against the URLs resolved in section 0, not against the literal
# "*/search/" this once used. That pattern was not merely incomplete, it was
# wrong in both directions: /es/buscar/ walked straight past it, while a site
# with a legitimate content page at /search/ would have been failed for it.
for url in "${indexed[@]}"; do
  for search_url in "${search_urls[@]}"; do
    if [ "$url" = "$search_url" ]; then
      echo "FAIL: the search page indexed itself: $url"
      echo "      It is a page of results, so every query would match it."
      fail=1
    fi
  done
done

# The opposite failure — the attribute falling off single.html entirely — shows
# up as an index far smaller than the site.
#
# Asserted PER LANGUAGE. A single site-wide floor was calibrated when there was
# one language and quietly stops meaning anything once there are two: the
# majority language's pages alone clear it, so a language whose content stops
# being indexed altogether is absorbed rather than caught. Pages are attributed
# to the language with the longest matching URL prefix, so "/" collects only
# what no other language claimed.
if ! python3 - "${expected[@]}" -- "${indexed[@]}" -- "${languages[@]}" <<'PY'
import sys

argv = sys.argv[1:]
expected = argv[:argv.index("--")]
rest = argv[argv.index("--") + 1:]
indexed = rest[:rest.index("--")]
languages = [row.split("\t") for row in rest[rest.index("--") + 1:]]

prefixes = [(code, prefix) for code, prefix, _ in languages]


def language_of(url):
    best = None
    for code, prefix in prefixes:
        if url.startswith(prefix) and (best is None or len(prefix) > len(best[1])):
            best = (code, prefix)
    return best[0] if best else None


bad = False
for code, _ in prefixes:
    want = [u for u in expected if language_of(u) == code]
    got = [u for u in indexed if language_of(u) == code]
    if not want:
        continue

    share = len(got) * 100 // len(want)
    print(f"indexed {code:<16} {len(got):3} of {len(want):3} regular page(s)  ({share}%)")

    # One opt-out per language is normal — the results page opts itself out.
    # Most of a language missing is data-pagefind-body having come off, or a
    # language that stopped being built into the index at all.
    if not got or share < 60:
        bad = True
        print(f"FAIL: {code} has {len(got)} of its {len(want)} regular pages indexed.")
        print("      Check that data-pagefind-body is still on <main> in")
        print("      layouts/single.html, and that this language still reaches it.")

sys.exit(1 if bad else 0)
PY
then
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
#
# Checked on every language's results page, not just the default one's. One
# script serves them all, so an id that only survives in English is a Spanish
# results page that loads and then sits there.
for search_url in "${search_urls[@]}"; do
  [ -f "public${search_url}index.html" ] || continue
  for id in js-search search-field-page search-status search-results search-unavailable; do
    if ! grep -q "id=\"$id\"" "public${search_url}index.html"; then
      echo "FAIL: #$id is missing from the rendered search page ${search_url}."
      echo "      assets/uswds/js/search.js looks it up by that id."
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the index holds the site's regular pages, and nothing else."
fi
exit "$fail"
