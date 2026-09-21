# Droëwors Spice Calculator — project context

Context for anyone (or any Claude session) picking this up cold. The work was
started in a different Claude session; this file is the handover, so no prior
conversation is needed.

## What it is

A spice calculator for droëwors, built as an installable web app (PWA). The
user enters a mince weight; every spice quantity scales to the gram. It is
meant to be used on a phone in a kitchen, offline.

It is deliberately **not** a native iOS app. That was considered and rejected:
the owner is on Windows, Xcode needs macOS, and App Store distribution costs
US$99/year — for an app that is one number in and seven numbers out, an
installed web app is functionally identical.

## Constraints that shaped it

- **No build step, no dependencies.** Plain HTML/CSS/ES5-ish JS in one file.
  Do not introduce npm, a bundler or a framework without being asked.
- **No Node, Python or ImageMagick on the build machine.** Icons are generated
  by `tools/make-icons.ps1` using .NET GDI+ through Windows PowerShell 5.1.
  Keep it that way unless the toolchain changes.
- **Offline first.** The kitchen has no signal. Anything added must not assume
  a network at runtime.
- Target host is GitHub Pages in a subfolder, so **every path stays relative**
  (`./index.html`, `icons/...`). No leading slashes.

## Design

Deliberate choices, not defaults — keep them unless asked:

- **Palette.** Warm neutrals with a red bias. Oxblood accent `#8E2F22` (light) /
  `#DB7360` (dark); olive `#5A6733` / `#A6B46C` marks liquid measures.
  Full light and dark token sets on `:root`, `@media (prefers-color-scheme: dark)`
  guarded with `:root:not([data-theme="light"])`, and `:root[data-theme="dark"]`.
- **Type.** Fraunces (display) / Karla (body) / IBM Plex Mono (all figures).
  Mono everywhere a number appears, with `font-variant-numeric: tabular-nums`,
  so columns of weights line up.
- **Icon.** A boerewors coil — an Archimedean spiral of 1.9 turns, round caps,
  cream on oxblood. Generated, not hand-drawn.

## The data model

Two arrays near the top of the `<script>` in `index.html`:

```js
var DRY = [ { name, id?, sub, per, gPerTsp, note, warn }, ... ];  // grams/kg
var WET = [ { name, sub, per, gPerTsp, note }, ... ];             // ml/kg
```

- `per` is per **kilogram of mince** — the single source of truth for the recipe.
- `gPerTsp` drives only the approximate spoon hints. These are approximations
  and are labelled as such in the footer; do not present them as exact.
- The row with `id: "salt"` is special: its rate comes from the slider
  (`#saltrate`, 12–26 g/kg, 0.5 steps) via `perOf()`, not from `per`.
  Salt is the only adjustable rate, by request — it is the one cooks tune.
  The chosen rate persists in `localStorage` under `droewors.saltRate`,
  wrapped in try/catch.

Everything recomputes through one `render()`. There is no state object and no
framework; `render()` rebuilds both lists, the three summary tiles and the
per-kg group headers from the current weight and salt rate.

## Gotchas

- **Bump `CACHE` in `sw.js` on every content change.** Otherwise installed
  copies keep serving stale files. This is the single most common way to ship a
  change that appears not to work.
- The service worker is skipped on `file://` by design, so opening the page off
  disk to edit it will not register one. Use a local HTTP server to test offline
  behaviour.
- Google Fonts is the only third party. `sw.js` runtime-caches both
  `fonts.googleapis.com` and `fonts.gstatic.com`, so the app keeps its
  typography offline after one online load. Fallback stacks are declared anyway.
- `apple-mobile-web-app-status-bar-style` is `default` on purpose.
  `black-translucent` puts content under the status bar and makes the status
  bar text unreadable on the light background.

## State of play

Done: the calculator, the salt slider, the PWA wiring, the icons, the README
with GitHub Pages and iPhone install steps.

Not done: not yet pushed to GitHub, so no live URL exists. Never tested on a
real iPhone — the install flow and safe-area insets are written to spec but
unverified on device.
