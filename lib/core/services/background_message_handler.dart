import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

// This function must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');

  // Initialize Firebase if needed
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Show local notification for background messages
  await _showLocalNotification(
    title: message.notification?.title ?? 'New Announcement',
    body: message.notification?.body ?? 'You have a new announcement',
    payload: message.data.toString(),
  );
}

// This function must also be top-level
@pragma('vm:entry-point')
Future<void> _showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  // Create notification channel for Android
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

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'church_app_channel',
    'Church App Notifications',
    channelDescription: 'Notifications for church announcements and updates',
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
    sound: 'notification_sound.aiff',
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
    payload: payload,
  );
}
