# Multilingual — implementation plan

Closes DESIGN.md §15.10's first bullet — *"multilingual ships on reasoning, not
evidence"* — and turns `i18n/es.toml` from a file nobody has ever rendered into
a tested path.

Hugo 0.164, USWDS 3.13.0, Pagefind 1.5.2. Status: planned, nothing built.

Everything in §1.4 was measured against a throwaway two-language build of
`exampleSite`, then reverted. Where this plan says something works, it was run.

---

## 1. Shape of the solution

### 1.1 Translation by file name, not `contentDir`

Hugo offers two ways to organise translations. They are not equally safe *in
this repository*.

`contentDir` per language means `[languages.es] contentDir = 'content/es'`,
which moves the content root. `exampleSite/hugo.toml` declares
`[[module.mounts]]`, and the first line of that file — and DESIGN.md §3.2 —
exists because declaring even one mount replaces **all** of Hugo's defaults and
produces a site with zero pages and one warning. Adding per-language content
roots means adding per-language mounts, on top of the seven already restated by
hand, to the file whose comment block is a warning about exactly this.

Translation by file name needs none of it:

```
content/about/mission.md      -> /about/mission/     (defaultContentLanguage)
content/about/mission.es.md   -> /es/about/mission/
```

Same mounts, same tree, one suffix. The language code in the suffix **must be
lowercase** — `mission.es-es.md`, never `mission.es-ES.md`.

Where a Spanish URL should not be the English one, `slug` in front matter
localises it without breaking the translation link (`url` for section pages).
Where two translations cannot share a path at all, `translationKey` in front
matter links them explicitly. Both are per-page opt-ins that cost nothing on
the pages that do not use them.

**Recommendation: file name, with localised `slug`s.** Revisit only if a site
wants wholly divergent trees per language.

### 1.2 The theme is closer than it looks, and wrong in five specific places

The audit, not a guess:

| Already correct | Why |
|---|---|
| `<html lang>` | `baseof.html:2` reads `site.Language.Locale` — renders `es-es`. |
| Interface strings | `i18n/es.toml` is picked up with no template change. |
| Dates | `time.Format ":date_long"` renders `30 de junio de 2026`. |
| Menu, footer, breadcrumb URLs | all `relLangURL`'d or `.RelPermalink`. |
| `site.Sections`, `site.Home` | per-language automatically. |
| Search page, base URL | `search.html` already emits `data-base-url="/es/"`. |
| RSS, sitemap | Hugo emits one per language. |

| Wrong | What happens today |
|---|---|
| **Menu labels** | `nav-menu.html:51,83`, `footer-nav.html:14`, `footer.html:44,47`, `header.html:57` render `.Name` raw. A Spanish page shows **English menu labels**. |
| **No language switcher** | Nothing in `layouts/` mentions `.Translations`. A reader who lands on `/es/` cannot get back. |
| **No `hreflang`** | `uswds/head.html` emits no alternates. Search engines see two unrelated sites. |
| **Untranslated sections** | See §1.3 — this one is not cosmetic. |
| **`share-image.html:68`** | uses `absURL`. Harmless for shared assets, but it is the one URL in the theme that is not language-aware; it needs a decision, not a shrug. |

### 1.3 Partial translation is the normal case, and it currently produces garbage

This is the finding that shapes the rest of the plan.

With one Spanish page added under `about/` and nothing else translated, the
build produced:

```html
<span data-pagefind-meta="section:Abouts">
```

`Abouts`. Hugo generates a section page for `/es/about/` because a page below it
exists, and with no `_index.es.md` it invents the title — in English, pluralised.
That string is not confined to one place: it is the breadcrumb, the search
result's section line, and the `<h1>` of `/es/about/`.

Worse, the Spanish navigation linked to `/es/docs/` and `/es/news/`, **neither of
which exists** — Hugo only materialises a section in a language that has content
in it. The masthead of every Spanish page carried two links to 404s. Which is
precisely the defect TODO §1 was opened for, reintroduced through a different
door.

Three ways out, and the plan takes the first two:

1. **Every section gets an `_index.<lang>.md`.** Six files. This is what kills
   `Abouts`, and it is not optional.
2. **Per-language menus**, so the Spanish masthead lists what Spanish has.
3. `lang.Merge` — fills a language's missing pages from another. Documented as
   the alternative for a site that wants complete navigation with incomplete
   translation, **not used by exampleSite**, because a reader clicking a Spanish
   menu item and getting English prose is its own kind of lie and should be a
   site's deliberate choice.

### 1.4 What was verified

Run against a two-language build, then reverted:

- `label` / `locale` are the current config keys. **`languageName` and
  `languageCode` are deprecated in Hugo 0.158+** and emit `WARN` — and
  `tools/check-build.sh` fails the build on any `WARN`. Using the old spelling
  breaks CI.
- **The template accessors are deprecated too, and the same `WARN` rule
  applies.** Measured on 0.164: `.Language.LanguageName` → use
  `.Language.Label`; `.Language.LanguageCode` → use `.Language.Locale`;
  `.Site.Sites` → use `hugo.Sites` (0.156); `.Site.Languages` → also 0.156, with
  no direct replacement. So iterating languages is `range hugo.Sites`, each
  element carrying `.Language` and `.Home`, and the default language is
  `hugo.Sites.Default`. `hugo.IsMultilingual` is the gate. Every tutorial
  written before 0.156 uses the deprecated spelling of all five, and each one
  fails CI rather than merely warning.
