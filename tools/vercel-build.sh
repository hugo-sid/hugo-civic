#!/usr/bin/env bash
#
# Vercel build. Referenced by vercel.json's buildCommand.
#
# This deliberately does NOT follow the tool-downloading recipe in Hugo's
# "Host on Vercel" docs. That script curls pinned Hugo, Dart Sass and Node
# tarballs into $HOME/.local on every build, because it assumes Hugo is not a
# project dependency. Here it is: hugo-extended and sass-embedded are pinned npm
# devDependencies, which is what makes `npm run check`, local dev and CI use the
# same binaries. Downloading Hugo again would give the version two sources of
# truth — exactly what DESIGN.md's upgrade story exists to avoid.
#
# It is also faster on Vercel. node_modules/** is always restored from the build
# cache; $HOME/.local is not, so the tarball approach re-downloads every time.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Recreate the theme link.
#
# exampleSite/themes/hugo-civic is a symlink pointing back at the repository root, and
# exampleSite/themes/ is gitignored — so a fresh CI clone does not have it and
# Hugo cannot resolve `theme = "hugo-civic"`. The failure mode is a site that builds
# "successfully" with zero pages and only a `found no layout file` warning.
mkdir -p exampleSite/themes
ln -sfn ../.. exampleSite/themes/hugo-civic

# 2. Put Hugo's cache somewhere the platform might keep.
#
# Hugo's default cacheDir is under /tmp and never survives a build; .vercel/cache
# is restored before the install command runs. This covers Hugo Modules and
# processed images.
#
# Do not expect much from it here. Compiled Sass is a RESOURCE, cached under
# resourceDir/_gen rather than cacheDir, so it does not travel this way — and
# measured on this site, a build with no _gen at all costs 3.8s against 3.4s with
# one. The real saving on Vercel is node_modules/**, which holds the ~50 MB
# hugo-extended binary and is restored automatically on every build.
#
# Vercel also documents its cached set as framework-preset dependent plus
# node_modules/**, and says it is not configurable. This project sets
# framework: null, so treat the Hugo cache as a bonus, not a guarantee.
export HUGO_CACHEDIR="${PWD}/.vercel/cache/hugo"

# 3. Point baseURL at the deployment being built.
#
# Hugo bakes baseURL into canonical links, og:url, the RSS feed and the sitemap
# at build time. Left alone, every preview would advertise the production URL —
# search engines and social cards would follow a preview link to production, and
# the canonical tag on a preview would be a lie.
#
# VERCEL_BRANCH_URL is stable per branch; VERCEL_URL changes on every deployment,
# so it is only the fallback. Both require "Enable access to System Environment
# Variables" in the project's Environment Variables settings.
BASE_URL=""
case "${VERCEL_ENV:-}" in
  preview|development)
    # VERCEL_BRANCH_URL is stable for the life of the branch. VERCEL_URL changes
    # with every deployment and is unavailable under Standard Deployment
    # Protection, so it is only the fallback.
    host="${VERCEL_BRANCH_URL:-${VERCEL_URL:-}}"
    if [ -z "$host" ]; then
      echo "ERROR: VERCEL_ENV=${VERCEL_ENV} but neither VERCEL_BRANCH_URL nor" >&2
      echo "       VERCEL_URL is set. Refusing to build a preview that would" >&2
      echo "       advertise production URLs in its canonical tags, RSS and" >&2
      echo "       sitemap." >&2
      exit 1
    fi
    BASE_URL="https://${host}/"
    ;;
  production)
    : # the baseURL in hugo.toml is the right one
    ;;
  *)
    # Locally this is just a normal build. On Vercel it means "Enable access to
    # System Environment Variables" is off, and the warning is the only thing
    # standing between you and previews that claim to be production.
    echo "NOTE: VERCEL_ENV is not set — building with the baseURL from hugo.toml."
    echo "      If this is a Vercel build, enable system environment variables in"
    echo "      Settings -> Environment Variables, or every preview will publish"
    echo "      production canonical tags, RSS links and sitemap entries."
    ;;
esac

# Explicit override, for the one case the logic above cannot infer: a custom
# domain assigned to a non-production branch. Hugo reads HUGO_BASEURL natively,
# so set it as a branch-scoped environment variable in Vercel and this script
# stays out of the way. (Vercel also skips its automatic X-Robots-Tag: noindex
# on custom preview domains, so that branch is publicly indexable — the baseURL
# needs to be right there in a way it does not on a *.vercel.app preview.)
if [ -n "${HUGO_BASEURL:-}" ]; then
  echo "HUGO_BASEURL is set to ${HUGO_BASEURL} — deferring to it"
  BASE_URL=""
fi

# TZ is deliberately left alone. Hugo's Vercel docs set one, but this site's
# front matter carries date-only values, which parse as midnight UTC — moving the
# build to a zone west of UTC would render every post a day early.
#
# git fetch --unshallow is likewise skipped. It is only needed for .GitInfo and
# .Lastmod, which nothing here uses yet; add it if enableGitInfo is switched on.

export PATH="$PWD/node_modules/.bin:$PATH"
hugo version

cd exampleSite
if [ -n "$BASE_URL" ]; then
  echo "building ${VERCEL_ENV:-preview} at $BASE_URL"
  hugo build --gc --minify --baseURL "$BASE_URL"
else
  echo "building at the baseURL already in the configuration"
  hugo build --gc --minify
fi
