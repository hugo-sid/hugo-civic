---
title: "Getting started"
description: "The page heading communicates the main focus of the page. Make it descriptive and keep it succinct."
weight: 10
in_page_nav: true
# Scan h2 only: this page's summary box has an h3 ("Key information") that is
# component chrome, not a section of the document.
in_page_nav_headings: "h2"
---

## Section heading (h2)

These headings introduce sections and subsections within your body copy. Be
succinct, descriptive, and precise.

Body copy carries the usual inline marks: **bold** for emphasis you would say
out loud, *italic* for terms being introduced, `inline code` for anything a
reader will type, ~~strikethrough~~ for superseded guidance, and
[links](https://designsystem.digital.gov/) to the source. Keep links
descriptive — "read the USWDS documentation" tells a screen reader user where
they are going; "click here" does not.

> Content is the reason people visit a government site. Everything else on the
> page is there to help them find it, read it, and act on it.

### Subsection heading (h3)

Begin with the information that's most important to your users, then present
information of less importance.

{{< alert type="info" title="Before you begin" >}}
This theme compiles USWDS from source. You need Hugo Extended and a Dart Sass
binary on `PATH` — `sass-embedded` from npm provides one.
{{< /alert >}}

## Requirements

| Tool | Version | Why |
|---|---|---|
| Hugo Extended | 0.146+ | Sass compilation |
| Dart Sass | any current | USWDS 3 modules |
| Node | 20+ | installs `@uswds/uswds` |

Hugo Extended ships LibSass, which cannot compile USWDS 3. The `sass-embedded`
package provides a real Dart Sass binary; put `node_modules/.bin` on `PATH` so
Hugo can find it.

{{< alert type="warning" title="npm 11 blocks install scripts" >}}
If `hugo` is missing after a successful install, run `npm approve-scripts`.
{{< /alert >}}

## Installation

{{< process-list heading_level="h3" >}}
{{< process-step heading="Install the dependencies" >}}
Run `npm install` to fetch `@uswds/uswds` and the build toolchain.

```bash
npm install @uswds/uswds@3 sass-embedded
```
{{< /process-step >}}
{{< process-step heading="Declare the mounts" >}}
Copy the `[module]` block from `exampleSite/hugo.toml`. Declaring any mount
replaces every default, so all of them must be listed.

```toml
[[module.mounts]]
  source = "node_modules/@uswds/uswds/dist"
  target = "assets/uswds-dist"
```
{{< /process-step >}}
{{< process-step heading="Build" >}}
Run `hugo` — the first build compiles Sass and is slower; later builds are cached.
{{< /process-step >}}
{{< /process-list >}}

## Presets

A preset decides which USWDS components get compiled. Every site pays for the
components it lists and nothing else.[^budget]

| Preset | Components | CSS (gzip) |
|---|---|---:|
| `minimal` | 9 | 22.2 KB |
| `standard` | 29 | 38.6 KB |
| `full` | 37 | 60.9 KB |
| `custom` | your manifest | — |

- `minimal` {{< tag >}}Smallest{{< /tag >}} — chrome and prose only.
- `standard` {{< tag >}}Default{{< /tag >}} — adds the content components most
  sites use.
- `full` — everything upstream ships, equivalent to stock USWDS.
- `custom` — your own `assets/uswds/_manifest.scss`.

{{< icon name="check_circle" size="3" >}} Switching preset is one line in
`hugo.toml`. Nothing else in the site changes:

```toml
[params.uswds]
  preset = "standard"
```

Preset
: Which components compile. Changes the CSS you ship.

Theme settings
: Colors, type and layout, under `[params.uswds.theme]`. Changes how those
  components look.

Utilities
: The utility class families emitted. Trimming them is safe — `npm run check`
  reports anything a template still uses.

## Writing content

Ordinary markdown is the input. Unordered lists work as you would expect, and
nest one level where a point genuinely has sub-points:

- Write in the second person, and say what the reader should do.
- Front-load the sentence.
  - Put the action first.
  - Put the qualification second.
- Cut every word that survives its own deletion.

Ordered lists carry sequence, so use them only when order matters:

1. Draft the page against a real user task.
2. Read it aloud.
3. Delete a third of it.

Task lists track work that is not finished yet:

- [x] Site chrome and content components
- [x] Landing and documentation templates
- [ ] Form controls and advanced interaction

A fenced block with no language set stays plain, which suits output and file
trees:

```
exampleSite/
  content/
  hugo.toml
```

---

Everything above is rendered by the theme's own templates. Components that
markdown has no syntax for are shortcodes — `alert`, `accordion`,
`process-list`, `summary-box`, `tag` and `icon` are all on this page.

## Frequently asked questions

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
{{< accordion-item title="Why compile from source instead of using dist?" expanded="true" >}}
Compiling from source is what makes settings-based theming and the component
manifest possible. Using the prebuilt CSS would mean shipping 61 KB gzip
instead of 17 KB, with no way to retheme without overriding rules.
{{< /accordion-item >}}
{{< accordion-item title="Do I have to run npm?" >}}
Yes. Sass load paths must be real on-disk paths, so the site needs
`node_modules` at its root. That same dependency is what makes upgrades a
`npm update` away.
{{< /accordion-item >}}
{{< accordion-item title="How do I add a component?" >}}
Add its `@forward` line to the manifest and create a partial that mirrors the
matching `.twig` contract.
{{< /accordion-item >}}
{{< accordion-item title="Can I use markdown tables?" >}}
Yes. A table render hook maps them onto `usa-table` inside a scrollable
container. Keep cells short — USWDS stops cells wrapping in that container, so
a sentence becomes a long horizontal scroll.
{{< /accordion-item >}}
{{< /accordion >}}

{{< summary-box title="Key information" >}}
- Hugo Extended **0.146+** is required.
- Dart Sass must be on `PATH`; USWDS 3 cannot compile under LibSass.
- The `standard` preset ships 29 components.
{{< /summary-box >}}

[^budget]: `tools/check-budget.sh` enforces a gzip budget per preset and fails
    the build when one regresses, so these numbers cannot drift unnoticed.
