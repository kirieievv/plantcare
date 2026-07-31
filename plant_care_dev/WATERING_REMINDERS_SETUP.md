# Watering Reminders via FCM - Setup Guide

This document outlines how to set up and deploy the FCM-based watering reminder system for the Plant Care app.

## Overview

The watering reminder system sends timely push notifications to users when their plants need water. It includes:

- **Pre-due reminders** (1 hour before due time)
- **Due reminders** (at the scheduled time)
- **Overdue reminders** (with gentle escalation on D+1, D+2, D+3, D+7)
- **Quiet hours** (user-configurable time window to avoid notifications)
- **Batching** (combines multiple plant reminders into one notification)
- **Daily caps** (limits notifications per day to avoid spam)
- **Quick actions** (Mark Watered, Snooze 6h)

## Architecture

### Components

1. **Flutter App** (`lib/services/notification_service.dart`)
   - Registers FCM tokens with Firestore
   - Handles foreground/background notifications
   - Implements quick action handlers (Mark Watered, Snooze)
   
2. **Cloud Functions** (`functions/index.js`)
   - Cron job that runs every 5 minutes
   - Queries plants needing notifications
   - Applies timing rules, quiet hours, batching, daily caps
   - Sends FCM messages via Firebase Admin SDK

3. **Data Models**
   - **User document** (`users/{userId}`):
     - `fcmTokens`: Array of FCM device tokens
     - `timezone`: IANA timezone string
     - `quietHours`: {start, end} in HH:mm format
     - `maxPushesPerDay`: Integer (default 3)
   
   - **Plant document** (`users/{userId}/plants/{plantId}` or `plants/{plantId}`):
     - `lastWateredAt`: DateTime
     - `wateringIntervalDays`: Integer
     - `preferredTime`: HH:mm format
     - `nextDueAt`: DateTime
     - `nextNotificationAt`: DateTime
     - `notificationState`: 'ok' | 'due' | 'overdue'
     - `snoozedUntil`: DateTime (nullable)
     - `muted`: Boolean
     - `overdueStreak`: Integer

## Setup Instructions

### 1. Firebase Configuration

#### Enable Firebase Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** → **Cloud Messaging**
4. Note your **Server Key** (for Cloud Functions)

#### Android Setup

1. Add the `google-services.json` file to `android/app/`
2. Update `android/app/build.gradle.kts`:
   ```kotlin
   dependencies {
       implementation(platform("com.google.firebase:firebase-bom:32.0.0"))
       implementation("com.google.firebase:firebase-messaging")
   }
   ```

3. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   
   <application>
       <service
           android:name="io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService"
           android:exported="false">
           <intent-filter>
               <action android:name="com.google.firebase.MESSAGING_EVENT" />
           </intent-filter>
       </service>
   </application>
   ```

#### iOS Setup

1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Enable **Push Notifications** capability
4. Enable **Background Modes** → **Remote notifications**
5. Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   import Firebase
   import FirebaseMessaging
   
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     FirebaseApp.configure()
     if #available(iOS 10.0, *) {
       UNUserNotificationCenter.current().delegate = self
     }
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```

#### Web Setup

1. Add Firebase config to `web/index.html`:
   ```html
   <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"></script>
   <script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js"></script>
   ```

2. Create `web/firebase-messaging-sw.js` (service worker for background messages)

### 2. Flutter Dependencies

Run:
```bash
cd plant_care
flutter pub get
```

The following packages have been added to `pubspec.yaml`:
- `firebase_messaging: ^15.0.0`
- `flutter_local_notifications: ^17.0.0`
- `timezone: ^0.9.0`

### 3. Cloud Functions Setup

#### Install Dependencies

```bash
cd functions
npm install
```

#### Deploy Cloud Function

```bash
firebase deploy --only functions:sendWateringReminders
```

This deploys the cron job that runs every 5 minutes.

#### Verify Deployment

