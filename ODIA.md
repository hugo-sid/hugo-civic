# Odia (or) language support — implementation plan

Status: **built.** Odia ships as a fourth language on `exampleSite`, all 25
English content pages translated. Full-site translation, not a fixture subset,
same as Hindi.

Font: **Noto Sans Oriya via `@fontsource`**, self-hosted, scoped to
`:lang(or)`. Translation quality bar: **drafted now, flagged for
native-speaker review** — see §5, which asks for that review more insistently
than Hindi's equivalent note did.

Everything in §§1-6 below is the plan as written before implementation;
`npm run check` (build, i18n, assets, utilities, search, budget) passes
against the result. What actually happened, against the §6 execution order:

- **§3's generalisation landed first, as planned.**
  `layouts/_partials/uswds/hindi-font.html` became
  `layouts/_partials/uswds/script-font.html`, driven by
  `params.uswds.scriptFonts` keyed by language code. `uswds/head.html` no
  longer names `hi`; it calls the partial unconditionally and the partial
  does nothing for a language with no table entry. One new field the plan did
  not anticipate: `subset`, because the fontsource filename embeds the script
  subset (`…-devanagari-400-…` vs `…-oriya-400-…`) and it is not derivable
  from the mount name.
- **The FONT budget check is gone** from `tools/check-budget.sh`, per §2. CSS,
  JS and search budgets stay.
- `assets/uswds/_custom.scss` gained the Oriya `@font-face` pair and the
  `:lang(or)` rule, hand-written per §3's SCSS decision.
- `i18n/or.toml` (new, 77 tables) plus `[language_name_or]` added to
  `en.toml`, `es.toml` and `hi.toml`.
- `exampleSite/hugo.toml` — the `[[module.mounts]]` for
  `@fontsource/noto-sans-oriya/files`, the `[params.uswds.scriptFonts]` table,
  and `[languages.or]` with the full menu.
- 25 `.or.md` content files. `content/search.or.md` keeps its default
  filename-derived slug, as planned.

Verified on the built site rather than assumed:

- Two Oriya weights publish (39 KB + 41 KB), the regular one preloads, and an
  Odia page's `:lang(or)` rule resolves to the compiled
  `noto sans oriya, Public Sans Web, …` stack.
- `hreflang` alternates carry all four languages plus `x-default`.
- `identifier_content_prefix`'s single-space value renders as nothing rather
  than falling back to English — the trap §5 inherited from Spanish.
- Odia heading ids survive Hugo's slugifier mangled but **non-empty and
  unique** (`ବ୍ୟବହାର` → `ବୟବହର`; matras and viramas are stripped), so
  `in-page-nav-heading-ids.js` carries over untouched exactly as §1 predicted.

One §5 question is now answered rather than open: **Pagefind stems `hi-in` but
not `or-in`.** See §5 and MULTILINGUAL.md §8.5.

---

## 1. What Hindi already paid for

- **The font pipeline is proven, just Hindi-specific.** `uswds/hindi-font.html`
  hardcodes `"hi"`, `"noto-sans-devanagari"`, and the family name throughout.
  Adding Odia by copy-pasting it into `odia-font.html` would duplicate ~40
  lines of identical publish/preload logic for three changed string literals.
  **Recommendation: generalize before adding the second script**, not after —
  see §3.
- **The in-page-nav scroll-spy fix needs no changes.** `assets/uswds/js/
  in-page-nav-heading-ids.js` rewrites broken anchor ids using the PARENT
  HEADING's own Hugo-assigned id, whatever script that id's text is in. It
  never looked at `hi` specifically. Odia headings get this fix automatically
  the moment `in_page_nav: true` is set on an Odia page — nothing to build.
- **The three-or-more dropdown is no longer an unknown.** Hindi already
  crossed the two-language threshold and exercised the accordion variant in a
  real build. Going from three languages to four doesn't change which variant
  renders — English, Spanish and Hindi stay on the dropdown they're already
  on. Lower risk than the Hindi rollout specifically because of this.
- **The identifier's language-blind link map (TODO §1) now affects four
  languages instead of three.** Still out of scope here, same as it was for
  Hindi — noted so the count keeps growing visibly rather than silently.

## 2. The one new technical fact: Odia needs its own font, and there's a budget collision

Devanagari and Odia (Oriya script) are different Unicode blocks — Noto Sans
Devanagari has no Oriya glyphs. Confirmed against
`@fontsource/noto-sans-oriya@5.3.0` (exists on npm, OFL-licensed, same
file-naming convention as the Devanagari package):

