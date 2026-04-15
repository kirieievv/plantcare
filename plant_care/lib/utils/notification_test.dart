import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper.dart';

/// Utility class for testing push notifications
class NotificationTest {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test notification permissions and token generation
  static Future<Map<String, dynamic>> testNotificationSetup() async {
    try {
      print('🔔 Testing notification setup...');
      
      // Check if notifications are supported
      final isSupported = await _messaging.isSupported();
      print('📱 Notifications supported: $isSupported');
      
      if (!isSupported) {
        return {
          'success': false,
          'error': 'Notifications not supported on this platform',
          'platform': defaultTargetPlatform.name,
          'isWeb': kIsWeb,
          'isMobileSafari': WebNotificationHelper.isMobileSafari,
          'recommendation': _getPlatformRecommendation(),
        };
      }

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('🔐 Permission status: ${settings.authorizationStatus}');
      print('🔐 Alert permission: ${settings.alert}');
      print('🔐 Badge permission: ${settings.badge}');
      print('🔐 Sound permission: ${settings.sound}');
      
      // Get FCM token
      String? token;
      String? tokenError;
      try {
        // For web, we need to handle token generation differently
        if (kIsWeb) {
          // Request permission first if not already granted
          if (settings.authorizationStatus != AuthorizationStatus.authorized) {
            final newSettings = await _messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            );
            print('🔐 Web permission after request: ${newSettings.authorizationStatus}');
          }
          
          // Wait a bit for web token generation
          await Future.delayed(const Duration(seconds: 3));
          
          // Try to get token with VAPID key for web
          try {
            // Note: You need to replace this with your actual VAPID key from Firebase Console
            // Go to Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
            token = await _messaging.getToken(
              vapidKey: 'BI0yI6i_be8uHYwHlGkuwK4w20TlouraY6LM5j0Y0_Gp2xrfMOKbC43GHx9y_fsILTrpEAmsbUE8UVVHZZpB9G4'
            );
          } catch (e) {
            print('❌ Error getting token with VAPID key: $e');
            // Fallback: try without VAPID key
            try {
              token = await _messaging.getToken();
            } catch (e2) {
              print('❌ Error getting token without VAPID key: $e2');
              tokenError = 'VAPID key required for web push notifications. Please configure in Firebase Console.';
            }
          }
        } else {
          token = await _messaging.getToken();
        }
        
        print('🎫 FCM Token: ${token?.substring(0, 50)}...');
      } catch (e) {
        print('❌ Error getting token: $e');
        tokenError = e.toString();
      }

      // Check user preferences
      final prefs = await SharedPreferences.getInstance();
      final wateringReminders = prefs.getBool('watering_reminders') ?? true;
      print('🌱 Watering reminders enabled: $wateringReminders');

      // Save token to Firestore if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await _saveTokenToFirestore(user.uid, token);
      }

      // Get web-specific information
      final browserInfo = WebNotificationHelper.getBrowserInfo();
      final notificationSupport = WebNotificationHelper.getNotificationSupport();
      final webPermission = WebNotificationHelper.getNotificationPermission();
      final isMobileSafari = WebNotificationHelper.isMobileSafari;
      final isMacOSSafari = WebNotificationHelper.isMacOSSafari;
      
      return {
        'success': token != null,
        'platform': defaultTargetPlatform.name,
        'isWeb': kIsWeb,
        'isMobileSafari': isMobileSafari,
        'isMacOSSafari': isMacOSSafari,
        'browserInfo': browserInfo,
        'notificationSupport': notificationSupport,
        'webPermission': webPermission,
        'permissionStatus': settings.authorizationStatus.name,
        'alert': settings.alert.toString(),
        'badge': settings.badge.toString(),
        'sound': settings.sound.toString(),
        'token': token,
        'tokenLength': token?.length ?? 0,
        'tokenError': tokenError,
        'userLoggedIn': user != null,
        'userId': user?.uid,
        'wateringRemindersEnabled': wateringReminders,
        'recommendation': _getPlatformRecommendation(),
      };
    } catch (e) {
      print('❌ Error testing notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
        'platform': defaultTargetPlatform.name,
        'isWeb': kIsWeb,
        'isMobileSafari': WebNotificationHelper.isMobileSafari,
        'recommendation': _getPlatformRecommendation(),
      };
    }
  }


  /// Get platform-specific recommendations
  static String _getPlatformRecommendation() {
    if (defaultTargetPlatform.name == 'macOS') {
      return 'Push notifications work best on mobile Safari. Try testing on iPhone/iPad Safari instead.';
    } else if (defaultTargetPlatform.name == 'web' && !kIsWeb) {
      return 'For best results, test on mobile Safari (iPhone/iPad) and add the app to home screen.';
    } else {
      return 'Push notifications are optimized for mobile Safari. Desktop browsers have limited support.';
    }
  }

  /// Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        List<String> tokens = [];
        if (snapshot.exists && snapshot.data()?['fcmTokens'] != null) {
          tokens = List<String>.from(snapshot.data()!['fcmTokens']);
        }

        // Only add if not already present
        if (!tokens.contains(token)) {
          tokens.add(token);
          transaction.set(
            userDoc,
            {
              'fcmTokens': tokens,
              'updatedAt': FieldValue.serverTimestamp(),
              'lastTokenUpdate': DateTime.now().toIso8601String(),
            },
            SetOptions(merge: true),
          );
          print('✅ FCM token saved to Firestore');
        } else {
          print('ℹ️ FCM token already registered');
        }
      });
    } catch (e) {
      print('❌ Error saving token to Firestore: $e');
    }
  }

  /// Show a simple test notification (web only)
  static Future<Map<String, dynamic>> showWebTestNotification() async {
    if (!kIsWeb) {
      return {
        'success': false,
        'error': 'Web test notification only works on web platform',
      };
    }
    
    try {
      final success = await WebNotificationHelper.showTestNotification(
        title: 'Plant Care Test',
        body: 'This is a test notification from Plant Care! 🌱',
      );
      
      return {
        'success': success,
        'message': success 
            ? 'Test notification shown successfully!' 
            : 'Failed to show notification - check permissions',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send a test notification (for development/testing)
  static Future<Map<String, dynamic>> sendTestNotification({
    String? userId,
    String? customToken,
  }) async {
    try {
      print('🧪 Sending test notification...');
      
      String? token = customToken;
      
      // If no custom token provided, get the current user's token
      if (token == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Get token from Firestore
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
            if (tokens.isNotEmpty) {
              token = tokens.first;
            }
          }
        }
      }

      if (token == null) {
        return {
          'success': false,
          'error': 'No FCM token available. Please ensure notifications are set up first.',
        };
      }

      // For testing, you would typically send this via your backend
      // For now, we'll just log the token and return success
      print('🎯 Test notification would be sent to token: ${token.substring(0, 50)}...');
      
      return {
        'success': true,
        'message': 'Test notification prepared (backend integration needed)',
        'token': token.substring(0, 50) + '...',
        'tokenLength': token.length,
      };
    } catch (e) {
      print('❌ Error sending test notification: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get notification status summary
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final setupResult = await testNotificationSetup();
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      return {
        ...setupResult,
        'timestamp': DateTime.now().toIso8601String(),
        'wateringReminders': prefs.getBool('watering_reminders') ?? true,
        'userEmail': user?.email,
        'isAnonymous': user?.isAnonymous ?? false,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
