class WebNotificationHelper {
  static bool get isWeb => false;
  static bool get isMobileSafari => false;
  static bool get isMacOSSafari => false;
  static Map<String, String> getBrowserInfo() => {};
  static Map<String, dynamic> getNotificationSupport() =>
      {'supported': false, 'reason': 'Not running on web platform'};
  static Future<Map<String, dynamic>> requestNotificationPermission() async =>
      {'success': false, 'error': 'Not running on web platform'};
  static String getNotificationPermission() => 'unknown';
  static Future<bool> sendSafariNotification({
    required String title,
    required String body,
    String? icon,
  }) async => false;
  static Future<bool> showTestNotification({
    String title = 'Plant Care Test',
    String body = 'This is a test notification from Plant Care!',
  }) async => false;
}
