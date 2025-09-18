// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_functions/cloud_functions.dart';

// class AnnouncementNotificationService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FirebaseFunctions _functions = FirebaseFunctions.instance;

//   /// Send FCM notification to all users when announcement is created
//   static Future<Map<String, dynamic>> sendAnnouncementNotification({
//     required String announcementId,
//     required String title,
//     required String body,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         return {'success': false, 'message': 'User not authenticated'};
//       }

//       // Create a notification document that will trigger FCM
//       final notificationData = {
//         'title': title,
//         'body': body,
//         'announcementId': announcementId,
//         'senderId': user.uid,
//         'senderName': user.displayName ?? 'Unknown',
//         'timestamp': FieldValue.serverTimestamp(),
//         'type': 'announcement',
//         'status': 'pending',
//       };

//       // Add to notifications collection to trigger FCM
//       await _firestore.collection('notifications').add(notificationData);

//       // Also try to send via Cloud Functions if available
//       try {
//         final result = await _functions
//             .httpsCallable('sendNotificationToUsers')
//             .call({
//               'title': title,
//               'body': body,
//               'data': {
//                 'announcementId': announcementId,
//                 'type': 'announcement',
//               },
//             });

//         print('Cloud Function result: ${result.data}');
//       } catch (e) {
//         print('Cloud Function not available, using Firestore trigger: $e');
//       }

//       return {
//         'success': true,
//         'message': 'Announcement notification sent via FCM',
//         'sentCount': 1,
//       };
//     } catch (e) {
//       print('Error sending announcement notification: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Subscribe user to announcement topic
//   static Future<void> subscribeToAnnouncements() async {
//     try {
//       await _messaging.subscribeToTopic('announcements');
//       print('Subscribed to announcements topic');
//     } catch (e) {
//       print('Error subscribing to announcements topic: $e');
//     }
//   }

//   /// Unsubscribe from announcement topic
//   static Future<void> unsubscribeFromAnnouncements() async {
//     try {
//       await _messaging.unsubscribeFromTopic('announcements');
//       print('Unsubscribed from announcements topic');
//     } catch (e) {
//       print('Error unsubscribing from announcements topic: $e');
//     }
//   }

//   /// Send notification to specific topic
//   static Future<Map<String, dynamic>> sendToTopic({
//     required String topic,
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         return {'success': false, 'message': 'User not authenticated'};
//       }

//       // Create topic notification document
//       final notificationData = {
//         'title': title,
//         'body': body,
//         'data': data ?? {},
//         'senderId': user.uid,
//         'senderName': user.displayName ?? 'Unknown',
//         'timestamp': FieldValue.serverTimestamp(),
//         'type': 'topic',
//         'topic': topic,
//         'status': 'pending',
//       };

//       await _firestore.collection('topic_notifications').add(notificationData);

//       return {
//         'success': true,
//         'message': 'Topic notification sent to $topic',
//         'sentCount': 1,
//       };
//     } catch (e) {
//       print('Error sending topic notification: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Get FCM token for current user
//   static Future<String?> getFCMToken() async {
//     try {
//       return await _messaging.getToken();
//     } catch (e) {
//       print('Error getting FCM token: $e');
//       return null;
//     }
//   }

//   /// Save FCM token to user document
//   static Future<void> saveFCMToken(String userId) async {
//     try {
//       final token = await getFCMToken();
//       if (token != null) {
//         await _firestore.collection('users').doc(userId).update({
//           'fcmToken': token,
//           'lastTokenUpdate': FieldValue.serverTimestamp(),
//         });
//         print('FCM token saved for user: $userId');
//       }
//     } catch (e) {
//       print('Error saving FCM token: $e');
//     }
//   }

//   /// Get notification history
//   static Stream<QuerySnapshot> getNotificationHistory() {
//     return _firestore
//         .collection('notifications')
//         .orderBy('timestamp', descending: true)
//         .limit(50)
//         .snapshots();
//   }

//   /// Get topic notification history
//   static Stream<QuerySnapshot> getTopicNotificationHistory() {
//     return _firestore
//         .collection('topic_notifications')
//         .orderBy('timestamp', descending: true)
//         .limit(50)
//         .snapshots();
//   }
// }