- **An EMPTY string in a translation table is a MISSING translation.** Hugo does
  not distinguish "this language has no word here" from "nobody wrote this yet":
  `other = ""` logs `i18n|MISSING_TRANSLATION` and falls back to the **default
  language**. `i18n/es.toml` had shipped `identifier_content_prefix = ""` since
  before this plan, so the first two-language build rendered the federally
  required identifier as **"An Un sitio web oficial de Example Parent Agency"** —
  an English article bolted onto a Spanish sentence. There is no way to express
  "deliberately nothing" in an i18n table; the value has to be non-empty. Fixed
  in step 3.
- **`T ""` returns the empty string, but logs
  `i18n|MISSING_TRANSLATION|<lang>|`** under `--printI18nWarnings`. Hugo's own
  menu template — and §2's first draft — write `or (T .Identifier) .Name`, which
  calls `T` with an empty key on every menu entry that has no identifier. The
  fallback is correct; the noise is not, and it lands in exactly the signal
  §5.1's `check-i18n.sh` reads. Guard on the identifier first.
- `<html lang="es-es">`, `i18n/es.toml`, and localised dates all work untouched.
- Pagefind partitioned cleanly: `en-us` (18 pages) and `es-es` (1), selected in
  the browser from `document.documentElement.lang`.
- **Pagefind stems on the primary subtag.** `en` and `en-us` behave identically,
  as do `es` and `es-es`: `trainings`→`training`, `publishing`→`publish`,
  `capacitaciones`→`capacitación`, and accent-folding (`capacitacion` matches
  `capacitación`). Controls (`zebra`, `cebra`) returned 0, so the test
  discriminates. **`locale = "es-es"` costs nothing in search quality.**

  Pagefind's own documentation agrees on both halves: it partitions on the
  full attribute (its worked example is `<html lang="pt-br">`) while adapting
  the stemmer to the language, and its support table lists **Spanish `es` with
  word stemming supported**, as English is. So this is measured *and* intended,
  rather than a behaviour that happens to work today.
- The npm package installs **`pagefind_extended`** (a 58 MB platform binary,
  confirmed in `node_modules/@pagefind/linux-x64/bin/`). This matters only for
  §8.5 — it is the release that carries the CJK segmenters.
- `hugo list all` includes every language and keeps its `kind` column, so
  `check-search.sh`'s existing filter already spans languages.
- `usa-language-selector` is in the **`full`** preset only. Adding it to
  `standard` costs **+325 B gzip**, taking that budget from 90% to 91% — the
  same order as `usa-pagination`'s +389 B, which went into `standard` for the
  same kind of reason (§14.5).

---

## 2. Files

### New

| Path | What it is |
| --- | --- |
| `layouts/_partials/chrome/menu-label.html` | A menu entry's localised label; see the row for its call sites below. |
| `layouts/_partials/chrome/language-selector.html` | `usa-language-selector`. Two languages render the button-link variant (no JS); three or more render the dropdown and call `uswds/require` for `usa-language-selector`. Links to the closest page that exists in the target language — this page's translation, else the nearest translated ancestor, else that language's home (§8.1). Never a 404. The masthead renders it **twice**, mobile and desktop, per upstream's `--header` variant; see §2's `chrome/header.html` row. |
| `layouts/_partials/uswds/hreflang.html` | `rel="alternate"` per translation plus `x-default`, from `.AllTranslations`. |
| `tools/check-i18n.sh` | Key parity between every `i18n/*.toml`, plus a build with `--printI18nWarnings`. See §5. |
| `exampleSite/content/**/*.es.md` | The Spanish fixture. See §4. |

### Modified

| Path | Change |
| --- | --- |
| `nav-menu.html`, `footer-nav.html`, `footer.html`, `header.html` | `{{ .Name }}` → `{{ partial "chrome/menu-label" . }}`. A site can then localise labels with translation tables *or* per-language menu definitions; today it can do neither. No-op when `identifier` is unset. The partial is Hugo's `or (T .Identifier) .Name` with the identifier checked before `T` is called — see §1.4 for why the one-liner cannot be used as written. |
| `layouts/_partials/uswds/head.html` | Call `uswds/hreflang`. |
| `layouts/_partials/chrome/header.html` | Render the selector **twice**, mobile and desktop, following `usa-language-selector--header`. Not decoration: the component's CSS positions it with `.usa-nav-container .usa-language-container` — absolute beside the menu button below 64em, flex-end above — so the basic header's desktop copy has to be a child of the nav container rather than of the slide-in panel, and only a copy in `.usa-navbar` is visible on mobile without opening an English "Menu" first. The extended header pairs `.usa-navbar` with `usa-nav__secondary`; below 64em `.usa-navbar` is flex in both variants, and the mobile copy is hidden at exactly the breakpoint where the extended navbar turns into a float context. Gated on `params.uswds.header.languageSelector` **and** on more than one language existing, and deliberately outside `with $items` — a site with no main menu still has a language. |
| `assets/uswds/presets/_minimal.scss`, `_standard.scss` | `@forward "usa-language-selector/src/styles";` in upstream order. `minimal` also gains `usa-accordion`, which the dropdown's list reset comes from. See §6 step 2. |
| `tools/check-budget.sh` | `minimal` 24576 → 26624, `standard` 44032 → 45056, and the `SRCH` line reworked for per-language partitions (§5). |
| `tools/check-search.sh` | Assert the configured search page **exists in every language** (§3.2). |
| `exampleSite/hugo.toml` | `[languages]`, per-language menus, per-language params. |
| `hugo.toml` | `[params.uswds.header] languageSelector`. |
| `i18n/en.toml`, `i18n/es.toml` | Menu-identifier keys for the example site's own menus; `languages` (the dropdown's button); `language_name_<code>`, which names each language in the table's own language so the dropdown can read "Español (Spanish)" to someone who does not read Spanish. Every table names every language, itself included, so §5.1's key-parity check holds; the self-naming entry is dropped at render rather than printed as "English (English)". No `language_selector` aria label — the contract has no slot for one, and an aria-label duplicating the visible endonym is an anti-pattern, not an improvement. |
| `README.md`, `DESIGN.md` §16, `TODO.md` | §7. |

