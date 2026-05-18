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
- Toca "Seleccionar Imagen" para cargar una foto desde el dispositivo
- Espera a que la imagen se suba a Cloudinary y guarde la URL en Firestore
- Marca el plato como disponible si quieres que sea visible para los clientes
- Toca en "Guardar Plato" para añadirlo al menú
- Resultado: El plato aparece a los clientes inmediatamente en el menú

5.4 Pestaña 3: Editar Platos
Permite modificar los platos existentes:
Pasos:
- Filtra por categoría si lo deseas
- Selecciona el plato que quieres editar
- Modifica los campos que necesites (nombre, descripción, precio, imagen, etc...)
- Usa el toggle "Disponible" para marcar el plato como disponible o no
- Toca "Guardar Cambios" para actualizar el plato
- Usa el botón "Eliminar" para borrar el plato del menú
- Resultado: Los cambios se reflejan en tiempo real para los clientes

5.5 Pestaña 4: Reservas
Muestra todas las reservas realizadas por los clientes:
Información mostrada:
- Nombre del cliente
- Número de personas
- Fecha y hora de la reserva
- Estado de la reserva (pendiente, confirmada, cancelada)
Acciones:
- Toca una reserva para ver detalles completos
- Usa el botón "Confirmar" para aceptar la reserva
- Usa el botón "Cancelar" para rechazar la reserva
- Resultado: El cliente recibe una notificación con el estado de su reserva

5.6 Pestaña 5: Pedidos
Gestiona los pedidos realizados por los clientes:
Información mostrada:
- Nombre del cliente
- Detalles del pedido (platos, cantidades, precio total)
- Estado del pedido (pendiente, en preparación, listo para recoger, entregado)
- Fecha y hora del pedido
Filtros:
- Puedes filtrar por estado para ver solo lo que necesitas
- Toca en los chips de color para cambiar el filtro
- Cambiar Estado del Pedido:
- Toca en un pedido
- Se abre un menú con los estados válidos para ese pedido
- Selecciona el nuevo estado
- El cliente recibirá una notificación automática
Estados posibles:
- Pendiente → Confirmado, Cancelado
- Confirmado → En Preparación, Cancelado
- En Preparación → Entregado, Cancelado
- Entregado (Final)
- Cancelado (Final)

5.7 Cerrar sesión
Abre el Drawer (Menú lateral)
- Toca "Cerrar Sesión" al final del menú
- Confirma que quieres cerrar sesión
- Resultado: Serás redirigido a la pantalla de inicio de sesión (Login)

## (6) GUÍA DE USO - CLIENTE
6.1 Pantalla Principal
- Al iniciar sesion como cliente, verás:
- 5 pestañas principales: Menú, Carrito, Pedidos, Reservas y Perfil
- Cada pestaña tiene funcionalidades específicas para los clientes

6.2 Pestaña 1: Menú
Muestra todos los platos disponibles con:
- Filtros por categoría (Todas, General(No se usa), Entrantes, Principales, Postres, Bebidas)
- Imagen del plato
- Nombre del plato
- Descripción breve
- Precio
- Categoría
- Boton "Agregar al Carrito" para añadir el plato al carrito de compras
Acciones: 
- Desliza hacia abajo para ver más platos
- Toca "Agregar al Carrito" para añadir un plato a tu carrito
Resultado: El plato se añade al carrito y se muestra una notificación de confirmación

6.3 Pestaña 2: Reservar
Permite hacer reservas en el restaurante con:
- Formulario de reserva con campos para número de personas, fecha y hora
- Botón "Reservar ahora" para enviar la reserva
- Resultado: Se crea la reserva y se muestra un resumen con los detalles de la reserva
- Recibirás una notificación automática con el estado de tu reserva (pendiente, confirmada, cancelada)

6.4 Pestaña 3: Mis Reservas
Muestra todas las reservas realizadas por el cliente con:
- Fecha y hora de la reserva
- Número de personas
- Estado de la reserva (pendiente, confirmada, cancelada)