```
noto-sans-oriya-oriya-400-normal.woff2   40 KB
noto-sans-oriya-oriya-700-normal.woff2   44 KB
```

Regular + bold only, same reasoning as Hindi's two weights. **84 KB combined.**

`tools/check-budget.sh` used to report `FONT woff2 324 KB on disk budget
400 KB` — that 324 KB already included Public Sans plus both Devanagari
weights, and Odia's 84 KB would have put the total at ~408 KB, over the
then-current 400 KB budget.

**Decision: remove the FONT budget check rather than keep bumping it.**
Every non-Latin script this theme adds a fontsource family for is one more
fixed cost that has nothing to do with the size regressions the CSS/JS/search
budgets exist to catch — a font family being large is a property of the
script, not a regression, and a fixed KB ceiling would have to be raised
again at every new language regardless of whether anything actually went
wrong. The CSS, JS and search budgets stay: those genuinely can regress.

## 3. Decision: generalize the font-loading partial

Rather than `layouts/_partials/uswds/odia-font.html` duplicating
`hindi-font.html`, fold both into one data-driven partial. This is the same
move `uswds/assets.html` already made for USWDS's own fonts — discover from a
small table instead of hand-writing a near-identical file per case — and two
real instances is the point where that stops being premature.

Shape:

```toml
# hugo.toml or exampleSite/hugo.toml
[params.uswds.scriptFonts.hi]
  family = "Noto Sans Devanagari"
  mount  = "noto-sans-devanagari"   # matches the fontsource package's file prefix
[params.uswds.scriptFonts.or]
  family = "Noto Sans Oriya"
  mount  = "noto-sans-oriya"
```

`uswds/hindi-font.html` becomes `uswds/script-font.html`: looks up
`site.Language.Lang` in `params.uswds.scriptFonts`, does nothing if there's no
entry (so `en`/`es` stay untouched), otherwise runs the same publish + preload
loop against `printf "fonts-dist/%s/..." $mount`. `uswds/head.html`'s
`{{ if eq site.Language.Lang "hi" }}` becomes `{{ if isset $scriptFonts
site.Language.Lang }}`.

**SCSS stays hand-written, not generalized.** `_custom.scss`'s two
`@font-face` blocks plus their `:lang()` rules are the kind of small, explicit,
commented additions that file already collects — piping the same table through
`hugo:vars` into a Sass `@each` loop would trade ~15 readable lines for a new
abstraction layer, for a part of the codebase that explicitly favors "additive
and explained" over "generated." Add a third block by hand when a third script
arrives; reconsider only if a fourth one does.

Each fontsource mount (`node_modules/@fontsource/noto-sans-oriya/files` →
`assets/fonts-dist/noto-sans-oriya`) still needs its own `[[module.mounts]]`
line — the mount table itself doesn't get more dynamic, only the code reading
it.

## 4. Everything else, mirroring HINDI.md §2-3

