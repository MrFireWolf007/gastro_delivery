import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool available;
  final String restaurantId;
  final DateTime createdAt;

  MenuModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.available,
    required this.restaurantId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'available': available,
      'restaurantId': restaurantId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MenuModel.fromMap(String id, Map<String, dynamic> map) {
    final createdRaw = map['createdAt'];
    DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt = DateTime.now();
    }

    return MenuModel(
      id: id,
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      category: map['category'],
      available: map['available'],
      restaurantId: map['restaurantId'],
      createdAt: createdAt,
    );
  }
}