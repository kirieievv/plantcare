import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Helper class for web-specific notification handling
class WebNotificationHelper {
  
  /// Check if we're running on web
  static bool get isWeb => kIsWeb;
  
  /// Check if we're in mobile Safari
  static bool get isMobileSafari {
    if (!kIsWeb) return false;
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('safari') && 
             !userAgent.contains('chrome') && 
             userAgent.contains('mobile');
    } catch (e) {
      return false;
    }
  }
  
  /// Check if we're on macOS Safari
  static bool get isMacOSSafari {
    if (!kIsWeb) return false;
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('safari') && 
             !userAgent.contains('chrome') && 
             userAgent.contains('macintosh');
    } catch (e) {
      return false;
    }
  }
  
  /// Get detailed browser information
  static Map<String, String> getBrowserInfo() {
    if (!kIsWeb) return {};
    
    try {
      final navigator = html.window.navigator;
      return {
        'userAgent': navigator.userAgent,
        'platform': navigator.platform ?? 'unknown',
        'language': navigator.language ?? 'unknown',
        'cookieEnabled': navigator.cookieEnabled.toString(),
        'onLine': navigator.onLine.toString(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Check notification support
  static Map<String, dynamic> getNotificationSupport() {
    if (!kIsWeb) {
      return {
        'supported': false,
        'reason': 'Not running on web platform',
      };
    }
    
    try {
      // Check for notification support using try-catch instead of hasOwnProperty
      bool hasNotification = false;
      bool hasServiceWorker = false;
      bool hasPushManager = false;
      
      try {
        hasNotification = html.Notification != null;
      } catch (e) {
        hasNotification = false;
      }
      
      try {
        hasServiceWorker = html.window.navigator.serviceWorker != null;
      } catch (e) {
        hasServiceWorker = false;
      }
      
      try {
        hasPushManager = html.window.navigator.serviceWorker?.ready != null;
      } catch (e) {
        hasPushManager = false;
      }
      
      return {
        'supported': hasNotification,
        'hasNotification': hasNotification,
        'hasServiceWorker': hasServiceWorker,
        'hasPushManager': hasPushManager,
        'browser': _getBrowserName(),
      };
    } catch (e) {
      return {
        'supported': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Get browser name from user agent
  static String _getBrowserName() {
    if (!kIsWeb) return 'unknown';
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      
      if (userAgent.contains('chrome') && !userAgent.contains('edge')) {
        return 'Chrome';
      } else if (userAgent.contains('firefox')) {
        return 'Firefox';
      } else if (userAgent.contains('safari') && !userAgent.contains('chrome')) {
        return 'Safari';
      } else if (userAgent.contains('edge')) {
        return 'Edge';
      } else {
        return 'Other';
      }
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Request notification permission with detailed feedback
  static Future<Map<String, dynamic>> requestNotificationPermission() async {
    if (!kIsWeb) {
      return {
        'success': false,
        'error': 'Not running on web platform',
      };
    }
    
    try {
      // Check if Notification API is available
      final support = getNotificationSupport();
      if (!support['supported']) {
        return {
          'success': false,
          'error': 'Notifications not supported: ${support['reason'] ?? 'Unknown reason'}',
          'support': support,
        };
      }
      
      // Request permission
      final permission = await html.Notification.requestPermission();
      
      return {
        'success': permission == 'granted',
        'permission': permission,
        'browser': support['browser'],
        'support': support,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'support': getNotificationSupport(),
      };
    }
  }
  
  /// Get current notification permission status
  static String getNotificationPermission() {
    if (!kIsWeb) return 'unknown';
    
    try {
      return html.Notification.permission ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// Send Safari-compatible notification
  static Future<bool> sendSafariNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    if (!kIsWeb) return false;
    
    try {
      // Check if we're in Safari
      if (isMobileSafari || isMacOSSafari) {
        // Use basic browser notification API for Safari
        final permission = html.Notification.requestPermission();
        
        permission.then((permission) {
          if (permission == 'granted') {
            html.Notification(
              title,
              body: body,
              icon: icon ?? '/icons/Icon-192.png',
            );
            return true;
          }
          return false;
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error sending Safari notification: $e');
      return false;
    }
  }
  
  /// Show a test notification
  static Future<bool> showTestNotification({
    String title = 'Plant Care Test',
    String body = 'This is a test notification from Plant Care!',
  }) async {
    if (!kIsWeb) return false;
    
    try {
      final permission = getNotificationPermission();
      if (permission != 'granted') {
        return false;
      }
      
      html.Notification(title, body: body);
      return true;
    } catch (e) {
      print('Error showing test notification: $e');
      return false;
    }
  }
}
