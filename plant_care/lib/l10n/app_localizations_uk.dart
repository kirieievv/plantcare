// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Plant Care';

  @override
  String get loadingPlantCare => 'Завантажуємо Plant Care...';

  @override
  String get home => 'Головна';

  @override
  String get myPlants => 'Мої рослини';

  @override
  String get addPlant => 'Додати рослину';

  @override
  String get profile => 'Профіль';

  @override
  String get settings => 'Налаштування';

  @override
  String get authenticationError => 'Помилка автентифікації';

  @override
  String get pleaseLoginAgain => 'Будь ласка, увійдіть знову';

  @override
  String get goToLogin => 'Перейти до входу';

  @override
  String get yourGardenOverview => 'Огляд саду';

  @override
  String get welcomeBack => 'Ласкаво просимо!';

  @override
  String get createYourAccount => 'Створіть акаунт';

  @override
  String get fullName => 'Повне ім\'я';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get pleaseEnterYourName => 'Будь ласка, введіть ім\'я';

  @override
  String get pleaseEnterYourEmail => 'Будь ласка, введіть email';

  @override
  String get pleaseEnterValidEmail => 'Введіть коректний email';

  @override
  String get pleaseEnterYourPassword => 'Будь ласка, введіть пароль';

  @override
  String get pleaseConfirmYourPassword => 'Будь ласка, підтвердіть пароль';

  @override
  String get passwordAtLeast6 => 'Пароль має містити не менше 6 символів';

  @override
  String get rememberMe30Days => 'Запам\'ятати мене на 30 днів';

  @override
  String get logIn => 'Увійти';

  @override
  String get registration => 'Реєстрація';

  @override
  String get dontHaveAccountRegistration => 'Немає акаунту? Реєстрація';

  @override
  String get alreadyHaveAccountLogin => 'Вже є акаунт? Увійти';

  @override
  String get loggedIn => 'Ви увійшли';

  @override
  String get preferences => 'Налаштування';

  @override
  String get wateringReminders => 'Нагадування про полив';

  @override
  String get getNotifiedWhenPlantsNeedWater => 'Отримуйте сповіщення, коли рослинам потрібен полив';

  @override
  String get quietHours => 'Тихі години';

  @override
  String get maxNotificationsPerDay => 'Макс. сповіщень на день';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сповіщення',
      many: '$count сповіщень',
      few: '$count сповіщення',
      one: '$count сповіщення',
    );
    return '$_temp0';
  }

  @override
  String get theme => 'Тема';

  @override
  String get light => 'Світла';

  @override
  String get dark => 'Темна';

  @override
  String get testNotifications => 'Тест сповіщень';

  @override
  String get checkNotificationSetupAndPermissions => 'Перевірити налаштування та дозволи сповіщень';

  @override
  String get language => 'Мова';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get russian => 'Русский';

  @override
  String get ukrainian => 'Українська';

  @override
  String get savePreferences => 'Зберегти налаштування';

  @override
  String get account => 'Акаунт';

  @override
  String get changePassword => 'Змінити пароль';

  @override
  String get updateYourAccountPassword => 'Оновити пароль акаунту';

  @override
  String get signOut => 'Вийти';

  @override
  String get signOutOfYourAccount => 'Вийти з акаунту';

  @override
  String get preferencesSavedSuccessfully => 'Налаштування збережено!';

  @override
  String errorSavingPreferences(Object error) {
    return 'Помилка збереження налаштувань: $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => 'Тихі години оновлено!';

  @override
  String get changePasswordTitle => 'Змінити пароль';

  @override
  String get currentPassword => 'Поточний пароль';

  @override
  String get newPassword => 'Новий пароль';

  @override
  String get confirmNewPassword => 'Підтвердьте новий пароль';

  @override
  String get enterCurrentPassword => 'Введіть поточний пароль';

  @override
  String get enterNewPassword => 'Введіть новий пароль';

  @override
  String get newPasswordMustBeDifferent => 'Новий пароль має відрізнятися';

  @override
  String get confirmYourNewPassword => 'Підтвердьте новий пароль';

  @override
  String get passwordsDoNotMatch => 'Паролі не збігаються';

  @override
  String get save => 'Зберегти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get passwordChangedSuccessfully => 'Пароль успішно змінено.';

  @override
  String errorChangingPassword(Object error) {
    return 'Помилка зміни пароля: $error';
  }

  @override
  String get signOutConfirmTitle => 'Вихід';

  @override
  String get signOutConfirmMessage => 'Ви впевнені, що хочете вийти?';

  @override
  String get userLabel => 'Користувач';

  @override
  String get nameCannotBeEmpty => 'Ім\'я не може бути порожнім';

  @override
  String get profileUpdatedSuccessfully => 'Профіль успішно оновлено!';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Помилка оновлення профілю: $error';
  }

  @override
  String get plantLover => 'Любитель рослин';

  @override
  String get profileInformation => 'Інформація профілю';

  @override
  String get bio => 'Про себе';

  @override
  String get bioHint => 'Розкажіть про свій досвід догляду за рослинами...';

  @override
  String get location => 'Місцезнаходження';

  @override
  String get locationHint => 'Де знаходяться ваші рослини?';

  @override
  String get name => 'Ім\'я';

  @override
  String get notSet => 'Не вказано';

  @override
  String get accountInfo => 'Інформація про акаунт';

  @override
  String get memberSince => 'Учасник з';

  @override
  String get lastLogin => 'Останній вхід';

  @override
  String get notAvailable => 'Н/Д';

  @override
  String get actions => 'Дії';

  @override
  String get errorLabel => 'Помилка';

  @override
  String get noPlantsYet => 'Рослин ще немає!';

  @override
  String get addFirstPlantToGetStarted => 'Додайте першу рослину для початку';

  @override
  String get addYourFirstPlant => 'Додати першу рослину';

  @override
  String errorPickingImage(Object error) {
    return 'Помилка вибору зображення: $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'Не вдалося проаналізувати фото: $statusCode';
  }

  @override
  String get aiAnalysisCompleted => 'ШІ-аналіз завершено! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'ШІ-аналіз не виконано: $error';
  }

  @override
  String apiTestError(Object error) {
    return 'Помилка тесту API: $error';
  }

  @override
  String get aiAnalysisRefreshed => 'ШІ-аналіз оновлено! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'Помилка оновлення ШІ-аналізу: $error';
  }

  @override
  String get retry => 'Повторити';

  @override
  String get uploadPlantPhoto => 'Завантажити фото рослини';

  @override
  String get notSpecified => 'Не вказано';

  @override
  String get onceEvery7Days => 'Раз на 7 днів';

  @override
  String get oncePerDay => 'Раз на день';

  @override
  String get oncePerWeek => 'Раз на тиждень';

  @override
  String onceEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Раз на $days дня',
      many: 'Раз на $days днів',
      few: 'Раз на $days дні',
      one: 'Щодня',
    );
    return '$_temp0';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Раз на $weeks тижня',
      many: 'Раз на $weeks тижнів',
      few: 'Раз на $weeks тижні',
      one: 'Щотижня',
    );
    return '$_temp0';
  }

  @override
  String get low => 'Низький';

  @override
  String get mediumLow => 'Нижче середнього';

  @override
  String get medium => 'Середній';

  @override
  String get mediumHigh => 'Вище середнього';

  @override
  String get high => 'Високий';

  @override
  String get userNotAuthenticated => 'Користувач не автентифікований';

  @override
  String get pleaseUploadPlantImage => 'Будь ласка, завантажте фото рослини';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant => 'Зачекайте завершення ШІ-аналізу перед додаванням рослини';

  @override
  String get plantLowercase => 'рослина';

  @override
  String get plantAddedSuccessfully => 'Рослину успішно додано! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Помилка додавання рослини: $error';
  }

  @override
  String get generateRandomName => 'Випадкова назва';

  @override
  String get plantName => 'Назва рослини';

  @override
  String get plantNameHint => 'наприклад, Монстера, Сансевієрія';

  @override
  String get pleaseEnterPlantName => 'Будь ласка, введіть назву';

  @override
  String get addingPlant => 'Додаємо рослину...';

  @override
  String get analyzingPhoto => 'Аналізуємо фото...';

  @override
  String get plantUpdatedSuccessfully => 'Рослину успішно оновлено! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Помилка оновлення рослини: $error';
  }

  @override
  String get species => 'Вид';

  @override
  String get wateringFrequency => 'Частота поливу';

  @override
  String everyNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Кожні $days дня',
      many: 'Кожні $days днів',
      few: 'Кожні $days дні',
      one: 'Кожен $days день',
    );
    return '$_temp0';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Виберіть частоту поливу';

  @override
  String get notes => 'Нотатки';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get loadingImage => 'Завантаження зображення...';

  @override
  String get changeImage => 'Змінити фото';

  @override
  String errorDeletingPlant(Object error) {
    return 'Помилка видалення рослини: $error';
  }

  @override
  String get plantNotDueForWateringYet => 'Ця рослина ще не потребує поливу';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'Помилка при відкритті екрана рослини: $error';
  }

  @override
  String get aiCare => 'ШІ-догляд';

  @override
  String get aiAgent => 'ШІ-помічник';

  @override
  String get plantChatOpen => 'Відкрити чат з рослиною';

  @override
  String plantChatTitle(Object plantName) {
    return 'Чат про $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return 'Привіт! Я ваш помічник з догляду за $plantName. Запитайте про полив, ознаки хвороб або що робити далі.';
  }

  @override
  String get plantChatInputHint => 'Запитайте про цю рослину...';

  @override
  String get plantChatLoginAgain => 'Будь ласка, увійдіть знову.';

  @override
  String get plantChatRequestFailed => 'Запит до чату не виконано';

  @override
  String get plantChatCouldNotGenerateResponse => 'Не вдалося згенерувати відповідь. Спробуйте ще раз.';

  @override
  String get plantChatConnectionError => 'Щось пішло не так при з\'єднанні з помічником. Спробуйте ще раз.';

  @override
  String get plantChatQuickWaterToday => 'Чи можна полити сьогодні?';

  @override
  String get plantChatQuickYellowLeaves => 'Чому жовтіє листя?';

  @override
  String get plantChatQuickWhatToDoNow => 'Що робити прямо зараз?';

  @override
  String get plantChatImageQuotaReached => 'Денний ліміт фото вичерпано. Спробуйте завтра.';

  @override
  String get splashTagline => 'Розумний догляд за рослинами';

  @override
  String get getStarted => 'Розпочати';

  @override
  String get splashDescription => 'Стежте за рослинами, отримуйте персоналізовані поради\nта відстежуйте їхнє здоров\'я — усе в одному місці.';

  @override
  String get forgotPassword => 'Забули пароль?';

  @override
  String get errorInvalidPin => 'Невірний код. Спробуйте ще раз.';

  @override
  String get errorPinExpired => 'Термін дії коду закінчився. Запросіть новий.';

  @override
  String get errorPinNotFound => 'Код не знайдено. Запросіть новий.';

  @override
  String get errorTooManyAttempts => 'Забагато спроб. Запросіть новий код.';

  @override
  String get errorSendFailed => 'Не вдалося надіслати код. Спробуйте ще раз.';

  @override
  String get errorUserNotFound => 'Акаунт з таким email не знайдено.';

  @override
  String get errorEmailAlreadyExists => 'Акаунт з таким email вже існує.';

  @override
  String get errorGeneric => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get resetYourPassword => 'Відновити пароль';

  @override
  String get enterEmailForCode => 'Введіть email акаунту, щоб отримати код підтвердження.';

  @override
  String get sendCode => 'Надіслати код';

  @override
  String get enterVerificationCode => 'Введіть код підтвердження';

  @override
  String get weSentACodeTo => 'Ми надіслали 6-значний код на';

  @override
  String get verificationCodeSentAgain => 'Код підтвердження надіслано повторно.';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Надіслати повторно через $secondsс';
  }

  @override
  String get resendCode => 'Надіслати код повторно';

  @override
  String get setNewPassword => 'Задати новий пароль';

  @override
  String get confirmPassword => 'Підтвердьте пароль';

  @override
  String get updatePassword => 'Оновити пароль';

  @override
  String get passwordResetSuccess => 'Пароль успішно скинуто. Будь ласка, увійдіть.';

  @override
  String get totalPlants => 'Всього рослин';

  @override
  String get needWater => 'Потребують поливу';

  @override
  String get healthy => 'Здорові';

  @override
  String get yourPlants => 'Мої рослини';

  @override
  String get plantCreatedSuccessfully => 'Рослину успішно створено! 🌱';

  @override
  String get searchPlantsHint => 'Пошук за назвою або видом';

  @override
  String get filterAll => 'Усі';

  @override
  String get filterOverdue => 'Прострочено';

  @override
  String get noResultsTitle => 'Нічого не знайдено';

  @override
  String get noResultsSub => 'Спробуйте інший запит або фільтр.';

  @override
  String get edit => 'Редагувати';

  @override
  String get wateringRemindersBlockSub => 'Отримуйте сповіщення про полив рослин.';

  @override
  String get emailRemindersTitle => 'Email-нагадування';

  @override
  String get emailRemindersSub => 'Нагадування про полив на email';

  @override
  String get pushNotificationsTitle => 'Push-сповіщення';

  @override
  String get pushNotificationsSub => 'Миттєві сповіщення на пристрій';

  @override
  String get quietHoursLabel => 'Тихі години';

  @override
  String get themeLabel => 'Тема';

  @override
  String get languageLabel => 'Мова';

  @override
  String get preferencesTitle => 'Налаштування';

  @override
  String get accountTitle => 'Акаунт';

  @override
  String get changePasswordTitleRow => 'Змінити пароль';

  @override
  String get changePasswordSubRow => 'Оновити пароль акаунту';

  @override
  String get signOutSubRow => 'Вийти з акаунту';

  @override
  String get aiAssistantOnline => 'ШІ-помічник з рослин · в мережі';

  @override
  String get clearHistoryAction => 'Очистити історію';

  @override
  String get clearHistoryConfirm => 'Очистити історію чату?';

  @override
  String get saving => 'Збереження…';

  @override
  String get plantPhoto => 'Фото рослини';

  @override
  String get addPlantTitle => 'Додати рослину';

  @override
  String get addPlantSubtitle => 'Сфотографуйте, визначте, збережіть';

  @override
  String get snapTitle => 'Зробіть фото';

  @override
  String get snapDescription => 'Чітке фото допоможе нашому ШІ визначити\nвашу рослину та підібрати догляд';

  @override
  String get useCamera => 'Камера';

  @override
  String get uploadFromGallery => 'З галереї';

  @override
  String get analyzing => 'Аналіз...';

  @override
  String get couldntIdentify => 'Не вдалося визначити рослину';

  @override
  String get tryAnotherPhoto => 'Спробуйте інше фото або введіть вид вручну нижче.';

  @override
  String get topMatch => 'Найкращий збіг';

  @override
  String get useThisMatch => 'Обрати це';

  @override
  String get manualNamePlaceholder => 'Назва рослини (напр. Іріс)';

  @override
  String get savePlantBtn => 'Зберегти рослину';

  @override
  String get tagOverdue => 'ПРОСТРОЧЕНО';

  @override
  String get tagDueSoon => 'СКОРО';

  @override
  String get tagHealthy => 'ЗДОРОВА';

  @override
  String get wateringScheduleTitle => 'Графік поливу';

  @override
  String get lastWatered => 'Останній полив';

  @override
  String get nextWatering => 'Наступний полив';

  @override
  String get frequency => 'Частота';

  @override
  String get waterNowAction => 'Полити зараз';

  @override
  String get rescheduleAction => 'Перенести';

  @override
  String get careRecommendationsTitle => 'Рекомендації з догляду';

  @override
  String get careSectionCultivar => 'Культивар';

  @override
  String get careSectionGeneralDescription => 'Загальний опис';

  @override
  String get careSectionSoil => 'Ґрунт';

  @override
  String get careSectionSoilMoisture => 'Вологість ґрунту';

  @override
  String get careSectionMoistureCheck => 'Перевірка вологості';

  @override
  String get careSectionWater => 'Полив';

  @override
  String get careSectionLight => 'Освітлення';

  @override
  String get careSectionTemperature => 'Температура';

  @override
  String get careSectionFertilizer => 'Добрива';

  @override
  String get careSectionGrowthRate => 'Швидкість росту';

  @override
  String get careSectionToxicity => 'Токсичність';

  @override
  String get careSectionPlacement => 'Розміщення';

  @override
  String get careSectionPersonality => 'Характер';

  @override
  String get aboutPlantTitle => 'Про рослину';

  @override
  String get askAssistantTitle => 'Запитати помічника';

  @override
  String get askAssistantSub => 'Персоналізовані поради від Iris AI';

  @override
  String get openChat => 'Відкрити чат';

  @override
  String get deletePlantAction => 'Видалити рослину';

  @override
  String get reminderEmail => 'Email';

  @override
  String get reminderEmailSubtitle => 'Email-нагадування про полив';

  @override
  String get pushNotifications => 'Push-сповіщення';

  @override
  String get pushNotificationsSubtitle => 'Сповіщення в додатку (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'Прострочено $daysд';
  }

  @override
  String get wateringToday => 'Полив сьогодні';

  @override
  String get wateringTomorrow => 'Полив завтра';

  @override
  String wateringInNDays(int days) {
    return 'Полив через $daysд';
  }

  @override
  String plantWateredSuccess(Object plantName) {
    return '$plantName полито! 💧';
  }

  @override
  String errorWateringPlant(Object error) {
    return 'Помилка поливу: $error';
  }

  @override
  String get healthIssueDetected => 'Виявлено проблему зі здоров\'ям';

  @override
  String get recommendedActionsLabel => 'Рекомендовані дії:';

  @override
  String get healthAlertNote => 'Сповіщення відображатиметься до тих пір, поки наступна перевірка не поверне статус OK';

  @override
  String get addHealthCheckTooltip => 'Додати перевірку здоров\'я';

  @override
  String get noHealthChecksYet => 'Перевірок здоров\'я ще немає';

  @override
  String get uploadPhotosToTrackHealth => 'Завантажуйте фото для відстеження здоров\'я рослини';

  @override
  String get today => 'Сьогодні';

  @override
  String get yesterday => 'Вчора';

  @override
  String nDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня тому',
      many: '$days днів тому',
      few: '$days дні тому',
      one: '$days день тому',
    );
    return '$_temp0';
  }

  @override
  String get healthStatusOk => 'Гаразд';

  @override
  String get healthStatusIssue => 'Проблема';

  @override
  String get assistantTyping => 'Помічник друкує...';

  @override
  String chatSourceLabel(Object source) {
    return 'Джерело: $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'База знань';

  @override
  String get chatSourceContext => 'Контекст';

  @override
  String get chatSourceAgent => 'Агент';

  @override
  String get chatAttachPhoto => 'Прикріпити фото';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit фото сьогодні';
  }

  @override
  String get chatPhotoQuotaExhausted => 'Денний ліміт фото вичерпано. Спробуйте завтра.';

  @override
  String get chatPhotoUploading => 'Завантаження фото...';

  @override
  String get chatPhotoUploadFailed => 'Не вдалося завантажити фото. Спробуйте ще раз.';

  @override
  String get chatRemovePhoto => 'Видалити фото';

  @override
  String get chatCopyMessage => 'Копіювати';

  @override
  String get chatClearHistory => 'Новий чат';

  @override
  String get chatClearHistoryConfirm => 'Почати нову розмову? Поточна історія буде видалена.';

  @override
  String get chatClearHistorySuccess => 'Нову розмову розпочато.';

  @override
  String get chatDateToday => 'Сьогодні';

  @override
  String get chatDateYesterday => 'Вчора';

  @override
  String get choosePhoto => 'Обрати фото';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String get analyzeHealth => 'Аналіз здоров\'я';

  @override
  String get waterFirstLabel => 'Спочатку полийте';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Наступна перевірка через $days д';
  }

  @override
  String get imageReadyForAnalysis => 'Фото завантажено! Готово до аналізу здоров\'я.';

  @override
  String get healthCheckTitle => 'Перевірка здоров\'я';

  @override
  String get healthCheckHistoryTitle => 'Історія перевірок здоров\'я';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Завантажте фото $plantName для ШІ-аналізу здоров\'я';
  }

  @override
  String get deletePlant => 'Видалити рослину';

  @override
  String get deletePlantConfirm => 'Ви впевнені, що хочете видалити цю рослину?';

  @override
  String get delete => 'Видалити';

  @override
  String get iHaveWatered => 'Я полив(ла)';

  @override
  String get soilMoisture => 'Ідеальний ґрунт';

  @override
  String get lightLabel => 'Освітлення';

  @override
  String get perDay => 'на день';

  @override
  String get hoursLabel => 'годин';

  @override
  String get interestingFactsTitle => 'Цікаві факти';

  @override
  String get noCareRecommendationsYet => 'Рекомендації з догляду від ШІ ще недоступні для цієї рослини.';

  @override
  String get noInterestingFactsYet => 'Цікаві факти від ШІ ще недоступні для цієї рослини.';

  @override
  String get noDescriptionYet => 'Опис ще не додано.';

  @override
  String get swipeToSeeMore => 'Гортайте, щоб побачити більше';

  @override
  String get uploadPhotosForHealthHistory => 'Завантажуйте фото для відстеження здоров\'я рослини';

  @override
  String plantDeletedMessage(Object plantName) {
    return 'Рослину \"$plantName\" видалено';
  }

  @override
  String get noImageAvailable => 'Фото недоступне';

  @override
  String get addPhotoToSeeYourPlant => 'Додайте фото, щоб бачити свою рослину';

  @override
  String get isThisYourPlant => 'Це ваша рослина?';

  @override
  String get speciesPickSubtitle => 'Ми знайшли варіанти — оберіть відповідний';

  @override
  String get noneOfThese => 'Жоден не підходить';

  @override
  String get typePlantNameRetry => 'Введіть назву рослини, і ми спробуємо знову';

  @override
  String get gettingCareRecommendations => 'Отримуємо рекомендації з догляду';

  @override
  String get imageUploadedAnalysisComplete => 'Фото завантажено! ШІ-аналіз завершено.';

  @override
  String get aiCareRecommendationsHeader => 'Рекомендації з догляду від ШІ';

  @override
  String get aiReady => 'ШІ готовий';

  @override
  String get checkPlantButton => 'Перевірити рослину';

  @override
  String get plantCareAssistantTitle => 'Помічник з догляду за рослинами';

  @override
  String get plantNeedsHelp => 'Рослина потребує допомоги!';

  @override
  String get whatToDoNow => 'Що робити зараз';

  @override
  String get wateringLabel => 'Полив';

  @override
  String get nowLabel => 'Зараз';

  @override
  String get nextIn1Day => 'Наступний через 1 день';

  @override
  String nextInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Наступний через $days дня',
      many: 'Наступний через $days днів',
      few: 'Наступний через $days дні',
      one: 'Наступний через $days день',
    );
    return '$_temp0';
  }

  @override
  String get wateringDone => 'Полив виконано';

  @override
  String get moistureDry => 'Суха';

  @override
  String get moistureWet => 'Волога';

  @override
  String get moistureLevelVeryDry => 'Дуже суха';

  @override
  String get moistureLevelDry => 'Суха';

  @override
  String get moistureLevelSlightlyMoist => 'Злегка волога';

  @override
  String get moistureLevelMoist => 'Волога';

  @override
  String get moistureLevelVeryMoist => 'Дуже волога';

  @override
  String bannerWaterTitle(String name) {
    return '$name потребує поливу';
  }

  @override
  String get bannerWaterSubtitle => 'Натисніть, щоб полити або переглянути деталі';

  @override
  String get bannerTipTitle => 'Порада дня';

  @override
  String get bannerTipSubtitle => 'Натисніть для сезонних порад';

  @override
  String get tipsOfTheDay => 'Поради дня';

  @override
  String get tipsOfTheDaySub => 'Сезонні поради від ШІ · оновлюються щотижня';

  @override
  String get tipCategoryWatering => 'Полив';

  @override
  String get tipCategoryLight => 'Освітлення';

  @override
  String get tipCategoryPests => 'Шкідники';

  @override
  String get tipCategoryFertilizing => 'Удобрення';

  @override
  String get tipCategorySeasonal => 'Сезонні';

  @override
  String get tipCategoryGeneral => 'Загальне';

  @override
  String get noTipsYet => 'Поради генеруються. Заходьте пізніше!';

  @override
  String get waterNow => 'Полити зараз';

  @override
  String get subscriptionUpgrade => 'Покращити';

  @override
  String get subscriptionManage => 'Управління';

  @override
  String get subscriptionActiveTitle => 'Premium активний';

  @override
  String get subscriptionGrandfatheredTitle => 'Довічний доступ';

  @override
  String get subscriptionTrialTitle => 'Безкоштовний пробний період';

  @override
  String get subscriptionExpiredTitle => 'Підписка закінчилась';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Активний до $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'Пробний період закінчується $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Залишилось $days дня',
      many: 'Залишилось $days днів',
      few: 'Залишилось $days дні',
      one: 'Залишився $days день',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionExpiredMessage => 'Ваша підписка закінчилась. Оформіть підписку, щоб продовжити.';

  @override
  String get subscriptionPlantLimitReached => 'Ліміт рослин досягнуто';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Досягнуто ліміт безкоштовного плану. Перейдіть на Premium — до $limit рослин.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired => 'Оформіть підписку, щоб додавати рослини.';

  @override
  String get subscriptionReadOnlyNotice => 'Режим читання. Оформіть підписку для редагування.';

  @override
  String get paywallTitle => 'Відкрити Premium';

  @override
  String get paywallSubtitle => 'Отримайте максимум від колекції рослин';

  @override
  String paywallFeature1(int limit) {
    return 'До $limit рослин';
  }

  @override
  String get paywallFeature2 => 'Необмежені нагадування про полив';

  @override
  String get paywallFeature3 => 'ШІ-помічник та перевірки здоров\'я';

  @override
  String get paywallFeature4 => 'Повне редагування та відстеження';

  @override
  String get paywallMonthly => 'Щомісячно';

  @override
  String get paywallAnnual => 'Щорічно';

  @override
  String get paywallBestValue => 'Найкраща ціна';

  @override
  String get paywallContinue => 'Продовжити';

  @override
  String get paywallRestore => 'Відновити покупку';

  @override
  String get paywallRestoring => 'Відновлення…';

  @override
  String get paywallRestoreSuccess => 'Покупку відновлено!';

  @override
  String get paywallRestoreNotFound => 'Попередні покупки не знайдено.';

  @override
  String get paywallRestoreAlreadyActive => 'Ваша підписка вже активна.';

  @override
  String get paywallTerms => 'Підписка автоматично поновлюється. Скасуйте в будь-який час у налаштуваннях App Store.';

  @override
  String get paywallLoading => 'Завантажуємо плани…';

  @override
  String get paywallPurchasing => 'Обробка…';

  @override
  String get paywallError => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get paywallHeroTitle => 'Рости без обмежень.';

  @override
  String get paywallHeroDescription => 'Ваш персональний ШІ-асистент — нагадування про полив, перевірка здоров\'я, сезонні поради і все необхідне для процвітання ваших рослин.';

  @override
  String get paywallChoosePlan => 'ОБЕРІТЬ ПЛАН';

  @override
  String paywallPerMonth(Object price) {
    return 'Лише $price / місяць';
  }

  @override
  String get paywallStartPremium => 'Почати Premium';

  @override
  String get paywallSecured => 'Захищено Stripe';

  @override
  String get paywallSecuredApple => 'Захищено';

  @override
  String get paywallCancelAnytime => 'Скасування в будь-який час';

  @override
  String get paywallAutoRenews => 'автопоновлення';

  @override
  String get stripeSuccessTitle => 'Підписку активовано!';

  @override
  String get stripeSuccessWaiting => 'Активуємо вашу підписку';

  @override
  String get stripeSuccessSubtitle => 'Ласкаво просимо до Botanly Premium! Тепер у вас є доступ до всіх функцій.';

  @override
  String get stripeSuccessButton => 'До моїх рослин';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'Не вдалося відкрити портал оплати: $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Помилка відновлення: $error';
  }

  @override
  String get emailCopied => 'Email скопійовано: support@botanly.app';

  @override
  String get labelExpires => 'Закінчується';

  @override
  String get labelNextRenewal => 'Наступне поновлення';

  @override
  String get labelAutoRenewal => 'Автопоновлення';

  @override
  String get labelRestorePurchases => 'Відновити покупки';

  @override
  String get labelPlants => 'Рослини';

  @override
  String get labelRenews => 'Поновлення';

  @override
  String get testWateringEmailQueued => 'Тестовий email про полив надіслано.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'Не вдалося надіслати тестовий email: $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'Помилка збереження каналів нагадувань: $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'Помилка оновлення тихих годин: $error';
  }

  @override
  String get deleteAccountTitle => 'Видалити акаунт';

  @override
  String get deleteAccountSubtitle => 'Назавжди вимкнути ваш акаунт';

  @override
  String get deleteAccountConfirmBody => 'Ваш акаунт буде назавжди вимкнено, і ви втратите доступ до програми. Дані про ваші рослини збережуться.\n\nЦю дію не можна скасувати.';

  @override
  String get deleteAccountAreYouSure => 'Ви впевнені?';

  @override
  String get deleteAccountTypeConfirm => 'Введіть DELETE для підтвердження:';

  @override
  String get deleteAccountConfirmBtn => 'Підтвердити видалення';

  @override
  String errorDeletingAccount(Object error) {
    return 'Не вдалося видалити акаунт: $error';
  }

  @override
  String get subPillPremium => 'Преміум';

  @override
  String get subPillEarlyMember => 'Ранній учасник';

  @override
  String get subPillFreePlan => 'Безкоштовний план';

  @override
  String get subPillFreeTrial => 'Пробний період';

  @override
  String get subMetaActivePlan => 'АКТИВНИЙ ПЛАН';

  @override
  String get subMetaForeverPremium => 'ВІЧНИЙ ПРЕМІУМ';

  @override
  String get subMetaTrialEnded => 'ПРОБНИЙ ПЕРІОД ЗАВЕРШЕНО';

  @override
  String subMetaNDayPreview(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ПЕРЕГЛЯД $n ДНЯ',
      many: 'ПЕРЕГЛЯД $n ДНІВ',
      few: 'ПЕРЕГЛЯД $n ДНІ',
      one: 'ПЕРЕГЛЯД $n ДЕНЬ',
    );
    return '$_temp0';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Поновлюється через $days дн. · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Закінчується через $days дн. · $date';
  }

  @override
  String get subActiveSubscription => 'Активна підписка';

  @override
  String get subGrantedEarlyMember => 'Надано як ранньому учаснику Botanly';

  @override
  String get subDaysLeft => 'днів залишилось';

  @override
  String get subUntilPreviewEnds => 'до кінця\nпробного періоду';

  @override
  String get subTrialEnded => 'пробний період\nзавершено';

  @override
  String get subAutoRenewOn => 'Автопоновлення увімкнено  ·  Можна скасувати';

  @override
  String get subAutoRenewOff => 'Автопоновлення вимкнено  ·  Доступ до закінчення';

  @override
  String get subDetails => 'Деталі';

  @override
  String get subReactivate => 'Поновити';

  @override
  String get subNoChargesEver => 'Без оплати назавжди  ·  Всі можливості відкриті';

  @override
  String get subLimitedAccess => 'Обмежений доступ  ·  Без AI-догляду';

  @override
  String get subUnlimitedAccess => 'Без обмежень  ·  AI-догляд  ·  Нагадування';

  @override
  String get subHeroYourePrefix => 'Ви ';

  @override
  String get subHeroGrowingWord => 'зростаєте';

  @override
  String get subHeroForeverWord => 'Назавжди';

  @override
  String get subHeroPremiumSuffix => ' Преміум';

  @override
  String get labelEnds => 'Закінчується';

  @override
  String get labelPlan => 'План';

  @override
  String get labelPremium => 'Преміум';

  @override
  String get labelGrandfathered => 'Спадковий доступ';

  @override
  String get labelOn => 'Увімк';

  @override
  String get labelOff => 'Вимк';

  @override
  String get yourPlan => 'Ваш план';

  @override
  String get manageSubscription => 'Керування підпискою';

  @override
  String get manageBillingWeb => 'Керування оплатою';

  @override
  String get manageInAppStore => 'Керування в App Store';

  @override
  String get manageBillingSubtitleWeb => 'Скасуйте, оновіть картку або перегляньте рахунки\nчерез портал Stripe.';

  @override
  String get manageBillingSubtitleAppStore => 'Щоб вимкнути автопоновлення або скасувати, перейдіть\nу підписки App Store.';

  @override
  String get tipGoodLight => 'гарне освітлення';

  @override
  String get tipShowLeaves => 'покажіть листя';

  @override
  String get tipSinglePlant => 'одна рослина';

  @override
  String get snapYourSprout => 'Сфотографуйте свій паросток';

  @override
  String get identifyingPlantPrefix => 'Визначаємо вашу ';

  @override
  String get identifyingPlantWord => 'рослину';

  @override
  String get identifyingSubtitle => 'Вивчаємо листя, стебла і сусідів поруч';

  @override
  String get specificIssues => 'Специфічні проблеми';

  @override
  String get healthCheckPhotoHint => 'Додайте до 3 фото — більше ракурсів означає точніший аналіз. Обов\'язкове лише перше фото.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Рослина повністю';

  @override
  String get healthCheckSlot1Desc => 'Сфотографуйте рослину повністю разом з горщиком — щоб було видно землю і весь горщик.';

  @override
  String get healthCheckSlot1Tag => 'Обов\'язково';

  @override
  String get healthCheckSlot2Title => 'Великий план';

  @override
  String get healthCheckSlot2Desc => 'Піднесіть камеру ближче, без горщика — щоб чітко видно листя та їхню фактуру.';

  @override
  String get healthCheckSlot2Tag => 'За бажанням';

  @override
  String get healthCheckSlot3Title => 'Проблемна зона';

  @override
  String get healthCheckSlot3Desc => 'Хочете показати щось окремо? Сфотографуйте пляму, шкідника або пошкоджений листок.';

  @override
  String get healthCheckSlot3Tag => 'За бажанням';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return 'Аналізувати $count фото';
  }

  @override
  String get healthCheckError => 'Аналіз не вдався. Будь ласка, спробуйте ще раз.';

  @override
  String get healthCheckDefaultPraise => '🌱 Ваша рослина почувається добре!';

  @override
  String get healthCheckDefaultFooter => 'Продовжуйте доглядати за рослиною відповідно до рекомендацій і відзначайте, коли поливаєте.';

  @override
  String get addPlantWholePlantTitle => 'Рослина цілком';

  @override
  String get addPlantWholePlantDesc => 'з горщиком і землею';

  @override
  String get addPlantWholePlantTag => 'Обов\'язково';

  @override
  String get addPlantCloseUpTitle => 'Великий план';

  @override
  String get addPlantCloseUpDesc => 'листя в деталях';

  @override
  String get addPlantCloseUpTag => 'За бажанням';

  @override
  String get addPlantDualHint => 'Два ракурси допоможуть ШІ точніше визначити вашу рослину.';

  @override
  String get addPlantAnalyzeButton => 'Аналізувати рослину';

  @override
  String get addPlantStepPhotosReceived => 'Фото отримані';

  @override
  String get addPlantStepIdentifying => 'Визначаємо вид';

  @override
  String get addPlantStepCarePlan => 'Складаємо план догляду';

  @override
  String get addPlantAnalyzingTitle => 'Аналізуємо вашу рослину';

  @override
  String get addPlantAnalyzingSubtitle => 'Зазвичай це займає кілька секунд…';

  @override
  String get addPlantAnalysisComplete => 'Аналіз завершено';

  @override
  String get addPlantSeePlantProfile => 'Переглянути профіль рослини';

  @override
  String get onboardingSkip => 'Пропустити';

  @override
  String get onboardingGetStarted => 'Почати';

  @override
  String get onboarding1Eyebrow => 'Ласкаво просимо';

  @override
  String get onboarding1Title => 'Знайомтесь: ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body => 'Ваш ШІ-помічник для щасливих і здорових рослин — завжди поруч.';

  @override
  String get onboarding2Eyebrow => 'Визначення';

  @override
  String get onboarding2Title => 'Дізнайтесь ';

  @override
  String get onboarding2TitleItalic => 'будь-яку рослину';

  @override
  String get onboarding2Body => 'Наведіть камеру — ШІ визначить вид, назву та все інше за секунди.';

  @override
  String get onboarding3Eyebrow => 'Догляд';

  @override
  String get onboarding3Title => 'Догляд став ';

  @override
  String get onboarding3TitleItalic => 'простішим';

  @override
  String get onboarding3Body => 'Нагадування про полив, освітлення та ґрунт — точно налаштовані під кожну рослину.';

  @override
  String get onboarding4Eyebrow => 'Перевірка здоров\'я';

  @override
  String get onboarding4Title => 'Помічайте проблеми ';

  @override
  String get onboarding4TitleItalic => 'вчасно';

  @override
  String get onboarding4Body => 'Сфотографуйте — отримайте миттєву перевірку здоров\'я та чіткий план лікування.';

  @override
  String get onboarding5Eyebrow => 'Готово';

  @override
  String get onboarding5Title => 'Давайте ';

  @override
  String get onboarding5TitleItalic => 'рости разом';

  @override
  String get onboarding5Body => 'Створіть свою колекцію і нічого не пропускайте. Ваша найзеленіша ера починається зараз.';

  @override
  String get tabCare => 'Догляд';

  @override
  String get tabAbout => 'Про рослину';

  @override
  String get tabHistory => 'Історія';

  @override
  String nDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days днів',
      few: '$days дні',
      one: '$days день',
    );
    return '$_temp0';
  }

  @override
  String get cycleJustStarted => 'Цикл щойно почався';

  @override
  String cyclePercentComplete(int percent) {
    return 'Цикл пройдено на $percent%';
  }

  @override
  String get wateringAmount => 'Обʼєм';

  @override
  String get noDataAvailable => 'Поки немає даних';

  @override
  String get healthCheckHistoryEmptyHint => 'Завантажуй фото раз на пару тижнів — складемо таймлайн стану рослини';

  @override
  String milliliters(int count) {
    return '$count мл';
  }

  @override
  String get millilitersShort => 'МЛ';

  @override
  String nHours(String hours) {
    return '$hours год';
  }

  @override
  String get lightDaily => 'На день';

  @override
  String get lightType => 'Тип';

  @override
  String get lightTypeDirect => 'Пряме';

  @override
  String get lightTypePartialSun => 'Півтінь';

  @override
  String get lightTypeBrightIndirect => 'Яскраве розсіяне';

  @override
  String get lightTypeLowLight => 'Слабке світло';

  @override
  String get everyDay => 'Щодня';

  @override
  String get healthCheckSeverity => 'Серйозність';

  @override
  String get healthCheckFollowUp => 'Повторна перевірка';

  @override
  String get severityLow => 'Низька';

  @override
  String get severityMedium => 'Середня';

  @override
  String get severityHigh => 'Висока';

  @override
  String get careKvFrequency => 'Частота';

  @override
  String get careKvSeason => 'Сезон';

  @override
  String get careKvOptimal => 'Оптимум';

  @override
  String get careKvMinimum => 'Мінімум';

  @override
  String get careKvDose => 'Доза';

  @override
  String get healthAnalyzeCta => 'Перевірити стан';

  @override
  String get healthNeedsAttention => 'Потребує уваги';

  @override
  String get healthStatusHealthy => 'Здорова рослина';

  @override
  String get healthWhatToDo => 'Що зробити';

  @override
  String get healthClose => 'Закрити';

  @override
  String get healthNotSavedYet => 'Перевірка ще не в історії';

  @override
  String get healthAskAssistant => 'Запитати AI';

  @override
  String get healthAddedToPlan => 'Додано до плану';

  @override
  String get healthLockedNeedsWatering => 'Позначте полив, щоб перевірити знову';

  @override
  String get healthLockedLimitReached => 'Перевірки на цей цикл вичерпано';

  @override
  String get healthAdviceSub => 'Подивитися, що зробити';

  @override
  String get healthAnalyzingTitle => 'Аналізуємо…';

  @override
  String get healthStepRecognize => 'Розпізнаємо рослину';

  @override
  String get healthStepCompare => 'Порівнюємо з минулими перевірками';

  @override
  String get healthStepAdvice => 'Формуємо рекомендації';

  @override
  String healthStepPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото отримано',
      few: '$count фото отримано',
      one: '$count фото отримано',
    );
    return '$_temp0';
  }

  @override
  String healthAdviceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рекомендацій після перевірки',
      few: '$count рекомендації після перевірки',
      one: '$count рекомендація після перевірки',
    );
    return '$_temp0';
  }

  @override
  String get healthHistoryLoadFailed => 'Не вдалося завантажити історію';

  @override
  String get healthUpToThreePhotos => 'До 3 фото';

  @override
  String get healthResultTitle => 'Результат';

  @override
  String get taskAllDone => 'Усе зроблено — рослина в порядку';

  @override
  String get taskBadgeScheduled => 'За розкладом';

  @override
  String get taskBadgeAnalysis => 'Після аналізу';

  @override
  String taskBadgeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Прострочено $days дня',
      many: 'Прострочено $days днів',
      few: 'Прострочено $days дні',
      one: 'Прострочено $days день',
    );
    return '$_temp0';
  }

  @override
  String get taskDone => 'Готово';

  @override
  String get taskDoneAlready => 'Зроблено';

  @override
  String get taskLater => 'Пізніше';

  @override
  String get taskAskAssistant => 'Запитати асистента';

  @override
  String taskAskQuestion(String title) {
    return 'Що потрібно зробити із завданням «$title»?';
  }

  @override
  String get homeGardenTitleLead => 'Твій';

  @override
  String get homeGardenTitleAccent => 'сад';

  @override
  String get gardenHealthLabel => 'Здоров’я саду';

  @override
  String get gardenAllGood => 'Усі рослини в порядку';

  @override
  String gardenOneWeak(String name) {
    return '$name тягне сад униз';
  }

  @override
  String gardenManyWeak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рослинам потрібен твій догляд',
      few: '$count рослинам потрібен твій догляд',
      one: '$count рослині потрібен твій догляд',
    );
    return '$_temp0';
  }

  @override
  String get homeOrbitHint => 'Натисни на рослину, щоб відкрити її';

  @override
  String get homeAllTasksLink => 'Усі завдання';

  @override
  String get deckAllClearTitle => 'Сад у порядку';

  @override
  String taskOverdueShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days днів',
      few: '$days дні',
      one: '$days день',
    );
    return '$_temp0';
  }

  @override
  String get taskPostponed => 'Відкладено';

  @override
  String get allTasksTitle => 'Усі завдання';

  @override
  String allTasksSubtitle(int today, int later) {
    return '$today сьогодні · $later далі';
  }

  @override
  String get allTasksToday => 'Сьогодні';

  @override
  String get allTasksLater => 'Далі';

  @override
  String get allTasksRuleNote => 'Нові завдання не з’являться, доки не розберешся із сьогоднішніми.';

  @override
  String get allTasksNothingToday => 'На сьогодні все закрито';

  @override
  String get whenTomorrow => 'Завтра';

  @override
  String get whenInAWeek => 'Через тиждень';

  @override
  String whenInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days днів',
      few: 'Через $days дні',
      one: 'Через $days день',
    );
    return '$_temp0';
  }

  @override
  String careAskAbout(String title) {
    return 'Запитати асистента про $title';
  }

  @override
  String careAskQuestion(String title) {
    return 'Розкажи докладніше про «$title» для моєї рослини';
  }

  @override
  String get healthAskQuestionIssue => 'Що зробити за результатами аналізу насамперед?';

  @override
  String get healthAskQuestionOk => 'Аналіз показав, що рослина здорова — що можна покращити?';

  @override
  String get glassesOne => '1 склянка';

  @override
  String glassesAmount(String value) {
    return '$value склянки';
  }

  @override
  String addPlantStepOf(int step, int total) {
    return 'Крок $step з $total';
  }

  @override
  String get addPlantTitleLead => 'Додати';

  @override
  String get addPlantTitleAccent => 'рослину';

  @override
  String get addPlantNameHint => 'Як зватимеш цю квітку — Моня, Фікусик, Monstera. Кубик придумає за тебе.';

  @override
  String get addPlantPhotosTitle => 'Світлини';

  @override
  String get addPlantWholePlant => 'Уся рослина';

  @override
  String get addPlantWholePlantHint => 'з горщиком і ґрунтом';

  @override
  String get addPlantRequired => 'Треба';

  @override
  String get addPlantTwoAnglesHint => 'Два ракурси точніше визначають вид — друга світлина не обов’язкова, але допомагає.';

  @override
  String get addPlantTipLight => 'добре світло';

  @override
  String get addPlantTipLeaves => 'видно листя';

  @override
  String get addPlantTipSingle => 'одна рослина';

  @override
  String get addPlantIdentifyCta => 'Визначити вид';

  @override
  String get addPlantRandomNames => 'Моня|Паросток|Фікусик|Зеленко|Базилік Великий|Листик|Сонько|Пих';

  @override
  String get addPlantIsThisYourPlant => 'Це твоя рослина?';

  @override
  String get addPlantPickSpeciesHint => 'Обери найближчий варіант — від цього залежить план догляду.';

  @override
  String get addPlantNoneMatch => 'Нічого не підходить — введу сам';

  @override
  String get addPlantManualHint => 'Введи назву виду — пошукаємо заново.';

  @override
  String get addPlantManualPlaceholder => 'Наприклад, Monstera deliciosa';

  @override
  String get addPlantBuildPlanCta => 'Скласти план догляду';

  @override
  String addPlantStartingScore(int score) {
    return 'Стартовий бал $score';
  }

  @override
  String get addPlantPlanWatering => 'Полив';

  @override
  String get addPlantPlanLight => 'Світло';

  @override
  String get addPlantPlanSoil => 'Ґрунт';

  @override
  String get addPlantSoilSlightlyMoist => 'Злегка вологий';

  @override
  String addPlantEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Раз на $days днів',
      few: 'Раз на $days дні',
      one: 'Раз на $days день',
    );
    return '$_temp0';
  }

  @override
  String get addPlantCarePlan => 'План догляду';

  @override
  String addPlantNTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count завдань',
      few: '$count завдання',
      one: '$count завдання',
    );
    return '$_temp0';
  }

  @override
  String get addPlantFirstWatering => 'Перший полив';

  @override
  String get addPlantToday => 'сьогодні';

  @override
  String get addPlantWaterToday => 'сьогодні';

  @override
  String get addPlantFertilising => 'Підживлення';

  @override
  String get addPlantFertilisingDetail => 'Через 2 тижні · половинна доза';

  @override
  String get addPlantHealthCheck => 'Перевірка здоров’я';

  @override
  String get addPlantHealthCheckDetail => 'Через місяць · 1–3 світлини';

  @override
  String get addPlantAddToGarden => 'Додати до саду';

  @override
  String get addPlantNoSpeciesFound => 'Не вдалося розпізнати рослину. Спробуй іншу світлину.';

  @override
  String get addPlantNoPlan => 'Не вдалося скласти план догляду. Спробуй ще раз.';

  @override
  String get addPlantLoaderPhotos => 'Світлини отримано';

  @override
  String get addPlantLoaderIdentify => 'Визначаємо вид';

  @override
  String get addPlantLoaderPlan => 'Складаємо план догляду';

  @override
  String get myPlantsTitleLead => 'Мої';

  @override
  String get myPlantsTitleAccent => 'рослини';

  @override
  String myPlantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рослин',
      few: '$count рослини',
      one: '$count рослина',
    );
    return '$_temp0';
  }

  @override
  String get myPlantsEmptyLabel => 'Поки порожньо';

  @override
  String get filterTomorrow => 'Завтра';

  @override
  String get filterNeedsCare => 'Потрібен догляд';

  @override
  String get myPlantsNothingFound => 'Нічого не знайдено';

  @override
  String get myPlantsNothingFoundHint => 'Спробуй іншу назву або вид.';

  @override
  String get myPlantsAllClearTitle => 'Усе гаразд';

  @override
  String get myPlantsAllClearHint => 'Зараз у цій групі порожньо — немає про що хвилюватися.';

  @override
  String get addFirstPlantHint => 'Додайте першу рослину, щоб почати';

  @override
  String get subHeroActiveLead => 'Сад';

  @override
  String get subHeroActiveAccent => 'під наглядом';

  @override
  String get subHeroForeverLead => 'Преміум';

  @override
  String get subHeroForeverAccent => 'назавжди';

  @override
  String get subHeroEndedLead => 'Пробний період';

  @override
  String get subHeroEndedAccent => 'завершено';

  @override
  String get subMetaNoCharges => 'Без списань';

  @override
  String get subFootAutoRenew => 'Автопродовження увімкнено · Можна скасувати';

  @override
  String get subFootTrial => 'Без обмежень · AI-догляд · Нагадування';

  @override
  String get subFootForever => 'Усі можливості відкриті';

  @override
  String get subFootFree => 'Обмежений доступ · Без AI-догляду';

  @override
  String get subCtaDetails => 'Деталі';

  @override
  String get subCtaResume => 'Відновити';

  @override
  String subTrialUntil(String date) {
    return 'Пробний період до $date';
  }

  @override
  String subEndedOn(String date) {
    return 'Завершився $date';
  }

  @override
  String get subscriptionManageTitle => 'Підписка';

  @override
  String get subscriptionPlanLabel => 'План';

  @override
  String get subscriptionNextChargeLabel => 'Наступне списання';

  @override
  String get subscriptionAutoRenewLabel => 'Автопродовження';

  @override
  String get subscriptionAutoRenewOn => 'Увімкнено';

  @override
  String get subscriptionAutoRenewOff => 'Вимкнено';

  @override
  String get subscriptionManageInStore => 'Списаннями керує App Store. Змінити або скасувати підписку можна в Налаштуваннях → Apple ID → Підписки.';

  @override
  String get deleteAccountContinue => 'Продовжити';

  @override
  String get deleteAccountKeyword => 'ВИДАЛИТИ';

  @override
  String deleteAccountTypeWord(String word) {
    return 'Введіть $word для підтвердження.';
  }

  @override
  String get settingsSavedToast => 'Налаштування збережено!';

  @override
  String get quietHoursUpdatedToast => 'Тихі години оновлено!';

  @override
  String get signedInChip => 'Ви увійшли';

  @override
  String get securityLabel => 'Безпека';

  @override
  String get emailNotificationsLabel => 'Email';

  @override
  String get changePasswordHint => 'Щонайменше 6 символів';

  @override
  String get quietHoursNeedsPush => 'Увімкніть push, щоб користуватися тихими годинами';

  @override
  String get quietHoursFrom => 'З';

  @override
  String get quietHoursTo => 'До';

  @override
  String quietHoursSummary(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Сповіщення не прийдуть $hours годин поспіль',
      few: 'Сповіщення не прийдуть $hours години поспіль',
      one: 'Сповіщення не прийдуть $hours годину поспіль',
    );
    return '$_temp0';
  }

  @override
  String get passwordTooShortError => 'Новий пароль має бути не коротшим за 6 символів.';

  @override
  String get passwordSameAsCurrentError => 'Новий пароль має відрізнятися від поточного.';

  @override
  String get passwordsDoNotMatchError => 'Паролі не збігаються.';

  @override
  String get passwordCurrentWrongError => 'Поточний пароль неправильний.';

  @override
  String get subscriptionLoading => 'Завантажуємо ваш план…';

  @override
  String get editPlantTitle => 'Редагування';

  @override
  String get newPhotoBadge => 'Нове фото';

  @override
  String get revertPhoto => 'Повернути попереднє фото';

  @override
  String get editPlantNameHint => 'Так рослина називатиметься в саду та в нагадуваннях';

  @override
  String get aiManagedNote => 'Вид і план догляду визначає ШІ — вони оновлюються після нового аналізу здоров\'я.';

  @override
  String get noPhotoYet => 'Фото поки немає';

  @override
  String get gardenLoadError => 'Не вдалося завантажити сад. Перевір з\'єднання та спробуй ще раз.';

  @override
  String get pullToRefreshHint => 'Потягни вниз, щоб оновити';

  @override
  String get refreshingGarden => 'Збираємо дані саду…';

  @override
  String get refreshFailed => 'Не вдалося оновити. Перевір з\'єднання.';
}
