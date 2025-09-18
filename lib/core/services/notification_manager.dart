// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'notification_service.dart';

// class NotificationManager {
//   static final FirebaseFunctions _functions = FirebaseFunctions.instance;

//   /// Send notification to all users
//   static Future<Map<String, dynamic>> sendNotificationToAll({
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception('User not authenticated');
//       }

//       final result = await _functions
//           .httpsCallable('sendNotificationToAll')
//           .call({'title': title, 'body': body, 'data': data ?? {}});

//       return result.data as Map<String, dynamic>;
//     } catch (e) {
//       throw Exception('Failed to send notification: $e');
//     }
//   }

//   /// Send notification to specific users
//   static Future<Map<String, dynamic>> sendNotificationToUsers({
//     required List<String> userIds,
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception('User not authenticated');
//       }

//       final result = await _functions
//           .httpsCallable('sendNotificationToUsers')
//           .call({
//             'userIds': userIds,
//             'title': title,
//             'body': body,
//             'data': data ?? {},
//           });

//       return result.data as Map<String, dynamic>;
//     } catch (e) {
//       throw Exception('Failed to send notification: $e');
//     }
//   }

//   /// Subscribe to a topic
//   static Future<void> subscribeToTopic(String topic) async {
//     try {
//       await NotificationService.subscribeToTopic(topic);
//     } catch (e) {
//       throw Exception('Failed to subscribe to topic: $e');
//     }
//   }

//   /// Unsubscribe from a topic
//   static Future<void> unsubscribeFromTopic(String topic) async {
//     try {
//       await NotificationService.unsubscribeFromTopic(topic);
//     } catch (e) {
//       throw Exception('Failed to unsubscribe from topic: $e');
//     }
//   }

//   /// Get current FCM token
//   static Future<String?> getFcmToken() async {
//     try {
//       return await NotificationService.getToken();
//     } catch (e) {
//       throw Exception('Failed to get FCM token: $e');
//     }
//   }
// }
