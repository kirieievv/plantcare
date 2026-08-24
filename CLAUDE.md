# Botanly — plant care app

Flutter app (iOS / Android / web) that identifies plants from a photo, computes a
scientific watering dose, and reminds the user to water. Backed by Firebase and OpenAI.
Live site: **botanly.tech**

---

## Repository layout

| Directory | What it is | Deploy target |
|---|---|---|
| `plant_care_dev/` | **Default work target.** Dev Flutter app | Firebase `plant-care-dev-0001` |
| `plant_care/` | **Production.** Flutter app behind botanly.tech and the store builds | Firebase `plant-care-94574` |
| `plant_care_admin/` | Next.js admin panel (see its own `AGENTS.md`) | Vercel |
| `plant_care_clean/` | Local scratch copy — git-ignored, not part of the product | — |
| `_backup_dev_screens_*/` | Frozen snapshot of old screens | — |

### Environment targeting — read this first

- Make **all** code changes in `plant_care_dev/` unless the user names another target.
- Treat `plant_care/` as production. Do not modify it unless the user explicitly asks.
- Before any deploy command, confirm it is scoped to dev (`plant-care-dev-0001`)
  unless the user explicitly asked for prod.
- "Sync prod into dev" means copy `plant_care/` → `plant_care_dev/` while preserving
  dev-specific config: `.firebaserc`, `firebase.json`, `.env`, `assets/.env`,
  the `version:` line in `pubspec.yaml`, and iOS/Android platform config.

---

## Deploying

### "Задеплой" / "deploy to the site" / "обнови сайт" = **production**

Unqualified deploy phrasing always means the live site. Full sequence:

1. Sync relevant changes `plant_care_dev/` → `plant_care/`, excluding the config files
   listed above.
2. `flutter gen-l10n` in `plant_care/`
3. `flutter build web --release` in `plant_care/`
4. `firebase deploy --only functions,hosting --project plant-care-94574` from `plant_care/`

**Stop and ask the user before running step 4.** Steps 1–3 are safe to run unattended.

### Dev deploy

Only when the user explicitly says "dev" / "деплой в дев":

```bash
cd plant_care_dev && flutter build web --release && firebase deploy --project plant-care-dev-0001
```

### iOS builds for TestFlight / App Store

Apple reads `CFBundleVersion` from `ios/Flutter/Generated.xcconfig`, which Flutter
generates. Editing `pubspec.yaml` alone does **not** update it.

When the user asks to bump the build, prepare a TestFlight build, "увеличь номер сборки",
"собери сборку" or similar:

1. Bump **only** the integer after `+` in `version:` (`1.0.0+15` → `1.0.0+16`). Never touch
   the marketing version (`1.0.0`) unless explicitly asked.
2. Default target is `plant_care/pubspec.yaml`. Bump `plant_care_dev/` too only if asked.
3. In every project whose pubspec was bumped, run the full sequence:

```bash
flutter clean && flutter pub get && flutter build ios --release
```

4. Tell the user to open `Runner.xcworkspace` in Xcode → Product → Archive.
   No Clean Build Folder needed; `flutter clean` already handled it.

**Never use `flutter build ios --config-only`.** It refreshes `Generated.xcconfig` but does
not bundle assets (`assets/.env`, `assets/logo.png`), which causes a white screen /
`FileNotFoundError` crash on launch.

Apply the same full sequence whenever you change `version:` yourself.

---

## Architecture (`plant_care_dev/lib/`)

**The core loop.** Photo → GPT-4o identifies species, plant size, pot size, growth stage and
visual soil state → `WateringCalculatorService` turns that into millilitres and an interval
→ plant is stored in Firestore with a `notificationState` → scheduled Cloud Functions send
push and email reminders → periodic health checks compare new photos over time.

```
main.dart            Firebase init, service bootstrap, auth-state listener
router.dart          go_router: top-level shells only, with an auth+onboarding guard
models/              plant.dart (the central model), user_model.dart, smart_plant.dart
screens/             21 screens; add_plant + plant_details are the big ones
services/            17 services (see below)
widgets/             botanly_* design-system kit + feature widgets
theme/               botanly_theme.dart — Material 3 via flex_color_scheme
l10n/                6 locales: en, ru, uk, de, fr, es (edit .arb, then flutter gen-l10n)
```

