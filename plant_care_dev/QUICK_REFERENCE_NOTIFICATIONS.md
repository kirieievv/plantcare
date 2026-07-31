# Watering Reminders - Quick Reference Card

## 🚀 Quick Start

```bash
# Deploy everything
./deploy_notifications.sh

# Or step-by-step:
flutter pub get
firebase deploy --only functions:sendWateringReminders
firebase deploy --only firestore:indexes
firebase deploy --only firestore:rules
```

---

## 📋 Key Files

| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | FCM token management, notification handling |
| `lib/models/user_model.dart` | User notification preferences |
| `lib/models/plant.dart` | Plant notification scheduling |
| `lib/services/plant_service.dart` | Plant watering logic |
| `lib/screens/settings_screen.dart` | User settings UI |
| `functions/index.js` | Cloud Function cron job |
| `lib/main.dart` | App initialization, background handler |

---

## 🔑 Important Fields

### User Document (`users/{userId}`)
```dart
timezone: "America/New_York"
quietHours: {start: "22:00", end: "08:00"}
fcmTokens: ["token1", "token2"]
maxPushesPerDay: 3
```

### Plant Document (`plants/{plantId}`)
```dart
lastWateredAt: DateTime
wateringIntervalDays: 7
preferredTime: "18:00"
nextDueAt: DateTime
nextNotificationAt: DateTime
notificationState: "ok" | "due" | "overdue"
snoozedUntil: DateTime?
muted: false
overdueStreak: 0
```

---

## 🕐 Notification Timeline

```
Today 17:00    → Pre-due: "Heads-up: Plant needs water in 1 hour"
Today 18:00    → Due: "Time to water Plant"
Tomorrow 18:00 → Overdue D+1: "Plant is thirsty"
D+2 at 18:00   → Overdue D+2: "Plant really needs water"
D+3 at 18:00   → Overdue D+3: "🆘 Plant is very thirsty!"
D+7 at 18:00   → Overdue D+7: "🆘 Plant is very thirsty!" (LAST)
```

---

## 🛠 Common Operations

### Initialize Notifications
```dart
await NotificationService().initialize();
```

### Update User Preferences
```dart
await NotificationService().updateUserTimezone("America/Los_Angeles");
await NotificationService().updateQuietHours("22:00", "08:00");
await NotificationService().updateMaxPushesPerDay(5);
```

### Mute/Unmute Plant
```dart
await NotificationService().togglePlantMute(plantId, true);  // mute
await NotificationService().togglePlantMute(plantId, false); // unmute
```

### Water a Plant
```dart
await PlantService().waterPlant(plantId);
// This automatically:
// - Updates lastWateredAt
// - Calculates nextDueAt
// - Sets nextNotificationAt = nextDueAt - 1h
// - Resets notificationState = 'ok'
// - Clears overdueStreak and snoozedUntil
```

---

## 🐛 Debugging

### Check FCM Token
```dart
// In app logs, look for:
"🔔 NotificationService: FCM Token: abc123..."
```

### Check Firestore
```javascript
// User tokens
users/{userId}.fcmTokens

// Plant schedule
plants/{plantId}.nextNotificationAt
plants/{plantId}.notificationState
```

### Check Cloud Function Logs
```bash
firebase functions:log --only sendWateringReminders
```

### Test Cloud Function Locally
```bash
cd functions
npm run serve
```

---

## 📱 Testing Scenarios

### Test Pre-due Notification
1. Create plant with `wateringIntervalDays: 0` (waters today)
2. Set `preferredTime: "{current_hour+1}:00"`
3. Wait 5 minutes for cron to run
4. Should receive pre-due notification

### Test Quiet Hours
1. Set quiet hours to current time range
2. Trigger notification
3. Check that `nextNotificationAt` is shifted to end of quiet hours

### Test Batching
1. Create 3 plants all with same notification time
2. Wait for cron
3. Should receive 1 combined notification

### Test Daily Cap
1. Set `maxPushesPerDay: 1`
2. Trigger multiple notifications
3. Should only receive 1, rest rolled to tomorrow

---

## 🔍 Troubleshooting

| Issue | Check | Solution |
|-------|-------|----------|
| No notifications | FCM token registered? | Check user doc `fcmTokens` array |
| Wrong timing | Timezone set? | Update in Settings |
| Too many notifications | Daily cap? | Set `maxPushesPerDay` lower |
| Notifications during sleep | Quiet hours? | Set in Settings |
| Plant always sending | Muted? | Check `plants/{id}.muted` field |
| Overdue won't stop | Streak count? | After D+7 (streak=4), stops automatically |

---

## 💡 Pro Tips

1. **Default Timezone:** Set to user's device timezone on first login
2. **Testing:** Use short intervals (5 min) for testing, reset to normal after
3. **Monitoring:** Set up Firebase alerts for Cloud Function errors
4. **Token Cleanup:** Cloud Function auto-removes invalid tokens
5. **Indexes:** Always deploy Firestore indexes before function
6. **Quiet Hours:** Recommend 22:00-08:00 for most users
7. **Daily Cap:** 3 is optimal to avoid spam while staying informed
8. **Snooze:** Perfect for "I'll water it after breakfast" scenarios
9. **Mute:** Use for test plants or plants in dormancy
10. **Preferred Time:** Evening (18:00) works best for most users

---

## 📞 Support Commands

```bash
# View function logs
firebase functions:log --only sendWateringReminders --limit 50

# Check function status
firebase functions:config:get

# Test notification locally
firebase emulators:start --only functions

# Check Firestore indexes
firebase firestore:indexes

# Deploy only one component
firebase deploy --only functions
firebase deploy --only firestore:indexes
firebase deploy --only firestore:rules
```

---

## 📚 Documentation Links

- **Full Setup Guide:** `WATERING_REMINDERS_SETUP.md`
- **Implementation Summary:** `WATERING_REMINDERS_IMPLEMENTATION_SUMMARY.md`
- **User Story:** Original requirements in this conversation
- **Firebase Docs:** https://firebase.google.com/docs/cloud-messaging
- **Cloud Scheduler:** https://firebase.google.com/docs/functions/schedule-functions

---

**Quick Help:** For issues, check logs first → verify Firestore data → test FCM token → check Cloud Function execution

**Version:** 1.0.0  
**Last Updated:** October 7, 2025