Check the Firebase Console → **Functions** section to confirm the function is deployed and scheduled.

### 4. Cloud Scheduler (Automatic)

The `sendWateringReminders` function is configured with:
```javascript
exports.sendWateringReminders = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('UTC')
  .onRun(async (context) => {
    // ... notification logic
  });
```

Firebase automatically creates a Cloud Scheduler job when you deploy this function.

### 5. Firestore Indexes

The cron function queries plants by `nextNotificationAt` and `muted`. Create a composite index:

1. Go to **Firestore** → **Indexes**
2. Create index for `plants` collection:
   - Fields: `nextNotificationAt` (Ascending), `muted` (Ascending)
   - Query scope: Collection

Or use the Firebase CLI:
```bash
firebase deploy --only firestore:indexes
```

With `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "plants",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "nextNotificationAt", "order": "ASCENDING" },
        { "fieldPath": "muted", "order": "ASCENDING" }
      ]
    }
  ]
}
```

### 6. Firestore Security Rules

Update `firestore.rules` to allow the app to update notification fields:

```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /plants/{plantId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /plants/{plantId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /notification_counts/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only firestore:rules
```

## Usage

### For Users

1. **Configure Notification Preferences**
   - Open the app → Settings
   - Set your timezone (e.g., "America/New_York")
   - Set quiet hours (e.g., 22:00 - 08:00)
   - Set max notifications per day (default: 3)

2. **Add Plants**
   - When adding a plant, the app automatically sets up notification scheduling
   - `preferredTime` defaults to 18:00 (6 PM)
   - `wateringIntervalDays` is based on the plant's watering frequency

3. **Receive Notifications**
   - **Pre-due**: "Heads-up: {Plant} needs water in 1 hour"
   - **Due**: "Time to water {Plant}"
   - **Overdue**: "🆘 {Plant} is very thirsty!"

4. **Quick Actions**
   - Tap **Mark Watered** to update the plant and reset the schedule
   - Tap **Snooze 6h** to delay the reminder

5. **Mute Plants**
   - Long-press a plant → Mute notifications
   - Useful for plants you're testing or don't want reminders for

### For Developers

#### Testing Locally

1. **Test FCM Registration**
   ```bash
   flutter run
   # Check logs for "🔔 NotificationService: FCM Token: ..."
   ```

2. **Test Cloud Function Locally**
   ```bash
   cd functions
   npm run serve
   ```

3. **Manual Trigger**
   You can manually trigger the function from the Firebase Console or via Pub/Sub.

#### Debugging

- Check Cloud Function logs: `firebase functions:log --only sendWateringReminders`
- Check Firestore for `notification_counts` collection to see daily push counts
- Check app logs for "🔔 NotificationService" messages

#### Monitoring

- **Firebase Console** → **Functions** → View function execution logs
- **Cloud Scheduler** → Check job runs and success/failure rates
- **Firestore** → Monitor `nextNotificationAt` timestamps

## Timing Rules

### Pre-due Reminder
- Sent 1 hour before `nextDueAt`
- Updates `notificationState` to 'due'
- Sets `nextNotificationAt` to `nextDueAt`

### Due Reminder
- Sent at `nextDueAt`
- Updates `notificationState` to 'overdue'
- Sets `nextNotificationAt` to tomorrow at `preferredTime`
- Sets `overdueStreak` to 1

### Overdue Reminders
- **D+1**: First overdue reminder
- **D+2**: Second overdue reminder
- **D+3**: Third overdue reminder
- **D+7**: Final reminder
- After D+7, no more reminders are sent (until user waters the plant)

### Quiet Hours
- If a notification falls within quiet hours, it's shifted to the end of quiet hours
- Example: Quiet hours 22:00 - 08:00, notification at 07:30 → shifted to 08:00

### Batching
- If multiple plants trigger within 1 hour, send one combined notification
- Title: "3 plants need water"
- Body: "{Plant1}, {Plant2} and 1 more need water"

