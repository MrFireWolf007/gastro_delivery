import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String menuId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderItemModel({
    required this.menuId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuId: (map['menuId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      imageUrl: (map['imageUrl'] ?? '').toString(),
    );
  }
}

class OrderModel {
  static const String statusPending = 'pendiente';
  static const String statusConfirmed = 'confirmado';
  static const String statusPreparing = 'en_preparacion';
  static const String statusDelivered = 'entregado';
  static const String statusCanceled = 'cancelado';

  static const Set<String> validStatuses = {
    statusPending,
    statusConfirmed,
    statusPreparing,
    statusDelivered,
    statusCanceled,
  };

  final String id;
  final String restaurantId;
  final String userId;
  final List<OrderItemModel> items;
  final double total;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    final createdAt = createdRaw is Timestamp
        ? createdRaw.toDate()
        : createdRaw is DateTime
            ? createdRaw
            : DateTime.now();

    final itemsRaw = map['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(OrderItemModel.fromMap)
            .toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: id,
      restaurantId: (map['restaurantId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? statusPending).toString(),
      createdAt: createdAt,
    );
  }
}

