# Cloud Functions - Gastro Delivery

Este directorio contiene las funciones que envían notificaciones de Firebase Cloud Messaging (FCM) cuando:

- se crea un pedido nuevo
- cambia el estado de un pedido

## Instalación

```bash
cd functions
npm install
```

## Despliegue

```bash
firebase deploy --only functions
```

## Qué hace cada función

- `onOrderCreated`
  - Notifica al topic `restaurant_<restaurantId>` para avisar al admin.
  - Notifica al topic `user_<userId>` para confirmar al cliente que el pedido fue recibido.

- `onOrderStatusUpdated`
  - Notifica al topic del restaurante para avisar a cocina/administración.
  - Notifica al topic del usuario para que vea el cambio de estado.

## Topics usados por la app Flutter

- `restaurant_res01`
- `user_<uid>`
- `role_admin`
- `role_client`

## Prueba rápida

Puedes ejecutar el emulador con:

```bash
firebase emulators:start --only functions
```

Y después modificar un pedido en Firestore para comprobar que se generan logs.

