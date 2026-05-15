# (1) Documentación del proyecto de FCT - Gastro Delivery

Proyecto para FCT de Segundo de Desarrollo de Aplicaciones Multiplataforma.
Gastro Delivery es una app que permite a los administradores gestionar su menú,
las reservas y los pedidos que recibe un restaurante, mientras que los clientes pueden navegar por el menú, realizar los pedidos y hacer
reservas en el restaurante, teniendo asi dos roles diferentes para los usuarios: administrador y cliente.

Realizado por un equipo de 5 personas: Cristian, Javier, Edu, Ángel y Lucía

## (2) Características principales

Para los Administradores:
- Gestión de menú: Crear, editar y eliminar platos con un filtro por categorías.
- Subida de Imágenes: Integracion con Cloudinary para subir imágenes de los platos y almacenar las URLs en Firestore.
- Gestion de Disponibilidad: Marcar los platos como disponibles o no disponibles para la venta.
- Gestión de Reservas: Ver y gestionar todas las reservas realizadas por los clientes, con detalles de cada reserva.
- Gestión de Pedidos: Ver y gestionar el estado de los pedidos realizados por los clientes.
- Dashboard de Resumen: Panel con las estadisticas del restaurante, como número de pedidos, reservas y platos disponibles.

Para los Clientes:
- Navegación por el Menú: Ver todos los platos disponibles, con detalles y flitrados por categorías.
- Carrito de Compras: Agrega y elimina platos al carrito antes de realizar el pedido con un calculo final del precio.
- Realización de Pedidos: Crea pedidos a partir del carrito, con una opción de confirmación y resumen del pedido.
- Seguimiento de Pedidos: Permite ver el estado en tiempo real de todos los pedidos realizados.
- Notificaciones: Permite que los clientes reciban notificaciones de la aplicación.
- Recordar Sesión: Permite a los clientes mantener la sesión iniciada para acceder más rápidamente

## (3) Requisitos del Sistema
Dispositivo
- Android 11 o superior
- Mínimo 4GB de RAM
- Conexión a Internet estable
- Credenciales de Firebase para autenticación y base de datos
- Credenciales de Cloudinary para la gestión de imágenes
- Permisos de almacenamiento para subir imágenes desde el dispositivo
- Permisos de notificaciones para recibir alertas sobre pedidos y reservas

## (4) Instalación y Configuración
Paso 1: Descargar e Instalar
- Descarga la aplicación desde el repositorio de Github
- Abre el proyecto en tu entorno de desarrollo preferido (Android Studio preferiblemente)
- Abre el archivo APK y autoriza la instalación desde fuentes desconocidas si es necesario
- Espera a que la instalación se complete y abre la aplicación
Paso 2: Primer Inicio
- Abre Gastro Delivery en tu dispositivo
- Si te solicita permisos, otorga acceso a almacenamiento y notificaciones para una experiencia completa
- Una vez dentro de la app verás la pantalla de inicio de sesión.
Paso 3: Crear una cuenta o iniciar sesión
- Toca "Iniciar Sesión" si ya tienes una cuenta, o "Registrarse" para crearla
- Ingresa tu correo electrónico y contraseña para iniciar sesión o registrarte
- (Opcional) Marca la casilla "Recordar Sesión" para mantener tu sesión iniciada

## (5) Guía de Uso - ADMINISTRADOR
5.1 Pantalla Principal
- Al iniciar sesión como administrador, verás:
- Un Drawer (Menú lateral) con todas las secciones disponibles
- 5 pestañas principales: Resumen, Crear, Editar, Reservas y Pedidos
- Atajos: Botones rápidos para acciones frecuentes

5.2 Pestaña 1: Resumen
Muestra un panel de control con:
- Número total de platos disponibles
- Reservas pendientes
- Resumen rápido de la actividad del restaurante
- Acción: Ver estadísticas iniciales de tu restaurante

5.3 Pestaña 2: Crear Platos
Permite crear nuevos platos para el menú
Pasos:
- Rellena el nombre del plato
- Ingresa la descripción del plato
- Selecciona la categoría (Entrante, Principal, Postre, Bebida)
- Ingresa el precio del plato
- Toca "Seleccionar Imagen"
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

