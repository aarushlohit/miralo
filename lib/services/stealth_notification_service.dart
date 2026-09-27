import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing stealth push notifications in system status bar / notification shade
/// as well as in-app notification banners.
class StealthNotificationService {
  StealthNotificationService._();

  static const String stealthTitle = 'Miralo AI';
  static const String stealthBody = 'Miralo AI spawns !!!';
  static const String channelId = 'miralo_stealth_notifications';
  static const String channelName = 'Miralo AI Notifications';
  static const String channelDescription =
      'Discreet push notifications in notification bar for incoming messages and AI alerts';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Initialize local notification settings and channels for Android, iOS, macOS, Linux
  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open Miralo');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification bar item tapped: ${response.payload}');
        },
      );

      // Request notification permissions for Android 13+ (API 33+)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }

    _isInitialized = true;
  }

  /// Display a stealth push notification into the system notification bar (top status bar / notification shade)
  static Future<void> showStealthInAppNotification(
    BuildContext? context, {
    VoidCallback? onTap,
    String title = stealthTitle,
    String body = stealthBody,
  }) async {
    // Exclusively push real notification to system status bar / notification drawer.
    // No in-app SnackBars inside Home screen or app views.
    await showSystemPushNotification(title: title, body: body);
  }

  /// Pushes a native notification directly to the device's System Notification Bar
  static Future<void> showSystemPushNotification({
    String title = stealthTitle,
    String body = stealthBody,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error dispatching system notification bar push: $e');
    }
  }

  /// Pushes an urgent real-time notification to the status bar
  static Future<void> showUrgentNotification({
    String title = 'Urgent Notice',
    String body = 'miralo  reminds urgent critical  news check it out !!! ',
  }) async {
    await showSystemPushNotification(
      title: title,
      body: body,
    );
  }
}
