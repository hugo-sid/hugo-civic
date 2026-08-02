---
title: "Theming"
description: "Retheme the site from hugo.toml without editing any SCSS."
weight: 20
---

## Colors and type

Set values under `[params.uswds.theme]`. They are passed into Sass through the
`hugo:vars` module, so no `.scss` file needs to change.

## Going further

If you need a setting that is not exposed, create `assets/uswds/_settings.scss`
in your own project. Hugo's union filesystem gives your file precedence over
the theme's, so the theme itself stays untouched and upgrades cleanly.
