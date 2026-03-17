# Watering Reminders - Deployment Checklist

Use this checklist to ensure a smooth deployment of the FCM watering reminder feature.

---

## ☑️ Pre-Deployment

### Firebase Setup
- [ ] Firebase project created
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Logged into Firebase CLI (`firebase login`)
- [ ] Project initialized (`firebase init`)

### FCM Configuration
- [ ] Firebase Cloud Messaging enabled in console
- [ ] `google-services.json` downloaded (Android)
- [ ] `GoogleService-Info.plist` downloaded (iOS)
- [ ] Web FCM config obtained (Web)

### Development Environment
- [ ] Flutter SDK installed (latest stable)
- [ ] Node.js installed (v18+)
- [ ] All dependencies installed (`flutter pub get`, `cd functions && npm install`)

---

## ☑️ Code Verification

### Models
- [ ] `UserModel` has notification fields (timezone, quietHours, fcmTokens, maxPushesPerDay)
- [ ] `Plant` model has scheduling fields (nextDueAt, nextNotificationAt, notificationState, etc.)
- [ ] `toMap()` and `fromMap()` methods updated for both models

### Services
- [ ] `NotificationService` created with FCM initialization
- [ ] `PlantService.addPlant()` initializes notification fields
- [ ] `PlantService.waterPlant()` updates notification schedule

### UI
- [ ] Settings screen has notification preferences
- [ ] Timezone selector implemented
- [ ] Quiet hours picker implemented
- [ ] Max pushes per day selector implemented

### Cloud Functions
- [ ] `sendWateringReminders` function created in `functions/index.js`
- [ ] Cron schedule set to "every 5 minutes"
- [ ] Helper functions implemented (batching, quiet hours, daily cap, etc.)

---

## ☑️ Platform-Specific Setup

### Android
- [ ] `google-services.json` in `android/app/`
- [ ] Firebase dependencies in `android/app/build.gradle.kts`
- [ ] `POST_NOTIFICATIONS` permission in `AndroidManifest.xml`
- [ ] FCM service configured in `AndroidManifest.xml`
- [ ] Test notification on Android device/emulator

### iOS
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] APNs certificate uploaded to Firebase Console
- [ ] `AppDelegate.swift` configured for FCM
- [ ] Test notification on iOS device/simulator

### Web
- [ ] Firebase config in `web/index.html`
- [ ] `firebase-messaging-sw.js` created
- [ ] FCM scripts loaded
- [ ] Test notification in web browser

---

## ☑️ Deployment Steps

### 1. Install Dependencies
```bash
cd /Users/krv/Desktop/Plant\ Care/plant_care
flutter pub get
cd functions
npm install
cd ..
```
- [ ] Flutter dependencies installed
- [ ] Cloud Functions dependencies installed

### 2. Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```
- [ ] Indexes deployed successfully
- [ ] Composite index for `plants` collection created (nextNotificationAt + muted)
- [ ] Verify in Firebase Console → Firestore → Indexes

### 3. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```
- [ ] Security rules deployed
- [ ] Users can read/write their own data
- [ ] Plants collection properly secured
- [ ] Notification counts accessible

### 4. Deploy Cloud Functions
```bash
firebase deploy --only functions:sendWateringReminders
```
- [ ] Function deployed successfully
- [ ] Cloud Scheduler job created automatically
- [ ] Verify in Firebase Console → Functions
- [ ] Check that schedule shows "every 5 minutes"

### 5. Verify Cloud Scheduler
- [ ] Go to Google Cloud Console → Cloud Scheduler
- [ ] Find `firebase-schedule-sendWateringReminders-{region}`
- [ ] Status is "ENABLED"
- [ ] Schedule is `*/5 * * * *` (every 5 minutes)
- [ ] Timezone is UTC

---

## ☑️ Testing

### FCM Token Registration
- [ ] Run app: `flutter run`
- [ ] Check logs for "🔔 NotificationService: FCM Token: ..."
- [ ] Open Firestore → users/{userId}
- [ ] Verify `fcmTokens` array contains token
- [ ] Test on multiple devices (should see multiple tokens)

### Notification Scheduling
- [ ] Add a test plant
- [ ] Check Firestore → plants/{plantId}
- [ ] Verify `nextDueAt` is calculated correctly
- [ ] Verify `nextNotificationAt` = nextDueAt - 1 hour
- [ ] Verify `notificationState` = 'ok'

### Cloud Function Execution
- [ ] Wait 5 minutes after deployment
- [ ] Check function logs: `firebase functions:log --only sendWateringReminders`
- [ ] Should see "🔔 Starting watering reminder check..."
- [ ] Verify no errors in logs

### Pre-due Notification
- [ ] Create plant with `wateringIntervalDays: 0` (same day)
- [ ] Set `preferredTime` to 1 hour from now
- [ ] Wait for notification (should arrive 2 hours from now)
- [ ] Verify notification received
- [ ] Verify quick actions work (Mark Watered, Snooze)

### Due Notification
- [ ] Don't water the plant from pre-due test
- [ ] Wait 1 hour
- [ ] Should receive "Time to water {Plant}"
- [ ] Check Firestore → `notificationState` changed to 'due'

