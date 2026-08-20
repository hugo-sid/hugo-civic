# Telugu (te) language support

Status: **built.** Telugu ships as a sixth language on `exampleSite`, all 25
English content pages translated. Full-site translation, not a fixture subset,
same as Hindi, Odia and Tamil.

Font: **Noto Sans Telugu via `@fontsource`**, self-hosted, scoped to
`:lang(te)` — back to a Noto after Tamil's exception, but chosen on
measurement rather than on family consistency. Translation quality bar:
**drafted now, flagged for native-speaker review**, same standing as Hindi's,
Odia's and Tamil's strings.

Like TAMIL.md and unlike HINDI.md and ODIA.md, this document was written after
the fact rather than as a plan. Adding a sixth language touched no template,
for the second rollout running. What follows is only what was genuinely new.

`npm run check` passes: no-vendor, build, i18n, danda, assets, utilities,
search and budget.

## 1. What Telugu cost, in full

| File | Change |
| --- | --- |
| `package.json` | `@fontsource/noto-sans-telugu` 5.3.0, exact pin |
| `exampleSite/hugo.toml` | one `[[module.mounts]]`, one `[params.uswds.scriptFonts.te]`, one `[languages.te]` with the full menu |
| `assets/uswds/_custom.scss` | one `@font-face` pair, one `:lang(te)` rule |
| `i18n/te.toml` | new, 79 tables |
| `i18n/{en,es,hi,or,ta}.toml` | `[language_name_te]` added to each |
| `exampleSite/content/**/*.te.md` | 25 files |
| `tools/check-budget.sh` | **unchanged** — see §7 |

No template changed, and unlike Tamil this language did not move a budget
either. The generalisation ODIA.md §3 argued for is now load-bearing twice.

## 2. The font decision: measured, not inherited

Tamil broke the Noto pattern for a reason (TAMIL.md §2), so "it is a Noto"
stopped being an argument. Three faces were compared: **Noto Sans Telugu**,
**Noto Serif Telugu**, and **Hind Guntur** — the Indian Type Foundry face that
stands in the same relation to Telugu that Mukta Malar does to Tamil, and
therefore the one Tamil's own reasoning would have picked.

All measured from the shipped `woff2` at `font-size: 100px`:

| | Noto Sans Telugu | Noto Serif Telugu | Hind Guntur | Public Sans |
| --- | ---: | ---: | ---: | ---: |
| woff2 pair, 400+700 | 73.2 KB | 75.8 KB | 140.8 KB | — |
| x-height | 50.0px | 50.0px | 50.5px | 51.7px |
| aspect ratio | 0.500 | 0.500 | 0.505 | 0.517 |
| క, base consonant | 73.7 × 54.5px | 74.0 × 49.8px | 77.0 × 42.4px | — |
| తెలుగు, advance | 276.2px | 258.6px | 265.8px | — |
| default line box | 135.2px | 188.8px | 135.2px* | 117.5px |
| descent | −48.3px | −48.3px | −77.3px | −22.5px |

\* Hind Guntur's line box is 188.8px; the two Notos share 135.2px exactly.

**Hind Guntur lost on the same axis Mukta Malar nearly lost on.** TAMIL.md §2
flagged "smaller glyphs in a looser line" as what reads like a language sitting
badly on a site, and accepted Mukta Malar's 166.2px line box for a face that
won on how it read. Hind Guntur asks for 188.8px against Public Sans's 117.5px
— 61% looser, deeper than the one already called out — and costs 1.9× the
bytes to do it. Nothing offsets that here.

**Noto Sans and Noto Serif Telugu are metrically identical.** Same x-height,
same aspect ratio, same line box, same descent, 2.6 KB apart. Superfamily
metric harmonisation means the choice between them is *only* texture, which
is what made it worth measuring properly rather than settling on taste.

## 3. Why there is no `font-size-adjust` here

Tamil's `:lang(ta)` carries `font-size-adjust: 0.517` because Mukta Malar's
aspect ratio is 0.468 — 10.5% short of Public Sans, on a page that mixes the
two on every line.

Telugu has the same mixing problem (only the `telugu` subset is published, so
`hugo.toml`, `USWDS`, `HTTPS` and every version number fall through to Public
Sans) and does not have the size problem. Noto Sans Telugu's aspect ratio is
0.500 against Public Sans's 0.517: **3.4% short, where Tamil was 10.5% short.**
Its line box is 135.2px against Public Sans's 117.5px, where Mukta Malar's is
166.2px.

Declaring `font-size-adjust: 0.517` on `:lang(te)` would scale Telugu by 1.034.
That is below the threshold where a mixed Telugu/Latin line reads as uneven,
and it would cost a declaration whose value has to be kept in sync with Public
Sans by hand. **The absence is measured, not skipped** — which is the only
reason it is worth a section.

## 4. The legibility test that chose sans over serif

