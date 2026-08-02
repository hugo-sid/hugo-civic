# USWDS Hugo Theme

A Hugo theme for the [U.S. Web Design System](https://designsystem.digital.gov/),
built so that upgrading USWDS stays cheap and pages stay small.

The theme contains **zero copied USWDS source**. Every deviation from stock is
configuration, component selection, or additive CSS — which is what turns a
USWDS upgrade into a diff review instead of a merge.

**Status: usable, pre-1.0.** Site chrome, content components, and the landing
and documentation page templates are complete and exercised by `exampleSite`.
Form controls and advanced interaction components are not built yet — see
[Known gaps](#known-gaps) before you commit to it.

See [DESIGN.md](DESIGN.md) for the architecture and the reasoning behind every
decision here.

---

## What you get

| | Stock USWDS 3.13 | This theme (`standard`) | |
|---|---:|---:|---|
| CSS | 61.1 KB gzip | **38.6 KB gzip** | −37% |
| JS (every page) | 25.9 KB gzip | **5.3 KB gzip** | −79% |
| Fonts | 5.3 MB | **212 KB** | −96% |

Measured from `exampleSite` by `tools/check-budget.sh`, which fails the build if
these regress. `minimal` is 22.2 KB gzip CSS; `full` is 60.9 KB and matches
stock.

The savings are not tricks. CSS shrinks because you compile the components you
use; JS shrinks because components register their own behaviours during render
instead of shipping one bundle for everything; fonts shrink because USWDS
declares `@font-face` for every configured type whether the site uses it or not,
and the theme lets you switch the unused families off.

---

## Requirements

| | |
|---|---|
| **Hugo Extended** | ≥ 0.146 (developed against 0.164) |
| **Dart Sass** | Required. Hugo Extended ships LibSass, which **cannot** compile USWDS 3's Sass modules. `sass-embedded` from npm provides the binary. |
| **Node** | ≥ 20, to install `@uswds/uswds` |

Your site needs `node_modules` at its root. Sass load paths must be real
on-disk paths — Hugo's virtual filesystem is not consulted for them — so USWDS
cannot be bundled invisibly inside the theme. That same npm dependency is what
makes upgrades a `npm update`.

---

## Quick start

```bash
npm install @uswds/uswds@3 sass-embedded
```

Add the theme (as a Hugo Module, submodule, or under `themes/`), then copy the
`[module]` block from [`exampleSite/hugo.toml`](exampleSite/hugo.toml).

> **Declaring any mount replaces every Hugo default.** All the standard mounts
> must be listed alongside the USWDS one, or you get a site with zero pages and
> only a `found no layout file` warning. This is the single most common way to
> break the setup.

```toml
[module]
  # ... content, assets, layouts, static, data, i18n, archetypes ...
  [[module.mounts]]
    source = "node_modules/@uswds/uswds/dist"
    target = "assets/uswds-dist"
```

Only that last mount is strictly required: Sass resolves USWDS through
`includePaths` and JS through `node_modules`, neither of which needs a mount.
It exists so fonts and icons flow through Hugo's asset pipeline.

Make sure `node_modules/.bin` is on `PATH` so Hugo finds `sass`:

```bash
PATH="$PWD/node_modules/.bin:$PATH" hugo
```

> If `npm` reports `hugo-extended` postinstall was blocked (npm ≥ 11 blocks
> install scripts by default), run `npm approve-scripts` or install Hugo
> separately. Symptom: `hugo: command not found` despite a successful install.

To see the theme running before you wire it into anything:

```bash
git clone <this repo> && cd uswds-hugo-theme
npm install
npm run dev          # serves exampleSite at localhost:1313
npm run check        # builds every preset and enforces the budgets
```

---

## Configuration

Everything is set from `hugo.toml`. **You should not need to write any SCSS.**

```toml
[params.uswds]
  preset = "standard"          # minimal | standard | full | custom
  iconMode = "inline"          # inline | sprite

[params.uswds.theme]
  colorPrimary = "blue-60v"
  fontTypeSans = "public-sans"
  fontTypeSerif = false        # false = never publish this family's fonts
  fontTypeMono = false
  gridContainerMaxWidth = "desktop-lg"
```

These are passed into Sass through Hugo's `hugo:vars` module, so retheming
touches no `.scss` file and survives upgrades untouched.

> **Set the identifier params before you launch.** The theme ships defaults
> pointing at `example.gov` and a fictional "Example Parent Agency" so the
> example site renders. A real site must override
> `params.uswds.identifier` — domain, parent agency, and the seven required
> links — or it will publish placeholder text in a federally required region.

### Presets

A preset is the component manifest: which USWDS packages get compiled.

| Preset | Components | CSS (gzip) |
|---|---|---:|
| `minimal` | 9 — chrome and prose only | 22.2 KB |
| `standard` | 29 — the default | 38.6 KB |
| `full` | 37 — everything upstream ships | 60.9 KB |
| `custom` | your own `assets/uswds/_manifest.scss` | — |

`standard` excludes the form-control and advanced-interaction set — combo box,
date pickers, file input, modal, tooltip, validation, step indicator,
pagination, language selector, embed. Those styles exist in `full`, but the
theme has no partials for them yet (see [Known gaps](#known-gaps)).

### Layout width

USWDS defaults every container to `desktop` (1024px). The documentation layout
puts a side nav and an in-page nav either side of the content, which at that
width leaves the prose about 450px — roughly 50 characters a line. Sites using
that layout should set `gridContainerMaxWidth` to `desktop-lg` or wider;
`exampleSite` does. The theme binds the banner, header, footer and identifier
widths to the same value, so the chrome stays aligned with the content.

### Fonts

USWDS declares `@font-face` for every configured font *type* whether the site
uses it or not. Setting `fontTypeSerif = false` and `fontTypeMono = false` is
what actually stops those families being published — 460 KB → 212 KB in the
example site. Only the files the compiled CSS references are ever copied.

### Overriding without forking

Create any of these in **your own project** and Hugo's union filesystem gives
it precedence over the theme's:

| File | Purpose |
|---|---|
| `assets/uswds/_settings.scss` | Any USWDS setting not exposed in `hugo.toml` |
| `assets/uswds/_manifest.scss` | Your own component list (`preset = "custom"`) |
| `assets/uswds/_custom.scss` | Additive project CSS |

The theme itself stays untouched, so upgrades never conflict.

---

## Writing content

Ordinary markdown is the input. Headings, lists, nested lists, task lists,
definition lists, blockquotes, footnotes, strikethrough and code all render
against USWDS's typography.

**Tables** go through a render hook that maps them onto `usa-table` inside a
scrollable container, so a wide table scrolls instead of pushing the page
sideways. USWDS stops cells wrapping inside that container — keep cells short.

**Code blocks** are highlighted by Chroma. Chroma's default style is a dark
editor theme; `exampleSite` sets a light one:

```toml
[markup.highlight]
  noClasses = true
  style = "github"
```

USWDS has no component for blockquotes, code, definition lists or task-list
checkboxes, so the theme adds a small amount of additive styling for them in
`_custom.scss`.

### Shortcodes

Eight shortcodes give content authors the components markdown has no syntax for:

```markdown
{{< alert type="info" title="Before you begin" >}}Body{{< /alert >}}

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
  {{< accordion-item title="First" expanded="true" >}}Body{{< /accordion-item >}}
{{< /accordion >}}

{{< process-list heading_level="h3" >}}
  {{< process-step heading="Install" >}}Run npm install.{{< /process-step >}}
{{< /process-list >}}

{{< summary-box title="Key information" >}}- A point{{< /summary-box >}}
{{< icon name="search" size="3" >}}   {{< tag >}}New{{< /tag >}}
```

### Front matter

In-page navigation is front matter, not a shortcode — its `<aside>` must be a
flex *sibling* of `<main>`, which a shortcode can never be:

```yaml
in_page_nav: true
in_page_nav_headings: "h2"   # USWDS scans h2+h3 by default, which sweeps up
                             # headings that belong to components
```

### Navigation

The side navigation is derived from the content directory: every page under the
top-level section, ordered by `weight`, nested as the directories are. It is
rooted at the top of the tree rather than the page's parent, so opening a
subsection never hides the rest of the documentation, and only the open branch
renders its children. Section index pages inside a tree render it too.

Breadcrumbs come from page ancestry and emit schema.org `BreadcrumbList`
metadata by default.

---

## Components

Partials mirror the upstream `.twig` contracts key-for-key, using the same
class names and ARIA attributes — USWDS's own CSS and JS depend on them.

```go-html-template
{{ partial "components/card-group" (dict "cards" .Params.cards "page" .) }}
{{ partial "components/alert" (dict "type" "warning" "title" "Heads up" "text" "Body") }}
```

Chrome: banner, header (basic / extended / megamenu), footer (default / slim /
big), identifier, skipnav, breadcrumb, side navigation, search.

Content: hero, card group, alert, site alert, tag, accordion, summary box,
process list, graphic list, media block, icon list, collection, in-page
navigation, table.

### Page types

| Layout | Used for |
|---|---|
| `home.html` | Landing page — hero, prose, graphic list, card group |
| `list.html` | Section index; renders a `usa-collection` of its pages |
| `single.html` | Article page; documentation layout when the section is a tree |
| `404.html` | Not found |

### JavaScript

Two tiers, automatically. A small core bundle (banner, header, skipnav) loads
on every page and stays cached site-wide; components that need JS register
themselves during render and get one extra bundle, shared by every page using
the same set. A page with no interactive components loads only the 5.3 KB core.

---

## Upgrading USWDS

```bash
npm install @uswds/uswds@3.14.0
tools/upgrade-diff.sh v3.13.0 v3.14.0
npm run check
```

`upgrade-diff.sh` reports changed markup contracts and maps each to the partial
that owns it, plus new settings, added or removed components, and JS behaviour
changes. Style-only and settings-only releases need nothing but the install.

`tools/check-no-vendored.sh` is what keeps this true — it fails the build if any
USWDS source is copied into the theme.

---

## Checks

```bash
npm run check
```

| Script | Catches |
|---|---|
| `check-no-vendored.sh` | Any vendored USWDS source — the core invariant |
| `check-build.sh` | Manifest, mount and template breakage across all presets |
| `check-assets.sh` | Assets referenced by rendered HTML but never published |
| `check-utilities.sh` | Utility classes used in HTML but never emitted |
| `check-budget.sh` | CSS/JS/font size regressions |

`check-utilities.sh` exists because `$output-these-utilities` fails *silently*:
an unrecognised family name emits nothing, with no warning. It also makes
trimming the utility list safe — shrink it, re-run, and it names what broke.

---

## Known gaps

Read this before choosing the theme for a project.

**Not built yet**

- **Form controls and advanced components** — the full form control set, combo
  box, date/time pickers, file input, character count, validation, modal,
  tooltip, step indicator, language selector. The styles are available in the
  `full` preset; the partials are not written.
- **A search results page.** The header search box posts to `/search/`, which
  no template answers. Either build that page, point
  `params.uswds.header.searchAction` at an external search, or set
  `params.uswds.header.search = false`.
- **Pagination.** `list.html` renders every page in a section at once, and
  `usa-pagination` is outside the `standard` preset. Fine for a documentation
  tree; not fine for a section with hundreds of entries.
- **Article metadata on the page itself.** Date, author and tags appear in
  collection listings but not on the article, and there is no previous/next
  navigation between sibling pages.
- **Taxonomy templates.** Tag and category pages fall back to `list.html`. They
  render, but nothing is tailored to them.
- **`og:image` and Twitter card tags** are not emitted.

**Built but unverified**

- **Automated accessibility testing.** Markup follows the USWDS contracts and
  the example site was reviewed by hand, but `pa11y`/`axe` in CI is not set up,
  and that is not the same as being verified.
- **Megamenu** is implemented but not exercised by the example site.
- **Lighthouse CI** is not set up; the size budgets are enforced, real-world
  performance is not measured.

**Housekeeping before you publish**

- No `LICENSE` file in the repository root. `theme.toml` declares CC0-1.0 and
  links to *USWDS's* licence, which is not the same thing as this theme's.
  Add the canonical CC0 text.
- No CI workflow. `npm run check` is the whole test suite and nothing runs it
  automatically.

---

## Roadmap

| Phase | Status |
|---|---|
| 1 — Foundation: Sass pipeline, presets, two-tier JS, asset publishing | Done |
| 2 — Core components: chrome, content components, landing + docs templates | Done |
| 3 — Forms and advanced components | Not started |
| 4 — Hardening: accessibility CI, Lighthouse CI, contract-drift tooling | Partial — five check scripts exist |
| 5 — Prove the upgrade across a real USWDS release | Not started |

---

## Contributing

The one rule that matters: **never copy USWDS source into the theme.** Every
deviation from stock must be a setting in `_settings.scss`, a selection in a
preset, or additive CSS in `_custom.scss`. `npm run check` enforces it.

New components mirror the upstream `.twig` contract key-for-key. Find it under
`node_modules/@uswds/uswds/packages/<component>/src/`, and cite the path in a
comment at the top of the partial — that comment is what makes the next upgrade
reviewable.

Run `npm run check` before opening a pull request.

---

## License

CC0 1.0 Universal, matching USWDS.
