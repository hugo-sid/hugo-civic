# Pagefind search — implementation plan

Closes the first half of TODO §1's *"Fix or disable the search box"*: the header
form GETs `/search/?q=` today and no template answers it, so every page in the
site links to a 404.

Pagefind 1.5.2. Status: planned, nothing built.

---

## 1. Shape of the solution

Pagefind is a **post-build** indexer. It reads the finished HTML in
`exampleSite/public/`, after Hugo has exited, and writes `public/pagefind/` —
`pagefind.js`, a wasm blob, and content-hashed index and fragment chunks. Hugo
never sees any of it.

So the theme ships templates and a client; the **site owner runs one extra
build step**. Two decisions follow from that, and both are load-bearing.

### 1.1 The JS API, not `pagefind-ui`

Pagefind ships a drop-in UI (`pagefind-ui.js` + `pagefind-ui.css`). Using it
would mean:

- ~10 KB of vendored CSS that this theme has spent DESIGN.md §4.1 avoiding,
  styling a component USWDS also styles, in a cascade where neither owns the
  result;
- markup that matches no USWDS contract, in a theme whose entire testing story
  (`tools/check-utilities.sh`, `tools/check-assets.sh`) assumes the markup came
  from one;
- a second search input on the page with different behaviour to the one in the
  masthead.

Instead: call the JS API directly and render results as `usa-collection`
markup. `usa-collection` is already in the `standard` preset
(`assets/uswds/presets/_standard.scss:28`), already compiled, already used by
`list.html`. **The CSS cost of this feature is one rule for `<mark>`.**

### 1.2 Pagefind's assets cannot go through Hugo's pipeline

`/pagefind/pagefind.js` does not exist when Hugo runs. It cannot be
`resources.Get`'d, cannot be fingerprinted, cannot be bundled.

The client therefore loads it with a runtime dynamic import:

```js
const pagefind = await import("/pagefind/pagefind.js");
```

and `js.Build` **must be told not to resolve that specifier**, or esbuild fails
the build with an unresolved import:

```go-html-template
{{ $js := resources.Get "uswds/js/search.js" | js.Build (dict
     "externals" (slice "/pagefind/pagefind.js")
     "minify" hugo.IsProduction
     "target" "es2018") }}
```

This is the single non-obvious constraint in the whole feature and it belongs in
DESIGN.md, not in a comment.

### 1.3 Degradation

Three states, all reachable in normal use:

| State | Cause | Behaviour |
| --- | --- | --- |
| No JS | user, or a script error | The masthead form still GETs `/search/?q=`. The page renders, explains that search needs JavaScript, and offers the section index. Nothing is broken, nothing lies. |
| No index | `hugo server` — pagefind has never run | `import()` rejects. Catch it and render a `usa-alert--info`: the index is built at deploy time. **Not** a console error. |
| Index present | production | Results. |

This matches the progressive-enhancement position in DESIGN.md §6.2.

---

## 2. Files

### New

| Path | What it is |
| --- | --- |
| `layouts/search.html` | Results page. `usa-search--big` form, `aria-live="polite"` results region, `role="status"` count line, `usa-alert` fallbacks. Carries `data-pagefind-ignore` so the search page never indexes itself. |
| `assets/uswds/js/search.js` | The client. Parses `?q=`, debounces input, `history.replaceState`s the query so results stay linkable, renders `usa-collection__item` nodes matching `_partials/components/collection.html:15-56` exactly. Lazy: the wasm downloads on first keystroke, not on page load. |
| `layouts/_partials/uswds/search-assets.html` | Builds `search.js` with the `externals` above; fingerprints in production, mirroring `_partials/uswds/js.html:40-45`. |
| `exampleSite/content/search.md` | `layout: search`, `sidenav: false`. |
| `tools/check-search.sh` | Build → run pagefind → assert the fragment count equals the number of regular pages, and that no list/taxonomy/search page is among them. Wired into `npm run check`. |

### Modified

| Path | Change |
| --- | --- |
| `layouts/single.html:63` | `<main id="main-content" class="usa-prose" data-pagefind-body>`, suppressed by front matter `search = false`. Plus `data-pagefind-meta` for section and date, `data-pagefind-filter` for tags. |
| `layouts/_partials/chrome/search.html:12` | Default `action` to the configured search page, `relLangURL`'d. `header.searchAction` keeps overriding it for the external-search case. |
| `hugo.toml`, `exampleSite/hugo.toml` | New `[params.uswds.search]` block — see §3. |
| `i18n/en.toml`, `i18n/es.toml` | Result count (`one`/`other`, like the existing `item_count`), no-results, searching, index-unavailable, needs-JavaScript. |
| `assets/uswds/_custom.scss` | One additive rule styling `mark` in excerpts, using USWDS colour tokens so it survives retheming. |
| `package.json` | `pagefind@1.5.2` as a devDependency. `build` becomes `hugo --minify && pagefind --site public`. New `check:search`. |
| `tools/vercel-build.sh` | `PAGEFIND_VERSION=1.5.2` alongside the Hugo/Dart Sass/Node pins, then `npx -y pagefind@$PAGEFIND_VERSION --site public` after `hugo build`. |
| `vercel.json` | A `/pagefind/(.*)` cache header. |
| `TODO.md` §1, `README.md`, `DESIGN.md` | See §6. |

