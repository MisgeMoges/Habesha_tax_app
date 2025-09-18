import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert'; // Added for jsonEncode
import 'package:http/http.dart' as http; // Added for http

class TargetedNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Send notification to ALL users
  static Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? type, // 'holiday', 'announcement', 'general'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get all users' FCM tokens
      final usersSnapshot = await _firestore.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'No users with FCM tokens found'};
      }

      final tokens = usersSnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token!.isNotEmpty)
          .cast<String>()
          .toList();

      if (tokens.isEmpty) {
        return {'success': false, 'message': 'No valid FCM tokens found'};
      }

      // Send FCM notification directly from the app
      const String serverKey =
          'YOUR_SERVER_KEY_HERE'; // <-- Replace with your FCM server key
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };
      final payload = {
        'registration_ids': tokens,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
        'priority': 'high',
      };
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headers,
        body: jsonEncode(payload),
      );
      print('FCM response: \\${response.statusCode} \\${response.body}');

      // Also save to Firestore for history
      final notificationData = {
        'title': title,
        'body': body,
        'data': data ?? {},
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': type ?? 'general',
        'target': 'all_users',
        'status': 'sent',
        'sentCount': tokens.length,
      };

      await _firestore
          .collection('targeted_notifications')
          .add(notificationData);

      return {
        'success': true,
        'message': 'Notification sent to all users',
        'target': 'all_users',
        'sentCount': tokens.length,
      };
    } catch (e) {
      print('Error sending notification to all users: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Send notification to specific users by their IDs
  static Future<Map<String, dynamic>> sendToSpecificUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? type, // 'meeting', 'committee', 'special'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      if (userIds.isEmpty) {
        return {'success': false, 'message': 'No user IDs provided'};
      }

      // Get specific users by IDs with FCM tokens
      final usersSnapshot = await _firestore.collection('users').get();

      final tokens = usersSnapshot.docs
          .where((doc) => userIds.contains(doc.id))
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token!.isNotEmpty)
          .cast<String>()
          .toList();

      if (tokens.isEmpty) {
        return {
          'success': false,
          'message': 'No valid FCM tokens found for specified users',
        };
      }

      // Send FCM notification directly
      final message = {
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
        'tokens': tokens,
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': 'church_app_channel',
            'priority': 'high',
            'defaultSound': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default', 'badge': 1},
          },
        },
      };

      // Use Firebase Functions to send the notification
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('sendNotificationToUsers')
          .call(message);

      print('FCM notification sent to ${tokens.length} specific users');
      print('Result: ${result.data}');

      // Also save to Firestore for history
      final notificationData = {
        'title': title,
        'body': body,
        'data': data ?? {},
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': type ?? 'specific',
        'target': 'specific_users',
        'targetUserIds': userIds,
        'status': 'sent',
        'sentCount': tokens.length,
      };

      await _firestore
          .collection('targeted_notifications')
          .add(notificationData);

      return {
        'success': true,
        'message': 'Notification sent to ${userIds.length} specific users',
        'target': 'specific_users',
        'targetCount': userIds.length,
        'sentCount': tokens.length,
      };
    } catch (e) {
      print('Error sending notification to specific users: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Send notification to users by member category
  static Future<Map<String, dynamic>> sendToCategory({
    required String category,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? type, // 'category_specific'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Get users by category with FCM tokens
      final usersSnapshot = await _firestore
          .collection('users')
          .where('memberCategory', isEqualTo: category)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No users found in category: $category',
        };
      }

      final tokens = usersSnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token!.isNotEmpty)
          .cast<String>()
          .toList();

      if (tokens.isEmpty) {
        return {
          'success': false,
          'message': 'No valid FCM tokens found for category: $category',
        };
      }

      // Send FCM notification directly
      final message = {
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
        'tokens': tokens,
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': 'church_app_channel',
            'priority': 'high',
            'defaultSound': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default', 'badge': 1},
          },
        },
      };

      // Use Firebase Functions to send the notification
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('sendNotificationToUsers')
          .call(message);

      print(
        'FCM notification sent to ${tokens.length} users in category: $category',
      );
      print('Result: ${result.data}');

      // Also save to Firestore for history
      final notificationData = {
        'title': title,
        'body': body,
        'data': data ?? {},
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'type': type ?? 'category',
        'target': 'category',
        'targetCategory': category,
        'status': 'sent',
        'sentCount': tokens.length,
      };

      await _firestore
          .collection('targeted_notifications')
          .add(notificationData);

      return {
        'success': true,
        'message': 'Notification sent to $category category',
        'target': 'category',
        'targetCategory': category,
        'sentCount': tokens.length,
      };
    } catch (e) {
      print('Error sending notification to category: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get all users for selection
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'email': data['email'] ?? '',
          'memberCategory': data['memberCategory'] ?? 'Member',
          'fcmToken': data['fcmToken'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Get users by category
  static Future<List<Map<String, dynamic>>> getUsersByCategory(
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('memberCategory', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'email': data['email'] ?? '',
          'memberCategory': data['memberCategory'] ?? 'Member',
          'fcmToken': data['fcmToken'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting users by category: $e');
      return [];
    }
  }

  /// Get available member categories
  static List<String> getMemberCategories() {
    return [
      'Clergy',
      'Priest',
      'Deacon',
      'Elder',
      'Member',
      'Youth',
      'Children',
      'Sunday Students Member',
    ];
  }

  /// Get targeted notification history
  static Stream<QuerySnapshot> getTargetedNotificationHistory() {
    return _firestore
        .collection('targeted_notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Subscribe user to appropriate topics based on their category
  static Future<void> subscribeUserToTopics(String memberCategory) async {
    try {
      // Subscribe to general topics
      await _messaging.subscribeToTopic('all_users');
      await _messaging.subscribeToTopic('announcements');

      // Subscribe to category-specific topic
      await _messaging.subscribeToTopic(
        'category_${memberCategory.toLowerCase()}',
      );

      print(
        'User subscribed to topics: all_users, announcements, category_${memberCategory.toLowerCase()}',
      );
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }
}
