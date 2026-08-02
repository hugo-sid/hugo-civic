---
title: "Alert"
description: "Call out information the reader needs before they carry on."
weight: 10
in_page_nav: true
in_page_nav_headings: "h2"
---

## Usage

```
{{</* alert type="warning" title="Check your version" */>}}
Body copy, written as **markdown**.
{{</* /alert */>}}
```

{{< alert type="warning" title="Check your version" >}}
Body copy, written as **markdown**.
{{< /alert >}}

## Parameters

| Parameter | Values | Default |
|---|---|---|
| `type` | info, warning, error, success, emergency | info |
| `title` | any text | none |
| `slim` | true | false |
| `no_icon` | true | false |

## When to use which

Reach for `slim` only when the message is one short line — the variant has no
heading slot and halves the padding, so a wrapped paragraph looks unbalanced in
it.

Leave `role` unset on a page that renders the alert at build time. Setting
`role="alert"` makes a screen reader interrupt whatever it was reading the
moment the page loads, which is right for something injected after a user
action and wrong for static copy.