**Navigation.** Only shell screens (`/welcome`, `/login`, `/register/*`, `/forgot-password/*`,
`/onboarding`, `/home`, `/stripe-success`) are `GoRoute`s. Inner screens like PlantDetails and
AddPlant are pushed with plain `Navigator.push` and deliberately have no named routes.

**Key services**

- `chatgpt_service.dart` — direct OpenAI calls, model `gpt-4o`. Heavy regex parsing of the
  AI's prose into structured fields.
- `watering_calculator_service.dart` — the dosing math: substrate volume × per-profile base
  fraction × soil-state multiplier, capped per session.
- `notification_service.dart` — FCM + `flutter_local_notifications`.
- `subscription_service.dart` — RevenueCat on mobile; `stripe_service.dart` for web checkout.
- `auth_service.dart` — Firebase Auth plus a **custom PIN flow** for email verification and
  password reset, implemented in Cloud Functions rather than Firebase's built-in email links.

**Backend** — `functions/index.js`, ~4k lines, 26 endpoints: `analyzePlantPhoto`,
`analyzeHealthCheckAgent`, `chatPlantAssistant`, the PIN endpoints, Stripe and RevenueCat
webhooks, and pubsub crons for watering reminders, seasonal tips and AI-usage aggregation.

---

## Conventions and gotchas

- **Never hardcode a Firebase project id.** Cloud Function URLs must come from
  `lib/utils/cloud_functions.dart`, which builds them from `Firebase.app().options.projectId`
  at runtime. A hardcoded `plant-care-dev-0001` in `add_plant_screen.dart` once rode a
  dev→prod sync into production and sent live users' photos to the dev backend for three
  months (introduced in `af54d3f5`, fixed in `212e3776`). It fails silently — no exception,
  no console error. If you need a new endpoint, add a getter to that file.
- **Web is a first-class target.** The app runs in Chrome and is hosted there, so avoid
  mobile-only APIs without a web fallback. `cors_proxy_service.dart` exists for this reason.
- **Legacy field pairs in `Plant`.** `lastWatered`/`lastWateredAt` and
  `wateringFrequency`/`wateringIntervalDays` coexist; old fields are not yet removed. Check
  which one a code path actually reads before changing either.
- **Firestore indexes: `firestore.indexes.json` is generated, not written.** Run
  `plant_care/scripts/sync-firestore-indexes.sh` and commit what it changes; a non-empty
  diff means somebody created an index outside the file, which is what the link in a "this
  query requires an index" error does. Keeping the file current is the whole safeguard,
  because a deploy deletes every index the file does not name: `--force` does it without
  asking, and a plain `firebase deploy --only firestore:indexes` asks — "Would you like to
  delete these indexes?" — which is one keystroke away from the same result. Production
  carried an undeclared `scheduled_test_pushes` index for months and came that close to
  losing it. Never hand-edit the file, and never spell out `__name__` in it: Firestore
  appends that key itself, and naming it where the generator would not makes every deploy
  die on a 409 (`b1619e8a`).
- **Another agent may be working in the other environment.** `plant_care` and
  `plant_care_dev` are kept identical by hand, so a copy in either direction can carry
  someone else's half-finished change with it. Diff the specific files you mean to sync
  before copying, and never copy a whole directory.
- **Secrets** live in `.env` and `assets/.env`, both git-ignored. Never commit or echo them.
- **Localization**: add keys to `lib/l10n/app_en.arb` and the other five, then run
  `flutter gen-l10n`. The `app_localizations*.dart` files are generated — do not hand-edit.
- After editing `initState`/`didChangeDependencies`, hot reload is not enough — hot restart
  (`R`) or a fresh `flutter run`.

## Commands

```bash
cd plant_care_dev
flutter run -d chrome          # web dev
flutter gen-l10n               # regenerate localizations
flutter analyze                # lint
cd functions && npm install    # cloud functions deps
```