6.5 Pestaña 4: Carrito
Muestra los platos que has añadido al carrito con:
Si el carrito está vacío:
- Muestra un mensaje "Tu carrito está vacío" con un botón para ver menú de platos
Si el carrito tiene platos: 
- Muestra una lista con los platos añadidos, cada uno con :
- Imagen del plato
- Nombre del plato
- Precio del plato
- Cantidad seleccionada con dos botones "+" y "-" para ajustar la cantidad
- Precio total del pedido calculado automáticamente
- Botón "Realizar Pedido" para confirmar el pedido
- Resultado: Se crea el pedido y se muestra un resumen con los detalles del pedido

6.6 Pestaña 5: Mis Pedidos
Muestra todos los pedidos realizados por el cliente y el estado actual de cada uno con:
- Id del pedido
- Estado del pedido (pendiente, en preparación, listo para recoger, entregado)
- Fecha y hora del pedido
- Número de platos en el pedido
- Precio total del pedido

## (7) SISTEMA DE NOTIFICACIONES
7.1 ¿Cómo Funciona?
- La app usa Firebase Cloud Messaging para enviar notificaciones
- Los usuarios se suscriben automáticamente a canales según su rol
- Las notificaciones llegan en tiempo real

7.2 Tipos de Notificaciones
Para Administradores:
- Nuevo pedido creado
- Cambios en reservas
- Actualizaciones del sistema
Para Clientes:
- Confirmación de pedido
- Cambios en el estado del pedido
- Notificaciones de reservas

7.3 Cómo Recibir Notificaciones
Requisitos:
- Debes estar registrado y con sesión iniciada
- Debes haber autorizado los permisos de notificaciones (pedido al instalar)
- Debes tener conexión a internet
Estados:
- App Abierta: La notificación aparece como card dentro de la app
- App Cerrada: La notificación aparece en la bandeja del dispositivo
- App en Background: La notificación aparece en la bandeja
- ¿No recibes notificaciones?
- Verifica que los permisos estén autorizados en Configuración del Dispositivo
- Asegúrate de estar conectado a internet
- Cierra y reabre la app
- Comprueba que hayas iniciado sesión correctamente

## (8) CARACTERÍSTICAS TÉCNICAS
8.1 Seguridad
- Autenticación mediante Google Firebase
- Contraseñas encriptadas
- Reglas de Firestore que protegen la información personal
- Solo verás tus propios datos y los del restaurante

8.2 Almacenamiento de Imágenes
- Las imágenes de platos se guardan en Cloudinary
- Está optimizado para carga rápida
- Funciona incluso con conexión lenta

8.3 Base de Datos
- Todos los datos se guardan en Firebase Firestore
- Sincronización en tiempo real
- Disponible offline (con limitaciones)

8.4 Dispositivos Compatibles
- Android 11 o superior
- Navegadores modernos (Chrome)
- Probado en Xiaomi Redmi 8
- Emulador Pixel 7

## (9) SOLUCIONES A PROBLEMAS COMUNES
9.1 Problema: No puedo iniciar sesión
Solución:
- Verifica tu conexión a internet
- Asegúrate de usar el correo y contraseña correctos
- Si el problema persiste, contacta con soporte técnico

9.2 Problema: No veo los platos en el menú
Solución:
- Verifica que el administrador haya marcado los platos como disponibles
- Asegúrate de tener conexión a internet para cargar los datos
- Si el problema persiste, contacta con soporte técnico

9.3 Problema: No recibo notificaciones
Solución:
- Verifica que hayas autorizado los permisos de notificaciones
- Asegúrate de estar conectado a internet
- Cierra y reabre la app para restablecer la conexión de notificaciones
- Si el problema persiste, contacta con soporte técnico

## (10) CONTACTO Y SOPORTE
Contacta con el equipo de soporte para cualquier duda o problema relacionado con Gastro Delivery