The theme's own `hugo.toml` declares **no** `[languages]` block and must not: a
theme that ships languages imposes them on every site that installs it.
Shipping `i18n/*.toml` is the whole of a theme's job here.

---

## 3. Configuration surface

### 3.1 Languages

```toml
defaultContentLanguage = "en"
defaultContentLanguageInSubdir = false   # English at /, Spanish at /es/

[languages]
  [languages.en]
    label  = "English"      # NOT languageName — deprecated, and WARN fails CI
    locale = "en-us"        # NOT languageCode — same
    weight = 1
    title  = "Example Agency"

  [languages.es]
    label  = "Español"
    locale = "es-es"
    weight = 2
    title  = "Agencia de Ejemplo"

    [languages.es.params]
      description = "Un sitio de ejemplo construido con el tema USWDS para Hugo."
```

`defaultContentLanguageInSubdir = false` keeps English at `/`, which is what
every existing URL, the sitemap, and the Vercel deployment already assume.
Setting it `true` moves every English page to `/en/` — a site-wide redirect
event, and a decision a site makes once. Worth one line in the README, not a
default the theme changes under anyone.

### 3.2 The search page needs a per-language answer

`params.uswds.search.page` is a **string**, and `chrome/search.html` resolves the
masthead form's action as `($s.page | relLangURL)`. That is correct only while
every language uses the same slug. Localise the Spanish page to `/es/buscar/`
and the masthead posts at `/es/search/` — a 404, silently, on every Spanish
page.

Two options:

- **Per-language params** (recommended, no theme change):
  ```toml
  [languages.es.params.uswds.search]
    page = "/buscar/"
  ```
- **Resolve by layout** — have the theme find the current language's page with
  `layout: search` and fall back to the configured string. Removes the trap
  entirely, at the cost of a site-wide `.Pages` filter on every page render.

Take the config option, and **close the trap with a check** instead: extend
`check-search.sh` to assert that the resolved search page exists as a built file
in every language. Cheap, and it fails loudly on the exact mistake.

### 3.3 Menus, per language

```toml
[[languages.es.menus.main]]
  identifier = "about"
  name = "Acerca de"
  pageRef = "/about"
  weight = 10
```

`pageRef` rather than `url`, so Hugo resolves the language's own permalink
instead of the theme having to prefix a string. `identifier` is what makes the
`or (T .Identifier) .Name` change in §2 useful for sites that would rather keep
one menu and translate the labels.

The Spanish menu deliberately **omits sections Spanish does not have** — see
§1.3. A site using `lang.Merge` would list them all.

---

## 4. The exampleSite content plan

19 regular pages and 6 section indexes. Translating all 25 is the obvious move
and the wrong one.

**Translate:**

- all **6** `_index.md` files — mandatory, this is what kills `Abouts`;
- `_index.md` (home);
- `search.md`, with `slug: "buscar"` — because localised slugs are exactly the
  case §3.2 is about, and a fixture that avoids the hard case tests nothing;
- `about/mission.md`;
- **3 of the 8** news posts, tags included.

**Leave untranslated:** the `docs/` tree, and 5 news posts.

The reason is that `exampleSite` is a test fixture before it is a demo, and a
**partially** translated site exercises strictly more than a fully translated
one: the untranslated path, the section-title fallback, the per-language menu,
the language selector's no-counterpart case, and two Pagefind partitions of
different sizes. A fully translated fixture makes every one of those
unreachable — and no real agency site is ever fully translated anyway.

Tags are content: `Accessibility` → `Accesibilidad` produces a separate Spanish
term page, which is correct, and gives the Pagefind filter something
language-appropriate to hold.

> **The Spanish prose in the fixture needs a native review before release.** The
> banner and identifier strings in `i18n/es.toml` are federally published
> wording and are already correct. Anything newly written for the example site
> is not, and a federal-facing example that ships machine Spanish is worse than
> one that ships none. This is a review task, not a coding task, and it belongs
> in TODO.

---

## 5. Checks

### 5.1 `check-i18n.sh` — new

Two assertions, both for silent failures:

1. **Key parity across `i18n/*.toml`.** A key missing from `es.toml` does *not*
   fall through to the template's `| default` — Hugo falls back to the **default
   language**, so a Spanish page silently renders an English string. There is no
   warning and the page looks fine. Every `[key]` in `en.toml` must exist in
   every other table, and vice versa.
