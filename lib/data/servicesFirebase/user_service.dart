import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    final data = user.toMap();

    if ((data['role'] ?? '').toString() == 'client' &&
        ((data['restaurantId'] ?? '').toString().trim().isEmpty)) {
      data['restaurantId'] = 'res01';
    }

    await _db.collection('users').doc(user.uid).set(data);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }
}