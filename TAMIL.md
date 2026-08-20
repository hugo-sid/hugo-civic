# Tamil (ta) language support

Status: **built.** Tamil ships as a fifth language on `exampleSite`, all 25
English content pages translated. Full-site translation, not a fixture subset,
same as Hindi and Odia.

Font: **Mukta Malar via `@fontsource`**, self-hosted, scoped to `:lang(ta)` —
the first script here **not** set in a Noto face. Translation quality bar:
**drafted now, flagged for native-speaker review**, same standing as Hindi's
and Odia's strings.

Unlike HINDI.md and ODIA.md, this document was written after the fact rather
than as a plan. Hindi and Odia had already paid for everything structural: the
`params.uswds.scriptFonts` table, `uswds/script-font.html`, the three-or-more
language dropdown, and the removal of the FONT budget. Adding a fifth language
touched no template. What follows is only what was genuinely new.

`npm run check` passes: no-vendor, build, i18n, danda, assets, utilities,
search and budget.

## 1. What Tamil cost, in full

| File | Change |
| --- | --- |
| `package.json` | `@fontsource/mukta-malar` 5.3.0, exact pin |
| `exampleSite/hugo.toml` | one `[[module.mounts]]`, one `[params.uswds.scriptFonts.ta]`, one `[languages.ta]` with the full menu |
| `assets/uswds/_custom.scss` | one `@font-face` pair, one `:lang(ta)` rule (see §3) |
| `i18n/ta.toml` | new, 78 tables |
| `i18n/{en,es,hi,or}.toml` | `[language_name_ta]` added to each |
| `exampleSite/content/**/*.ta.md` | 25 files |
| `tools/check-budget.sh` | `SEARCH_BUDGET_GZ` raised, see §7 |

No template changed. That is the whole point of the generalisation ODIA.md §3
argued for, arriving one language later.

## 2. The font decision: Mukta Malar, not a third Noto

Tamil is the first script here where the obvious choice was not taken. Noto
Sans Tamil exists, is in the same superfamily as the Devanagari and Oriya faces
already shipping, and is less than half the size — 28.7 KB for both weights
against Mukta Malar's 64.3 KB. It was compared side by side against Mukta Malar
(Ek Type) at the sizes this theme actually sets, in the strings this theme
actually renders, and Mukta Malar was chosen on how it reads.

Measured from the shipped `woff2` files at `font-size: 100px`:

| | Noto Sans Tamil | Mukta Malar | Public Sans |
| --- | ---: | ---: | ---: |
| க, base consonant | 56.6px | 50.2px | — |
| ர | 76.6px | 66.8px | — |
| தமிழ், whole word | 116.4 × 280.3px | 103.0 × 233.3px | — |
| x-height | 55.4px | 46.8px | 51.7px |
| default line box | 124px | 166.2px | 117.5px |

Two facts in that table are load-bearing and neither is visible by eye:

- **Mukta Malar sets 11-13% smaller and 17% narrower than Noto Sans Tamil at
  the same `font-size`**, while asking for a line box a third taller. Smaller
  glyphs in a looser line is exactly the combination that reads as "this
  language looks small on this site". §3 is what answers it.
- **Neither face matches Public Sans on its own.** Noto's base consonant
  overshoots Public Sans's x-height by 7%, Mukta's undershoots it by 5%. Every
  Tamil page mixes the two on one line — `hugo.toml`, `USWDS`, `HTTPS` and
  every version number fall through to Public Sans, because only the `tamil`
  subset of the family is published — so the pairing, not the face alone, is
  what had to be judged.

## 3. `font-size-adjust`, the one declaration no other script here needs

```scss
:lang(ta) {
  font-family: "Mukta Malar", #{get-font-stack("body")};
  font-size-adjust: 0.517;
}
```

`0.517` is Public Sans's own aspect ratio (`xHeight 1034 / unitsPerEm 2000`).
Declaring it scales Mukta Malar up by `0.517 / 0.468 = 1.105`, which is exactly
the 10.5% it was short, and leaves the Latin runs untouched — their font's
aspect ratio already *is* 0.517, so the adjustment resolves to a no-op for
them. It does not compound through nested elements the way a `font-size` in
`em` would, which is the reason a size bump on `:lang(ta)` was not used
instead.

A browser without `font-size-adjust` support renders the unadjusted face:
slightly small, entirely legible. Deleting the one line is the whole rollback.

## 4. Translation quality, same bar as Hindi and Odia

`i18n/ta.toml` and all 25 `.ta.md` pages were translated for this repository
and **have had no native-speaker review**. USWDS publishes no official Tamil
translation of the federally standardised banner and identifier wording, so
even those strings — the ones where a wrong register is most visible and
matters most — are drafts.