The serif is the one choice a reader would reasonably expect to be argued for,
so it was tested rather than dismissed. In Telugu "serif" does not mean Latin
serifs; it means stroke modulation, and Telugu readers see modulated letterforms
in print constantly. Familiarity is a real driver of reading speed, and there is
**no credible reading-speed research on Telugu serif vs sans** — the Latin
"serif reads better in print" folklore does not transfer to an abugida. So the
test had to be about rendering mechanics, which are measurable.

Method: rasterise each glyph at 400px/em with a nonzero-winding fill, run an
exact Euclidean distance transform, and sample stroke width along the medial
axis. Identical method for all four faces. Body text on this theme is
`font-size: 1rem` under `html{font-size:100%}` — 16px, not a stand-in.

| | thin (p10) | thick (p90) | contrast | thin @16px | *vattulu* thin @16px | 1px thin at |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Noto Sans Telugu | 0.0743em | 0.0850em | **1.14:1** | **1.19px** | **1.07px** | 13.5px |
| Noto Serif Telugu | 0.0450em | 0.1051em | **2.34:1** | **0.72px** | **0.72px** | 22.2px |
| Hind Guntur | 0.0650em | 0.0800em | 1.23:1 | 1.04px | 0.96px | 15.4px |
| Public Sans (Latin ref) | 0.0640em | 0.0950em | 1.48:1 | 1.02px | — | 15.6px |

Noto Serif Telugu's thin strokes are **0.72px at body size** and do not reach
one full device pixel until about 22px, which on this site is heading territory.
On a 1× display every thin stroke in Telugu body text therefore renders as
partial-coverage grey rather than solid ink. That is not invisibility; it is a
reduction in *effective* contrast, applied selectively to the thinnest strokes.

Which strokes those are is the whole argument. Telugu's minimal pairs turn on
small features — వ/ప, ద/ధ, బ/ఖ — and the subscript conjuncts (*vattulu*) hang
below the baseline at reduced size, which is what that −48.3px descent is for.
The serif thins to 0.72px on the conjuncts too, so the contrast loss lands
hardest on exactly the marks carrying the distinctions. Noto Sans holds 1.07px
there.

Two honest limits. On a 2× display 0.72px is 1.44 device pixels and the effect
largely disappears — this is a 1× concern, which for a public-facing government
site with an older-hardware audience is the case that matters. And the
distance-transform ridge measure is a comparative proxy for stroke width, not a
rendering simulation; it is trustworthy because the same method ran over all
four faces, not because it models any particular rasteriser.

**If the serif's texture is ever wanted, the consistent way to get it is to turn
the theme's serif role back on** — `exampleSite/hugo.toml` sets
`fontTypeSerif = false` and `fontRoleAlt = "sans"`, and `_settings.scss:42-45`
records that switching serif off is "the difference between publishing one font
family and publishing three". A serif Telugu today would be the only serif in
the build, set inline with Public Sans on nearly every page.

## 5. No danda, and that is not an omission

Modern Telugu prose ends a sentence with a full stop, not U+0964, so the
convention that governs every Odia string — a no-break space before every
danda, ODIA.md §7 — has no Telugu equivalent and `tools/check-danda.sh` has
nothing to check in any Telugu file.

The check needed no change to stay correct, for the same reason it needed none
for Tamil: it classifies each danda by the nearest preceding Indic letter and
only acts on Oriya ones, and Telugu (U+0C00-U+0C7F) is not a script it
recognises. Its count is unchanged at **206 dandas** after Telugu landed, which
is the right answer.

**ZWNJ is load-bearing in `i18n/te.toml` and in the content**, and is the one
invisible character convention Telugu does bring. Telugu forms a conjunct across
a virama, so `వెబ్` + `సైట్` renders as a single ligature without U+200C between
them. `వెబ్‌సైట్`, `సైట్‌లో`, `కంటెంట్‌కు` and `ఇన్‌స్పెక్టర్` each carry one.
Deleting them changes the letterforms rather than the spacing — the same class
of silent damage ODIA.md §7 built a check for, and a candidate for one if a
native-speaker review ever rewrites these strings.

## 6. The agency identifier: Telugu sidesteps it, Hindi and Odia still do not

TAMIL.md §6 recorded this and it is unchanged: `chrome/identifier.html` renders
`identifier_content` and *then* the agency's name, because the English sentence
runs "An official website of the `<a>`". Telugu is postpositional and would
have inherited the same defect.

It takes Tamil's answer — a label form that is correct Telugu in the order the
template actually emits. Verified on the built site:

```
en    An official website of the Example Parent Agency
es    Un sitio web oficial de Example Parent Agency
hi    की एक आधिकारिक वेबसाइट Example Parent Agency     ← still backwards
or    ର ଏକ ସରକାରୀ ୱେବସାଇଟ Example Parent Agency        ← still backwards
ta    அதிகாரப்பூர்வ இணையதளம்: Example Parent Agency
te    అధికారిక వెబ్‌సైట్: Example Parent Agency
```

