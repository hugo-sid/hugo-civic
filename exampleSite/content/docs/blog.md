---
title: "Blog and news"
description: "What a section of dated articles gets for free, and the three settings that control it."
weight: 30
in_page_nav: true
in_page_nav_headings: "h2"
---

Any section of dated pages behaves as a news section — there is no separate
layout to opt into. The `/news/` section on this site is an ordinary content
directory; everything below comes from front matter and config.

## Article front matter

```yaml
---
title: "Section 508 audit results published"
date: 2026-06-30
author: "Digital Services"
tags: ["Accessibility", "Performance"]
description: "Findings from the annual audit, with remediation dates."
image: "img/og-news.png"
imageAlt: "Example Agency news"
---
```

`date`, `author` and `tags` render as a byline under the title. Each is
optional and the byline disappears entirely when all three are absent, which is
why documentation pages — like this one — do not show one.

`lastmod` adds an "Updated" date, but only when it is genuinely later than
`date`. Hugo defaults `lastmod` to `date`, so an unchanged page stays quiet.

Topics link to their term page. Where those links go is decided by the
taxonomy, not by the byline.

## Listing style

A section chooses how its listing renders from its `_index.md`:

```yaml
---
title: "News"
collection_variant: "cards"     # "" | condensed | calendar | media | cards
card_grid: "tablet:grid-col-6 desktop:grid-col-4"   # cards only
---
```

`cards` renders a `usa-card-group`. Each post becomes a card carrying its first
tag as a kicker, its image if it has one, its description, and its byline —
the shape USWDS's own site gives a news item, expressed through the card
component. The heading links to the post and the footer button repeats the
link, labelled with the title so a screen reader reading links out of context
does not meet a column of identical "Read more"s.

Everything else is a `usa-collection`: the default, `condensed` for long
lists, `calendar` for a date block, `media` for a thumbnail. Cards suit a short
feed with images; a collection stays readable at a hundred entries.

## Pagination

Listing pages paginate at Hugo's `[pagination]` setting:

```toml
[pagination]
  pagerSize = 5
```

Sections shorter than one page render no control at all, and the entries keep
their URLs — pagination is not something a small section pays for. Set
`pagerSize` high to switch it off.

## One onward block, not three

An article ends with exactly one way forward: **related content** when the
related-content index finds matches, **previous / next** when it does not.

That is a deliberate limit rather than a missing feature. An article carrying a
side nav listing every sibling, a previous/next pair drawn from those same
siblings, and a related list drawn from them again is not three times the
navigation — it is one decision put to the reader three times.

The split follows the content. A dated feed has no order worth reading in, so
"more like this" is the useful offer; a documentation tree is ordered, so
"the next one along" is. Sections opt out of the side navigation from their
`_index.md`:

```yaml
---
title: "News"
cascade:
  sidenav: false
---
```

Documentation sections leave `sidenav` unset and keep the tree.

## Related content

Related content needs an index configured in **your site's** config, not the
theme's: Hugo ships a built-in `[related]` default, and a theme's config can
only add to it, never replace it. Until you copy the block below, articles fall
back to previous/next links.

```toml
[related]
  threshold = 80
  includeNewer = true

  [[related.indices]]
    name = "tags"
    weight = 100
  [[related.indices]]
    name = "date"
    weight = 10
```

`includeNewer = true` is worth keeping. Hugo's default of `false` looks only at
older pages, which means the newest article — usually the most visited one —
never shows anything.

## Topic pages

`/tags/` lists every topic with a count; `/tags/accessibility/` lists the pages
filed under it, paginated. Both are generated from the same `tags` front
matter, and both work for any taxonomy the site declares, not just tags.

The topic index is deliberately not paginated: a vocabulary split across
numbered pages hides the term the reader is scanning for.

## Share images

Links to the site preview with an image, resolved in this order:

1. `images` in front matter — Hugo's convention, a list, first entry wins
2. `image` in front matter
3. `params.uswds.ogImage`, the site-wide fallback

```toml
[params.uswds]
  ogImage = "img/og-default.png"
  ogImageAlt = "Example Agency"
  twitter = "@example_agency"     # optional, adds twitter:site
```

Paths resolve as page-bundle resources first, then `assets/`, then `static/`;
an absolute URL is used as-is. Images wider than 1200px are resized down, and
are never cropped to the recommended 1200x630 — a square seal or a portrait
letterboxes in the card rather than losing its top half.

## Switching the furniture off

```toml
[params.uswds.article]
  date = true       # byline
  prevNext = true   # the fallback when there is no related content
  related = 3       # how many related pages to list; 0 makes prev/next the
                    # onward block on every page, tagged or not
```

`sidenav` is per-section front matter rather than a site param, because a site
usually wants a tree in one section and a feed in another.
