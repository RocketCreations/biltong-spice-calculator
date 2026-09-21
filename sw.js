/* Droëwors Spice Calculator - offline service worker.
 *
 * Strategy: stale-while-revalidate. The app opens instantly from cache
 * (kitchen, no signal, fine) and quietly refreshes itself in the background
 * whenever there is a connection. A change you publish lands on the second
 * launch after it goes live.
 *
 * Bump CACHE when you change the file list below.
 */

var CACHE = "droewors-v4";

var CORE = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-512.png",
  "./icons/apple-touch-icon.png",
  "./icons/favicon-32.png"
];

// Google Fonts is the one third party the page loads; cache it too, or the
// app falls back to system faces the moment it goes offline.
var FONT_ORIGINS = ["https://fonts.googleapis.com", "https://fonts.gstatic.com"];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE)
      .then(function (cache) { return cache.addAll(CORE); })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys()
      .then(function (keys) {
        return Promise.all(keys.map(function (k) {
          return k === CACHE ? null : caches.delete(k);
        }));
      })
      .then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (event) {
  var req = event.request;
  if (req.method !== "GET") return;

  var url = new URL(req.url);
  var mine = url.origin === self.location.origin;
  var font = FONT_ORIGINS.indexOf(url.origin) !== -1;
  if (!mine && !font) return;

  event.respondWith(staleWhileRevalidate(req));
});

function staleWhileRevalidate(req) {
  return caches.open(CACHE).then(function (cache) {
    return cache.match(req).then(function (cached) {

      var fresh = fetch(req).then(function (res) {
        // opaque responses (the cross-origin font CSS) are cacheable but not readable
        if (res && (res.ok || res.type === "opaque")) {
          cache.put(req, res.clone());
        }
        return res;
      }).catch(function () { return null; });

      if (cached) return cached;

      return fresh.then(function (res) {
        if (res) return res;
        // offline, never cached: a navigation still gets the app shell
        if (req.mode === "navigate") return cache.match("./index.html");
        return new Response("", { status: 504, statusText: "Offline" });
      });
    });
  });
}