**The real fix, still not done:** pass the agency link into the string as a
template argument so each language positions it itself. It now touches all six
tables and the partial, and it remains a fix to Hindi and Odia rather than part
of a Telugu rollout.

## 7. Telugu needed no budget change, and the reason is not that it is small

`SEARCH_BUDGET_GZ` stays at 126976 B. Telugu is reported at ~40850 B, and Tamil
remains the budgeted language at ~116797 B.

(Every "on the wire" total in this section wobbles by a byte or two between
runs: the index chunks and wasm are counted at their on-disk size, but the
shared client files are gzipped at check time and gzip is not byte-reproducible
here. The index-chunk figures below are on-disk sizes and are stable.)

That gap is not about Telugu's prose. Gzipped index chunks over the same 18
pages put Telugu third of six:

| es-es | en-us | hi-in | or-in | te-in | ta-in |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1386 B | 12515 B | 22421 B | 23083 B | **25812 B** | 30013 B |

The difference is the **wasm**, and it follows from §7.1: a stemmed language
gets its own stemmer build (`en-us` 72209 B, `es-es` 71934, `hi-in` 69894,
`ta-in` 71749) and an unstemmed one shares `wasm.unknown.pagefind` at 68024 B.

### 7.1 Pagefind does **not** stem `te-in`

Checked the way MULTILINGUAL.md §8.5 says to check — by reading Pagefind's own
stderr across the six-language index, not by reasoning from the script:

```
Note: Pagefind doesn't support stemming for the language or-in.
Note: Pagefind doesn't support stemming for the language te-in.
```

**This corrects two documents.** TAMIL.md §7 says Pagefind "names `or-in` and
only `or-in`", and MULTILINGUAL.md §8.5 says "Odia remains this repository's one
unstemmed language". Both were true when written and are not any more: Telugu is
the second. Odia and Telugu search without matching across root forms; English,
Spanish, Hindi and Tamil stem.

Worth noting what this kills as a heuristic. Telugu and Tamil are both Dravidian,
both agglutinative, both South Indian abugidas — and they land on opposite sides
of this line. Hindi stems and Odia does not, though both are Indo-Aryan
Devanagari-adjacent scripts. **No property of the script or the family predicts
it**, which is exactly why the instruction is to read the output.

### 7.2 A defect this exposed in `check-budget.sh`, not fixed here

For an unstemmed language Pagefind writes `"wasm": null` in
`pagefind-entry.json` and ships the shared `wasm.unknown.pagefind`.
`tools/check-budget.sh` builds the path `wasm.$wasm.pagefind` from that field,
so for `or-in` and `te-in` it looks for a file that does not exist, the `[ -f ]`
guard skips it, and **the wasm contributes zero to their reported total.**

The two unstemmed languages are therefore under-reported by 68024 B each:

| | reported | actually fetched |
| --- | ---: | ---: |
| `or-in` | ~38136 B | ~106160 B |
| `te-in` | ~40850 B | ~108874 B |

Nothing about the pass/fail changes — both true figures are under the 126976 B
budget, and `ta-in` at ~116797 B is still the largest partition and still the
language held to it. But the reported numbers for those two are wrong, and the
figures in §7 above are the script's, so they carry the same understatement.

**This is not Telugu's bug.** It has been latent since Odia landed; `or-in` was
simply never close enough to the budget for anyone to look at its number. It is
a one-line fix — fall back to `wasm.unknown.pagefind` when the manifest field is
null — and it belongs in its own commit, on the same reasoning TAMIL.md §6 gave
for the identifier: a language rollout should not quietly ship a fix to a check
that governs every other language.

## 8. Verified on the built site, not assumed

- `<html lang="te-in">`, and `:lang(te)` resolves to the compiled
  `noto sans telugu, Public Sans Web, …` stack with no `font-size-adjust`.
- Both Telugu weights publish (35760 B and 37448 B), and the regular one
  preloads.
- The dropdown lists all six languages from a Telugu page, each endonym in its
  own `lang` span, glossed in Telugu — `English (ఆంగ్లం)`, `தமிழ் (తమిళం)` —
  with the self-naming Telugu entry correctly unglossed and carrying
  `aria-current="page"`.
- The identifier renders `అధికారిక వెబ్‌సైట్: Example Parent Agency`, §6.
- Telugu builds 49 pages, exact parity with Hindi, Odia and Tamil.
- `hreflang` alternates carry all six languages plus `x-default`.
- 18 of 19 regular pages indexed, matching every other full-site language; the
  search results page is correctly excluded.

## 9. One thing to know before running a build

Unchanged from TAMIL.md §9, and still the first thing to check: Hugo needs
`node_modules/.bin` on `PATH` to find Dart Sass. Every script in `tools/`
exports it and `npm run dev` gets it for free, but a bare
`node_modules/.bin/hugo` invocation does not — and when Dart Sass is missing,
that build can **block indefinitely** rather than failing. If a build hangs at
`Start building sites …` with no further output, check for orphaned `hugo`
processes first.