2. **`hugo build --printI18nWarnings`**, failing on `MISSING_TRANSLATION`.

`enableMissingTranslationPlaceholders` is deliberately **not** enabled: it
rewrites missing strings to `[i18n] identifier` in the output, which is a
debugging aid, not a build setting.

### 5.2 `check-search.sh` — extend

- Assert the configured search page exists per language (§3.2).
- The self-indexing guard matches `*/search/`; a localised slug (`/es/buscar/`)
  slips past it. Resolve the path from config per language instead of matching a
  literal.
- The `expected - 5` floor on indexed pages was calibrated for one language.
  Assert **per language** instead, so a language whose content silently stops
  being indexed is caught rather than absorbed.

### 5.3 `check-budget.sh` — rework the `SRCH` line

Today it sums **every** index chunk and the largest wasm. With two languages
that measures a page nobody loads: a reader on `/es/` fetches the `es-es` wasm
and the `es-es` chunks, never the English ones.

Change it to measure **one language — the largest partition** — and report the
per-language figures. A second language should not read as a regression in a
budget that exists to catch regressions.

---

## 6. Order of work

1. ~~**Menu labels + `hreflang` + language selector partial.**~~ **Done.** All
   theme-side, all provable against the *existing* single-language site:
   `hreflang` renders nothing, the selector renders nothing, `chrome/menu-label`
   falls back to `.Name`. Verified: the 96-file `exampleSite` build is
   byte-identical before and after, and `npm run check` passes unchanged.
   Verified separately against a throwaway two- then three-language build, since
   an inert diff proves only that the code does not fire — reciprocal `hreflang`
   with `x-default` on the default language, per-language menu labels, the
   two-language button-link, the three-language dropdown registering
   `usa-language-selector`'s JS and nothing else registering it, and an
   untranslated page's selector landing on the translated home rather than a
   404. The control is **unstyled until step 2** adds it to the `standard`
   preset.
2. ~~**`_standard.scss` + the budget bump.**~~ **Done, and wider than planned** —
   the control is now styled at *every* preset, because the theme renders it on
   any site with a second language and a control it renders is a control it has
   to style. §6's original "confirm 91%" and §2's budget bump could not both be
   satisfied anyway: 91% is the figure *before* the budget moves.

   | preset | was | now | what was added |
   |---|---|---|---|
   | `minimal` | 22823 B | 23538 B | `usa-language-selector` **and `usa-accordion`** |
   | `standard` | 40024 B | 40349 B | `usa-language-selector` |
   | `full` | 62413 B | 62413 B | nothing — it already had it |

   `usa-accordion` is not optional in `minimal`: `.usa-language__primary`
   carries the `usa-accordion` class and takes its list reset
   (`list-style-type: none; padding-left: 0`) from it, so without it the
   three-or-more dropdown renders as a bulleted, indented list. It also fixes
   the nav's own submenu buttons, which have been missing that reset in
   `minimal` all along. Budgets moved to 26624 / 45056 / 66560.
3. ~~**`[languages]` + the 6 section `_index.es.md` files + per-language menus.**~~
   **Done.** All three confirmations hold: no invented section title anywhere
   (`/es/docs/components/navigation/` reads *Navegación* with the breadcrumb
   *Agencia de Ejemplo › Documentación › Componentes › Navegación*), no Spanish
   menu entry pointing at a section Spanish does not have, and no `WARN` from
   any of the three presets. A link check over the whole two-language build
   found **no Spanish-specific broken link**; the seven that exist are
   pre-existing and English-only in origin (§8.4).

   Three things came out differently than written:

   - **Menus are defined per language for BOTH languages**, not just Spanish. A
     top-level `[menus]` block is inherited by every language, so the choice was
     between explicit tables and a Spanish menu that silently inherits English
     entries. Hugo's own documentation recommends the explicit form.
   - **No `identifier` on any menu entry, and so no menu keys in `i18n/*.toml`**
     — §2's table said otherwise. Identifiers exist to relabel ONE shared menu
     from a translation table; these menus differ in *structure*, not wording,
     so an identifier would be dead config that also makes every entry report a
     missing translation. The mechanism still exists in `chrome/menu-label.html`
     for sites whose menus are identical across languages; the fixture just is
     not one of them.
   - **The `docs/` Spanish indexes are signposts, not empty shells.** Each says,
     in Spanish, that the section is available in English and links to it. This
     is what the language selector's ancestor walk lands on (§8.1), so leaving
     them blank would have made the control worse than useless there.

   One defect found and fixed on the way, in the identifier's disclaimer — see
   §1.4's note on empty translations. The theme had dropped upstream's
   `{% if masthead.content_prefix %}` guard; it is back.

   **Known and expected at the end of this step:** every Spanish masthead's
   search box posts to `/es/search/`, which does not exist. That is §3.2's trap,
   and step 4 is where it gets watched failing and then fixed.
