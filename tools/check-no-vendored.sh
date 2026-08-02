#!/usr/bin/env bash
# Enforces the core invariant from DESIGN.md §4.1: the theme contains ZERO
# copied USWDS source. Every deviation from stock USWDS must be configuration
# (_settings.scss), selection (a preset), or additive CSS (_custom.scss).
#
# This is the most important check in the repo. It is what turns a USWDS
# upgrade from a merge into a diff review — if nothing is forked, nothing can
# conflict.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

# A @forward/@use path into the installed package is fine; actual USWDS style
# code copied into our tree is not. USWDS source is recognisable by its
# settings variables and mixin definitions.
if grep -rEln '^\s*\$theme-[a-z-]+:.*!default' assets/ 2>/dev/null; then
  echo "FAIL: USWDS settings source copied into assets/ (files above)."
  echo "      Configure via @forward \"uswds-core\" with (...) instead."
  fail=1
fi

if grep -rEln '^\s*@mixin (u-|at-media|set-text-from-bg)' assets/ 2>/dev/null; then
  echo "FAIL: USWDS mixin definitions copied into assets/ (files above)."
  fail=1
fi

# The packages themselves must never be part of the theme. Only the theme's own
# source is scanned: node_modules is where USWDS is SUPPOSED to live, and
# uswds/ + tools/upstream/ are gitignored reference checkouts used for diffing.
THEME_DIRS=(assets layouts i18n data archetypes)
for d in "${THEME_DIRS[@]}"; do
  [ -d "$d" ] || continue
  if find "$d" -type d -name 'uswds-core' -print 2>/dev/null | grep -q .; then
    echo "FAIL: a uswds-core directory is vendored under $d/. USWDS comes from npm."
    fail=1
  fi
done

# If this is a git repo, the reference clone must not be tracked.
if git rev-parse --git-dir >/dev/null 2>&1; then
  for d in uswds tools/upstream; do
    if [ -d "$d" ] && git ls-files --error-unmatch "$d" >/dev/null 2>&1; then
      echo "FAIL: $d/ is tracked by git. It belongs in .gitignore — the theme"
      echo "      depends on @uswds/uswds from npm (DESIGN.md §4.2)."
      fail=1
    fi
  done
fi

# Presets must only contain @forward lines and comments. Any real CSS here is
# a fork in disguise.
for f in assets/uswds/presets/_*.scss; do
  [ -e "$f" ] || continue
  if grep -vE '^\s*(//.*)?$|^\s*@forward' "$f" | grep -q .; then
    echo "FAIL: $f contains more than @forward lines and comments."
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: no vendored USWDS source."
fi
exit "$fail"
