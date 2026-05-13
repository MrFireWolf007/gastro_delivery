import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  static const String statusPending = 'pendiente';
  static const String statusConfirmed = 'confirmado';
  static const String statusCanceled = 'cancelado';

  static const Set<String> validStatuses = {
    statusPending,
    statusConfirmed,
    statusCanceled,
  };

  final String id;
  final String restaurantId;
  final String userId;
  final DateTime date;
  final int people;
  final String status; // pendiente, confirmado, cancelado
  final DateTime createdAt;

  ReservationModel({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.date,
    required this.people,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'date': date,
      'people': people,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
    final rawDate = map['date'];
    final rawCreatedAt = map['createdAt'];

    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is DateTime
            ? rawDate
            : DateTime.now();

    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : rawCreatedAt is DateTime
            ? rawCreatedAt
            : DateTime.now();

    return ReservationModel(
      id: id,
      restaurantId: map['restaurantId'] ?? '',
      userId: map['userId'] ?? '',
      date: date,
      people: map['people'] ?? 0,
      status: map['status'] ?? statusPending,
      createdAt: createdAt,
    );
  }

  static String labelForStatus(String status) {
    switch (status) {
      case statusConfirmed:
        return 'Confirmada';
      case statusCanceled:
        return 'Cancelada';
      case statusPending:
      default:
        return 'Pendiente';
    }
  }
}