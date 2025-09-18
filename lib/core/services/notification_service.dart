import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'background_message_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
      );
      print('iOS Notification Permission: \\${settings.authorizationStatus}');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // Wait for APNS token on iOS before using FCM features that require it
    if (Platform.isIOS) {
      String? apnsToken;
      int retry = 0;
      // Try for up to 5 seconds (10 x 500ms)
      while (apnsToken == null && retry < 10) {
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(milliseconds: 500));
          retry++;
        }
      }
      print('APNS Token: \\${apnsToken}');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: \\${token}');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Listen for new notifications in Firestore
    _listenToNotifications();

    // Subscribe to topics
    await _firebaseMessaging.subscribeToTopic('announcements');
    await _firebaseMessaging.subscribeToTopic('all_users');
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'church_app_channel',
      'Church App Notifications',
      description: 'Notifications for church announcements and updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static void _listenToNotifications() {
    _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final notification = snapshot.docs.first.data();
            final timestamp = notification['timestamp'] as Timestamp?;

            // Only show if notification is recent (within last 10 seconds)
            if (timestamp != null &&
                DateTime.now().difference(timestamp.toDate()).inSeconds < 10) {
              _showLocalNotification(
                title: notification['title'] ?? 'New Notification',
                body: notification['body'] ?? 'You have a new notification',
                payload: notification.toString(),
              );
            }
          }
        });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Handling background message: ${message.messageId}');

    // Show local notification for background messages
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Announcement',
      body: message.notification?.body ?? 'You have a new announcement',
      payload: message.data.toString(),
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    _showLocalNotification(
      title: message.notification?.title ?? 'New Announcement',
      body: message.notification?.body ?? 'You have a new announcement',
      payload: message.data.toString(),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Navigate to appropriate screen based on message data
    // This will be handled in the main app navigation
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'church_app_channel',
          'Church App Notifications',
          channelDescription:
              'Notifications for church announcements and updates',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Test method for development
  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from the church app!',
      payload: 'test_notification',
    );
  }

  // Send a direct FCM notification to test device notifications
  static Future<void> sendDirectFCMNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Create a notification document that will trigger FCM
      await _firestore.collection('direct_notifications').add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'direct_test',
        'target': 'all_users',
      });

      // Also show local notification immediately
      await _showLocalNotification(
        title: title,
        body: body,
        payload: 'direct_fcm_test',
      );
    } catch (e) {
      print('Error sending direct FCM notification: $e');
    }
  }

  // Send FCM notification to topic
  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification document to trigger FCM
      await _firestore.collection('topic_notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'topic': topic,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'topic',
      });
    } catch (e) {
      print('Error sending topic notification: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'holiday_channel',
          'Holiday Reminders',
          channelDescription: 'Reminders for holidays',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