Register aimed for: ordinary written Tamil a government site would publish, not
high literary Tamil. Where a technical term has no settled Tamil equivalent a
reader would recognise faster than the English (`JavaScript`, `FOIA`, `HTTPS`,
`.gov`, `USA.gov`), the English is kept — translating it makes the string
harder to act on, not easier.

## 5. No danda, and that is not an omission

Tamil does not use U+0964. It ends sentences with a full stop, so the
convention that governs every Odia string — a no-break space before every
danda, ODIA.md §7 — has no Tamil equivalent and `tools/check-danda.sh` has
nothing to check in any Tamil file.

The check needed no change to stay correct. It classifies each danda by the
nearest preceding Indic letter and only acts on Oriya ones, so Tamil letters
(U+0B80-U+0BFF) are simply not a script it recognises. Its count is unchanged
at 206 dandas across 176 files after Tamil landed, which is the right answer.

## 6. The agency identifier reads backwards in Hindi and Odia

Found while writing `i18n/ta.toml`, and it is **not a Tamil bug** — Tamil is
just the language that made it obvious.

`chrome/identifier.html` renders `identifier_content` and *then* the agency's
name, because the English sentence runs "An official website of the `<a>`".
Hindi and Odia both translated the tail of that English sentence, so the
rendered result is:

```
en    An official website of the Example Parent Agency
es    Un sitio web oficial de Example Parent Agency
hi    की एक आधिकारिक वेबसाइट Example Parent Agency
or    ର ଏକ ସରକାରୀ ୱେବସାଇଟ Example Parent Agency
```

English and Spanish are prepositional and read correctly. Hindi and Odia are
postpositional: the postposition sits in front of the word it governs, which is
not a sentence in either language. No i18n string can fix it, because no string
can reorder a template.

Tamil is postpositional too and would have inherited the same defect. It
sidesteps it with a label form that is correct Tamil in the order the template
emits — `அதிகாரப்பூர்வ இணையதளம்: <agency>` — rather than reproducing the fault
in a third language.

**The real fix, not done here:** pass the agency link into the string as a
template argument, so each language positions it itself.

```go-html-template
{{ i18n "identifier_content" (dict "agency" $link) | safeHTML }}
```

That touches all five tables and the partial, and belongs in its own change
with its own review — it is a fix to Hindi and Odia, which is not what a Tamil
rollout should quietly ship.

## 7. Tamil is a bigger language to index

`tools/check-budget.sh`'s `SEARCH_BUDGET_GZ` went from 110592 B to 126976 B.
Tamil measured 116780 B, which is 105% of the old budget and 91% of the new
one.

It is not a regression. Gzipped index chunks over the same 18 pages:

| es-es | en-us | hi-in | or-in | ta-in |
| ---: | ---: | ---: | ---: | ---: |
| 1432 B | 12561 B | 22467 B | 23129 B | 30059 B |

The wasm is flat across all of them — `ta-in` 71802 B, between `hi-in`'s 69947
and `en-us`'s 72262 — so the entire difference is the index itself. Tamil is
agglutinative: case, number and postpositions attach to the noun rather than
standing as separate words, so identical prose yields far more distinct surface
forms to index, and no tuning here makes that smaller.

The budget was raised rather than removed, unlike the FONT budget in ODIA.md
§2. A font family's size is fixed by the script and can only be paid once; an
index can still bloat by indexing pages it should not, which is a regression
worth catching.

**Pagefind stems `ta-in`.** Checked the way MULTILINGUAL.md §8.5 says to check
— by reading Pagefind's own stderr across the five-language index, not by
reasoning from the script. It names `or-in` and only `or-in`. Odia remains this
repository's one unstemmed language.

## 8. Verified on the built site, not assumed

- `<html lang="ta-in">`, and `:lang(ta)` resolves to the compiled
  `mukta malar, Public Sans Web, …` stack with `font-size-adjust: .517`.
- Both Tamil weights publish (31380 B and 34512 B), and the regular one
  preloads.
- The dropdown lists all five languages from a Tamil page, each endonym in its
  own `lang` span, glossed in Tamil — `English (ஆங்கிலம்)`, `ଓଡ଼ିଆ (ஒடியா)` —
  with the self-naming Tamil entry correctly unglossed and carrying
  `aria-current="page"`.
- Tamil builds 49 pages, exact parity with Hindi and Odia.
- `hreflang` alternates carry all five languages plus `x-default`.

## 9. One thing to know before running a build

Hugo needs `node_modules/.bin` on `PATH` to find Dart Sass. Every script in
`tools/` exports it and `npm run dev` gets it for free, but a bare
`node_modules/.bin/hugo` invocation does not — and when Dart Sass is missing,
that build can **block indefinitely** rather than failing. Two such builds left
running will also wedge a `hugo server` started later. If a build hangs at
`Start building sites …` with no further output, check for orphaned `hugo`
processes first.
