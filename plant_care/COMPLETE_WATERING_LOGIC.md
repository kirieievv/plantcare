# Complete Watering Logic Implementation

## Overview
This document explains the complete watering calculation flow from AI analysis to UI display, with consistent preferred time handling across all flows.

---

## 1. AI RESPONSE STRUCTURE

The AI (ChatGPT) returns species-specific watering data:

```json
{
  "watering_plan": {
    "should_water_now": true,        // boolean
    "next_watering_in_days": 7,      // integer 1-60
    "reason_short": "..."            // string
  },
  "species": {
    "ai_species_guess": "Pelargonium",
    "species_confidence": 0.9
  },
  "soil": {
    "visual_state": "dry",
    "moisture_current_pct": 40
  }
}
```

### AI Logic:
- `should_water_now = true`: "Water now, then again in X days" → interval is days until NEXT watering after this one
- `should_water_now = false`: "Don't water now, water in X days" → interval is days from today

**Both cases use the same calculation:** `nextWateringAt = today + next_watering_in_days` (with preferred time applied)

---

## 2. SHARED CALCULATION HELPER

**File:** `lib/services/plant_service.dart`

```dart
static DateTime calculateNextWateringAt({
  required DateTime from,
  required int intervalDays,
  String preferredTime = '18:00',
}) {
  // Parse preferred time (HH:mm format)
  final timeParts = preferredTime.split(':');
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  
  // Add interval days to base date
  var nextDue = from.add(Duration(days: intervalDays));
  
  // Apply preferred time (same day, just change hour/minute)
  return DateTime(
    nextDue.year,
    nextDue.month,
    nextDue.day,
    hour,
    minute,
    0, 0, 0  // seconds, milliseconds, microseconds
  );
}
```

**This is the single source of truth** for calculating `nextWateringAt` with preferred time.

---

## 3. FLOW 1: ADD PLANT (Initial AI Analysis)

**Files:**
- `lib/screens/add_plant_screen.dart` (extraction)
- `lib/services/plant_service.dart` (calculation)

### Step 1: Extract from AI Response
```dart
final wateringPlan = recommendations['watering_plan'];
_nextWateringInDays = wateringPlan['next_watering_in_days'];  // e.g., 7
_shouldWaterNow = wateringPlan['should_water_now'];            // e.g., false
```

### Step 2: Store in Plant Model
```dart
Plant(
  wateringIntervalDays: _nextWateringInDays,  // 7
  shouldWaterNow: _shouldWaterNow,            // false
  // ... other fields
)
```

### Step 3: Calculate nextWateringAt in PlantService.addPlant()
```dart
final nextDue = calculateNextWateringAt(
  from: DateTime.now(),
  intervalDays: wateringIntervalDays,  // 7
  preferredTime: '18:00',              // or from settings
);

// Result: If today is Dec 2, 2024 at 15:00
// nextDue = Dec 9, 2024 at 18:00
```

**Saved to Firestore:**
- `wateringIntervalDays`: 7
- `shouldWaterNow`: false
- `nextDueAt`: "2024-12-09T18:00:00.000Z"
- `preferredTime`: "18:00"

---

## 4. FLOW 2: HEALTH CHECK (Check Plant)

**Files:**
- `lib/widgets/health_check_modal.dart` (extraction)
- `lib/screens/plant_details_screen.dart` (calculation)

### Step 1: Extract from AI Response
```dart
final wateringPlan = recommendations['watering_plan'];
final wateringIntervalDays = wateringPlan['next_watering_in_days'];  // e.g., 5
final shouldWaterNow = wateringPlan['should_water_now'];              // e.g., true
```

### Step 2: Calculate nextWateringAt (SAME LOGIC AS ADD PLANT)
```dart
final now = DateTime.now();
final preferredTime = _plant.preferredTime ?? '18:00';

final newNextDueAt = PlantService.calculateNextWateringAt(
  from: now,
  intervalDays: newIntervalDays,  // 5
  preferredTime: preferredTime,   // "18:00"
);

// Result: If today is Dec 2, 2024 at 15:00
// newNextDueAt = Dec 7, 2024 at 18:00
```

### Step 3: Update Plant
```dart
final updatedPlant = _plant.copyWith(
  wateringIntervalDays: newIntervalDays,  // 5
  shouldWaterNow: newShouldWaterNow,      // true
  nextDueAt: newNextDueAt,                // Dec 7, 2024 18:00
);
```

**Key Point:** Uses the **same helper function** as AddPlant, ensuring consistency!

---

## 5. FLOW 3: USER WATERS PLANT

**File:** `lib/services/plant_service.dart` (waterPlant method)

### Logic:
```dart
final wateringIntervalDays = plant.wateringIntervalDays ?? plant.wateringFrequency;
final preferredTime = plant.preferredTime ?? '18:00';

// Use shared helper (SAME AS OTHER FLOWS)
final nextDue = calculateNextWateringAt(
  from: DateTime.now(),
  intervalDays: wateringIntervalDays,
  preferredTime: preferredTime,
);

// Update plant
transaction.update(docRef, {
  'nextDueAt': nextDue.toIso8601String(),
  'shouldWaterNow': false,  // Reset after watering
  // ... other fields
});
```

**Key Point:** Also uses the **same helper function** and resets `shouldWaterNow` to false.

---

## 6. UI DISPLAY LOGIC

**File:** `lib/screens/plant_details_screen.dart`

