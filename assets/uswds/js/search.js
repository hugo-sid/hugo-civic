// The search client.
//
// Pagefind is a POST-BUILD indexer: it reads the finished HTML in public/ after
// Hugo has exited and writes public/pagefind/. So /pagefind/pagefind.js does
// not exist while Hugo is running — it cannot be resources.Get'd, cannot be
// fingerprinted, and cannot be bundled. It is loaded below with a runtime
// dynamic import, and uswds/search-assets.html is what tells js.Build to leave
// that specifier unresolved. Forget that and the BUILD fails, not the page.
// See DESIGN.md §15.
//
// Everything user-visible comes from the page: layouts/search.html renders the
// markup and hands the translated strings over as data attributes on #js-search,
// because this file is compiled once and served to every language.
//
// The DOM contract with that template — change one, change the other:
//
//   #js-search           root; carries data-* config and the strings
//   #search-field-page   the query input (chrome/search renders it)
//   #search-status       role="status"; the count line and the only announcer
//   #search-results      where the usa-collection goes
//   #search-unavailable  the "no index" alert, hidden with .display-none

const PAGEFIND_SCRIPT = "/pagefind/pagefind.js";

// Long enough that typing a word is one query rather than five, short enough
// that it still feels like it is keeping up.
const DEBOUNCE_MS = 200;

const root = document.getElementById("js-search");
const input = document.getElementById("search-field-page");
const status = document.getElementById("search-status");
const output = document.getElementById("search-results");
const unavailable = document.getElementById("search-unavailable");

