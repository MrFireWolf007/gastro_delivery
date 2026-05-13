import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrder(OrderModel order) async {
    if (order.restaurantId.trim().isEmpty) {
      throw Exception('El restaurante no es valido');
    }
    if (order.userId.trim().isEmpty) {
      throw Exception('El usuario no es valido');
    }
    if (order.items.isEmpty) {
      throw Exception('El pedido debe incluir al menos un plato');
    }

    final invalidQty = order.items.any((item) => item.quantity <= 0);
    if (invalidQty) {
      throw Exception('Todas las cantidades deben ser mayores que 0');
    }

    final calculatedTotal = order.items.fold<double>(
      0,
      (acc, item) => acc + (item.price * item.quantity),
    );

    final docRef = _db
        .collection('restaurants')
        .doc(order.restaurantId)
        .collection('orders')
        .doc();

    final newOrder = OrderModel(
      id: docRef.id,
      restaurantId: order.restaurantId,
      userId: order.userId,
      items: order.items,
      total: calculatedTotal,
      status: OrderModel.statusPending,
      createdAt: DateTime.now(),
    );

    await docRef.set(newOrder.toMap());
  }

  Stream<List<OrderModel>> getOrdersByUser(String restaurantId, String userId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
                .toList();

            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          },
        );
  }

  Stream<List<OrderModel>> getOrdersByRestaurant(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .snapshots()
        .map(
          (snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
                .toList();

            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          },
        );
  }

  Future<void> updateOrderStatus(
    String restaurantId,
    String orderId,
    String status,
  ) async {
    if (!OrderModel.validStatuses.contains(status)) {
      throw ArgumentError('Estado de pedido no válido: $status');
    }

    if (restaurantId.trim().isEmpty) {
      throw ArgumentError('restaurantId must not be empty');
    }

    if (orderId.trim().isEmpty) {
      throw ArgumentError('orderId must not be empty');
    }

    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .doc(orderId)
        .update({'status': status});
  }
}

