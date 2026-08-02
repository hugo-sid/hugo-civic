---
title: "Accordion"
description: "Collapse long supporting detail so the page stays scannable."
weight: 20
---

An accordion is two shortcodes: a wrapper that carries the group's options, and
one item per panel.

```
{{</* accordion bordered="true" multiselectable="true" heading_level="h3" */>}}
{{</* accordion-item title="First question" expanded="true" */>}}
Body copy.
{{</* /accordion-item */>}}
{{</* /accordion */>}}
```

{{< accordion bordered="true" multiselectable="true" heading_level="h3" >}}
{{< accordion-item title="What does bordered change?" expanded="true" >}}
It draws a border around each panel. Use it when the accordion sits directly on
the page background rather than inside a card.
{{< /accordion-item >}}
{{< accordion-item title="What does multiselectable change?" >}}
It lets more than one panel be open at once. Without it, opening a panel closes
the others.
{{< /accordion-item >}}
{{< accordion-item title="Why set heading_level?" >}}
Items default to `h4`. Directly under an `h2` that skips a level, so pass the
level that keeps the document outline contiguous.
{{< /accordion-item >}}
{{< /accordion >}}

Panel ids come from the shortcode's ordinal, so several accordions can share a
page without their ids colliding.
