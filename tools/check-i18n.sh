#!/usr/bin/env bash
#
# Verifies the translation tables in i18n/.
#
# Both failures this catches are silent by default, and the two assertions
# below cover different halves of the problem — neither one subsumes the other:
#
#   1. A MISSING key renders the DEFAULT LANGUAGE's string. Hugo does not fall
#      through to the template's `| default`; a key in en.toml and not in
#      es.toml puts English on a Spanish page, and the page looks finished.
#      Assertion 2 does warn about this, but only for keys the build actually
#      ASKS FOR: a string used by a partial no exampleSite page happens to
#      render, or by a branch (the three-language dropdown, a header variant)
#      the fixture does not exercise, is invisible to it. Reading the tables
#      against each other is the only check that covers strings by existing
#      rather than by being reached, so that is assertion 1.
#
#   2. An EMPTY value warns, but only if you ask. `other = ""` is treated as a
#      missing translation, not as "this language deliberately says nothing" —
#      there is no way to express the latter in an i18n table. It logs
#      i18n|MISSING_TRANSLATION and falls back to the default language, which
#      is how `identifier_content_prefix = ""` once rendered the federally
#      required identifier as "An Un sitio web oficial de …": an English
#      article bolted onto a Spanish sentence. Assertion 2 turns the warning
#      on and fails on it.
#
# Two things about assertion 2's flags, both learned the hard way:
#
#   --printI18nWarnings is off by default, so tools/check-build.sh's blanket
#   "fail on any WARN" never sees these. And --quiet SUPPRESSES them even when
#   the flag is passed, so this build deliberately runs loud where every other
#   check in this repo runs quiet.
#
# enableMissingTranslationPlaceholders is deliberately NOT used. It rewrites
# missing strings to "[i18n] identifier" in the OUTPUT — a debugging aid that
# ships broken text to production if it is ever left on. A build flag that
# fails CI is the same information without that risk.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/node_modules/.bin:$PATH"

fail=0

# --- 1. Key parity across every table -------------------------------------
#
# Parity is checked over (key, plural form) pairs rather than keys alone. A
# table that has [pages] other but not [pages] one is missing a translation in
# exactly the same silent way as one missing [pages] entirely; it just only
# shows up when a count happens to be 1.
if ! python3 - <<'PY'
import glob, sys, tomllib

tables = {}
for path in sorted(glob.glob("i18n/*.toml")):
    with open(path, "rb") as fh:
        tables[path] = tomllib.load(fh)

if len(tables) < 2:
    print(f"only {len(tables)} translation table(s); nothing to compare")
    sys.exit(0)


def pairs(table):
    """(key, form) for every string the table defines.

    Hugo accepts both `key = "value"` and the [key] / other = "value" table
    form; the flat spelling has no plural forms, so it reports one pair.
    """
    out = set()
    for key, value in table.items():
        if isinstance(value, dict):
            out.update((key, form) for form in value)
        else:
            out.add((key, ""))
    return out


def empties(table):
    """Keys whose value is the empty string exactly.

    Not `not value.strip()`. A single space is the only way to say "this
    language deliberately says nothing here": it is non-empty, so Hugo does
    not fall back, and it collapses to nothing on screen.
    i18n/es.toml's identifier_content_prefix is exactly that, and a check that
    stripped whitespace would demand the "" that caused the bug in the first
    place.
    """
    for key, value in table.items():
        if isinstance(value, dict):
            for form, text in value.items():
                if text == "":
                    yield f"{key}.{form}"
        elif value == "":
            yield key


everything = set().union(*(pairs(t) for t in tables.values()))
bad = False

for path, table in tables.items():
    missing = everything - pairs(table)
    if missing:
        bad = True
        print(f"FAIL: {path} is missing {len(missing)} translation(s):")
        for key, form in sorted(missing):
            print(f"  {key}" + (f" [{form}]" if form else ""))
        print("      A missing key renders the DEFAULT language's string on")
        print("      this language's pages. The build only warns about the")
        print("      ones it happens to render; this covers the rest.")

    blank = sorted(empties(table))
    if blank:
        bad = True
        print(f"FAIL: {path} has {len(blank)} empty value(s):")
        for key in blank:
            print(f"  {key}")
        print("      An empty string is a MISSING translation to Hugo, not a")
        print("      deliberate blank. Write the words out.")

if bad:
    sys.exit(1)

print(f"{len(tables)} table(s), {len(everything)} translation(s) each, none empty")
PY
then
  fail=1
fi

# --- 2. The build's own i18n warnings --------------------------------------
#
# Catches what assertion 1 structurally cannot: a key the templates ask for
# that no table defines at all, and `T ""` — calling the lookup with an empty
# identifier, which returns "" correctly but logs a missing translation for
# every menu entry without an identifier. Hugo's own menu example is written
# that way; chrome/menu-label.html guards on the identifier first because of
# this, and this is the check that would notice if that guard were removed.
#
# Run loud (see the header): --quiet would suppress the very lines being
# grepped for.
warnings=$(cd exampleSite && rm -rf public resources && \
           hugo --printI18nWarnings -e production 2>&1 \
           | grep 'i18n|MISSING_TRANSLATION' || true)

if [ -n "$warnings" ]; then
  echo "FAIL: the build reported missing translations:"
  # WARN  i18n|MISSING_TRANSLATION|es|return_to_top -> es  return_to_top
  echo "$warnings" | sort -u | awk -F'|' '{ printf "  %-6s %s\n", $3, ($4 == "" ? "(no key — T was called with an empty identifier)" : $4) }'
  # Only worth saying when it actually happened; it is a different bug from a
  # key that is merely absent.
  if echo "$warnings" | awk -F'|' '$4 == ""{ found = 1 } END { exit !found }'; then
    echo "      A blank key means a template called T with no identifier at"
    echo "      all — guard the call (see chrome/menu-label.html) rather than"
    echo "      translating nothing."
  fi
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: every table defines every string, and the build asked for nothing more."
fi
exit "$fail"
