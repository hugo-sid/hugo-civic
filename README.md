# 🏛️ Civic

<div align="center">

**A Hugo theme for the U.S. Web Design System, built for upgradeability and web performance.**

[Live Demo](https://civic.sid.one) · [Documentation](https://civic.sid.one/docs/) · [Design Notes](DESIGN.md)

</div>

## 📖 Overview

Civic brings the U.S. Web Design System (USWDS) to Hugo without vendoring a single line of it.

USWDS is one of the most mature design systems available for content-first websites: accessible, research-backed components, consistent interaction patterns, and a strong foundation for publishing information clearly. The usual cost of wrapping it in a theme is a fork — copied SCSS, patched components, and an upgrade path that turns into a hand-merge every release.

Civic avoids that. USWDS is installed from npm and compiled from source; every deviation from stock is either **configuration** (Sass settings passed from `hugo.toml`), **selection** (which components get compiled), or **additive CSS**. Nothing is forked, so nothing can conflict — an upgrade is `npm update` plus a review of a short, mechanical diff. A CI check enforces this rule rather than trusting it.

The second constraint is payload. Compiling only the components a site uses, and loading JS behaviours only on pages that need them, ships materially less than the stock distribution: **39.0 KB gzip CSS** on the default preset against 61.1 KB, and **5.3 KB gzip JS** on every page against 25.9 KB for all 22 behaviours.

> **Note:** Civic is an independent project. It is not maintained by the U.S. General Services Administration or the USWDS team.

## ✨ Features

- **🇺🇸 Real USWDS, not a lookalike.** Compiled from `@uswds/uswds` at build time. Partials reproduce upstream's markup contracts — class names, ARIA attributes, DOM ordering — because USWDS's own CSS and JS depend on them.
- **🔒 Zero vendored source.** `npm run check:no-vendor` fails the build if USWDS settings or mixin definitions are ever copied into `assets/`. This is what makes upgrades a diff instead of a merge.
- **⚙️ Configuration-driven theming.** Colors, font families, type roles, and grid width are set in `hugo.toml` and passed into Sass via Hugo's `vars` module. Retheming requires no SCSS edits.
- **📦 Four component presets.** `minimal` (13 components, 21.9 KB gzip), `standard` (34, 39.0 KB), `full` (all), or `custom` — supply your own manifest and compile exactly what you use.
- **⚡ Two-tier JavaScript.** A small, stable core bundle (banner, header, skipnav) is cached across every page; interactive components register their behaviour per page and are collected into one additional bundle.
- **📏 Enforced size budgets.** CSS, JS, and search-index budgets are measured per preset and language and checked in `npm run check`. A budget you do not enforce is a wish. Fonts are deliberately *not* budgeted: a family's size is a property of the script, not a regression.
- **♿ Accessibility built in.** Skip navigation, the federal government banner, the required site identifier, breadcrumbs, and in-page navigation ship as first-class partials.
- **🌐 Multilingual.** English, Spanish, Hindi, Odia, and Tamil translations included; all interface strings go through `i18n`.
- **✍️ Content components as shortcodes.** Accordions, alerts, summary boxes, process lists, tags, and icons, usable directly from Markdown.
- **📰 Article furniture.** Date and author bylines, tag-driven related content, previous/next sibling links, and pagination — each a no-op on pages that have nothing to show. An article ends with **one** onward block, never three: related content where the index matches, previous/next where it does not, and a section declares itself a flat feed rather than a tree with `sidenav: false`.
- **🔎 Site search.** A [Pagefind](https://pagefind.app) index driven through its JS API, rendering results as `usa-collection` — so the CSS cost of the whole feature is one rule for `<mark>`. Degrades honestly with JavaScript off or with no index built, and `provider = "none"` removes the box entirely.
- **🔍 Upgrade tooling.** `tools/upgrade-diff.sh` diffs USWDS markup contracts between two versions and maps each change to the partial that owns it.

## 🖥️ Screenshots

The [live demo](https://civic.sid.one) is the example site in this repository, built at the `standard` preset.

<!-- TODO: add desktop and mobile screenshots once the demo is stable. -->

## 🛠️ Tech Stack

| Layer | Tool |
| :--- | :--- |
| Static site generator | Hugo Extended 0.146+ (verified on 0.164.0) |
| Design system | `@uswds/uswds` 3.13.0 |
| Styling | Sass modules, compiled by Dart Sass via `sass-embedded` |
| JavaScript | Hugo Pipes `js.Build` (esbuild), no bundler config |
| Runtime | Node.js 24.x |
| CI / release | GitHub Actions, release-please |
| Hosting (demo) | Vercel |

There is no Webpack, no PostCSS, and no CSS framework beneath USWDS. Hugo's own asset pipeline does the whole build.

## 🚀 Quick Start

### Prerequisites

- **Hugo Extended** — 0.146.0 or newer. The non-extended build cannot compile Sass. [Install guide](https://gohugo.io/installation/)
- **Dart Sass** — USWDS 3 uses Sass modules (`@use` / `@forward`), which LibSass cannot compile. The `sass-embedded` npm package provides a real Dart Sass binary; putting `node_modules/.bin` on `PATH` is enough for Hugo to find it.
- **Node.js 20+** — to install USWDS itself.

### 1. Create a site and add the theme

```bash
hugo new site my-agency-site
cd my-agency-site
git init
git submodule add https://github.com/hugo-sid/hugo-civic.git themes/hugo-civic
```

### 2. Install USWDS in your site

USWDS is resolved from **your site's** `node_modules`, not the theme's.

```bash
npm init -y
npm install @uswds/uswds@3 sass-embedded
```

> If `npm 11` skips install scripts and a binary is missing afterwards, run `npm approve-scripts`.

### 3. Configure `hugo.toml`

The one thing that is not optional is the mount. Hugo resolves Sass through include paths and JS through `node_modules`, neither of which needs a mount — but fonts and icons are published through the asset pipeline, and that does.

```toml
theme = "hugo-civic"

[module]
  # Declaring even ONE mount replaces ALL of Hugo's defaults, so the standard
  # seven are restated before the USWDS one is added. Omitting them produces a
  # site with zero pages and only a "found no layout file" warning.
  [[module.mounts]]
    source = "content"
    target = "content"
  [[module.mounts]]
    source = "assets"
    target = "assets"
  [[module.mounts]]
    source = "layouts"
    target = "layouts"
  [[module.mounts]]
    source = "static"
    target = "static"
  [[module.mounts]]
    source = "data"
    target = "data"
  [[module.mounts]]
    source = "i18n"
    target = "i18n"
  [[module.mounts]]
    source = "archetypes"
    target = "archetypes"
  [[module.mounts]]
    source = "node_modules/@uswds/uswds/dist"
    target = "assets/uswds-dist"
```

### 4. Run it

```bash
export PATH="$PWD/node_modules/.bin:$PATH"
hugo server
```

`exampleSite/` in this repository is a complete, working reference for all of the above — copying its `hugo.toml` and adapting it is the fastest path.

## 📁 Project Structure

```
hugo-civic/
├── assets/
│   └── uswds/
│       ├── _settings.scss        # USWDS settings, fed from hugo.toml
│       ├── _custom.scss          # additive theme CSS — never overrides upstream
│       ├── _manifest.scss        # the "custom" preset's component list
│       ├── main-*.scss           # one entry point per preset
│       ├── presets/              # minimal / standard / full component sets
│       └── js/core.js            # tier-1 bundle, loaded on every page
├── layouts/
│   ├── baseof.html               # page skeleton: banner, header, main, footer, identifier
│   ├── home.html  list.html  single.html  term.html  taxonomy.html  404.html
│   ├── _partials/
│   │   ├── uswds/                # the pipeline: stylesheet, js, sass-vars, assets, icons
│   │   ├── chrome/               # banner, header, nav, search, sidenav, footer, identifier
│   │   ├── components/           # USWDS content components as partials
│   │   └── article/              # byline, onward block, previous/next — no USWDS contract
│   ├── _shortcodes/              # the same components, callable from Markdown
│   └── _markup/                  # render hooks (USWDS-styled tables)
├── exampleSite/                  # the demo site — also the test fixture
├── i18n/                         # en.toml, es.toml
├── tools/                        # the check suite + upgrade-diff + Vercel build
├── hugo.toml                     # theme defaults, fully commented
├── theme.toml                    # Hugo theme metadata
├── DESIGN.md                     # architecture, measurements, and why things are this way
└── TODO.md                       # what is not done yet, and what it blocks
```

## ⚙️ Configuration

Everything lives under `params.uswds` in your site's `hugo.toml`. The theme's own `hugo.toml` documents every key with its default; what follows is the shape of it.

### Presets and asset delivery

```toml
[params.uswds]
  preset = "standard"        # minimal | standard | full | custom
  iconMode = "inline"        # inline embeds SVGs; sprite publishes the 71 KB sprite
  imagePath = "/img/uswds"
  fontPath = "/fonts"
```

`custom` compiles `assets/uswds/_manifest.scss`, which your site supplies — the way to ship exactly the components you use.

### Theming

Curated USWDS settings, passed straight into Sass. No SCSS editing required.

```toml
[params.uswds.theme]
  colorPrimary = "blue-60v"
  colorPrimaryDarker = "blue-warm-80v"
  colorSecondary = "red-50"
  colorBase = "gray-cool-60"

  fontTypeSans = "public-sans"
  fontTypeSerif = false        # false removes the @font-face rules AND the files
  fontTypeMono = false
  fontRoleHeading = "sans"
  fontRoleBody = "sans"

  gridContainerMaxWidth = "desktop-lg"
```

Switching a font type off is what actually removes it: USWDS declares `@font-face` for every configured type whether the page uses it or not.

### Chrome

```toml
[params.uswds.banner]
  enable = true

[params.uswds.header]
  variant = "extended"       # basic | extended
  megamenu = false
  search = true

[params.uswds.footer]
  variant = "default"        # default | slim | big
  returnToTop = true
  [params.uswds.footer.contact]
    agencyName = "Example Agency"
    phone = "1-800-555-5555"
    email = "info@example.gov"

[params.uswds.identifier]
  enable = true
  domain = "example.gov"
  showUsagov = true
  [params.uswds.identifier.parent]
    name = "Example Parent Agency"
    shortname = "EPA"
    url = "https://example.gov"
```

> **Set `params.uswds.identifier` for your own site.** The identifier is a federally required region, and the theme's defaults are placeholders.

### Search

```toml
[params.uswds.search]
  provider = "pagefind"      # pagefind | none | external
  page = "/search/"          # where the results template lives
  resultsPerPage = 10
```

`params.uswds.header.search` is the layout question — does the masthead carry a box. `provider` is what submitting it does:

| `provider` | Behaviour |
| :--- | :--- |
| `pagefind` | The theme's results page, backed by a [Pagefind](https://pagefind.app) index. |
| `none` | No search box anywhere. The honest setting for a site with no indexer. |
| `external` | Keeps the box and posts it at `params.uswds.header.searchAction`. |

Search is **two things, and only one of them is a template.** Add a page to your own site:

```yaml
# content/search.md
---
title: "Search"
layout: search
sidenav: false
search: false
---
```

and then add the indexing step to your build, because Hugo cannot do it:

```bash
hugo --minify && npx pagefind@1.5.2 --site public
```

Pagefind reads the finished HTML *after* Hugo has exited and writes `public/pagefind/`. **A site that copies this theme gets the templates and does not get that command** — `tools/vercel-build.sh` is where this repo's demo runs it. Until you add it, `/search/` renders, explains that the index is built at publish time, and offers the section list; nothing is broken, and nothing pretends to work.

Pages are indexed automatically. List pages, taxonomy and term pages, `404`, and the search page itself are excluded — put `search: false` in a page's front matter to opt it out too.

Three things worth knowing before you adopt it:

- **Results use `usa-collection`,** the same component listing pages use, so they carry the same preset requirement: on `minimal`, which has neither `usa-collection` nor `usa-button`, results render unstyled exactly as a listing page already does there. Use `standard` or a custom manifest.
- **If you add a `Content-Security-Policy`,** it needs `script-src … 'wasm-unsafe-eval'`. Pagefind runs in WebAssembly, and without it search fails with an error that does not obviously point at the CSP.
- **Cache `/pagefind/` for a day, not forever.** The index and fragment filenames are content-hashed, but `pagefind-entry.json` is not — it changes every build and points at all the others. Served stale, it points at fragments that no longer exist and search fails silently. See `vercel.json`.

### Languages

The theme is multilingual with no template changes: `<html lang>`, dates, menus, breadcrumbs, RSS, sitemaps, `hreflang` and the language selector are all per-language once you declare the languages.

```toml
defaultContentLanguage = "en"
defaultContentLanguageInSubdir = false

[languages]
  [languages.en]
    label  = "English"      # NOT languageName — deprecated, and it fails CI
    locale = "en-us"        # NOT languageCode — same
    weight = 1
    title  = "Example Agency"

  [languages.es]
    label  = "Español"
    locale = "es-es"
    weight = 2
    title  = "Agencia de Ejemplo"
```

> **`label` and `locale`, not `languageName` and `languageCode`.** The old spellings were deprecated in Hugo 0.158 and emit a `WARN`, and `tools/check-build.sh` fails the build on any warning. The same applies in templates: `hugo.Sites`, not `.Site.Sites`. Nearly every multilingual Hugo tutorial predates this.

Translations are **file names**, not separate directories:

```
content/about/mission.md      ->  /about/mission/
content/about/mission.es.md   ->  /es/about/mission/
```

The language code must be lowercase. To localise the URL too, add `slug: "mision"` to the Spanish front matter — it changes the path without breaking the link between the two translations.

**`defaultContentLanguageInSubdir` is the one decision you cannot change later for free.** `false` leaves English at `/about/`; `true` moves it to `/en/about/`. Flipping it after launch changes the URL of every page in your default language, so it wants a redirect map and a reason.

#### Every section needs an index in every language

This is the mistake that costs the most. Hugo creates a section page for `/es/about/` as soon as any page below it exists — and with no `_index.es.md` it **invents the title in English, pluralised**, so the breadcrumb, the `<h1>` and the search result all read `Abouts`. Hugo also only creates a section in a language that has content in it, so a shared menu linking to `/es/docs/` when nothing under `docs/` is translated points at a 404.

Two rules follow:

1. **Give every section an `_index.<lang>.md`.** Even a short signpost saying the section is available in another language beats an invented title.
2. **Define menus per language,** so each language's masthead lists only what that language actually has.

```toml
[[languages.es.menus.main]]
  name    = "Acerca de"
  pageRef = "/about"
  weight  = 10
```

A top-level `[menus]` block is inherited by *every* language, which means a Spanish menu silently full of English entries — so define them explicitly per language, as Hugo's own documentation recommends. If your menus are identical across languages and differ only in wording, give each entry an `identifier` naming a key in `i18n/*.toml` and the theme will translate the labels instead.

#### The search page needs its own slug per language

`params.uswds.search.page` is a single string, so if a language localises its search page's slug, that language's masthead posts to a URL that does not exist — on every page, silently:

```toml
[languages.es.params.uswds.search]
  page = "/buscar/"          # matches `slug: "buscar"` in content/search.es.md
```

Language params **deep-merge** into the root `[params]`, so this overrides one key and inherits `provider` and `resultsPerPage` from above.

#### What to know before you rely on it

- **Search does not cross languages.** Pagefind indexes each language separately and searches only the current page's partition, so a Spanish reader will not find English-only pages. Pagefind's `--force-language` flag merges them, at the cost of stemming every language with one stemmer — which makes search measurably worse for your majority language. Prefer translating the pages that matter.
- **Interface strings come from `i18n/`.** The theme ships `en`, `es`, `hi`, and `or`. For another language, copy `i18n/en.toml`, translate it, and keep every key — a missing key silently renders the **default language's** string, not a blank. `npm run check:i18n` enforces that.
- **Name each language in every table.** A `[language_name_es]` entry in `en.toml` (`other = "Spanish"`) is what lets the three-or-more dropdown read "Español (Spanish)" to a reader who does not read Spanish — it is what makes a language in an unfamiliar script selectable at all.
- **Banner and identifier wording is federally standardised — where a source exists.** The English and Spanish strings are copied verbatim from USWDS; do not paraphrase them. USWDS publishes no official Hindi, Odia or Tamil translation of this wording, so `i18n/hi.toml`'s, `i18n/or.toml`'s and `i18n/ta.toml`'s banner/identifier strings — and the rest of their UI strings — were translated for this repository and have had no native-speaker review. See HINDI.md, ODIA.md and TAMIL.md.
- **A script outside USWDS's fonts needs its own font.** Public Sans, Merriweather and Roboto Mono are Latin-only, so Hindi is set in a self-hosted Noto Sans Devanagari, Odia in Noto Sans Oriya and Tamil in Mukta Malar (all `@fontsource`), each scoped to its own `:lang()` and published only on pages in that language. A face that sets smaller than Public Sans can carry a `font-size-adjust` alongside it, as Tamil's does — see TAMIL.md §3. Adding a script is a table entry plus an `@font-face` block, not a new template:

  ```toml
  [params.uswds.scriptFonts.or]
    family = "Noto Sans Oriya"    # documentation only
    mount  = "noto-sans-oriya"    # the fontsource package, mounted under assets/fonts-dist/
    subset = "oriya"              # the script subset in the fontsource filename
  ```

  `uswds/script-font.html` reads that table and does nothing for a language with no entry; the matching `@font-face` and `:lang()` rules are hand-written in `assets/uswds/_custom.scss`. A language whose script *is* Latin needs neither.
- **Pagefind stems some languages and not others.** It names the ones it cannot on every index run — here, `or-in` — and those search without matching across root forms. Read that output rather than assuming from the script: `hi-in` is stemmed, `or-in` is not.
- **An empty translation is a *missing* translation.** `other = ""` makes Hugo fall back to the default language, so a "deliberately blank" string renders as English. Use a single space if you truly want nothing.

### Articles and listings

```toml
[params.uswds.article]
  date = true        # byline under the title
  prevNext = true    # the onward block used when nothing is related
  related = 3        # related pages to list; 0 makes prev/next the only branch

[pagination]
  pagerSize = 10
```

The side navigation is per-section front matter rather than a param — a site
normally wants a tree in its documentation and a flat feed in its news:

```yaml
# content/news/_index.md
cascade:
  sidenav: false
```

Related content additionally needs a `[related]` block **in your site's config** — Hugo's built-in default takes precedence over a theme's, so the theme cannot ship one. `exampleSite/hugo.toml` carries the recommended block; the partial renders nothing until you copy it.

### Shortcodes

```markdown
{{< alert type="warning" title="Heads up" >}}Body **markdown**.{{< /alert >}}

{{< summary-box title="Key information" >}}- A point{{< /summary-box >}}

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
  {{< accordion-item title="First" expanded="true" >}}Body{{< /accordion-item >}}
{{< /accordion >}}

{{< process-list heading_level="h3" >}}
  {{< process-step heading="Install" >}}Run `npm install`.{{< /process-step >}}
{{< /process-list >}}

{{< icon name="search" size="3" label="Search" >}}

{{< tag >}}New{{< /tag >}}
```

Interactive shortcodes register their JS behaviour with the page, and the footer emits one bundle for whatever the page actually used.

## 🔧 Development

```bash
git clone https://github.com/hugo-sid/hugo-civic.git
cd hugo-civic
npm install
npm run dev
```

`npm run dev` serves `exampleSite/` with `--disableFastRender`, which the theme needs because template and SCSS changes reach beyond the page being edited.

### Available scripts

| Command | Description |
| :--- | :--- |
| `npm run dev` | Hugo dev server on `exampleSite/`. |
| `npm run build` | Production build of `exampleSite/`, minified, plus the Pagefind index. |
| `npm run build:site` / `build:search` | The two halves of it, separately. |
| `npm run check` | The full suite — run this before opening a PR. |
| `npm run check:no-vendor` | Fails if any USWDS source has been copied into `assets/`. |
| `npm run check:build` | Builds every preset; treats Hugo warnings as failures. |
| `npm run check:i18n` | Verifies every translation table defines every string, and none is empty. |
| `npm run check:assets` | Verifies every asset the rendered HTML references was published. |
| `npm run check:utilities` | Verifies every USWDS utility class used actually exists in the CSS. |
| `npm run check:search` | Verifies the Pagefind index holds the site's regular pages and nothing else. |
| `npm run check:budget` | Enforces the CSS, JS, font, and search size budgets per preset. |
| `npm run upgrade:diff` | `tools/upgrade-diff.sh v3.13.0 v3.14.0` — reviews a USWDS upgrade. |

Each check exists because the failure it catches is **silent**. `$output-these-utilities` emits nothing for an unrecognised name with no error; a hardcoded `<img src>` that 404s renders as fallback alt text and looks like a CSS bug; Pagefind's documented comma-separated metadata syntax indexes one key whose value is the rest of the attribute, and the page still builds and still searches; a key missing from one translation table renders the **default language's** string, so a Spanish page quietly shows English and looks finished. `DESIGN.md` §13, §15 and §16 record what building these changed.

### Adding a component

1. Add the package to the relevant preset in `assets/uswds/presets/`, keeping upstream's order — the CSS cascade depends on it, and matching upstream's shape is what lets `upgrade-diff.sh` work.
2. Add a partial in `layouts/_partials/components/`, named after the upstream package (`usa-accordion.twig` → `accordion.html`). That 1:1 convention is load-bearing.
3. If it has a JS behaviour, call `partial "uswds/require"` with the page and the component name. Do not add it to `core.js`.
4. Optionally wrap it in a shortcode.
5. Run `npm run check`.

## 🧪 Testing

`exampleSite/` is both the demo and the test fixture — every component and preset is exercised by building it. `npm run check` builds it at `minimal`, `standard`, and `full`, then verifies assets, utility classes, the search index, and size budgets against measured numbers set ~10% above current output, so a real regression trips them and normal drift does not.

Automated accessibility testing (`pa11y` or `axe` in CI) is not yet wired up — the markup follows the USWDS contracts and the example site was reviewed by hand, but neither is the same as being verified. See `TODO.md`.

## 🚀 Deployment

Any static host works. The demo deploys to Vercel via `tools/vercel-build.sh`, which follows Hugo's "Host on Vercel" recipe: pinned Hugo, Dart Sass, and Node tarballs downloaded per build, the site root pointed at `exampleSite/`, and `baseURL` rewritten for preview deployments so previews never advertise production URLs.

For your own site:

```bash
export PATH="$PWD/node_modules/.bin:$PATH"
hugo --minify --gc
npx pagefind --site public         # only if you use params.uswds.search
```

Pin Hugo, Dart Sass, and Pagefind in CI to the versions you develop against, as [Search](#search) shows. A build that compiled with a different Sass version is a different build, and an index built by a different indexer is not the index your checks passed against.

In this repo the Pagefind version and the command that runs it both live in `package.json` — `npm run build:search` — and `tools/vercel-build.sh` calls that script rather than restating either. The Hugo and Dart Sass pins are duplicated in that script because they are what *downloads* the toolchain, before there is a Node to read a manifest with.

Serve `/pagefind/` with `max-age=86400` rather than `immutable` — see [Search](#search) above and `vercel.json`.

## 🤝 Contributing

Issues and pull requests are welcome. Run `npm run check` before opening one.

One project rule is non-negotiable:

> **Never vendor or modify USWDS source.**

Every deviation from stock USWDS must be configuration (`_settings.scss`), selection (a preset or manifest), or additive CSS (`_custom.scss`). `check:no-vendor` enforces it. Read `DESIGN.md` §4.1 before proposing an exception.

## 📄 License

MIT — see [LICENSE](LICENSE).

Third-party notices for what a built site ships:

- **USWDS** — [CC0 1.0 / public domain](https://github.com/uswds/uswds/blob/develop/LICENSE.md)
- **Public Sans, Merriweather, Roboto Mono, Source Sans Pro** — SIL Open Font License 1.1
- **USWDS icons** — Apache License 2.0 (derived from Material Icons)

## 🙏 Acknowledgments

- The **U.S. Web Design System** team, for a design system good enough to be worth not forking.
- **Hugo**, for an asset pipeline that made the bundler unnecessary.

## 📞 Support

- 🐛 Issues: [GitHub Issues](https://github.com/hugo-sid/hugo-civic/issues)
- 📚 Architecture and rationale: [DESIGN.md](DESIGN.md)
- 🗺️ Known gaps and roadmap: [TODO.md](TODO.md)

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ by [Sidharth R](https://github.com/hugo-sid)

</div>