### 6.1. Watering Card (Date Only)

```dart
// Shows ONLY date, no time
DateFormat('MMM dd').format(_getNextWateringDate())  // "Dec 09"
_getNextWateringDisplay()                             // "Next in 7 days"
```

### 6.2. Button State & Label

```dart
bool _canWaterPlant() {
  // PRIORITY 1: Use shouldWaterNow flag from AI
  if (_plant.shouldWaterNow) {
    return true;  // Button enabled, shows "Water now"
  }
  
  // PRIORITY 2: Fallback to date comparison
  final now = DateTime.now();
  final wateringDate = _getNextWateringDate();
  return wateringDate.isBefore(now) || wateringDate.isAtSameMomentAs(now);
}

String _getWateringButtonLabel() {
  if (_plant.shouldWaterNow) {
    return 'Water now';  // Active button
  }
  
  if (_wateringCountdownLabel != null) {
    return 'Next in $_wateringCountdownLabel';  // Disabled, shows countdown
  }
  
  return 'I have watered';  // Default
}
```

### Button Behavior:
- **`shouldWaterNow = true`**: 
  - Button **enabled** (green)
  - Label: **"Water now"**
  
- **`shouldWaterNow = false`**:
  - Button **disabled** (grey)
  - Label: **"Next in X days"** (days calculated from today to nextDueAt)

---

## 7. DATA FLOW SUMMARY

```
AI Analysis
    ↓
watering_plan.next_watering_in_days (1-60)
watering_plan.should_water_now (boolean)
    ↓
Extract & Store in Plant Model
    ↓
calculateNextWateringAt(from: now, intervalDays, preferredTime)
    ↓
nextDueAt = Dec 9, 2024 at 18:00 (with preferred time)
    ↓
Save to Firestore
    ↓
UI Display:
  - Card: "Dec 09" (date only)
  - Button: "Water now" or "Next in X days"
```

---

## 8. KEY CONSISTENCY RULES

✅ **Same Calculation Everywhere:**
- AddPlant → uses `calculateNextWateringAt()`
- HealthCheck → uses `calculateNextWateringAt()`
- WaterPlant → uses `calculateNextWateringAt()`

✅ **Preferred Time Always Applied:**
- All flows use the same preferred time (default 18:00)
- Next watering date always has the preferred hour/minute

✅ **Days Only, No Hours:**
- UI shows dates only: "Dec 09"
- Button shows days only: "Next in 7 days"
- No hours/minutes displayed

✅ **shouldWaterNow Controls Button:**
- `true` → Button enabled, "Water now"
- `false` → Button disabled, "Next in X days"

✅ **Per-Plant Intervals:**
- Each plant has its own `wateringIntervalDays` from AI
- No global/shared intervals
- Species-specific based on photo analysis

---

## 9. EXAMPLE SCENARIOS

### Scenario 1: New Plant
1. User adds plant with photo
2. AI: `should_water_now=false, next_watering_in_days=7`
3. Calculation: `now + 7 days = Dec 9 at 18:00`
4. UI: Button disabled, shows "Next in 7 days"

### Scenario 2: Health Check - Plant Needs Water
1. User clicks "Check plant", uploads photo
2. AI: `should_water_now=true, next_watering_in_days=5`
3. Calculation: `now + 5 days = Dec 7 at 18:00`
4. UI: Button **enabled**, shows **"Water now"**
5. User waters → `shouldWaterNow` resets to `false`, next date recalculated

### Scenario 3: Health Check - Plant OK
1. User clicks "Check plant", uploads photo
2. AI: `should_water_now=false, next_watering_in_days=10`
3. Calculation: `now + 10 days = Dec 12 at 18:00`
4. UI: Button disabled, shows "Next in 10 days"

---

## 10. FILES MODIFIED

### Model
- ✅ `lib/models/plant.dart` - Added `shouldWaterNow` field

### Services
- ✅ `lib/services/plant_service.dart` - Added `calculateNextWateringAt()` helper, updated `addPlant()` and `waterPlant()`

### Screens
- ✅ `lib/screens/add_plant_screen.dart` - Extract and store `shouldWaterNow`
- ✅ `lib/screens/plant_details_screen.dart` - Use helper, apply preferred time, use `shouldWaterNow` for button

### Widgets
- ✅ `lib/widgets/health_check_modal.dart` - Extract `shouldWaterNow` from response

### Backend
- ✅ `functions/index.js` - Updated prompt for new species-specific logic

---

## VERIFICATION CHECKLIST

- [ ] Plant model includes `shouldWaterNow` field
- [ ] `calculateNextWateringAt()` helper exists and uses preferred time
- [ ] AddPlant flow uses helper and stores `shouldWaterNow`
- [ ] HealthCheck flow uses helper and applies preferred time
- [ ] WaterPlant flow uses helper and resets `shouldWaterNow`
- [ ] UI button uses `shouldWaterNow` for state
- [ ] UI shows only dates (no hours/minutes)
- [ ] Each plant has per-plant interval from AI
- [ ] No redundant interval recalculation

---

## CURRENT STATUS

✅ **Completed:**
- Plant model updated with `shouldWaterNow`
- Shared helper function created
- Health check handler uses helper
- Button logic uses `shouldWaterNow`
- Preferred time applied consistently

🔄 **Ready for Testing:**
- Full flow from AI → Database → UI
- Verify dates show correctly
- Verify button state changes
- Verify preferred time is applied


