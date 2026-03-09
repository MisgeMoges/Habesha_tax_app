class NotificationService {
  // Firebase push configuration is temporarily disabled.
  // Uncomment/restore Firebase setup when ready.
  static Future<void> initialize() async {}

  static Future<void> subscribeToTopic(String topic) async {}

  static Future<void> unsubscribeFromTopic(String topic) async {}

  static Future<String?> getToken() async => null;
}