Why npx on Vercel rather than the devDependency: `vercel-build.sh` installs
`--omit=dev` deliberately (it would otherwise pull ~60 MB of hugo-extended and
sass-embedded that the downloaded tarballs already provide). The version pin
gets the same *"keep them in step"* note the other three pins carry.

---

## 3. Configuration surface

```toml
[params.uswds.search]
  # "pagefind" | "none" | "external"
  #
  # "none" hides the masthead search entirely — the honest setting for a site
  # that has not wired up an indexer, and better than today's silent 404.
  # "external" keeps the form and posts it at header.searchAction.
  provider = "pagefind"

  # Where the results template lives. The masthead form's action defaults here.
  page = "/search/"

  resultsPerPage = 10
```

`params.uswds.header.search` (bool) stays as the "is there a box in the
masthead" switch. `provider` is "what happens when you submit it". They are
genuinely different questions — an extended header with no search box is a
layout choice, and a site with no index is a deployment fact.

---

## 4. What gets indexed

`data-pagefind-body` on single pages only. This is not a partial measure —
once **any** page in a build carries that attribute, Pagefind excludes every
page that does not. So one attribute in `single.html` gets, for free:

- list pages excluded (a section index is a list of titles that are all
  themselves results — indexing it puts every section in every result set);
- taxonomy and term pages excluded, for the same reason;
- `404.html` excluded;
- the search page excluded.

Per-page opt-out is `search = false` in front matter, in the same spirit as the
rest of the article furniture: a no-op where it is not set.

Metadata captured explicitly, because the defaults are a guess:

- `data-pagefind-meta="date"` — Pagefind cannot know which of several dates on
  the page is the published one;
- `data-pagefind-meta="section"` — so a result can say where it came from;
- `data-pagefind-filter="tags"` — indexing filters is nearly free even if
  nothing renders them yet.

A faceted filter UI is deliberately **not** in this plan. USWDS's checkbox
group would do it, but it is a second feature and the results list should be
proven first.

---

## 5. Order of work

1. **Config surface + `chrome/search.html` wiring.** After this step the
   masthead form no longer points at a 404 in any configuration, even though
   results do not work yet. `provider = "none"` alone closes the TODO item.
2. **`search.html` + `search.js` + i18n.** Verify on `hugo server` that the
   missing-index path renders the alert and not a console error — that is the
   state every contributor sees first, so it is the one most worth getting
   right.
3. **`data-pagefind-body` + local index.** Run pagefind; confirm the fragment
   count equals the regular-page count and that no list, taxonomy or search
   page appears.
4. **Deployment: `package.json`, `vercel-build.sh`, `vercel.json`.** Push a
   preview and confirm `trailingSlash: true` does not rewrite the
   `.pf_fragment` / `.pf_index` fetches. **This is the one risk that cannot be
   verified locally.**
5. **`tools/check-search.sh` into `npm run check`.** Re-run `check:budget` and
   `check:assets`.
6. **Docs** — DESIGN.md §15, README Configuration subsection, TODO §1 ticked.

---

## 6. Documentation to write

- **DESIGN.md §15**, covering: why the JS API and not `pagefind-ui`; why the
  import is `externals` and what happens if you forget; why `data-pagefind-body`
  on single pages excludes everything else; why the index is a post-build step
  a theme cannot perform on a downstream site's behalf.
- **README**, under Configuration: the `[params.uswds.search]` block, and the
  build step a site adopting the theme has to add. This is the part that is
  easy to underdocument — the theme works on Vercel because
  `tools/vercel-build.sh` was edited, and a site copying the theme gets the
  templates but not that script.
- **TODO.md §1** — tick the item; note that provider `"none"` is the escape
  hatch for a site that does not want an indexer.

---

## 7. Open questions and known gaps

### 7.1 The budgets do not see this

`tools/check-budget.sh` measures `public/css`, `public/js` and `public/fonts`.
Pagefind's wasm (~50 KB gzip) and index chunks land in `public/pagefind/` and
are invisible to it.

That is defensible — they are fetched only on `/search/`, and only after a
keystroke, so the core tier that loads on every page is genuinely unchanged.
But a theme that enforces size budgets should not have a blind spot in it. Add
a fourth budget line covering the search page's total transfer in step 5.

### 7.2 Multilingual is nearly free, and would ship unverified

Pagefind partitions its index by `<html lang>`, which `baseof.html:2` already
sets from `site.Language.Locale`, and the JS API selects the right partition
from `document.documentElement.lang` without configuration.

The theme has `i18n/es.toml`, but exampleSite publishes one language — so this
would ship on reasoning rather than evidence. Fix by adding a second language
to the example site, or state the limitation in the README. Do not leave it
implied.

### 7.3 A CSP would need `wasm-unsafe-eval`

`vercel.json` sets security headers but no `Content-Security-Policy` today, so
nothing breaks now. Anyone adding one later needs `script-src ...
'wasm-unsafe-eval'` or search stops working, with an error that does not
obviously point at the CSP. Worth a line in the deployment docs.

### 7.4 Cache headers are not the `/css/` treatment

Pagefind's index and fragment filenames are content-hashed, but
`pagefind-entry.json` is not — it changes on every build and is the file that
points at all the others. So `/pagefind/(.*)` gets `max-age=86400`, **not** the
`immutable` header `/css/` and `/js/` carry. Getting this wrong serves a stale
entry file that points at fragments which no longer exist, and search fails
silently for the length of the cache.
