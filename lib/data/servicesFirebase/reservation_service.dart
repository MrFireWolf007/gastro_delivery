import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String statusPending = ReservationModel.statusPending;
  static const String statusConfirmed = ReservationModel.statusConfirmed;
  static const String statusCanceled = ReservationModel.statusCanceled;

  Future<void> createReservation(ReservationModel reservation) async {
    //🔴VALIDACIONES

    if (reservation.people <= 0) {
      throw Exception('Número de personas inválido');
    }

    if (reservation.date.isBefore(DateTime.now())) {
      throw Exception('No puedes reservar en el pasado');
    }

    if (reservation.people > 20) {
      throw Exception('Máximo 20 personas por reserva');
    }

    //🔥EVITAR DUPLICADOS

    final existing = await _db
        .collection('restaurants')
        .doc(reservation.restaurantId)
        .collection('reservations')
        .where('userId', isEqualTo: reservation.userId)
        .get();

    final duplicateReservation = existing.docs.any((doc) {
      final data = doc.data();
      final rawDate = data['date'];

      final existingDate = rawDate is Timestamp
          ? rawDate.toDate()
          : rawDate is DateTime
              ? rawDate
              : null;

      if (existingDate == null) return false;

      return existingDate.year == reservation.date.year &&
          existingDate.month == reservation.date.month &&
          existingDate.day == reservation.date.day &&
          existingDate.hour == reservation.date.hour &&
          existingDate.minute == reservation.date.minute;
    });

    if (duplicateReservation) {
      throw Exception('Ya tienes una reserva para esa fecha');
    }

    // ✅CREAR RESERVA

    final docRef = _db
        .collection('restaurants')
        .doc(reservation.restaurantId)
        .collection('reservations')
        .doc();

    final newReservation = ReservationModel(
      id: docRef.id,
      restaurantId: reservation.restaurantId,
      userId: reservation.userId,
      date: reservation.date,
      people: reservation.people,
      status: statusPending,
      createdAt: DateTime.now(),
    );

    await docRef.set(newReservation.toMap());
  }

  // Obtener reservas de un restaurante (admin)
  Stream<List<ReservationModel>> getReservationsByRestaurant(
      String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  // Obtener reservas de un usuario (cliente) dentro de un restaurante concreto
  Stream<List<ReservationModel>> getReservationsByUser(
    String restaurantId,
    String userId,
  ) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReservationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Actualizar estado de la reserva (aceptar/rechazar)
  Future<void> updateReservationStatus(
      String restaurantId, String reservationId, String status) async {
    if (!ReservationModel.validStatuses.contains(status)) {
      throw ArgumentError('Estado de reserva no válido: $status');
    }

    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .doc(reservationId)
        .update({'status': status});
  }

  // Eliminar reserva
  Future<void> deleteReservation(
      String restaurantId, String reservationId) async {
    await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .doc(reservationId)
        .delete();
  }
}