4. ~~**The rest of the Spanish content**, including `search.es.md` with the
   localised slug — which should fail §3.2's new check until the per-language
   param is set. **Watch it fail first.**~~ **Done.** §4's fixture is complete:
   `search.es.md` (`slug: "buscar"`), `about/mission.es.md`, and 3 of the 8 news
   posts with translated tags. Five Spanish regular pages, four of them indexed.

   **The trap was watched failing.** Built with `search.es.md` present and no
   per-language param: `/es/buscar/` exists, `/es/search/` does not, and every
   Spanish masthead carried `action=/es/search/` — a 404 on every page of the
   language, silently, exactly as §3.2 describes. Setting
   `[languages.es.params.uswds.search] page = "/buscar/"` moved it to
   `action=/es/buscar/` with English untouched at `/search/`.

   Three things worth recording:

   - **Language params deep-merge into the root `[params]`.** Overriding
     `uswds.search.page` for one language does *not* replace the `uswds` map:
     the Spanish results page still renders `data-page-size=10` and the Spanish
     masthead still resolves `imagePath`, both inherited from the root table.
     This is what makes §3.2's "no theme change" recommendation actually cheap —
     had it replaced the map, a one-key override would have cost a site its
     whole theme configuration for that language.
   - **Localised slugs were extended past `search.md`** to `mission.es.md` and
     all three posts, because §1.1's central claim — that `slug` localises a URL
     *without breaking the translation link* — was otherwise asserted and never
     run. It holds: `/about/mission/` and `/es/about/mision/` carry reciprocal
     `hreflang` with `x-default` on the English page, and the language selector
     crosses the differing slugs in both directions. The untranslated-page walk
     still works alongside it (`/news/plain-language-guidance/` → `/es/news/`).
   - **Accented tag slugs percent-encode and resolve.** `Aviso público` publishes
     to `/es/tags/aviso-público/` and is linked as `/es/tags/aviso-p%C3%BAblico/`.
     A naive link checker reports these as broken; they are not. Worth knowing
     before `removePathAccents` gets reached for as a fix to a non-problem.

   Verification: no `WARN` from any preset, `npm run check` passes all six
   checks, Pagefind partitions 18 `en-us` / 4 `es-es`, Spanish Pagefind metadata
   reads `section:Noticias` and `tags:Capacitación` rather than English, and a
   link check over the two-language build still finds **exactly the seven
   pre-existing broken targets of §8.4** and no new one.

   §8.3 is partly answered in passing: the translated post carries `image` with
   a translated `imageAlt`, so the asset is shared and the alt text is not. A
   Spanish post with an image of its *own* still does not exist, and that is the
   half of §8.3 that needs an asset rather than a decision.

   **Known and expected at the end of this step**, both step 5's work:
   `check-search.sh` reports *"indexed 22 page(s); hugo reports 24 regular"* —
   its `expected - 5` floor is now absorbing two languages at once rather than
   asserting either, and its self-indexing guard matches the literal `*/search/`,
   which `/es/buscar/` walks straight past (the page is excluded today only
   because it sets `search: false`). `SRCH` sits at 91% of budget because it
   sums both partitions — the reading §5.3 exists to correct.
5. ~~**`check-i18n.sh`**, then `check-search.sh` and `check-budget.sh` per §5.~~
   **Done.** All three assertions from §5 are in place and `npm run check` passes
   all **seven** checks — seven because of the first finding below.

   - **`check-i18n.sh` was written, passed, and was never run.** It was not in
     `package.json`'s `check` chain, so neither CI nor a local `npm run check`
     would have executed it; it only ever passed because it was invoked by hand.
     A check outside the gate is the same wish this repo's budgets exist not to
     be. It now runs after `check:build`.
   - **§5.3's premise is right and its magnitude was wrong.** Measuring one
     language instead of summing every partition moves `SRCH` by **1523 B**
     (101188 → 99665, 91% → 90% of budget), not by a partition's worth. The old
     line already counted only the *largest* wasm, and the wasm is ~85% of a
     partition, so the double-count was confined to the meta and index chunks.
     The rework is still worth having, but for a reason the plan did not state:
     it keeps the figure a *page load* as languages are added. Under the old
     arithmetic a fourth language added its whole index to a number describing a
     single visitor, so the error grew with the site.
   - **`pagefind-entry.json` is the authority on what partitions exist** — it
     names each language's meta hash, its wasm build, and its page count, and it
     is the same file the client reads to decide what to fetch. Deriving the
     partitions from filenames would have guessed at all three.
   - **The per-language index assertion reads 18 of 19 (en) and 4 of 5 (es).**
     Neither is a gap: the one unindexed page in each language is that
     language's own results page, which sets `search: false`. The old
     `expected - 5` floor could not have told those two apart from five silently
     missing pages.

   `SRCH` now reports every language and budgets the largest:

   | partition | on the wire | pages |
   |---|---|---|
   | `en-us` | 99665 B | 18 |
   | `es-es` | 88139 B | 4 |