if (root && input && status && output) {
  const s = root.dataset;
  const pageSize = parseInt(s.pageSize, 10) || 10;
  const lang = document.documentElement.lang || undefined;

  // null = not tried yet, false = tried and failed, otherwise the module.
  let pagefind = null;
  let results = [];
  let shown = 0;

  // Every render is awaited, so a fast second query can finish while a slow
  // first one is still resolving its fragments. Each run takes a ticket and
  // anything holding a stale one throws its work away.
  let ticket = 0;

  let timer = null;

  // --- rendering ---------------------------------------------------------

  const el = (tag, className, text) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  };

  // Pagefind's excerpt is the only string here that is allowed to carry markup,
  // and the only markup it is allowed to carry is <mark>. Escaping the whole
  // thing and then putting those two tags back is cheaper than trusting the
  // indexer's escaping, and it fails closed.
  const excerptHTML = (text) => {
    const box = document.createElement("div");
    box.textContent = text || "";
    return box.innerHTML
      .replace(/&lt;mark&gt;/g, "<mark>")
      .replace(/&lt;\/mark&gt;/g, "</mark>");
  };

  // "2026-01-08" -> the same long form the collection partial renders. Parsed
  // with an explicit time so it is local midnight rather than UTC midnight,
  // which west of Greenwich would print the previous day.
  const formatDate = (value) => {
    const date = new Date(`${value}T00:00:00`);
    if (isNaN(date)) return null;
    return date.toLocaleDateString(lang, {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  // A result renders as a usa-collection__item, matching
  // _partials/components/collection.html element for element. That is the whole
  // reason this is the JS API and not pagefind-ui: the component is already
  // compiled into the stylesheet, so the CSS cost of search is one rule for
  // <mark>.
  const renderResult = (data) => {
    const item = el("li", "usa-collection__item");
    const body = el("div", "usa-collection__body");

    const heading = el("h3", "usa-collection__heading");
    const link = el("a", "usa-link", (data.meta && data.meta.title) || data.url);
    link.href = data.url;
    heading.append(link);
    body.append(heading);

    if (data.excerpt) {
      const p = el("p", "usa-collection__description");
      p.innerHTML = excerptHTML(data.excerpt);
      body.append(p);
    }

    const meta = data.meta || {};
    const date = meta.date ? formatDate(meta.date) : null;
    if (date || meta.section) {
      const list = el("ul", "usa-collection__meta");
      list.setAttribute("aria-label", s.moreInformation);
      if (meta.section) {
        list.append(el("li", "usa-collection__meta-item", meta.section));
      }
      if (date) {
        const li = el("li", "usa-collection__meta-item");
        const time = el("time", null, date);
        time.setAttribute("datetime", meta.date);
        li.append(time);
        list.append(li);
      }
      body.append(list);
    }

    const tags = (data.filters && data.filters.tags) || [];
    if (tags.length) {
      const list = el("ul", "usa-collection__meta");
      list.setAttribute("aria-label", s.topics);
      tags.forEach((tag) => {
        list.append(el("li", "usa-collection__meta-item usa-tag", tag));
      });
      body.append(list);
    }

    item.append(body);
    return item;
  };

  const clear = () => {
    output.textContent = "";
    shown = 0;
  };

  // Appends the next page of results, and the button that asks for the one
  // after it. Pagefind returns every match at once and each result's data() is
  // a separate fragment fetch, so "results per page" is what stops a
  // three-letter query from pulling the entire site down.
  const renderNextPage = async (mine) => {
    const slice = results.slice(shown, shown + pageSize);
    const data = await Promise.all(slice.map((r) => r.data()));
    if (mine !== ticket) return;

    const existing = output.querySelector(".usa-collection");
    const list = existing || el("ul", "usa-collection");
    data.forEach((d) => list.append(renderResult(d)));

    const oldButton = output.querySelector("button");
    if (oldButton) oldButton.remove();
    if (!existing) output.append(list);

    shown += data.length;
    if (shown < results.length) {
      const more = el(
        "button",
        "usa-button usa-button--outline margin-top-2",
        s.loadMore,
      );
      more.type = "button";
      more.addEventListener("click", () => {
        more.disabled = true;
        renderNextPage(ticket);
      });
      output.append(more);
    }
  };

  const showCount = (n) => {
    const tpl = n === 1 ? s.countOne : s.countOther;
    status.textContent = tpl.replace("%d", String(n));
  };

  const showNoResults = (query) => {
    status.textContent = "";
    const token = "%s";
    const at = s.noResults.indexOf(token);
    if (at === -1) {
      status.textContent = s.noResults;
    } else {
      const strong = el("strong", null, query);
      status.append(
        s.noResults.slice(0, at),
        strong,
        s.noResults.slice(at + token.length),
      );
    }
    if (s.noResultsHint) {
      output.append(el("p", "margin-top-1", s.noResultsHint));
    }
  };

  // No index. The common cause is `hugo server`, where pagefind has never run —
  // which is the state every contributor sees first. It is a fact about the
  // deployment, not a fault, so it is reported on the page rather than in the
  // console, and the status line carries it too because that is the only region
  // a screen reader is listening to.
  const showUnavailable = () => {
    clear();
    if (unavailable) unavailable.classList.remove("display-none");
    // The alert says this in full, so repeating it as a grey line above the
    // alert is noise. usa-sr-only clips rather than un-renders, so the live
    // region stays in the accessibility tree and still announces — which is
    // the whole reason the message is set here at all.
    status.classList.add("usa-sr-only");
    status.textContent = s.unavailable || "";
  };

  // --- searching ---------------------------------------------------------

  const loadPagefind = async () => {
    if (pagefind !== null) return pagefind;
    try {
      const mod = await import(PAGEFIND_SCRIPT);
      // A site published under a subdirectory serves public/ at that prefix,
      // but Pagefind indexed it as the root and its URLs start at "/". This is
      // the supported way to put the prefix back; doing it here rather than
      // with --base-url keeps the flag out of every adopting site's build
      // command.
      if (s.baseUrl && s.baseUrl !== "/") {
        await mod.options({ baseUrl: s.baseUrl });
      }
      await mod.init();
      pagefind = mod;
    } catch (e) {
      // Reported by the caller, not here: this runs once, and every query
      // after it gets the cached `false` without entering the catch. Reporting
      // here would leave the second search sitting on "Searching…" forever.
      pagefind = false;
    }
    return pagefind;
  };

  const run = async (query) => {
    const mine = ++ticket;
    const trimmed = query.trim();
    status.classList.remove("usa-sr-only");

    if (!trimmed) {
      clear();
      status.textContent = s.prompt || "";
      return;
    }

    status.textContent = s.searching || "";

    const api = await loadPagefind();
    if (mine !== ticket) return;
    if (!api) {
      showUnavailable();
      return;
    }

    const found = await api.search(trimmed);
    if (mine !== ticket) return;

    results = found.results;
    clear();

    if (!results.length) {
      showNoResults(trimmed);
      return;
    }

    showCount(results.length);
    await renderNextPage(mine);
  };

  // The query stays in the URL so a result set can be linked and reloaded.
  // replaceState, not pushState: a debounced keystroke is not a navigation, and
  // pushing one per word would bury the page the reader arrived from under a
  // dozen history entries.
  const syncUrl = (query) => {
    const url = new URL(window.location.href);
    if (query) {
      url.searchParams.set("q", query);
    } else {
      url.searchParams.delete("q");
    }
    window.history.replaceState(null, "", url);
  };

  const schedule = () => {
    window.clearTimeout(timer);
    timer = window.setTimeout(() => {
      syncUrl(input.value.trim());
      run(input.value);
    }, DEBOUNCE_MS);
  };

  input.addEventListener("input", schedule);

  // Submitting must not reload: the page it would load is this one, minus the
  // results it just discarded. The form keeps working without JS, which is the
  // point of leaving it a real form.
  if (input.form) {
    input.form.addEventListener("submit", (event) => {
      event.preventDefault();
      window.clearTimeout(timer);
      syncUrl(input.value.trim());
      run(input.value);
    });
  }

  // Arriving from the masthead: /search/?q=… is a GET from a form on another
  // page, so the query is in the URL and nothing has been typed here yet.
  const initial = new URL(window.location.href).searchParams.get("q");
  if (initial) {
    input.value = initial;
    run(initial);
  }
}
