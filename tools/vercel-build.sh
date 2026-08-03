#!/usr/bin/env bash

#------------------------------------------------------------------------------
# @file
# Builds a Hugo project hosted on Vercel.
#
# This follows the recipe in Hugo's "Host on Vercel" documentation: pinned Hugo,
# Dart Sass and Node tarballs are downloaded into $HOME/.local on every build.
# The npm devDependencies (hugo-extended, sass-embedded) exist for local dev and
# `npm run check`; on Vercel the tarballs above are what run, so the version
# pins here and in package.json must be kept in step.
#
# Three things are specific to this repository:
#
#   1. The Hugo site is exampleSite/, not the repository root.
#   2. exampleSite/themes/hugo-civic and exampleSite/node_modules are symlinks
#      back into the repository, and both are gitignored — a fresh CI clone does
#      not have them and they have to be recreated before Hugo runs.
#   3. baseURL is rewritten for preview deployments so previews never advertise
#      production URLs.
#------------------------------------------------------------------------------

# Exit on error, undefined variables, or pipe failures
set -euo pipefail

# Define tool versions
#
# DART_SASS_VERSION tracks the sass-embedded pin in package.json and
# HUGO_VERSION the hugo-extended pin: those are what local dev and `npm run
# check` compile with, and a Vercel build that used a different compiler would
# not be testable locally. Bump them together.
DART_SASS_VERSION=1.100.0
GO_VERSION=1.26.4
HUGO_VERSION=0.164.0
NODE_VERSION=24.18.0

# Build from the repository root, wherever this script was invoked from
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Define the site directory and the name Hugo resolves the theme by
SITE_DIR=exampleSite
THEME_NAME=hugo-civic

# Set the build time zone
#
# Front matter here carries date-only values, which parse as midnight in this
# zone. Keep the zone at or east of UTC: west of it, every post renders a day
# early.
TZ=Asia/Kolkata

# Set the build cache directory
#
# Hugo's default cacheDir is under /tmp and never survives a build; .vercel/cache
# is restored before the build runs. Do not expect much from it — compiled Sass
# is a resource, cached under resourceDir/_gen rather than cacheDir, so it does
# not travel this way.
HUGO_CACHEDIR="${PWD}/.vercel/cache/hugo"

# Perform cleanup
cleanup() {
  if [[ -n "${build_temp_dir:-}" && -d "${build_temp_dir}" ]]; then
    rm -rf "${build_temp_dir}"
  fi
}

# Register the cleanup trap
trap cleanup EXIT SIGINT SIGTERM

# Recreate the gitignored symlinks that point back into the repository
#
# themes/<name> is how Hugo resolves `theme = "hugo-civic"`; without it the site
# builds "successfully" with zero pages and only a `found no layout file`
# warning. node_modules is what makes the USWDS mount in exampleSite/hugo.toml
# and the Sass includePaths resolve from the site root.
link_repo_into_site() {
  echo "Linking the repository into ${SITE_DIR}..."
  mkdir -p "${SITE_DIR}/themes"
  ln -sfn ../.. "${SITE_DIR}/themes/${THEME_NAME}"
  ln -sfn ../node_modules "${SITE_DIR}/node_modules"
}

# Resolve the baseURL for the deployment being built
#
# Hugo bakes baseURL into canonical links, og:url, the RSS feed and the sitemap
# at build time. Left alone, every preview would advertise the production URL —
# search engines and social cards would follow a preview link to production, and
# the canonical tag on a preview would be a lie.
#
# Echoes the URL to use, or nothing to mean "the baseURL in hugo.toml is right".
# Both VERCEL_* variables require "Enable access to System Environment
# Variables" in the project's Environment Variables settings.
resolve_base_url() {
  # An explicit override covers the one case the logic below cannot infer: a
  # custom domain assigned to a non-production branch. Hugo reads HUGO_BASEURL
  # natively, so set it as a branch-scoped environment variable in Vercel and
  # this function stays out of the way. (Vercel also skips its automatic
  # X-Robots-Tag: noindex on custom preview domains, so that branch is publicly
  # indexable — the baseURL needs to be right there in a way it does not on a
  # *.vercel.app preview.)
  if [[ -n "${HUGO_BASEURL:-}" ]]; then
    echo "HUGO_BASEURL is set to ${HUGO_BASEURL} — deferring to it" >&2
    return 0
  fi

  case "${VERCEL_ENV:-}" in
    preview | development)
      # VERCEL_BRANCH_URL is stable for the life of the branch. VERCEL_URL
      # changes with every deployment and is unavailable under Standard
      # Deployment Protection, so it is only the fallback.
      local host="${VERCEL_BRANCH_URL:-${VERCEL_URL:-}}"
      if [[ -z "${host}" ]]; then
        echo "ERROR: VERCEL_ENV=${VERCEL_ENV} but neither VERCEL_BRANCH_URL nor" >&2
        echo "       VERCEL_URL is set. Refusing to build a preview that would" >&2
        echo "       advertise production URLs in its canonical tags, RSS and" >&2
        echo "       sitemap." >&2
        return 1
      fi
      echo "https://${host}/"
      ;;
    production)
      : # the baseURL in hugo.toml is the right one
      ;;
    *)
      # Locally this is just a normal build. On Vercel it means "Enable access
      # to System Environment Variables" is off, and this warning is the only
      # thing standing between you and previews that claim to be production.
      echo "NOTE: VERCEL_ENV is not set — building with the baseURL from hugo.toml." >&2
      echo "      If this is a Vercel build, enable system environment variables in" >&2
      echo "      Settings -> Environment Variables, or every preview will publish" >&2
      echo "      production canonical tags, RSS links and sitemap entries." >&2
      ;;
  esac
}

