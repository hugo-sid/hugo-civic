# Hindi (hi) language support — implementation plan

Status: **built.** Hindi ships as a third language on `exampleSite`, all 25
English content pages translated, closing TODO.md §3's *"Add a third language
to `exampleSite`"*.

Font: **Noto Sans Devanagari via `@fontsource`**, self-hosted, scoped to
`:lang(hi)`. Translation quality bar: **drafted now, flagged for
native-speaker review** — same posture Spanish already shipped with. Scope:
**all 25 pages**, per the original request.

Everything in §§1-6 below is the plan as written before implementation;
`npm run check` (build, i18n, assets, utilities, search, budget) passes
against the result. What follows is what actually happened, file by file:

- `layouts/_partials/uswds/hindi-font.html` (new) — publishes the two
  weights and preloads the regular one, only when `site.Language.Lang` is
  `hi`.
- `assets/uswds/_custom.scss` — the `@font-face` pair and the `:lang(hi)`
  rule.
- `layouts/_partials/uswds/assets.html` — gained a fallback lookup
  (`extraFontsDistPath`, default `fonts-dist`) for fonts the compiled CSS
  references that aren't USWDS's own, because the Devanagari `@font-face`
  compiles into every preset (it's in `_custom.scss`) and the stylesheet
  scanner can't distinguish "USWDS font" from "any font" — without the
  fallback this warned on every build, in every language, and
  `tools/check-build.sh` fails on any warning.
- `exampleSite/hugo.toml` — a `[[module.mounts]]` for
  `node_modules/@fontsource/noto-sans-devanagari/files`, and
  `[languages.hi]` with the full menu (unlike Spanish's deliberately
  shorter one — every section has Hindi content).
- `i18n/hi.toml` (new, 78 keys) plus `[language_name_hi]` added to
  `en.toml` and `es.toml`.
- 25 `.hi.md` content files under `exampleSite/content/`.
- `content/search.hi.md` keeps its default filename-derived slug, so
  — unlike Spanish — no `params.uswds.search.page` override was needed.

One thing the plan called correctly and is worth restating: crossing from
two languages to three flips the language selector from the plain
button-link variant to the `usa-accordion` dropdown **for every language,
English and Spanish included** — that path had never rendered in a real
build before this. It now does, on every `exampleSite` build. See
MULTILINGUAL.md §8.5 for what was checked.

---

## 1. Why this is a bigger job than the Spanish rollout was

- **Full translation, not a fixture subset.** Spanish covers 10 of 19 English
  pages, chosen to exercise the "closest translated ancestor" fallback in
  `language-selector.html`. Hindi is asked for on all 19, so that fallback
  path barely fires for Hindi — worth keeping the logic, since a 20th English
  page added later will still need it.
- **Devanagari has no font today.** `fontTypeSans = "public-sans"` (and
  Merriweather, Roboto Mono) are Latin-only — confirmed against the woff2s
  `@uswds/uswds` ships. Hindi content rendered as-is shows tofu/missing
  glyphs. This is the one real blocker; everything else is translation and
  config. See §4.
- **No official USWDS Hindi text to copy.** `i18n/es.toml`'s banner and
  identifier strings are copied verbatim from USWDS's own published Spanish;
  USWDS ships no equivalent Hindi translation to copy for the federally
  standardised banner/identifier wording. Those strings have to be translated
  for this repo specifically and flagged for native review, same as the rest
  of `es.toml` already is.
- **Two languages becomes three, which changes the selector's rendered
  variant for English and Spanish too.** `language-selector.html` renders the
  plain button-link only `{{- if eq (len $langs) 2 -}}`; at three languages
  every page — English and Spanish included — switches to the
  `usa-accordion`-driven dropdown. That branch has never rendered in a real
  build. Adding Hindi is what tests it.
- **Pagefind's stemming support for Hindi is unconfirmed.** MULTILINGUAL.md
  §1.4 verified word-stemming quality for `es` against Pagefind's own support
  table before trusting it; the same check has not been done for `hi` and
  needs to happen before claiming search quality, not after.
- **The identifier's language-blind links (TODO §1) now affect three
  languages.** `params.uswds.identifier.links` is a flat, unlocalised map;
  MULTILINGUAL.md §8.4 measured this at 6 broken link targets × every Spanish
  page. Adding Hindi adds a third multiplier to a gap that's already open and
  not part of this plan's scope to fix.

---

## 2. Files to add or touch

### Fonts (new — see §4 for the decision)
- `assets/uswds/fonts/noto-sans-devanagari/*.woff2` (or wherever the theme's
  font convention puts a new family)
- SCSS: a `[lang="hi"]` (or `:lang(hi)`)-scoped `@font-face` + fallback stack,
  added to whichever preset(s) render Hindi text — likely alongside where
  `usa-language-selector` was added, since it's the same "chrome the theme
  renders unprompted, styled everywhere" argument.
- `tools/check-budget.sh`: `FONT_BUDGET_KB` is documented as "one family,
  woff2 only" — a second family needs either its own budget line or an
  explicit bump with the same before/after accounting the language-selector
  budget change used.

### i18n
- `i18n/hi.toml` — new, all 75 keys from `i18n/en.toml`, including
  `[language_name_hi]`.
- `i18n/en.toml`, `i18n/es.toml` — add `[language_name_hi]` to each (self- and
  cross-naming convention already established for `language_name_es`).
- `npm run check:i18n` should pass with no missing-key or empty-value
  warnings once `hi.toml` lands.

### Config
- `exampleSite/hugo.toml` — add `[languages.hi]`: `label = "हिन्दी"`,
  `locale = "hi-in"`, `weight = 3`, translated `title`, per-language
  `[[languages.hi.menus.main/secondary/footer]]` entries (full set, since
  every section now has Hindi content — unlike Spanish's deliberately
  shorter menu).
- **No `params.uswds.search.page` override recommended.** Spanish needed one
  because `content/search.es.md` set a localised `slug: "buscar"`. Keeping
  `content/search.hi.md`'s slug as the default (`search`, from the filename)
  avoids that whole class of bug — recommend translating the page's title
  and body only, not its URL.

### Content — 19 new `.hi.md` files, one per existing English page
```
content/_index.md
content/about/_index.md
content/about/mission.md
content/docs/_index.md
content/docs/blog.md
content/docs/getting-started.md
content/docs/theming.md
content/docs/components/_index.md
content/docs/components/accordion.md
content/docs/components/alert.md
content/docs/components/process-list.md
content/docs/components/navigation/_index.md
content/docs/components/navigation/breadcrumb.md
content/docs/components/navigation/in-page-navigation.md
content/docs/components/navigation/side-navigation.md
content/news/_index.md
content/news/accessibility-guidance-published.md
content/news/accessibility-office-hours.md
content/news/grant-applications-open.md
content/news/performance-dashboard-refresh.md
content/news/plain-language-guidance.md
content/news/quarterly-performance-update.md
content/news/records-request-processing-times.md
content/news/section-508-audit-results.md
content/search.md
```
(25 files, not 19 — corrected count above includes every leaf and section
`_index.md`.)

### Docs
- `MULTILINGUAL.md` — record what §8.5 asked for: whether Pagefind stems
  Hindi, whether the dropdown variant works as documented, and the font
  decision.
- `TODO.md` — check off "Add a third language to `exampleSite`"; add the
  Devanagari font gap and Hindi native-review gap as new open items next to
  the existing Spanish-review one.
- `README.md` — "English and Spanish" → "English, Spanish, and Hindi".

---

## 3. Execution order

1. **Font decision first** (§4) — everything else is reversible; shipping
   Hindi text nobody can read is not a good first impression.
2. `i18n/hi.toml`, plus the `language_name_hi` additions to `en.toml` /
   `es.toml`. Run `npm run check:i18n`.
3. `[languages.hi]` in `exampleSite/hugo.toml`, menus included.
4. One test page (`content/_index.hi.md`) end to end — build, look at it,
   confirm the font renders, confirm the selector's dropdown variant appears
   and behaves, before translating the other 24.
5. Translate the remaining content files.
6. Full check suite: `npm run check:build`, `check:i18n`, `check:search`,
   `check:budget`.
7. Manual verification pass (§5).
8. Update `MULTILINGUAL.md`, `TODO.md`, `README.md`.

---

## 4. Font decision (needs a call before step 1)

| Option | Trade-off |
|---|---|
| **Noto Sans Devanagari, self-hosted woff2** (recommended) | OFL-licensed, matches the theme's existing "no external font requests" stance (README/PAGEFIND already avoid CDN calls), consistent rendering across browsers/OS. Costs real KB against `FONT_BUDGET_KB`, scoped to `[lang="hi"]` so English/Spanish pages pay nothing. |
| System font stack only (`ui-sans-serif`, native Devanagari fallbacks) | Zero asset cost, but rendering is inconsistent — older Android/Windows builds and some Linux setups lack a Devanagari system font, so this risks the "tofu" problem it's meant to avoid for exactly the low-end/older-device audience `ACCESSIBILITY-CHECKLIST.md` calls out. |

## 5. Manual verification checklist (can't be scripted)

- [ ] Hindi text actually renders in Devanagari, not tofu, on a build without
      the dev machine's system fonts (throttle/clean-profile test).
- [ ] Three-language dropdown: opens, closes, `aria-expanded` toggles,
      `aria-current="page"` lands on the right language, keyboard-only
      operation works (ties to `ACCESSIBILITY-CHECKLIST.md`'s keyboard-nav
      item).
- [ ] `hreflang` alternates include all three languages plus `x-default` on
      every page.
- [ ] Identifier's `identifier_content_prefix` renders correctly for `hi`
      (the empty-string-vs-missing-key trap that broke Spanish once —
      `identifier.html`'s fix should already generalise, but verify).
- [ ] Pagefind: confirm `hi` gets word stemming per Pagefind's support table,
      not silent unstemmed/segmented indexing; re-measure `SEARCH_BUDGET_GZ`
      per language once three partitions exist.
- [ ] `check-search.sh`'s per-language masthead-action check passes for `hi`
      with the no-slug-override approach from §2.

---

## 6. Open decisions to confirm before implementation starts

1. **Font**: Noto Sans Devanagari (recommended) vs. system-font-only.
2. **Translation quality bar**: draft translations now, explicitly flagged
   "needs native-speaker review" (same posture as the existing Spanish
   content), or hold for a human translator before merging. Recommend the
   former — same as Spanish shipped.
3. **Scope confirmation**: all 25 English content files, or a smaller subset
   like Spanish's 10-page fixture. This plan assumes "all," per the request.
