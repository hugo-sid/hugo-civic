# Civic

A Hugo theme for building accessible informational websites using the principles of the U.S. Web Design System.

## Why?

The U.S. Web Design System is one of the most mature design systems available for content-first websites. It provides accessible, research-backed components, consistent interaction patterns, and a strong foundation for publishing information clearly and inclusively.

Civic brings those principles to Hugo in a way that stays true to upstream USWDS while avoiding the maintenance burden that typically comes with framework integrations.

Civic brings the U.S. Web Design System to Hugo with an emphasis on staying close to upstream. Rather than copying or modifying USWDS, it uses configuration, component selection, and additive styles to help keep upgrades straightforward while producing small, efficient sites.

[NOTE]: Civic is an independent project. It is not maintained by the U.S. General Services Administration or the USWDS team.

## Features

* No vendored or modified USWDS source
* Configuration-driven theming
* Upgrade-friendly architecture

## Requirements

* Hugo Extended
* Node.js
* `@uswds/uswds`
* `sass-embedded`

---

## Installation

```bash
npm install @uswds/uswds@3 sass-embedded
```

Add the theme to your project and mount the USWDS distribution into Hugo's asset pipeline. See `exampleSite/` for a complete working configuration.

---

## Configuration

Everything is configured from `hugo.toml`.

```toml
[params.uswds]
preset = "standard"

[params.uswds.theme]
colorPrimary = "blue-60v"
fontTypeSans = "public-sans"
fontTypeSerif = false
fontTypeMono = false
```

## Documentation

* `exampleSite/` — complete reference implementation


## Contributing

Please run:

```bash
npm run check
```

before opening a pull request.

One project rule is non-negotiable:

> **Never vendor or modify USWDS source.**


## License

MIT.
