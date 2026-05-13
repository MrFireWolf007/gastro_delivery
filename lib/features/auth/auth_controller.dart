import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/push_notification_service.dart';
import '../../data/servicesFirebase/user_service.dart';
import 'data/auth_service.dart';
import '../../data/models/user_model.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _authService.login(email, password);
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final user = await _authService.register(email, password);

      if (user != null) {
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          role: 'client',
          // Todos los clientes se asignan por defecto al restaurante 'res01'
          restaurantId: 'res01',
        );

        await _userService.createUser(newUser);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e.toString());
      }
    }
  }

  /// Cierra la sesión y opcionalmente borra la preferencia 'rememberMe'.
  Future<void> logout({bool clearRemember = true}) async {
    await PushNotificationService.instance.clearCurrentUser();

    if (clearRemember) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rememberMe');
    }
    await _authService.logout();
  }

  Future<String?> getUserRole(String uid) async {
    final user = await _userService.getUser(uid);
    return user?.role;
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    return await _userService.getUser(user.uid);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}