### Daily Caps
- If user has received `maxPushesPerDay` notifications today, roll remaining notifications to tomorrow
- Counts are tracked in `notification_counts/{userId}_{date}`

## Acceptance Criteria (GWT)

### ✅ Pre-due reminder
- **Given** a plant with `next_due_at` = today 18:00
- **When** time is 17:00 in user's timezone
- **Then** user receives "Heads-up: {Plant} needs water in 1 hour"

### ✅ Due reminder
- **Given** pre-due was sent and user didn't mark watered
- **When** time reaches `next_due_at`
- **Then** send "Time to water {Plant}" and set state='due'

### ✅ Overdue escalation
- **Given** due reminder was sent and not completed
- **When** day is D+1 at `preferred_time`
- **Then** send overdue nudge and set `overdueStreak`=1; repeat at D+3 and D+7, then stop

### ✅ Quiet hours shift
- **Given** `quiet_hours`=22:00–08:00 and a reminder falls at 07:30
- **When** cron runs
- **Then** do not send; set `next_notification_at`=08:00

### ✅ Batching
- **Given** 3 plants trigger within 15 minutes
- **When** notifications are sent
- **Then** send a single push: title "3 plants need water", body with first 2 names and "+1 more"

### ✅ Daily cap
- **Given** user already received 3 pushes today
- **When** another reminder becomes due
- **Then** do not send; roll `next_notification_at` to next calendar day at `preferred_time`

### ✅ Mark watered action
- **Given** a Due or Overdue notification
- **When** user taps Mark watered
- **Then** update fields and no further nudges for that cycle

### ✅ Snooze action
- **Given** any reminder
- **When** user taps Snooze 6h
- **Then** set `snoozed_until`=now+6h and suppress pushes until then

### ✅ Timezone correctness
- **Given** user `tz` = Europe/Berlin
- **When** `preferred_time` = 18:00
- **Then** `next_due_at` aligns to 18:00 local even across DST changes

### ✅ Token handling
- **Given** user installs on a new device
- **When** app registers an FCM token
- **Then** token is added to `fcm_tokens[]`; notifications are delivered to all active tokens

## Troubleshooting

### Notifications Not Received

1. **Check FCM token registration**
   - Look for "🔔 NotificationService: FCM Token: ..." in app logs
   - Verify `fcmTokens` array in user document is not empty

2. **Check Cloud Function execution**
   - View function logs: `firebase functions:log`
   - Ensure function runs every 5 minutes

3. **Check plant scheduling**
   - Verify `nextNotificationAt` is in the past
   - Verify `muted` is false
   - Verify `snoozedUntil` is null or in the past

4. **Check Firestore indexes**
   - Ensure composite index for `plants` collection exists

### Notifications Sent at Wrong Time

1. **Check user timezone**
   - Verify `timezone` field in user document
   - Update via Settings → Timezone

2. **Check quiet hours**
   - Verify `quietHours.start` and `quietHours.end`
   - Notifications in quiet hours are shifted to the end

3. **Check preferred time**
   - Verify `preferredTime` field in plant document
   - Default is "18:00" if not set

### Too Many / Too Few Notifications

1. **Check daily cap**
   - Verify `maxPushesPerDay` in user document
   - Check `notification_counts` collection

2. **Check batching logic**
   - Multiple plants within 1 hour should batch

3. **Check overdue streak**
   - After D+7, reminders stop until plant is watered

## Next Steps

- [ ] Add iOS APNs certificates for production
- [ ] Implement rich notifications with images
- [ ] Add notification history/log in the app
- [ ] Support multiple watering times per day
- [ ] Add seasonal adjustments (e.g., water less in winter)
- [ ] Implement "Mark as on vacation" to pause all reminders

## Support

For issues or questions, please check:
- Firebase Console logs
- App logs (Flutter DevTools)
- Firestore data consistency

---

**Last Updated**: October 2025
**Version**: 1.0.0


