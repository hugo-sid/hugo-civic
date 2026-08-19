# Widest-Reach Design Checklist

A reference for designing/building this theme so it works for the widest range of devices, contexts, abilities, and constraints. Grouped by concern; use as a checklist when reviewing or auditing changes.

## Accessibility (a11y)
- Semantic HTML (proper headings, landmarks, lists) so screen readers can navigate
- Sufficient color contrast (WCAG AA at minimum)
- Keyboard-only navigation — everything reachable and operable without a mouse
- Alt text for images, captions/transcripts for video and audio
- Focus states that are visible, not stripped out for aesthetics
- ARIA only where semantic HTML isn't enough — don't overuse it
- Respect `prefers-reduced-motion` for animations

## Progressive enhancement
- Core content and functionality work with no JS (forms submit via plain HTML, links are real `<a>` tags, not `onclick` divs)
- CSS-optional fallback — content still readable if stylesheets fail to load
- Feature detection over browser sniffing when you do use JS

## Performance & low-end devices
- Small payload sizes — lots of the audience may be on slow connections or older phones
- Lazy-load images/videos, compress assets
- Avoid heavy JS frameworks if a lighter approach does the job
- Test on throttled network + low-end CPU, not just the dev machine

## Device & viewport diversity
- Responsive design, not just "mobile-friendly" — test small phones, tablets, ultra-wide monitors
- Touch targets big enough for fingers, not just cursors
- Avoid relying on hover-only interactions (many touch devices have no true hover)

## Browser compatibility
- Test across evergreen browsers, but also consider older versions still in use in some markets
- Graceful degradation for unsupported CSS/JS features
- Avoid bleeding-edge APIs without fallbacks

## Internationalization & localization
- Unicode support, RTL layout support if relevant
- Avoid text baked into images (hard to translate, bad for a11y)
- Be mindful of date/number/currency formats if localizing
- Avoid idioms/culture-specific references if audience is global

## Connectivity constraints
- Offline support or graceful failure (service workers, caching) if relevant
- Avoid assuming persistent connection — some users are on limited data plans

## Cognitive load & clarity
- Plain language, clear navigation, predictable UI patterns
- Avoid dark patterns and overly complex flows
- Don't overload with autoplay media, popups, interstitials

## Privacy & trust
- Minimize tracking/cookies where possible — some users block scripts or use privacy-focused browsers
- Clear, honest forms — don't demand more info than needed

## SEO & discoverability
- Proper meta tags, structured data, crawlable content (benefits from no-JS-dependent content, since some crawlers don't execute JS)
