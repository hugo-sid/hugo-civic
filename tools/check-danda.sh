#!/usr/bin/env bash
#
# Verifies that every Odia danda is preceded by a NO-BREAK SPACE.
#
# The rule: in Odia text, a danda (।, U+0964) must be preceded by U+00A0,
# never by an ordinary space and never by nothing at all.
#
#   ...ଆବରି ଥିଲା ।      correct: U+00A0 + U+0964
#   ...ଆବରି ଥିଲା।       wrong:   reads as a matra, not a full stop
#   ...ଆବରି ଥିଲା ।      wrong:   danda can wrap onto the next line alone
#
# Two separate reasons, and a check is needed because BOTH failures are
# invisible:
#
#   1. Odia's aa-kar matra (ା, U+0B3E) is very nearly the danda's twin. Set
#      tight against the preceding consonant, a danda reads as a matra hanging
#      off that last letter rather than as a sentence ending. A native reader
#      sees a misspelled word; nobody else sees anything wrong at all.
#
#   2. U+00A0 and U+0020 render IDENTICALLY in every editor, terminal, diff and
#      code review. Retyping a sentence silently downgrades the one to the
#      other, the site still builds, every other check still passes, and the
#      regression only surfaces as an occasional danda orphaned at the start of
#      a line on some viewport width. There is no way to notice this by
#      looking, which is the entire argument for checking it mechanically.
#
# This matters most for the native-speaker review ODIA.md §5 asks for, which is
# by definition someone rewriting these sentences — the exact operation that
# destroys the convention. See ODIA.md §7 and i18n/or.toml's header.
#
# Dandas are classified BY SCRIPT, not by filename. Each one is attributed to
# the nearest preceding Indic letter on its line: Oriya (U+0B00-U+0B7F) means
# check it, Devanagari (U+0900-U+097F) means skip it. Hindi sets its danda
# tight by convention and must not be "fixed" here.
#
# Filename would not have worked. exampleSite/hugo.toml holds Hindi and Odia
# `description` strings eleven lines apart, and the Odia one was missed by
# exactly the filename-shaped assumption this avoids — it was caught by reading
# rendered HTML, which is not a thing a check should have to do.
#
# Scope is what ships: i18n/, exampleSite/content/, layouts/ and
# exampleSite/hugo.toml. The repo-root design docs are deliberately NOT scanned
# — ODIA.md §7 quotes the broken form on purpose to explain it, and a check
# that failed on its own documentation would be its own bug.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! python3 - <<'PY'
import glob, sys

DANDA = "।"
NBSP = " "


def script_of(ch):
    """"oriya", "devanagari", or None for anything that is neither."""
    cp = ord(ch)
    if 0x0B00 <= cp <= 0x0B7F:
        return "oriya"
    if 0x0900 <= cp <= 0x097F:
        return "devanagari"
    return None


paths = sorted(
    set(
        glob.glob("i18n/*.toml")
        + glob.glob("exampleSite/content/**/*.md", recursive=True)
        + glob.glob("layouts/**/*.html", recursive=True)
        + ["exampleSite/hugo.toml"]
    )
)

checked = 0
bad = []

for path in paths:
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        continue
    for lineno, line in enumerate(text.split("\n"), 1):
        for i, ch in enumerate(line):
            if ch != DANDA:
                continue
            # Attribute this danda to the nearest Indic letter behind it on
            # this line. Scanning back over spaces, digits, ASCII words and
            # markup is deliberate: "...ପର୍ଯ୍ୟନ୍ତ 31 ଅକ୍ଟୋବର ।" and
            # "...`h4` ହୁଏ ।" are both Odia despite what sits adjacent.
            script = next(
                (s for s in map(script_of, reversed(line[:i])) if s), None
            )
            if script != "oriya":
                continue
            checked += 1
            prev = line[i - 1] if i else ""
            if prev != NBSP:
                what = (
                    "nothing (danda set tight — reads as an aa-kar matra)"
                    if prev != " "
                    else "an ordinary space U+0020 (danda can be orphaned by a line wrap)"
                )
                bad.append((path, lineno, what, line.strip()))

if bad:
    print(f"FAIL: {len(bad)} Odia danda(s) not preceded by a no-break space:")
    for path, lineno, what, line in bad:
        print(f"  {path}:{lineno} — preceded by {what}")
        print(f"    {line[:88]}")
    print()
    print("      Every Odia danda needs U+00A0 before it, not U+0020 and not")
    print("      nothing. The two look identical in your editor, so copy an")
    print("      existing pair rather than retyping the danda. See ODIA.md §7.")
    sys.exit(1)

print(f"checked {checked} Odia danda(s) across {len(paths)} file(s)")
print("PASS: every Odia danda is preceded by a no-break space.")
PY
then
  exit 1
fi
