const CACHE_NAME = 'beaver-jewels-v1';
const ASSETS = [
  './',
  './index.html',
  './index.js',
  './index.pck',
  './index.wasm',
  './manifest.json',
  './index.icon.png',
  './index.apple-touch-icon.png',
  './icon_512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      // Add assets one by one so if one fails, others are still cached
      return Promise.allSettled(
        ASSETS.map(asset => cache.add(asset))
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      return cachedResponse || fetch(event.request);
    })
  );
});
