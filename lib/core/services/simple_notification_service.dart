import 'dart:convert';
import '../config/frappe_config.dart';
import 'frappe_client.dart';

class TargetedNotificationService {
  static Future<void> sendAnnouncementNotification({
    required String targetType, // 'all', 'category', 'users'
    required String title,
    required String body,
    List<String>? categories,
    List<String>? userIds,
    Map<String, dynamic>? data,
  }) async {
    final client = FrappeClient();
    final payload = <String, dynamic>{
      FrappeConfig.notificationTitleField: title,
      FrappeConfig.notificationBodyField: body,
      FrappeConfig.notificationTargetTypeField: targetType,
      FrappeConfig.notificationDataField: jsonEncode(data ?? {}),
    };
    if (targetType == 'category' && categories != null) {
      payload[FrappeConfig.notificationCategoriesField] = jsonEncode(
        categories,
      );
    } else if (targetType == 'users' && userIds != null) {
      payload[FrappeConfig.notificationUserIdsField] = jsonEncode(userIds);
    }

    await client.post(
      '/api/resource/${FrappeConfig.notificationDoctype}',
      body: {'data': payload},
    );
  }
}
