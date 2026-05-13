const admin = require('firebase-admin');
const functions = require('firebase-functions');

admin.initializeApp();

const db = admin.firestore();

function normalizeStatusLabel(status) {
  switch ((status || '').toString()) {
    case 'confirmado':
      return 'confirmado';
    case 'en_preparacion':
      return 'en preparación';
    case 'entregado':
      return 'entregado';
    case 'cancelado':
      return 'cancelado';
    case 'pendiente':
    default:
      return 'pendiente';
  }
}

function shortId(id) {
  if (!id) return 'pedido';
  return id.length > 8 ? `${id.substring(0, 8)}…` : id;
}

function getItemCount(items) {
  if (!Array.isArray(items)) return 0;
  return items.reduce((sum, item) => sum + (Number(item.quantity) || 0), 0);
}

async function sendTopicNotification(topic, title, body, data = {}) {
  if (!topic) return;

  await admin.messaging().send({
    topic,
    notification: {
      title,
      body,
    },
    data: Object.entries(data).reduce((acc, [key, value]) => {
      acc[key] = String(value);
      return acc;
    }, {}),
    android: {
      priority: 'high',
    },
  });
}

exports.onOrderCreated = functions.firestore
  .document('restaurants/{restaurantId}/orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data() || {};
    const restaurantId = context.params.restaurantId;
    const orderId = context.params.orderId;
    const userId = (order.userId || '').toString();
    const itemsCount = getItemCount(order.items);

    functions.logger.info('Nuevo pedido creado', { restaurantId, orderId, userId });

    const restaurantTopic = `restaurant_${restaurantId}`;
    const userTopic = userId ? `user_${userId}` : null;

    const promises = [
      sendTopicNotification(
        restaurantTopic,
        'Nuevo pedido recibido',
        `Tienes un pedido nuevo ${shortId(orderId)} con ${itemsCount} platos.`,
        {
          type: 'order_created',
          orderId,
          restaurantId,
          userId,
        },
      ),
    ];

    if (userTopic) {
      promises.push(
        sendTopicNotification(
          userTopic,
          'Pedido recibido',
          `Hemos recibido tu pedido ${shortId(orderId)}.`,
          {
            type: 'order_received',
            orderId,
            restaurantId,
            userId,
          },
        ),
      );
    }

    await Promise.all(promises);
    return null;
  });

exports.onOrderStatusUpdated = functions.firestore
  .document('restaurants/{restaurantId}/orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const restaurantId = context.params.restaurantId;
    const orderId = context.params.orderId;

    if ((before.status || '') === (after.status || '')) {
      return null;
    }

    const userId = (after.userId || '').toString();
    const statusLabel = normalizeStatusLabel(after.status);
    const restaurantTopic = `restaurant_${restaurantId}`;
    const userTopic = userId ? `user_${userId}` : null;

    functions.logger.info('Pedido actualizado', {
      restaurantId,
      orderId,
      previousStatus: before.status,
      status: after.status,
      userId,
    });

    const promises = [
      sendTopicNotification(
        restaurantTopic,
        'Pedido actualizado',
        `El pedido ${shortId(orderId)} pasó a ${statusLabel}.`,
        {
          type: 'order_status_updated',
          orderId,
          restaurantId,
          userId,
          status: after.status,
        },
      ),
    ];

    if (userTopic) {
      promises.push(
        sendTopicNotification(
          userTopic,
          'Tu pedido ha cambiado',
          `Tu pedido ${shortId(orderId)} ahora está ${statusLabel}.`,
          {
            type: 'order_status_updated',
            orderId,
            restaurantId,
            userId,
            status: after.status,
          },
        ),
      );
    }

    await Promise.all(promises);
    return null;
  });

exports._test = {
  normalizeStatusLabel,
  shortId,
  getItemCount,
};

