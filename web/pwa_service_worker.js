const CACHE_NAME = 'loharano-critical-v1';
const CRITICAL_ASSETS = [
  'assets/assets/models/model_unquant.tflite',
  'assets/assets/models/labels.txt',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CRITICAL_ASSETS)),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  if (!CRITICAL_ASSETS.some((asset) => event.request.url.endsWith(asset))) {
    return;
  }
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request)),
  );
});
