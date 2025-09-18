// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'notification_service.dart';

// class FCMMessagingService {
//   static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

//   // TODO: Replace with your actual FCM Server Key
//   // Get this from: Firebase Console > Project Settings > Cloud Messaging > Server key
//   // The key should start with "AAAA..."
//   static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

//   /// Send notification to a specific user by their FCM token
//   static Future<bool> sendToUser({
//     required String fcmToken,
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse(_fcmUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'key=$_serverKey',
//         },
//         body: jsonEncode({
//           'to': fcmToken,
//           'notification': {'title': title, 'body': body, 'sound': 'default'},
//           'data': data ?? {},
//           'priority': 'high',
//         }),
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         return result['success'] == 1;
//       }
//       return false;
//     } catch (e) {
//       print('Error sending FCM notification: $e');
//       return false;
//     }
//   }

//   /// Send notification to all users
//   static Future<Map<String, dynamic>> sendToAllUsers({
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       // Get all users with FCM tokens
//       final usersSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('fcmToken', isNotEqualTo: '')
//           .get();

//       if (usersSnapshot.docs.isEmpty) {
//         return {'success': false, 'message': 'No users with FCM tokens found'};
//       }

//       final tokens = usersSnapshot.docs
//           .map((doc) => doc.data()['fcmToken'] as String)
//           .where((token) => token.isNotEmpty)
//           .toList();

//       if (tokens.isEmpty) {
//         return {'success': false, 'message': 'No valid FCM tokens found'};
//       }

//       // Send to multiple tokens (FCM allows up to 1000 tokens per request)
//       final response = await http.post(
//         Uri.parse(_fcmUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'key=$_serverKey',
//         },
//         body: jsonEncode({
//           'registration_ids': tokens,
//           'notification': {'title': title, 'body': body, 'sound': 'default'},
//           'data': data ?? {},
//           'priority': 'high',
//         }),
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         return {
//           'success': true,
//           'sentCount': result['success'] ?? 0,
//           'failureCount': result['failure'] ?? 0,
//         };
//       }

//       return {'success': false, 'message': 'Failed to send notifications'};
//     } catch (e) {
//       print('Error sending FCM notifications: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Send notification to users by member category
//   static Future<Map<String, dynamic>> sendToCategory({
//     required String category,
//     required String title,
//     required String body,
//     Map<String, dynamic>? data,
//   }) async {
//     try {
//       final usersSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('memberCategory', isEqualTo: category)
//           .where('fcmToken', isNotEqualTo: '')
//           .get();

//       if (usersSnapshot.docs.isEmpty) {
//         return {
//           'success': false,
//           'message': 'No users found in category $category',
//         };
//       }

//       final tokens = usersSnapshot.docs
//           .map((doc) => doc.data()['fcmToken'] as String)
//           .where((token) => token.isNotEmpty)
//           .toList();

//       if (tokens.isEmpty) {
//         return {
//           'success': false,
//           'message': 'No valid FCM tokens found for category $category',
//         };
//       }

//       final response = await http.post(
//         Uri.parse(_fcmUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'key=$_serverKey',
//         },
//         body: jsonEncode({
//           'registration_ids': tokens,
//           'notification': {'title': title, 'body': body, 'sound': 'default'},
//           'data': data ?? {},
//           'priority': 'high',
//         }),
//       );

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         return {
//           'success': true,
//           'sentCount': result['success'] ?? 0,
//           'failureCount': result['failure'] ?? 0,
//         };
//       }

//       return {'success': false, 'message': 'Failed to send notifications'};
//     } catch (e) {
//       print('Error sending FCM notifications: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   /// Get current user's FCM token
//   static Future<String?> getCurrentUserToken() async {
//     return await NotificationService.getToken();
//   }
// }
