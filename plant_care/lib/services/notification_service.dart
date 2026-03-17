import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/plant_service.dart';

/// Handles FCM push notifications and local notifications for watering reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _initialized = false;

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🔔 NotificationService: Initializing...');

      // Initialize timezone database
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Get and register FCM token
      await _registerFCMToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_onTokenRefresh);

      // Set up message handlers
      _setupMessageHandlers();

      _initialized = true;
      print('✅ NotificationService: Initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Error during initialization: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'watering_reminders',
          'Watering Reminders',
          description: 'Notifications for plant watering reminders',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  /// Request notification permissions from the user
  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 NotificationService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ NotificationService: Notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ NotificationService: Provisional notification permissions granted');
      } else {
        print('❌ NotificationService: Notification permissions denied');
      }
    } catch (e) {
      print('❌ NotificationService: Error requesting permissions: $e');
    }
  }

  /// Get FCM token and register it with Firestore
  Future<void> _registerFCMToken() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        print('⚠️ NotificationService: No user logged in, skipping token registration');
        return;
      }

      String? token;
      
      // For web platform, we need to handle token generation differently
      if (kIsWeb) {
        try {
          // Request permission first
          final settings = await _fcm.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            // For web, we might need to wait a bit for the token
            await Future.delayed(const Duration(seconds: 2));
            token = await _fcm.getToken();
          } else {
            print('❌ NotificationService: Web notification permission not granted');
            return;
          }
        } catch (e) {
          print('❌ NotificationService: Error getting web token: $e');
          return;
        }
      } else {
        // For mobile platforms
        token = await _fcm.getToken();
      }

      if (token == null) {
        print('❌ NotificationService: Failed to get FCM token');
        return;
      }

      print('🔔 NotificationService: FCM Token: ${token.substring(0, 20)}...');

      // Store token in Firestore
      await _addTokenToFirestore(user.uid, token);
    } catch (e) {
      print('❌ NotificationService: Error registering FCM token: $e');
    }
  }

  /// Add FCM token to user's Firestore document
  Future<void> _addTokenToFirestore(String userId, String token) async {
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
            },
            SetOptions(merge: true),
          );
          print('✅ NotificationService: FCM token added to Firestore');
        } else {
          print('ℹ️ NotificationService: FCM token already registered');
        }
      });
    } catch (e) {
      print('❌ NotificationService: Error adding token to Firestore: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    print('🔔 NotificationService: FCM token refreshed');
    final user = AuthService.currentUser;
    if (user != null) {
      await _addTokenToFirestore(user.uid, newToken);
    }
  }

  /// Remove FCM token from Firestore (e.g., on logout)
  Future<void> removeFCMToken() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        if (snapshot.exists && snapshot.data()?['fcmTokens'] != null) {
          List<String> tokens = List<String>.from(snapshot.data()!['fcmTokens']);
          tokens.remove(token);
          
          transaction.update(userDoc, {
            'fcmTokens': tokens,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ NotificationService: FCM token removed from Firestore');
        }
      });

      // Delete token from FCM
      await _fcm.deleteToken();
    } catch (e) {
      print('❌ NotificationService: Error removing FCM token: $e');
    }
  }

  /// Set up message handlers for FCM
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification tap when app was terminated
    _checkInitialMessage();
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 NotificationService: Foreground message received');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle when user taps on a notification (app was in background)
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('🔔 NotificationService: Notification opened app from background');
    await _handleNotificationAction(message.data);
  }

  /// Check if app was opened from a notification when it was terminated
  Future<void> _checkInitialMessage() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      print('🔔 NotificationService: App opened from notification (was terminated)');
      await _handleNotificationAction(message.data);
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'watering_reminders',
      'Watering Reminders',
      channelDescription: 'Notifications for plant watering reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      // Action buttons for quick responses
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_watered',
          'Mark Watered',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 6h',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _encodePayload(message.data),
    );
  }

  /// Handle notification action (tap or button press)
  Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    print('🔔 NotificationService: Handling notification action');
    print('   Data: $data');

    final action = data['action'];
    final plantId = data['plantId'];

    if (plantId == null) {
      print('⚠️ NotificationService: No plantId in notification data');
      return;
    }

    switch (action) {
      case 'mark_watered':
        await _markPlantWatered(plantId);
        break;
      case 'snooze':
        await _snoozePlantReminder(plantId);
        break;
      default:
        print('ℹ️ NotificationService: Opening plant details for $plantId');
        // Navigation will be handled by the app
        break;
    }
  }

  /// Handle taps on local notifications
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 NotificationService: Local notification tapped');
    
    if (response.actionId == 'mark_watered') {
      final data = _decodePayload(response.payload ?? '');
      final plantId = data['plantId'];
      if (plantId != null) {
        _markPlantWatered(plantId);
      }
    } else if (response.actionId == 'snooze') {
      final data = _decodePayload(response.payload ?? '');
      final plantId = data['plantId'];
      if (plantId != null) {
        _snoozePlantReminder(plantId);
      }
    } else if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      print('   Payload data: $data');
      // Navigation will be handled by the app
    }
  }

  /// Mark a plant as watered and update its schedule
  Future<void> _markPlantWatered(String plantId) async {
    try {
      print('💧 NotificationService: Marking plant $plantId as watered');
      
      final user = AuthService.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final plantDoc = _firestore.collection('plants').doc(plantId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(plantDoc);
        
        if (!snapshot.exists) {
          print('⚠️ NotificationService: Plant $plantId not found');
          return;
        }

        final data = snapshot.data()!;
        final wateringIntervalDays = data['wateringIntervalDays'] ?? data['wateringFrequency'] ?? 7;
        final preferredTime = data['preferredTime'] ?? '18:00';

        // Calculate next due date at preferred time
        final nextDue = _calculateNextDueAt(now, wateringIntervalDays, preferredTime);
        
        // Set next notification to 1 hour before due time
        final nextNotification = nextDue.subtract(const Duration(hours: 1));

        transaction.update(plantDoc, {
          'lastWatered': now.toIso8601String(),
          'lastWateredAt': now.toIso8601String(),
          'nextWatering': nextDue.toIso8601String(),
          'nextDueAt': nextDue.toIso8601String(),
          'nextNotificationAt': nextNotification.toIso8601String(),
          'notificationState': 'ok',
          'overdueStreak': 0,
          'snoozedUntil': null,
        });

        print('✅ NotificationService: Plant watered, next due: $nextDue');
      });
    } catch (e) {
      print('❌ NotificationService: Error marking plant as watered: $e');
    }
  }

  /// Snooze a plant reminder for 6 hours
  Future<void> _snoozePlantReminder(String plantId) async {
    try {
      print('⏰ NotificationService: Snoozing plant $plantId for 6 hours');
      
      final now = DateTime.now();
      final snoozedUntil = now.add(const Duration(hours: 6));

      await _firestore.collection('plants').doc(plantId).update({
        'snoozedUntil': snoozedUntil.toIso8601String(),
      });

      print('✅ NotificationService: Plant snoozed until $snoozedUntil');
    } catch (e) {
      print('❌ NotificationService: Error snoozing plant reminder: $e');
    }
  }

  /// Calculate next due date at preferred time
  DateTime _calculateNextDueAt(DateTime from, int intervalDays, String preferredTime) {
    // Parse preferred time (HH:mm)
    final timeParts = preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Add interval days to current date
    var nextDue = from.add(Duration(days: intervalDays));
    
    // Set to preferred time
    nextDue = DateTime(
      nextDue.year,
      nextDue.month,
      nextDue.day,
      hour,
      minute,
    );

    return nextDue;
  }

  /// Encode notification payload as a simple string
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode notification payload from string
  Map<String, String> _decodePayload(String payload) {
    if (payload.isEmpty) return {};
    
    return Map.fromEntries(
      payload.split('&').map((pair) {
        final parts = pair.split('=');
        return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
      }),
    );
  }

  /// Update user's timezone in Firestore
  Future<void> updateUserTimezone(String timezone) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'timezone': timezone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ NotificationService: User timezone updated to $timezone');
    } catch (e) {
      print('❌ NotificationService: Error updating timezone: $e');
    }
  }

  /// Update user's quiet hours
  Future<void> updateQuietHours(String start, String end) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'quietHours': {
          'start': start,
          'end': end,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ NotificationService: Quiet hours updated to $start - $end');
    } catch (e) {
      print('❌ NotificationService: Error updating quiet hours: $e');
    }
  }

  /// Update max pushes per day
  Future<void> updateMaxPushesPerDay(int max) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'maxPushesPerDay': max,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ NotificationService: Max pushes per day updated to $max');
    } catch (e) {
      print('❌ NotificationService: Error updating max pushes: $e');
    }
  }

  /// Mute/unmute notifications for a specific plant
  Future<void> togglePlantMute(String plantId, bool muted) async {
    try {
      await _firestore.collection('plants').doc(plantId).update({
        'muted': muted,
      });

      print('✅ NotificationService: Plant $plantId ${muted ? "muted" : "unmuted"}');
    } catch (e) {
      print('❌ NotificationService: Error toggling plant mute: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
  // Handle background message
}


