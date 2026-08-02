---
title: "Breadcrumb"
description: "The trail from the home page down to the page being read."
weight: 20
---

The trail is built from the page's ancestors, so it needs no configuration. The
current page is a `span` carrying `aria-current="page"`, never a link — a link
to the page you are on is a dead end.

At the top level the breadcrumb renders nothing at all. A trail with one entry
is noise.

Every trail also emits schema.org `BreadcrumbList` metadata, which costs nothing
at render time and is what produces the trail shown under a search result. Turn
it off with:

```toml
[params.uswds.breadcrumb]
  metadata = false
```
