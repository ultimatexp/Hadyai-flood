import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

import '../navigation/push_chat_navigation.dart';
import '../navigation/push_pet_match_navigation.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Map<String, dynamic>? _pendingPushPayload;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Firebase (if not already done in main, but usually good to ensure)
    // assuming Firebase.initializeApp() is called in main.dart before this.

    // 2. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2.5. Explicitly set foreground presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Setup Local Notifications (for foreground display)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          unawaited(handleNotificationDataMap(map));
        } catch (e) {
          debugPrint('Notification tap payload decode error: $e');
        }
      },
    );

    // 4. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // 5b. Notification opened while app in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      unawaited(handleOpenedRemoteMessage(message));
    });

    // 6. Get Token and Save
    await _saveToken();

    // 7. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenRaw(newToken);
    });

    _isInitialized = true;
  }

  /// Persists the current FCM token to `profiles.fcm_token` and opens any deferred push route.
  Future<void> syncTokenToProfile() async {
    await _saveToken();
    await _tryConsumePendingPushNavigation();
  }

  /// Call once from the root widget after the first frame (e.g. [FondueApp] `initState`) so
  /// [MaterialApp]'s navigator exists for cold-start notification opens.
  Future<void> consumeInitialNotificationIfAny() async {
    final initial = await _firebaseMessaging.getInitialMessage();
    if (initial != null) {
      await handleOpenedRemoteMessage(initial);
    }
  }

  Future<void> handleOpenedRemoteMessage(RemoteMessage message) async {
    await handleNotificationDataMap(Map<String, dynamic>.from(message.data));
  }

  /// Routes FCM `data` (chat or pet match) from Edge Functions or local notification payload.
  Future<void> handleNotificationDataMap(Map<String, dynamic> data) async {
    if (!isChatPushPayload(data) && !isPetMatchPushPayload(data)) return;

    if (Supabase.instance.client.auth.currentUser == null) {
      _pendingPushPayload = Map<String, dynamic>.from(data);
      debugPrint('Deferred push navigation until user signs in');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _dispatchPushRoute(data);
    });
  }

  Future<void> _dispatchPushRoute(Map<String, dynamic> data) async {
    if (isChatPushPayload(data)) {
      await openChatFromPushData(data);
    } else if (isPetMatchPushPayload(data)) {
      await openPetMatchFromPushData(data);
    }
  }

  Future<void> _tryConsumePendingPushNavigation() async {
    final pending = _pendingPushPayload;
    if (pending == null) return;
    if (Supabase.instance.client.auth.currentUser == null) return;

    _pendingPushPayload = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _dispatchPushRoute(pending);
    });
  }

  Future<void> _saveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await _saveTokenRaw(token);
      }
    } catch (e) {
      // APNS token not available on iOS Simulator — silently ignore
      debugPrint("FCM token unavailable (expected on simulator): $e");
    }
  }

  Future<void> _saveTokenRaw(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint("FCM Token saved to database for user $userId");
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    // On iOS, we want to show the notification even if 'android' is null
    if (notification != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
