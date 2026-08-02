// Tier 1 — the core bundle, loaded on every page.
//
// Only behaviours that belong to site chrome present in baseof.html. Keeping
// this set small and STABLE is the point: it gets one fingerprinted URL that
// stays warm in cache across every page of the site. Measured at ~12 KB raw /
// 5.3 KB gzip, against 75 KB / 25.9 KB for all 22 USWDS behaviours.
//
// Anything a page uses conditionally belongs in tier 2 instead — see
// layouts/_partials/uswds/require.html. Do not add components here to "make it
// simpler"; that trades the whole site's payload for one page's convenience.

import banner from "@uswds/uswds/js/usa-banner";
import navigation from "@uswds/uswds/js/usa-header";
import skipnav from "@uswds/uswds/js/usa-skipnav";

const behaviors = [banner, navigation, skipnav];

const init = () => {
  behaviors.forEach((behavior) => behavior.on(document.body));
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init, { once: true });
} else {
  init();
}
