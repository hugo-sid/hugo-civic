// Fixes the ids usa-in-page-navigation assigns to headings whose text is not
// Latin script.
//
// The component's own id generator (packages/usa-in-page-navigation/src/index.js,
// getHeadingId) does `.replace(/[^a-z\d]/g, "-")` on the heading's text — it
// keeps only ASCII letters and digits. A heading written entirely in
// Devanagari (or any non-Latin script) reduces to an empty string; several
// such headings on one page all reduce to the SAME empty id. The scroll-spy
// (setActive, in the same file) looks up the link to highlight with
// `a[href="#${id}"]`, so an empty or duplicate id means the wrong link
// highlights, or none does — "On this page" stops tracking scroll position on
// exactly the pages this theme's multilingual support exists to serve.
//
// This is upstream USWDS behaviour, not a template bug, and getHeadingId is
// not exported — there is nothing in the component's public surface to
// configure or override. Rewriting the whole file to fix one function would
// mean vendoring USWDS source, which this theme deliberately does not do (see
// README's "zero copied USWDS source"). So this runs AFTER the component has
// already inserted its (possibly broken) anchors and links, and repairs them
// in place instead: every heading Hugo rendered already carries a real,
// page-unique id — the same one the "On this page" link's TEXT was already
// generated from newly, just not its href — so this substitutes that id back
// in, matching anchors to links by their shared DOM order rather than by
// searching for the (potentially colliding) id the component generated.
export default function fixInPageNavHeadingIds(root = document) {
  root.querySelectorAll(".usa-in-page-nav-container").forEach((container) => {
    const anchors = Array.from(
      container.querySelectorAll("main .usa-anchor"),
    );
    const links = Array.from(
      container.querySelectorAll(".usa-in-page-nav__link"),
    );

    anchors.forEach((anchor, i) => {
      const heading = anchor.parentElement;
      const link = links[i];
      if (!heading || !heading.id || !link) return;
      if (anchor.id === heading.id) return;

      anchor.id = heading.id;
      link.setAttribute("href", `#${heading.id}`);
    });
  });
}
