// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'notification_service.dart';

// class TopicNotificationService {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

//   /// Send notification to all users via FCM topic
//   static Future<Map<String, dynamic>> sendToAllUsers({
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         return {'success': false, 'message': 'User not authenticated'};
//       }

//       // Create a notification document that will trigger topic notification
//       final notificationData = {
//         'title': title,
//         'body': body,
//         'data': data ?? {},
//         'senderId': user.uid,
//         'senderName': user.displayName ?? 'Unknown',
//         'timestamp': FieldValue.serverTimestamp(),
//         'type': 'topic_broadcast',
//         'topic': 'all_users',
//         'status': 'pending',
//       };

//       await _firestore.collection('topic_notifications').add(notificationData);

//       // Show local notification for the sender
//       await NotificationService.showTestNotification();

//       return {
//         'success': true,
//         'message': 'Topic notification sent to all users',
//         'sentCount': 1,
//       };
//     } catch (e) {
//       print('Error sending topic notification: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Send notification to specific category via FCM topic
//   static Future<Map<String, dynamic>> sendToCategory({
//     required String category,
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         return {'success': false, 'message': 'User not authenticated'};
//       }

//       final notificationData = {
//         'title': title,
//         'body': body,
//         'data': data ?? {},
//         'senderId': user.uid,
//         'senderName': user.displayName ?? 'Unknown',
//         'timestamp': FieldValue.serverTimestamp(),
//         'type': 'topic_category',
//         'category': category,
//         'topic': 'category_${category.toLowerCase()}',
//         'status': 'pending',
//       };

//       await _firestore.collection('topic_notifications').add(notificationData);

//       // Show local notification for the sender
//       await NotificationService.showTestNotification();

//       return {
//         'success': true,
//         'message': 'Topic notification sent to $category',
//         'sentCount': 1,
//       };
//     } catch (e) {
//       print('Error sending category topic notification: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Subscribe user to topics based on their member category
//   static Future<void> subscribeToTopics(String memberCategory) async {
//     try {
//       // Subscribe to general announcements
//       await _messaging.subscribeToTopic('all_users');

//       // Subscribe to category-specific topic
//       await _messaging.subscribeToTopic(
//         'category_${memberCategory.toLowerCase()}',
//       );

//       print(
//         'Subscribed to topics: all_users, category_${memberCategory.toLowerCase()}',
//       );
//     } catch (e) {
//       print('Error subscribing to topics: $e');
//     }
//   }

//   /// Unsubscribe from all topics
//   static Future<void> unsubscribeFromAllTopics() async {
//     try {
//       await _messaging.unsubscribeFromTopic('all_users');

//       // Unsubscribe from all category topics
//       final categories = [
//         'clergy',
//         'member',
//         'priest',
//         'deacon',
//         'sunday students member',
//         'elder',
//         'youth',
//         'children',
//       ];

//       for (final category in categories) {
//         await _messaging.unsubscribeFromTopic('category_$category');
//       }

//       print('Unsubscribed from all topics');
//     } catch (e) {
//       print('Error unsubscribing from topics: $e');
//     }
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
