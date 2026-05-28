# Print Architecture

## Single-event views (public area)

Standard CSS print using `@media print`. Header and footer are `position: fixed` so they repeat on every page. The `_print_header` partial accepts an optional `event:` local (renders a black number box) and a `type_label:` for the document type. Individual race blocks use `break-inside: avoid`. All print styles live in `print.scss`.

## Full-regatta print (internal area)

Uses [Paged.js](https://pagedjs.org/) to polyfill CSS Paged Media — necessary for running headers that change content per section, which plain CSS cannot do cross-browser.

**Layout**: a dedicated print layout loads Paged.js unconditionally (no side effects on normal views).

**Page breaks**: always via a CSS class (e.g. `.print-page-break`), never inline styles. Paged.js processes breaks from its own CSS parse tree and ignores computed/inline styles.

**Running headers**: use `string-set` on a section header element, then `content: string(...)` in an `@page` rule. Note that `position: running()` is extracted by Paged.js before the cascade runs — overriding it with a higher-specificity `position: relative` does nothing. Use a separate class to opt elements out of extraction.

**Partial reuse**: `_race_results`, `_start_col` etc. are shared between public and print views unchanged.
