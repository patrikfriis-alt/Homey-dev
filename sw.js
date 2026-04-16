const CACHE_NAME = 'homey-v6';
const ASSETS = [
  '/Homey/',
  '/Homey/index.html',
  '/Homey/manifest.json',
  '/Homey/icon-192.png',
  '/Homey/icon-512.png',
];

// External libs to cache on first use
const CACHE_EXTERNAL = [
  'https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.js',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Supabase realtime websockets — never intercept
  if (url.includes('supabase.co/realtime')) return;

  // Supabase REST API — network-only, no cache
  if (url.includes('supabase.co/rest') || url.includes('supabase.co/auth')) return;

  // External libs (supabase-js CDN) — cache-first
  if (CACHE_EXTERNAL.some(u => url.startsWith(u))) {
    e.respondWith(
      caches.match(e.request).then(cached => {
        if (cached) return cached;
        return fetch(e.request).then(res => {
          if (res && res.status === 200) {
            caches.open(CACHE_NAME).then(c => c.put(e.request, res.clone()));
          }
          return res;
        });
      })
    );
    return;
  }

  // App shell — stale-while-revalidate
  e.respondWith(
    caches.open(CACHE_NAME).then(cache =>
      cache.match(e.request).then(cached => {
        const fetchPromise = fetch(e.request).then(res => {
          if (res && res.status === 200 && res.type === 'basic') {
            cache.put(e.request, res.clone());
          }
          return res;
        }).catch(() => cached || caches.match('/Homey/index.html'));
        return cached || fetchPromise;
      })
    )
  );
});

// ===== PUSH NOTIFICATIONS =====
self.addEventListener('push', e => {
  let data = { title: 'Homey', body: '' };
  try { data = e.data?.json() ?? data; } catch { data.body = e.data?.text() ?? ''; }
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/Homey/icon-192.png',
      badge: '/Homey/icon-192.png',
      vibrate: [100, 50, 100],
      data: { url: '/Homey/' },
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      const existing = list.find(c => c.url.includes('/Homey/'));
      if (existing) return existing.focus();
      return clients.openWindow('/Homey/');
    })
  );
});