6. ~~**Docs** — DESIGN.md §16, README, TODO.~~ **Done.**

   - **DESIGN.md §16**, nine subsections: file-name translation and the mounts
     argument (§16.1), partial translation as design (§16.2), the `Abouts`
     failure (§16.3), the selector's ancestor walk and its three departures from
     upstream's contract (§16.4), empty-vs-missing translations and the `T ""`
     trap (§16.5), the five deprecations that fail CI (§16.6), what was measured
     to know Pagefind needed no configuration, plus the search-slug trap
     (§16.7), the two checks (§16.8), and known gaps (§16.9).
   - **§15.10's multilingual bullet is struck**, pointing at §16 and replaced by
     the narrower gap that actually remains — search does not cross partitions.
   - **§15.8 was rewritten**, not just renumbered. It documented the old SRCH
     arithmetic ("the largest wasm is counted, every index chunk is counted") as
     a *deliberate conservative choice*, which step 5 made false. It now carries
     the per-language table and the honest 1523 B figure.
   - **README** gained a `Languages` section after `Search`: the `[languages]`
     block with the `label`/`locale` warning, file-name translation, the
     `_index.<lang>.md` rule with the `Abouts` failure as the reason,
     per-language menus, the search-slug trap, and
     `defaultContentLanguageInSubdir` as the one decision that is not free
     later. `check:i18n` added to the scripts table, and to the paragraph on why
     every check exists.
   - **TODO.md**: the search item's "left open" list drops multilingual and
     keeps the two that are still open; the language selector is ticked in §4;
     §1's identifier item gains the language-blind links half; and §3 gains two
     new items — the native Spanish review, and adding a third language, since
     the dropdown that ships is the variant CI never exercises.

   **One item from §7 needed no work.** The §8.6 correction — §15.2 naming a
   Pagefind UI that upstream superseded — was **already correct in DESIGN.md**,
   which reads "`pagefind-ui` historically, and since 1.5.0 the Component UI
   that replaced it". §8.6 was written against an older draft of §15.2 than the
   one in the repository. Recorded rather than silently dropped, so the next
   reader does not go looking for a fix that was never needed.

Steps 1 and 3 are the ones with real risk. Step 1 touches five partials that
render on every page of every site using the theme; step 3 is where the
navigation of a whole language is decided.

---

## 7. Documentation to write

- **DESIGN.md §16**, covering: why file-name translation and not `contentDir`
  (the mounts argument, §1.1); why partial translation is the fixture's design
  rather than an unfinished job; the `Abouts` failure and what it teaches about
  section indexes; why Pagefind needs no configuration and what was measured to
  know that; and the `label`/`locale` deprecation, which will otherwise be
  rediscovered by whoever next reads an old tutorial.
- **README**, under Configuration: the `[languages]` block, per-language menus,
  the search-page slug trap, and `defaultContentLanguageInSubdir` as the one
  decision a site cannot change later for free.
- **DESIGN.md §15.2 correction** (§8.6): the bundled UI it argues against was
  replaced by the Component UI in Pagefind 1.5.0. The argument stands; the name
  in it does not.
- **TODO.md**: tick DESIGN.md §15.10's multilingual bullet; add the native
  Spanish review from §4 as its own item, and the §8.6 correction.

---

## 8. Open questions and known gaps

### 8.1 Should the selector switch page, or language? — **settled, better than planned**

`.Translations` gives the counterpart page. When there is none — most of `docs/`
under this plan — the choice was framed as the translated **home page** or
hiding the control, and the plan took the home page: a disabled control on two
thirds of a site is worse than a working one that lands a page higher.

What shipped is neither. The selector walks to the **closest page that exists in
the target language**: this page's translation, else the nearest translated
ancestor, else that language's home. `/docs/forms/validation/` with no Spanish
lands on `/es/docs/` if that exists — verified — rather than being thrown to the
site root. The walk always terminates, because home exists in every language.

What remains open is whether to *tell* the reader they did not get a
translation of the page they were on. A visually-hidden note is the obvious
move and was deliberately not taken: it would have to be written in the current
page's language, which is the one language the reader has just told us they
would rather not read, and giving screen-reader users a caveat that sighted
users do not get is its own accessibility problem. Landing them somewhere
recognisable in their own language says it better than prose would.

### 8.2 Search does not cross languages, and `--force-language` is the wrong fix

Pagefind searches only the current page's partition. Under §4's deliberately
partial fixture that bites immediately: a Spanish reader searching for anything
in `docs/` gets nothing, with no indication the page exists in English at all.

Pagefind documents an opt-out — `--force-language <ISO 639-1 code>`, which
*"ignores any detected languages and indexes the whole site as a single
language"*. It is one flag, and it is tempting, and this plan does **not** take
it:

- **One stemmer for every language.** `--force-language es` stems English
  content with Spanish rules. The `trainings`→`training` match verified in §1.4
  stops working — search gets worse for the majority language to make it exist
  for the minority one.
- It takes a **bare ISO 639-1 code** (`es`), not the locale the rest of this
  plan uses (`es-es`) — a small trap, since every other language value in the
  config is a locale.
- Results would mix languages with nothing in the UI to mark which is which,
  and `search.js` renders no language column.

The honest middle path is a second query against the other partitions, rendered
as a separate *"also N results in English"* block — Pagefind's JS API can select
a partition explicitly, so this is a known-shaped feature rather than a hope.
Deliberately out of scope here, because it needs a UI decision (a second list? a
link? what does the count line say?) that should follow a working single-language
results page, not precede it.

**What ships instead:** the limitation stated plainly in the README, and
`--force-language` documented as the lever a site can pull if its languages
genuinely share one corpus.

### 8.3 `share-image.html:68` uses `absURL`

Share images resolve from `assets/`, and page-bundle resources are **inherited
across linked translations**, so a Spanish page with no image of its own gets its
English counterpart's — which is the desired behaviour and needs no change. The
open question is whether `og:image` should ever be language-specific (an image
with English text baked in, shared from a Spanish page). Needs a decision, not a
change, and the fixture should include one Spanish post with its own image to
force the question.

### 8.4 The identifier's required links are English URLs

