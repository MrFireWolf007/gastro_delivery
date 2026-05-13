import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'gastro_delivery_high_importance',
    'Notificaciones de pedidos',
    description: 'Avisos sobre pedidos, reservas y mensajes importantes.',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentUid;
  String? _currentRestaurantId;
  String? _currentRole;
  String? _cachedToken;

  Future<void> initialize() async {
    if (_initialized) return;

    await _initializeLocalNotifications();
    await _requestPermissions();
    _configureMessageListeners();
    await _loadAndLogToken('initialize');

    _messaging.onTokenRefresh.listen((token) {
      _cachedToken = token;
      debugPrint('FCM token refreshed: $token');
    });

    _initialized = true;
  }

  Future<void> configureForUser({
    required String uid,
    required String restaurantId,
    required String role,
  }) async {
    await initialize();

    if (_currentUid == uid &&
        _currentRestaurantId == restaurantId &&
        _currentRole == role) {
      return;
    }

    await clearCurrentUser();

    _currentUid = uid;
    _currentRestaurantId = restaurantId;
    _currentRole = role;

    if (restaurantId.trim().isNotEmpty) {
      await _messaging.subscribeToTopic('restaurant_$restaurantId');
    }

    await _messaging.subscribeToTopic('user_$uid');
    await _messaging.subscribeToTopic('role_$role');

    await _loadAndLogToken('configureForUser');

    debugPrint(
      'FCM topics subscribed for uid=$uid restaurantId=$restaurantId role=$role',
    );
  }

  Future<void> clearCurrentUser() async {
    if (_currentUid == null &&
        _currentRestaurantId == null &&
        _currentRole == null) {
      return;
    }

    if (_currentRestaurantId != null && _currentRestaurantId!.trim().isNotEmpty) {
      await _messaging.unsubscribeFromTopic('restaurant_$_currentRestaurantId');
    }

    if (_currentUid != null) {
      await _messaging.unsubscribeFromTopic('user_$_currentUid');
    }

    if (_currentRole != null) {
      await _messaging.unsubscribeFromTopic('role_$_currentRole');
    }

    _currentUid = null;
    _currentRestaurantId = null;
    _currentRole = null;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(initializationSettings);

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<String?> getCurrentToken() async {
    if (_cachedToken != null) return _cachedToken;
    return await _messaging.getToken();
  }

  Future<void> _loadAndLogToken(String source) async {
    final token = await _messaging.getToken();
    _cachedToken = token;
    debugPrint('FCM token [$source]: ${token ?? 'null'}');
  }

  void _configureMessageListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleOpenedMessage(message);
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('FCM notification opened: ${message.messageId}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = message.data['title']?.toString() ??
        notification?.title ??
        'Gastro Delivery';
    final body = message.data['body']?.toString() ??
        notification?.body ??
        'Tienes una nueva notificación';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}