### Overdue Notification
- [ ] Still don't water the plant
- [ ] Wait until next day at preferred time
- [ ] Should receive overdue notification
- [ ] Check Firestore → `overdueStreak` = 1

### Quiet Hours
- [ ] Set quiet hours to current time ± 30 min
- [ ] Create test plant to trigger notification now
- [ ] Verify notification is NOT sent
- [ ] Verify `nextNotificationAt` is shifted to end of quiet hours

### Batching
- [ ] Create 3 plants all with same notification time
- [ ] Wait for notifications
- [ ] Should receive 1 combined notification
- [ ] Body should mention multiple plants

### Daily Cap
- [ ] Set `maxPushesPerDay: 1` in settings
- [ ] Create multiple test plants
- [ ] Should only receive 1 notification
- [ ] Check `notification_counts` collection
- [ ] Verify count is tracked

### Mark Watered Action
- [ ] Tap "Mark Watered" on notification
- [ ] Check Firestore → `lastWateredAt` updated
- [ ] Verify `nextDueAt` recalculated
- [ ] Verify `notificationState` = 'ok'
- [ ] Verify `overdueStreak` = 0

### Snooze Action
- [ ] Tap "Snooze 6h" on notification
- [ ] Check Firestore → `snoozedUntil` set to now + 6h
- [ ] Wait 5 minutes
- [ ] Verify no new notification sent
- [ ] Wait 6 hours
- [ ] Verify notification resumes

### Mute Plant
- [ ] Toggle mute on a plant
- [ ] Verify `muted` = true in Firestore
- [ ] Verify plant is excluded from notifications
- [ ] Unmute and verify notifications resume

---

## ☑️ Monitoring

### Set Up Alerts
- [ ] Firebase Console → Functions → sendWateringReminders → Metrics
- [ ] Create alert for error rate > 5%
- [ ] Create alert for execution time > 30s
- [ ] Create alert for memory usage > 512MB

### Monitor Metrics
- [ ] Function invocations (should be ~12/hour)
- [ ] Error rate (should be < 1%)
- [ ] Execution duration (should be < 10s)
- [ ] Firestore reads/writes

### Check Logs Regularly
- [ ] `firebase functions:log --only sendWateringReminders`
- [ ] Look for errors or warnings
- [ ] Monitor FCM delivery success rate
- [ ] Check for invalid token removals

---

## ☑️ User Communication

### Documentation
- [ ] Update app README with notification features
- [ ] Create user guide for notification settings
- [ ] Document troubleshooting steps

### Release Notes
- [ ] Mention new watering reminder feature
- [ ] Explain quiet hours and daily caps
- [ ] Show how to configure preferences
- [ ] Explain Mark Watered and Snooze actions

### Support
- [ ] Prepare FAQ for common questions
- [ ] Train support team on notification settings
- [ ] Set up feedback mechanism for notification issues

---

## ☑️ Post-Deployment

### Week 1
- [ ] Monitor function execution daily
- [ ] Check user feedback/complaints
- [ ] Verify FCM delivery rates
- [ ] Adjust cron frequency if needed
- [ ] Fix any critical bugs

### Week 2-4
- [ ] Analyze notification engagement (open rates, actions)
- [ ] Optimize notification copy based on feedback
- [ ] Adjust default settings if needed
- [ ] Consider adding more reminder types

### Month 2+
- [ ] Review and optimize Cloud Function performance
- [ ] Consider batching improvements
- [ ] Add advanced features (rich notifications, images)
- [ ] Implement ML-based scheduling

---

## ☑️ Rollback Plan

### If Critical Issues Arise

1. **Disable Notifications Immediately**
   ```bash
   firebase functions:config:set notifications.enabled=false
   firebase deploy --only functions:sendWateringReminders
   ```

2. **Pause Cloud Scheduler**
   - Go to Cloud Scheduler in Google Cloud Console
   - Pause the `sendWateringReminders` job

3. **Fix Issues**
   - Identify root cause from logs
   - Test fix locally
   - Deploy fix

4. **Re-enable Gradually**
   - Enable for small group of users first
   - Monitor closely
   - Expand to all users once stable

---

## 🎉 Success Criteria

Deployment is successful when:
- [ ] FCM tokens registered for all logged-in users
- [ ] Notifications sent on schedule (every 5 minutes)
- [ ] Pre-due, due, and overdue reminders work correctly
- [ ] Quiet hours respected
- [ ] Batching combines multiple plant reminders
- [ ] Daily cap prevents spam
- [ ] Quick actions (Mark Watered, Snooze) work
- [ ] No critical errors in Cloud Function logs
- [ ] User satisfaction with notification timing and frequency

---

## 📞 Emergency Contacts

- **Firebase Console:** https://console.firebase.google.com/
- **Google Cloud Console:** https://console.cloud.google.com/
- **FCM Documentation:** https://firebase.google.com/docs/cloud-messaging
- **Support:** Check Firebase support channels

---

## 📝 Notes

Use this space for deployment-specific notes:

```
Deployment Date: _______________
Deployed By: _______________
Firebase Project: _______________
Issues Encountered: _______________
_______________
_______________
```

---

**Checklist Version:** 1.0.0  
**Last Updated:** October 7, 2025  
**Next Review:** After 1 month of production use