main() {
  # Export the build time zone
  export TZ

  # Export the build cache directory
  export HUGO_CACHEDIR

  # Create a temporary directory for downloads
  build_temp_dir=$(mktemp -d)

  # Create a local tools directory
  mkdir -p "${HOME}/.local"

  # Install Dart Sass
  #
  # USWDS 3 is written in Sass modules, which the LibSass in Hugo Extended
  # cannot compile. This binary is what css.Sass with transpiler "dartsass"
  # shells out to, found by name on PATH.
  echo "Installing Dart Sass ${DART_SASS_VERSION}..."
  curl -sfL --output-dir "${build_temp_dir}" -O "https://github.com/sass/dart-sass/releases/download/${DART_SASS_VERSION}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
  tar -C "${HOME}/.local" -xf "${build_temp_dir}/dart-sass-${DART_SASS_VERSION}-linux-x64.tar.gz"
  export PATH="${HOME}/.local/dart-sass:${PATH}"

  # Install Go
  if [[ -f "go.mod" ]]; then
    echo "Installing Go ${GO_VERSION}..."
    curl -sfL --output-dir "${build_temp_dir}" -O "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    tar -C "${HOME}/.local" -xf "${build_temp_dir}/go${GO_VERSION}.linux-amd64.tar.gz"
    export PATH="${HOME}/.local/go/bin:${PATH}"
  fi

  # Install Hugo
  #
  # The extended build, not the standard one: theme.toml declares
  # `extended = true` and Hugo refuses to build the theme without it.
  echo "Installing Hugo ${HUGO_VERSION} (extended)..."
  curl -sfL --output-dir "${build_temp_dir}" -O "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
  mkdir -p "${HOME}/.local/hugo"
  tar -C "${HOME}/.local/hugo" -xf "${build_temp_dir}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
  export PATH="${HOME}/.local/hugo:${PATH}"

  # Install Node.js
  if [[ -f "package-lock.json" ]]; then
    echo "Installing Node.js ${NODE_VERSION}..."
    curl -sfL --output-dir "${build_temp_dir}" -O "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz"
    tar -C "${HOME}/.local" -xf "${build_temp_dir}/node-v${NODE_VERSION}-linux-x64.tar.gz"
    export PATH="${HOME}/.local/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"
  fi

  # Log tool versions
  echo "Logging tool versions..."
  command -v sass &> /dev/null && echo "Dart Sass: $(sass --version)" || echo "Dart Sass: not installed"
  command -v go &> /dev/null && echo "Go: $(go version)" || echo "Go: not installed"
  command -v hugo &> /dev/null && echo "Hugo: $(hugo version)" || echo "Hugo: not installed"
  command -v node &> /dev/null && echo "Node.js: $(node --version)" || echo "Node.js: not installed"

  # Configure Git
  echo "Configuring Git..."
  git config --global core.quotepath false

  # Fetch full Git history
  if [[ $(git rev-parse --is-shallow-repository) == true ]]; then
    echo "Fetching full Git history..."
    git fetch --unshallow
  fi

  # Initialize Git submodules
  if [[ -f .gitmodules ]]; then
    echo "Initializing Git submodules..."
    git submodule update --init --recursive
  fi

  # Install Node.js dependencies
  #
  # Only the production set: @uswds/uswds is the one dependency the site
  # compiles against. hugo-extended and sass-embedded are devDependencies that
  # exist so local dev and CI use pinned binaries; here the tarballs above are
  # already on PATH, and installing them again would download ~60 MB for
  # nothing.
  if [[ -f package-lock.json ]]; then
    echo "Installing Node.js dependencies..."
    npm ci --omit=dev
  else
    echo "ERROR: package-lock.json is missing. @uswds/uswds would not be" >&2
    echo "       installed and the Sass build would fail on the first @use." >&2
    exit 1
  fi

  # Recreate the symlinks a fresh clone does not have
  link_repo_into_site

  # Resolve the baseURL for this deployment
  local base_url
  base_url=$(resolve_base_url)

  # Build the project
  echo "Building the project..."
  cd "${SITE_DIR}"
  if [[ -n "${base_url}" ]]; then
    echo "Building ${VERCEL_ENV:-preview} at ${base_url}"
    hugo build --gc --minify --baseURL "${base_url}"
  else
    echo "Building at the baseURL already in the configuration"
    hugo build --gc --minify
  fi
}

main "$@"