- `package.json`: `@fontsource/noto-sans-oriya` (exact version, matching the
  repo's existing pin style — not `^`).
- `i18n/or.toml` (new, 78 keys — same count as `hi.toml`), plus
  `[language_name_or]` added to `en.toml`, `es.toml`, and `hi.toml`.
- `exampleSite/hugo.toml`: `[languages.or]`, `label = "ଓଡ଼ିଆ"`, `locale =
  "or-in"`, `weight = 4`, full menu (every section gets Odia content, same as
  Hindi). `content/search.or.md` keeps its default slug, same reasoning as
  Hindi's.
- 25 `.or.md` content files, one per existing English page.
- `MULTILINGUAL.md` / `HINDI.md` cross-references updated once this lands, the
  way `MULTILINGUAL.md` §8.5 got a Hindi addendum.
- `README.md`: "English, Spanish, and Hindi" → "...and Odia"; the
  `scriptFonts` table replaces the Hindi-only font paragraph once §3 lands.

## 5. The translation-quality bar is the real risk here, not the code

HINDI.md flagged Hindi's UI/content strings as machine-drafted and
unreviewed. That review still hasn't happened. Odia compounds it:

- **My Odia is measurably weaker than my Hindi.** Hindi is a
  higher-resource language for me; Odia translations I draft carry a real
  chance of being stiff, subtly wrong, or using a register nobody would
  actually publish. Ship them the same way Hindi's shipped — clearly labeled
  "drafted, not reviewed" in `i18n/or.toml`'s header comment and in
  `TODO.md` — but weight the recommendation to get a native speaker to check
  before this is anything but a demo fixture more heavily than Hindi's
  equivalent note.
- **No official USWDS Odia source exists either**, same gap as Hindi — the
  banner/identifier federal wording has to be translated for this repository
  specifically, which is exactly the wording where a wrong register or a
  wrong word is most visible and most likely to matter.
- **Pagefind stems Hindi but not Odia** — checked for both in one pass, as
  this section asked. Pagefind indexes four languages and emits
  `Note: Pagefind doesn't support stemming for the language or-in` for Odia
  and nothing for `hi-in`, so Hindi gets Snowball stemming and Odia gets
  unstemmed word matching. Search still works for Odia; it just will not match
  across root forms, which matters more in a heavily inflected language than
  the note's tone suggests. `check-search.sh` passes either way — its
  assertions are about index completeness and the masthead action, not
  stemming quality. Recorded in MULTILINGUAL.md §8.5, which previously
  asserted the opposite about Hindi.

## 6. Execution order

1. Land §3's `script-font.html` generalization against the EXISTING Hindi
   setup first, as a refactor with no behavior change — verify `npm run
   check` still passes and the Hindi build is pixel-identical before adding
   Odia on top of it.
2. Remove the FONT budget check per §2.
3. `i18n/or.toml` + `language_name_or` entries; `npm run check:i18n`.
4. `[languages.or]` + the Oriya `[[module.mounts]]` line.
5. One test page (`content/_index.or.md`) end to end before translating the
   rest — same reasoning as HINDI.md §3, confirm the font renders and the
   dropdown lists four languages correctly before committing to 25 files.
6. Translate the remaining 24 pages.
7. Full check suite; manual verification pass (font renders, in-page-nav
   still tracks scroll on an Odia doc page, hreflang carries all four
   languages).
8. Update docs per §4's last two bullets.

## 7. Danda spacing: a no-break space before every `।`

Added after the fact, on native-speaker instruction, once the 25 pages
existed. It is the one convention in this rollout that **nothing enforces and
nothing can see.**

Every danda (`।`, U+0964) in `i18n/or.toml` and all 25 `.or.md` files is
preceded by a NO-BREAK SPACE (U+00A0) — 204 of them, no exceptions:

```
...ଆବରି ଥିଲା ।      U+00A0 + U+0964
```

Two separate reasons, and both are needed:

- **Why a space at all.** Odia's aa-kar matra (`ା`, U+0B3E) is very nearly the
  danda's twin. Set tight against the preceding consonant — `ଥିଲା।` — the
  danda reads as a matra hanging off that last letter rather than as a full
  stop. This was the original report: *"otherwise it will look like aakar."*
- **Why non-breaking.** An ordinary space lets the browser wrap between the
  word and the danda, so on some viewport widths a danda lands alone at the
  start of a line. U+00A0 renders identically and forbids that break.

There is no single "space + danda" character; these are two codepoints, and
U+0964 is simply what a danda *is* — shared across Indic scripts, not
something Odia-specific that had to be chosen. Only the space had a decision
in it.

**The trap.** U+00A0 renders exactly like U+0020 in every editor, terminal and
diff. Retyping a sentence silently replaces it and the site still builds, and
the regression only shows up as an occasional orphaned danda on a narrow
viewport. This matters most for the native-speaker review §5 asks for, which is
by definition someone rewriting these sentences. `i18n/or.toml`'s header
carries the same warning for whoever opens that file first.

**`tools/check-danda.sh` enforces it**, in `npm run check`. Two things about
how it is written, both load-bearing:

- **Dandas are classified by script, not by filename.** Each one is attributed
  to the nearest preceding Indic letter on its line — Oriya means check it,
  Devanagari means skip it, because Hindi sets its danda tight by convention
  and must not be "corrected" here. Filename would have been the obvious
  implementation and would have been wrong: `exampleSite/hugo.toml` carries
  Hindi and Odia `description` strings eleven lines apart, and that Odia string
  is exactly the one the first pass over `*.or.md` missed. It was caught by
  reading rendered HTML, which is not a thing a check should require.
- **The repo-root design docs are out of scope.** This section quotes the
  broken form deliberately in order to explain it; a check that failed on its
  own documentation would be its own bug.

The check found a real defect the moment it first ran: the example in
`i18n/or.toml`'s header, the one captioned `<- U+00A0 + U+0964`, was written
with an ordinary space. The convention's own documentation was the first thing
to violate it, which is about as good an argument for mechanical enforcement
as this repository is going to produce.
