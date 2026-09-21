# Droëwors Spice Calculator

A single-page spice calculator for droëwors. Enter the weight of your mince and
every ingredient scales to the gram. Installs to an iPhone (or Android) home
screen and works with no signal.

No build step, no dependencies, no framework. It is one HTML file plus a
manifest, a service worker and five PNGs.

---

## Files

| Path                    | What it is                                                     |
| ----------------------- | -------------------------------------------------------------- |
| `index.html`            | The whole app — markup, styles and logic in one file            |
| `manifest.webmanifest`  | Makes it installable; name, icons, colours, standalone display  |
| `sw.js`                 | Service worker — offline caching                                |
| `icons/`                | Generated PNGs (192, 512, maskable 512, apple-touch 180, favicon 32) |
| `tools/make-icons.ps1`  | Regenerates every icon from one vector mark, via .NET GDI+      |
| `.nojekyll`             | Stops GitHub Pages running the files through Jekyll             |

---

## Run it locally

Opening `index.html` straight off disk works for everything except the service
worker — browsers only register one over `http://` or `https://`. That is fine
for editing the calculator.

To test the offline behaviour you need a local web server. In VS Code the
easiest is the **Live Server** extension: right-click `index.html` →
*Open with Live Server*.

---

## Publish it to GitHub Pages

**Repo name matters** — it becomes part of the URL, so use hyphens, not spaces.

1. Create an empty repo on GitHub, e.g. `droewors-spice-calculator`.
   It has to be **public** — Pages from a private repo needs a paid GitHub plan.

2. From this folder:

   ```bash
   git init
   git add -A
   git commit -m "Droewors spice calculator"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/droewors-spice-calculator.git
   git push -u origin main
   ```

3. On GitHub: **Settings → Pages → Build and deployment**.
   Source: *Deploy from a branch*. Branch: `main`, folder: `/ (root)`. **Save**.

4. Wait a minute or two, then open:

   ```
   https://YOUR-USERNAME.github.io/droewors-spice-calculator/
   ```

   The trailing slash matters — every path in the app is relative, which is what
   lets it live in a subfolder like this.

Pages serves over HTTPS, which the service worker requires. Nothing else to configure.

---

## Put it on your iPhone

1. Open the URL **in Safari**. Chrome on iOS can add a bookmark, but Safari is
   the reliable path to a real installed web app.
2. Tap the **Share** button (the square with the arrow).
3. Scroll down and tap **Add to Home Screen**, then **Add**.

You get a home-screen icon that launches full screen with no browser chrome.
Load it once with signal so the service worker can cache everything, and from
then on it opens instantly and works offline.

Android/Chrome is the same idea: the browser will offer *Install app*.

---

## Changing it

Everything the recipe knows lives in two arrays near the top of the `<script>`
block in `index.html`:

```js
var DRY = [ { name, id?, sub, per, gPerTsp, note, warn }, ... ];
var WET = [ { name, sub, per, gPerTsp, note }, ... ];
```

- `per` — grams (dry) or millilitres (wet) **per kilogram of mince**
- `gPerTsp` — approximate grams per level teaspoon, used only for the
  "≈ 1 tbsp + ½ tsp" hints under each figure
- `id: "salt"` marks the one row driven by the slider instead of a fixed rate

**After any change, bump the cache version in `sw.js`:**

```js
var CACHE = "droewors-v1";   // -> "droewors-v2"
```

Without that, installed copies keep serving the old files. With it, the next
launch after your push picks up the change.

### Regenerating the icons

```bash
powershell -ExecutionPolicy Bypass -File tools\make-icons.ps1
```

The mark is a boerewors coil drawn as an Archimedean spiral — cream `#F2E7D5`
on oxblood `#8E2F22`. Change `$INK`, `$WORS`, `$turns` or `$r0` in the script
and re-run.

---

## The recipe

Base rates, per kilogram of mince:

| Ingredient            | Per kg   | Notes                        |
| --------------------- | -------- | ---------------------------- |
| Coarse sea salt       | 18 g     | Adjustable, 12–26 g/kg. Never iodised |
| Coriander seeds       | 6 g      | Toast whole, then grind      |
| Black pepper, cracked | 2 g      |                              |
| Ground cloves         | 1 g      | Very strong — sparingly      |
| Ground nutmeg         | 2 g      |                              |
| Brown vinegar         | 15 ml    |                              |
| Worcestershire sauce  | 15 ml    |                              |

Salt is the only rate exposed in the UI, because it is the one people actually
tune. 18 g/kg (1.8%) is the classic cure; most makers land between 15 and 21.
