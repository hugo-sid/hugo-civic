---
title: "In-page navigation"
description: "The 'On this page' list, built at runtime from the headings in the body."
weight: 30
in_page_nav: true
in_page_nav_headings: "h2"
---

## Turning it on

It is front matter, not a shortcode:

```yaml
in_page_nav: true
in_page_nav_headings: "h2"
```

A shortcode can only render inside `main`, and this component has to be a
sibling of `main` for the two to lay out side by side. Front matter is the only
place the decision can be made in time.

## Choosing which headings

USWDS scans `h2` and `h3` by default, which sweeps up headings that belong to
*components* — a summary box's `h3` shows up as if it were a section of the
document. On a page using components, narrow it to `h2`.

| Parameter | Effect |
|---|---|
| `in_page_nav_headings` | which levels to scan |
| `in_page_nav_title` | heading above the list |
| `in_page_nav_min_headings` | hide below this count |

The list is built by JavaScript from the rendered headings, so with JS off there
is no list — which is correct, because the headings themselves are still there
and still in order.
