import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:api_client/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize notification service for Vendor/Doctor App
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      print('ℹ️ [VendorApp] Push notifications are handled natively on mobile. Skipping web FCM initialization.');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        print('⚠️ [VendorApp] Firebase not initialized. Skipping push notification setup.');
        return;
      }

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ [VendorApp] Notification permission granted');

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('📱 [VendorApp] FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          await sendTokenToBackend(_fcmToken!);
        }

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Setup message handlers
        _setupMessageHandlers();

        _isInitialized = true;
      } else {
        print('❌ [VendorApp] Notification permission denied');
      }
    } catch (e) {
      print('⚠️ [VendorApp] Error initializing notifications: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTapped(response);
      },
    );

    // Create high-importance channel for Android vendor alerts
    const androidChannel = AndroidNotificationChannel(
      'onmint_vendor_high_importance_channel',
      'OnMint Vendor Notifications',
      description: 'This channel is used for important vendor order/booking notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    try {
      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background messages opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Terminated state messages
      _firebaseMessaging.getInitialMessage().then((message) {
        if (message != null) {
          _handleBackgroundMessage(message);
        }
      });

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        sendTokenToBackend(newToken);
      });
    } catch (e) {
      print('⚠️ [VendorApp] Error setting up message handlers: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    String title = notification?.title ?? data['title'] ?? 'OnMint Healthcare Vendor';
    String body = notification?.body ?? data['body'] ?? data['message'] ?? '';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: data.toString(),
    );
  }

  /// Handle background/terminated messages
  void _handleBackgroundMessage(RemoteMessage message) {
    final data = message.data;
    _handleNotificationNavigation(data);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'onmint_vendor_high_importance_channel',
      'OnMint Vendor Notifications',
      channelDescription: 'This channel is used for important vendor order/booking notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _handleNotificationNavigation({});
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('Vendor notification tapped with data: $data');
  }

  /// Send FCM token to backend
  Future<void> sendTokenToBackend(String token) async {
    try {
      final apiClient = OnMintApiClient();
      await apiClient.auth.updateDeviceToken(token);
      print('✅ [VendorApp] FCM Device token successfully registered on backend');
    } catch (e) {
      print('❌ [VendorApp] Failed to update FCM device token on backend: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling vendor background message: ${message.messageId}");
}
