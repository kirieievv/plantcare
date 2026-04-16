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
  bool _tokenRegistered = false;
  /// Last Firebase uid for which we saved the current device token to Firestore.
  String? _registeredTokenUserId;
  String? _currentToken;

  static const int _maxTokenRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 3);

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

      // Get and register FCM token (with retries)
      await _registerFCMTokenWithRetry();
      // Second pass: on iOS APNs is sometimes still null after the first 3 attempts.
      await ensureFCMTokenRegistered();

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

  /// Public method to ensure the FCM token is registered.
  /// Safe to call multiple times — skips if token is already saved.
  /// Useful on every app launch and after sign-up/sign-in.
  Future<void> ensureFCMTokenRegistered() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    if (_tokenRegistered && _registeredTokenUserId == user.uid) return;
    await _registerFCMTokenWithRetry();
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

  /// Try to register the FCM token with retries.
  /// On iOS the APNs token may not be available immediately after launch,
  /// so we retry a few times with a delay.
  Future<void> _registerFCMTokenWithRetry() async {
    for (int attempt = 1; attempt <= _maxTokenRetries; attempt++) {
      final success = await _registerFCMToken();
      if (success) return;

      if (attempt < _maxTokenRetries) {
        print('🔄 NotificationService: Retry $attempt/$_maxTokenRetries '
            'in ${_retryDelay.inSeconds}s...');
        await Future.delayed(_retryDelay);
      }
    }
    print('⚠️ NotificationService: Could not register FCM token after '
        '$_maxTokenRetries attempts. Will rely on onTokenRefresh.');
  }

  /// Get FCM token and register it with Firestore.
  /// Returns true if the token was successfully saved.
  Future<bool> _registerFCMToken() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        print('⚠️ NotificationService: No user logged in, skipping token registration');
        return false;
      }

      String? token;
      
      if (kIsWeb) {
        try {
          final settings = await _fcm.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            await Future.delayed(const Duration(seconds: 2));
            token = await _fcm.getToken();
          } else {
            print('❌ NotificationService: Web notification permission not granted');
            return false;
          }
        } catch (e) {
          print('❌ NotificationService: Error getting web token: $e');
          return false;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        // On iOS, wait for the APNs token before requesting FCM token
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          print('⏳ NotificationService: APNs token not ready, waiting...');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _fcm.getAPNSToken();
        }
        if (apnsToken == null) {
          print('❌ NotificationService: APNs token still not available');
          return false;
        }
        print('✅ NotificationService: APNs token available');
        token = await _fcm.getToken();
      } else {
        token = await _fcm.getToken();
      }

      if (token == null) {
        print('❌ NotificationService: Failed to get FCM token');
        return false;
      }

      print('🔔 NotificationService: FCM Token: ${token.substring(0, 20)}...');

      await _saveTokenToCollection(user.uid, token);
      _currentToken = token;
      _tokenRegistered = true;
      _registeredTokenUserId = user.uid;
      return true;
    } catch (e) {
      print('❌ NotificationService: Error registering FCM token: $e');
      return false;
    }
  }

  /// Save FCM token to the dedicated fcm_tokens collection and update
  /// summary fields on the user document so it's visible in Firestore.
  Future<void> _saveTokenToCollection(String userId, String token) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _firestore.collection('fcm_tokens').doc(token).set({
        'userId': userId,
        'createdAt': now,
      });

      // Count how many tokens this user now has.
      final snap = await _firestore
          .collection('fcm_tokens')
          .where('userId', isEqualTo: userId)
          .get();
      final count = snap.docs.length;
      final preview = token.length > 20 ? token.substring(0, 20) : token;

      await _firestore.collection('users').doc(userId).set({
        'lastFcmTokenAt': now,
        'lastFcmTokenPreview': preview,
        'fcmTokenCount': count,
      }, SetOptions(merge: true));

      print('✅ NotificationService: FCM token saved (total $count for user)');
    } catch (e) {
      print('❌ NotificationService: Error saving token to collection: $e');
    }
  }

  /// Handle token refresh — delete old token doc, create new one
  Future<void> _onTokenRefresh(String newToken) async {
    print('🔔 NotificationService: FCM token refreshed');
    final user = AuthService.currentUser;
    if (user == null) return;

    final oldToken = _currentToken;
    if (oldToken != null && oldToken != newToken) {
      await _firestore.collection('fcm_tokens').doc(oldToken).delete();
    }
    await _saveTokenToCollection(user.uid, newToken);
    _currentToken = newToken;
    _registeredTokenUserId = user.uid;
    _tokenRegistered = true;
  }

  /// Remove FCM token from Firestore (e.g., on logout)
  Future<void> removeFCMToken() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('fcm_tokens').doc(token).delete();
        print('✅ NotificationService: FCM token removed from fcm_tokens');
      }

      await _fcm.deleteToken();
      _currentToken = null;
      _tokenRegistered = false;
      _registeredTokenUserId = null;
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
      case 'open_plant':
        print('ℹ️ NotificationService: open_plant for $plantId (type=${data['type']})');
        break;
      default:
        print('ℹ️ NotificationService: Opening plant details for $plantId');
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


