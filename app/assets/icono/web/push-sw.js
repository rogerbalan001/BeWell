// Service worker de notificaciones push de BeWell (HU: recordatorios en el teléfono).
// Muestra el aviso aunque la app esté cerrada y, al tocarlo, abre la pantalla relacionada.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (evento) => evento.waitUntil(self.clients.claim()));

self.addEventListener('push', (evento) => {
  let datos = {};
  try {
    datos = evento.data ? evento.data.json() : {};
  } catch (_) {
    datos = { titulo: 'BeWell', mensaje: evento.data ? evento.data.text() : '' };
  }
  const titulo = datos.titulo || 'BeWell';
  evento.waitUntil(
    self.registration.showNotification(titulo, {
      body: datos.mensaje || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: datos.ruta || 'bewell',
      data: { ruta: datos.ruta || '/notificaciones' },
    }),
  );
});

self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();
  const ruta = (evento.notification.data && evento.notification.data.ruta) || '/notificaciones';
  const destino = self.location.origin + '/#' + ruta;
  evento.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((ventanas) => {
      for (const v of ventanas) {
        if (v.url.startsWith(self.location.origin) && 'focus' in v) {
          return v.focus().then((enfocada) => (enfocada && 'navigate' in enfocada ? enfocada.navigate(destino).catch(() => self.clients.openWindow(destino)) : self.clients.openWindow(destino)));
        }
      }
      return self.clients.openWindow(destino);
    }),
  );
});
