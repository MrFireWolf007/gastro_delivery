# gastro_delivery

Proyecto para FCT de Segundo de Desarrollo de Aplicaciones Multiplataforma,
en el que se ha desarrollado una aplicación de delivery de comida, con una interfaz
sencilla y fácil de usar, con un sistema de pedidos y reservas para los clientes.

## Subida de imágenes con Cloudinary

La pantalla de administración permite seleccionar imágenes y subirlas a Cloudinary
antes de guardar la URL en Firestore. Para que funcione, lanza la app con:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=tu_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=tu_upload_preset
```

## Firebase Messaging / notificaciones

La app ya inicializa Firebase Messaging y muestra notificaciones en primer plano
con `flutter_local_notifications`.

### Qué hace la app

- Solicita permiso de notificaciones al arrancar.
- Se suscribe automáticamente al topic del restaurante del usuario:
  - `restaurant_res01` para el restaurante asignado
  - `user_<uid>` para notificaciones personales
  - `role_admin` o `role_client` según el rol
- Muestra notificaciones locales cuando llega un mensaje FCM con la app abierta.

### Cómo probarlo

1. Arranca la app en un dispositivo real.
2. Ve a Firebase Console → Messaging.
3. Crea un mensaje de prueba.
4. En destino, selecciona el topic `restaurant_res01`.
5. Envía el mensaje.

### Prueba con token

La app imprime en los logs el token FCM del dispositivo cuando un usuario inicia
sesión. Ese token te permite enviar una prueba directa desde Firebase Console o
desde una herramienta de backend.

Busca en los logs algo como:

```text
FCM token: eyJhbGciOi...
```

Ese valor puedes usarlo para una prueba individual del dispositivo.

### Nota importante

FCM necesita un origen que envíe los mensajes. Desde este proyecto ya queda
preparada la recepción y la suscripción a topics; para envíos automáticos desde
el cambio de estado de pedidos, lo normal es usar una Cloud Function o Firebase
Console.

