# Plant Care — dev-окружение

Эта папка — копия проекта для экспериментов (например, ветка с Tool use). Она настроена на Firebase-проект **Plant Care Dev** (ID: **plant-care-dev-0001**).

## Что уже сделано

- **.firebaserc** — по умолчанию выбран проект `plant-care-dev-0001` (деплой функций и хостинга идёт в dev).
- **lib/firebase_options.dart** — сгенерирован FlutterFire под проект plant-care-dev-0001 (Web app зарегистрирован).
- **URL Cloud Function** — берётся из текущего Firebase-проекта (`lib/utils/cloud_functions.dart`). При запуске из этой папки приложение вызывает функции dev, а не прод.

**Запуск из этой папки** (`flutter run -d chrome`) — приложение подключается к **plant-care-dev-0001** (Auth, Firestore, Storage, Functions).  
**Запуск из основной папки** `plant_care` — по-прежнему прод (plant-care-94574).

## Firebase Hosting для dev

Hosting настроен в `firebase.json` (папка `build/web`, SPA rewrites, cache headers). Для проекта plant-care-dev-0001 сайт Hosting создаётся при первом деплое.

Первый раз задеплоить Hosting в dev:

```bash
cd "/Users/krv/Desktop/Plant Care/plant_care_dev"
flutter build web
firebase deploy --only hosting
```

После этого приложение будет доступно по адресу вида `https://plant-care-dev-0001.web.app` (точный URL покажет Firebase CLI после деплоя).

## Деплой в dev

Из этой папки:

```bash
flutter build web
firebase deploy
# или только нужное:
firebase deploy --only hosting,functions
```

Деплой идёт в проект plant-care-dev-0001 (см. .firebaserc).
