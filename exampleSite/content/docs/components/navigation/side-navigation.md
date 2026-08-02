---
title: "Side navigation"
description: "The section tree, rendered from the content directory and opened to the page you are on."
weight: 10
in_page_nav: true
in_page_nav_headings: "h2"
---

## Where it comes from

Nothing declares this menu. It is the content directory: every page under the
top-level section, ordered by `weight`, nested exactly as the directories are.
Add a folder with an `_index.md` and it appears.

The nav is rooted at the **top** of the tree rather than at the page's parent.
Rooted at the parent, this page would list only its two siblings, and the rest
of the documentation would disappear the moment you opened a subsection.

## What it renders

| Page position | What you see |
|---|---|
| Sibling | plain link |
| Open section | blue rule, bold |
| Current page | blue text, `aria-current` |

Only the open branch renders its children. Emitting every descendant of every
section would put the whole site in the DOM of every page — a payload cost, and
a screen reader would have to walk all of it.

## Depth

This page sits three levels down — Documentation, Components, Navigation — and
the branch above it is open on the left. The partial recurses without a depth
limit; USWDS styles the indentation to three levels of sublist.

{{< alert type="info" title="Section index pages keep the nav too" >}}
Clicking a subsection in the sidenav lands on its index page. That page is a
list, not an article, but it renders the same tree — otherwise navigation would
vanish exactly where a reader is most likely to be looking for it.
{{< /alert >}}
