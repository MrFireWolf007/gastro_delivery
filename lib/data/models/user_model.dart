class UserModel {
  final String uid;
  final String email;
  final String role;
  final String restaurantId;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.restaurantId,
  });

  // Mapa de datos

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'restaurantId': restaurantId,
    };
  }

  // Factory para construir un UserModel desde un mapade datos
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
    );
  }
}