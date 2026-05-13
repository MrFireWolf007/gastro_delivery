import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/models/user_model.dart';
import 'features/menu/presentation/admin_menu_screen.dart';
import 'features/menu/presentation/user_menu_screen.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/auth_controller.dart';
import 'core/services/push_notification_service.dart';

Future<void> _requestPermissions() async {
  final Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    Permission.photos,
    Permission.notification,
  ].request();

  // Verificar si se otorgaron los permisos
  statuses.forEach((permission, status) {
    if (status.isDenied) {
      debugPrint('Permiso denegado: $permission');
    } else if (status.isPermanentlyDenied) {
      debugPrint('Permiso permanentemente denegado: $permission');
      openAppSettings();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.instance.initialize();
  await FirebaseAuth.instance.signOut();

  // Solicitar permisos de almacenamiento
  await _requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController();
    final PushNotificationService pushNotificationService =
        PushNotificationService.instance;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder<UserModel?>(
              future: authController.getCurrentUserData(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = userSnapshot.data;
                if (user == null) {
                  return const LoginScreen();
                }

                unawaited(
                  pushNotificationService.configureForUser(
                    uid: user.uid,
                    restaurantId: user.restaurantId,
                    role: user.role,
                  ),
                );

                if (user.role == 'admin') {
                  return const AdminMenuScreen();
                } else {
                  return const UserMenuScreen();
                }
              },
            );
          }

          return const LoginScreen();
        },
      ),
    );
  }
}