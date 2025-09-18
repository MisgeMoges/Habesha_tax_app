import 'package:http/http.dart' as http;
import 'dart:convert';

class TargetedNotificationService {
  static Future<void> sendAnnouncementNotification({
    required String targetType, // 'all', 'category', 'users'
    required String title,
    required String body,
    List<String>? categories,
    List<String>? userIds,
    Map<String, dynamic>? data,
  }) async {
    final url =
        'https://test-app-3-uauz.onrender.com/send-notification'; // <-- Replace with your deployed Node.js server URL
    final payload = {
      'title': title,
      'body': body,
      'data': data ?? {},
      'targetType': targetType,
    };
    if (targetType == 'category' && categories != null) {
      payload['categories'] = categories;
    } else if (targetType == 'users' && userIds != null) {
      payload['userIds'] = userIds;
    }
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('Notification response: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