`params.uswds.identifier.links` is a flat map of URLs (`/about/`,
`/accessibility/`…) in a federally required region. Per-language values work via
`[languages.es.params]`, but nothing in the theme *checks* that a Spanish page's
identifier does not link to English-only pages. Out of scope here; it belongs
with TODO §1's existing identifier item, which is still open.

Measured at step 3, since the numbers make the case better than the argument
does. A link check over the two-language build finds seven broken internal
targets, and **six of them are these**: `/accessibility/`, `/foia/`,
`/inspector-general/`, `/no-fear-act/`, `/performance/` and `/privacy/`, each on
all 44 pages — Spanish included, because the map is flat and language-blind. The
seventh is `/contact/`, from the English secondary menu, which is why Spanish
has no secondary menu. None of this is new in this branch: `exampleSite` shipped
those links pointing at pages it does not contain. It is simply now visible in
two languages instead of one.

### 8.5 Two languages is not N languages

Everything here is designed against `en` + `es`, and the selector's three-or-more
variant is the only part that is written for N without being run at N. A third
language is cheap to add to the fixture later and is the only way that variant
gets tested. Say so rather than implying it works.

Two specifics for whoever adds the third:

- **Check Pagefind's support table first.** Every language works, but only
  listed ones get word stemming — Korean, Thai, Ukrainian and Vietnamese are
  indexed without it, so results will not match across root words. That is a
  content decision (how the site's search will feel) masquerading as a config
  line, and it should be made knowingly.
- **Chinese, Japanese and Korean are a different mechanism.** Pagefind
  segments rather than stems them, and only in the extended release — which is
  what `npm install` puts in `node_modules` here (§1.4), so it would work, but
  `check-search.sh`'s word-count assumptions and the `SRCH` budget were both
  calibrated on whitespace-delimited text and should be re-measured rather than
  trusted.

**Update: the third language landed.** Hindi (`hi-in`), full-site rather than
a fixture subset — see HINDI.md for the plan and font decision. What actually
ran:

- The three-or-more dropdown renders and behaves — `aria-expanded`,
  `aria-current`, keyboard operation — for all three languages, English and
  Spanish included, since crossing the two-language threshold flips their
  variant too. This was the untested path §8.5 flagged; it is now exercised
  by `exampleSite` on every build.
- ~~Devanagari is not in Pagefind's Snowball-based stemming table the way `es`
  is, so Hindi search is unstemmed word matching, not stemmed.~~ **Wrong — see
  the Odia update below.** `hi-in` *is* stemmed; this claim was written from
  the assumption that a non-Latin script implies no stemmer, and never checked
  against what Pagefind actually reports. Pagefind names the languages it
  cannot stem, on stderr, on every index run; that output is the support table.
- No font question existed for `es` — Spanish is Latin script. Hindi's is the
  one real blocker of the three: Devanagari has no glyphs in any USWDS font,
  so `@fontsource/noto-sans-devanagari` is self-hosted and scoped to
  `:lang(hi)`. See HINDI.md §4.

**Update: a fourth language landed too.** Odia (`or-in`), full-site, 25 pages
— see ODIA.md. Three of §8.5's four language-count worries were already spent
by Hindi and cost nothing the second time; what the fourth language actually
taught:

- **Pagefind stems `hi-in` and does not stem `or-in`.** Checked properly this
  time, by reading Pagefind's own output across a four-language index rather
  than reasoning from the script. It prints
  `Note: Pagefind doesn't support stemming for the language or-in` and says
  nothing about `hi-in`, `es-es` or `en-us`. So Odia — not Hindi — is this
  repository's one unstemmed language, and the §8.5 bullet above about
  checking the support table *first* was right in substance and was then not
  followed.
- **The second non-Latin script is what justified generalising the font
  partial, not the first.** `uswds/hindi-font.html` hardcoded `hi` three ways;
  a copy-pasted `odia-font.html` would have duplicated ~40 lines to change
  three string literals. It is now `uswds/script-font.html`, driven by a
  `params.uswds.scriptFonts` table keyed by language code, and `head.html`
  names no language at all. The SCSS stayed hand-written per script — see
  ODIA.md §3 for why the same table does not drive the `@font-face` rules.

**Update: a fifth language landed, and cost nothing structural.** Tamil
(`ta-in`), full-site, 25 pages — see TAMIL.md. No template changed: a mount, a
`scriptFonts` entry, a `[languages.ta]` block, an `@font-face` pair and a
`:lang()` rule. That is the generalisation ODIA.md §3 argued for, paying off
one language later. Three things the fifth language did teach:

- **Pagefind stems `ta-in`.** Checked by reading Pagefind's stderr across a
  five-language index, per the bullet above. It names `or-in` and only `or-in`,
  ~~so Odia is still this repository's one unstemmed language.~~ **The first
  half holds; the second did not survive a sixth language — see the Telugu
  update below.** `ta-in` is stemmed. `or-in` is no longer alone.
- **`SRCH` is now a per-language budget in practice.** Tamil's index is 30059 B
  gzipped against Hindi's 22467 B and English's 12561 B over the same 18 pages,
  with a flat wasm — Tamil is agglutinative, so identical prose yields far more
  distinct surface forms. The budget was raised to 126976 B rather than
  removed; see TAMIL.md §7 for why that differs from the FONT budget's fate.
- **A script's font can need a size adjustment, not just an `@font-face`.**
  Mukta Malar sets 11-13% smaller than Public Sans at the same `font-size`, and
  every Tamil page mixes the two on one line because only the `tamil` subset is
  published. `:lang(ta)` carries `font-size-adjust: 0.517` — Public Sans's own
  aspect ratio — which sizes the Tamil to the Latin beside it and is a no-op on
  the Latin itself. TAMIL.md §3.
- **The agency identifier reads backwards in every postpositional language.**
  Not a Tamil bug; Hindi and Odia have shipped it since they landed.
  `chrome/identifier.html` emits `identifier_content` before the agency link,
  which no translation table can reorder. Tamil sidesteps it with a label form;
  the real fix is passing the link into the string as a template argument, and
  it is a fix to Hindi and Odia rather than part of a Tamil rollout. TAMIL.md
  §6.
- **A fixed per-family font budget does not survive a multilingual theme.**
  `check-budget.sh`'s `FONT` line was removed rather than bumped a second
  time: a font family's size is a property of the script, not a regression,
  so raising the ceiling at every new language measures nothing. The CSS, JS
  and search budgets — which genuinely can regress — stay.
- **Hugo's slugifier mangles Odia heading ids but does not empty them.**
  Matras and viramas are stripped (`ବ୍ୟବହାର` → `ବୟବହର`), leaving ids that are
  ugly, non-empty and — checked across all 25 pages — unique. So
  `in-page-nav-heading-ids.js`, written for Hindi, needed no change: it keys
  off the parent heading's own Hugo-assigned id whatever script it is in.

**Update: a sixth language landed, and cost nothing structural either.**
Telugu (`te-in`), full-site, 25 pages — see TELUGU.md. Same shape as Tamil: a
mount, a `scriptFonts` entry, a `[languages.te]` block, an `@font-face` pair and
a `:lang()` rule, and no template touched. Two rollouts running is the point at
which ODIA.md §3's generalisation stops being a claim. What the sixth language
taught:

- **`or-in` is not the only unstemmed language, and the script does not predict
  which are.** Pagefind names `or-in` *and* `te-in` on every index run, which
  corrects the bullet above and TAMIL.md §7. Telugu and Tamil are both
  Dravidian, both agglutinative, both South Indian abugidas, and they land on
  opposite sides of this line; Hindi stems and Odia does not. Read the stderr —
  there is no rule to infer it from. TELUGU.md §7.1.
- **`SRCH` did not need raising for a sixth language**, and the reason is the
  wasm rather than the prose. An unstemmed language shares
  `wasm.unknown.pagefind` (68024 B) instead of getting its own stemmer build
  (~70-72 KB), so Telugu reports smaller than Tamil despite indexing 25812 B
  against Tamil's 30013 B. `ta-in` is still the budgeted language.
- **`check-budget.sh` under-reports every unstemmed language by the size of the
  shared wasm.** Pagefind writes `"wasm": null` for them and the script builds a
  filename from that field, so the `[ -f ]` guard silently drops 68024 B from
  `or-in`'s and `te-in`'s totals. Latent since Odia landed, found because Telugu
  made two of them. Not fixed in the Telugu rollout; TELUGU.md §7.2.
- **A font decision can go back to the obvious answer without going back to the
  obvious reasoning.** Tamil broke the Noto pattern, so Telugu could not just
  inherit it — Noto Sans Telugu, Noto Serif Telugu and Hind Guntur (Telugu's
  Mukta Malar, by Tamil's own logic) were all measured. Hind Guntur lost on the
  line box TAMIL.md §2 had already flagged, at 1.9x the bytes; the serif lost on
  stroke contrast, thinning to 0.72px at the 16px this theme sets body text at,
  on exactly the *vattulu* that carry Telugu's distinctions. TELUGU.md §2 and §4.
- **`font-size-adjust` is a per-face measurement, not a per-script habit.**
  Tamil needed it at 10.5% short of Public Sans; Telugu is 3.4% short and
  deliberately does not carry it. Recording the absence and its measurement is
  what stops the next language copying the declaration on faith. TELUGU.md §3.
- **Telugu brings its own invisible-character convention, and it is not the
  danda.** ZWNJ (U+200C) stops a conjunct forming across a virama, so
  `వెబ్‌సైట్` needs one and loses its letterforms without it — the same class of
  silent damage as Odia's no-break space, currently unchecked. TELUGU.md §5.

### 8.6 The Component UI does not change the §15.2 decision, but dates its wording

Pagefind 1.5.0 replaced the Default UI (`pagefind-ui.js` / `PagefindUI`) with a
Component UI — a search modal with better accessibility and customisation.
DESIGN.md §15.2 argues against "Pagefind's drop-in UI" by name and predates
that.

The decision is unaffected: the reasons were vendored CSS in a theme whose
central rule is that no CSS is vendored, markup matching no USWDS contract, and
a second search input behaving unlike the masthead's. A newer, better bundled UI
is still all three. The Component UI's built-in translations are likewise moot —
this theme routes every string through `i18n/*.toml`, which is what makes
§4's Spanish work at all.

But §15.2 should be updated to say *"the bundled UI, currently the Component
UI"* rather than naming a component that upstream has superseded, or the next
reader will reasonably conclude the argument was never evaluated against the
current version. **This is a documentation fix, listed in §7, not a code
change.** It is also a reminder that `pagefind-component-ui.js` is now the
largest single file in the ~400 KB of unused UI assets §15.8 declines to
budget for.
