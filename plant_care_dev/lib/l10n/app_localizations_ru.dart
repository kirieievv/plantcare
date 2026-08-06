// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Plant Care';

  @override
  String get loadingPlantCare => 'Загружаем Plant Care...';

  @override
  String get home => 'Главная';

  @override
  String get myPlants => 'Мои растения';

  @override
  String get addPlant => 'Добавить растение';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get authenticationError => 'Ошибка аутентификации';

  @override
  String get pleaseLoginAgain => 'Пожалуйста, войдите снова';

  @override
  String get goToLogin => 'Перейти ко входу';

  @override
  String get yourGardenOverview => 'Обзор сада';

  @override
  String get welcomeBack => 'Добро пожаловать!';

  @override
  String get createYourAccount => 'Создайте аккаунт';

  @override
  String get fullName => 'Полное имя';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get pleaseEnterYourName => 'Пожалуйста, введите имя';

  @override
  String get pleaseEnterYourEmail => 'Пожалуйста, введите email';

  @override
  String get pleaseEnterValidEmail => 'Введите корректный email';

  @override
  String get pleaseEnterYourPassword => 'Пожалуйста, введите пароль';

  @override
  String get pleaseConfirmYourPassword => 'Пожалуйста, подтвердите пароль';

  @override
  String get passwordAtLeast6 => 'Пароль должен содержать не менее 6 символов';

  @override
  String get rememberMe30Days => 'Запомнить меня на 30 дней';

  @override
  String get logIn => 'Войти';

  @override
  String get registration => 'Регистрация';

  @override
  String get dontHaveAccountRegistration => 'Нет аккаунта? Регистрация';

  @override
  String get alreadyHaveAccountLogin => 'Уже есть аккаунт? Войти';

  @override
  String get loggedIn => 'Вы вошли';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get wateringReminders => 'Напоминания о поливе';

  @override
  String get getNotifiedWhenPlantsNeedWater =>
      'Получайте уведомления, когда растениям нужен полив';

  @override
  String get quietHours => 'Тихие часы';

  @override
  String get maxNotificationsPerDay => 'Макс. уведомлений в день';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уведомления',
      many: '$count уведомлений',
      few: '$count уведомления',
      one: '$count уведомление',
    );
    return '$_temp0';
  }

  @override
  String get theme => 'Тема';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get testNotifications => 'Тест уведомлений';

  @override
  String get checkNotificationSetupAndPermissions =>
      'Проверить настройки и разрешения уведомлений';

  @override
  String get language => 'Язык';

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
  String get savePreferences => 'Сохранить настройки';

  @override
  String get account => 'Аккаунт';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get updateYourAccountPassword => 'Обновить пароль аккаунта';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutOfYourAccount => 'Выйти из аккаунта';

  @override
  String get preferencesSavedSuccessfully => 'Настройки сохранены!';

  @override
  String errorSavingPreferences(Object error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => 'Тихие часы обновлены!';

  @override
  String get changePasswordTitle => 'Изменить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get enterCurrentPassword => 'Введите текущий пароль';

  @override
  String get enterNewPassword => 'Введите новый пароль';

  @override
  String get newPasswordMustBeDifferent => 'Новый пароль должен отличаться';

  @override
  String get confirmYourNewPassword => 'Подтвердите новый пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get passwordChangedSuccessfully => 'Пароль успешно изменён.';

  @override
  String errorChangingPassword(Object error) {
    return 'Ошибка изменения пароля: $error';
  }

  @override
  String get signOutConfirmTitle => 'Выход';

  @override
  String get signOutConfirmMessage => 'Вы уверены, что хотите выйти?';

  @override
  String get userLabel => 'Пользователь';

  @override
  String get nameCannotBeEmpty => 'Имя не может быть пустым';

  @override
  String get profileUpdatedSuccessfully => 'Профиль успешно обновлён!';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Ошибка обновления профиля: $error';
  }

  @override
  String get plantLover => 'Любитель растений';

  @override
  String get profileInformation => 'Информация профиля';

  @override
  String get bio => 'О себе';

  @override
  String get bioHint => 'Расскажите о своём опыте ухода за растениями...';

  @override
  String get location => 'Местоположение';

  @override
  String get locationHint => 'Где находятся ваши растения?';

  @override
  String get name => 'Имя';

  @override
  String get notSet => 'Не указано';

  @override
  String get accountInfo => 'Информация об аккаунте';

  @override
  String get memberSince => 'Участник с';

  @override
  String get lastLogin => 'Последний вход';

  @override
  String get notAvailable => 'Н/Д';

  @override
  String get actions => 'Действия';

  @override
  String get errorLabel => 'Ошибка';

  @override
  String get noPlantsYet => 'Растений пока нет!';

  @override
  String get addFirstPlantToGetStarted => 'Добавьте первое растение для начала';

  @override
  String get addYourFirstPlant => 'Добавить первое растение';

  @override
  String errorPickingImage(Object error) {
    return 'Ошибка выбора изображения: $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'Не удалось проанализировать фото: $statusCode';
  }

  @override
  String get aiAnalysisCompleted => 'ИИ-анализ завершён! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'ИИ-анализ не выполнен: $error';
  }

  @override
  String apiTestError(Object error) {
    return 'Ошибка теста API: $error';
  }

  @override
  String get aiAnalysisRefreshed => 'ИИ-анализ обновлён! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'Ошибка обновления ИИ-анализа: $error';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get uploadPlantPhoto => 'Загрузить фото растения';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get onceEvery7Days => 'Раз в 7 дней';

  @override
  String get oncePerDay => 'Раз в день';

  @override
  String get oncePerWeek => 'Раз в неделю';

  @override
  String onceEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Раз в $days дня',
      many: 'Раз в $days дней',
      few: 'Раз в $days дня',
      one: 'Каждый день',
    );
    return '$_temp0';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Раз в $weeks недели',
      many: 'Раз в $weeks недель',
      few: 'Раз в $weeks недели',
      one: 'Каждую неделю',
    );
    return '$_temp0';
  }

  @override
  String get low => 'Низкий';

  @override
  String get mediumLow => 'Ниже среднего';

  @override
  String get medium => 'Средний';

  @override
  String get mediumHigh => 'Выше среднего';

  @override
  String get high => 'Высокий';

  @override
  String get userNotAuthenticated => 'Пользователь не аутентифицирован';

  @override
  String get pleaseUploadPlantImage => 'Пожалуйста, загрузите фото растения';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant =>
      'Подождите завершения ИИ-анализа перед добавлением растения';

  @override
  String get plantLowercase => 'растение';

  @override
  String get plantAddedSuccessfully => 'Растение успешно добавлено! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Ошибка добавления растения: $error';
  }

  @override
  String get generateRandomName => 'Случайное название';

  @override
  String get plantName => 'Название растения';

  @override
  String get plantNameHint => 'например, Монстера, Сансевиерия';

  @override
  String get pleaseEnterPlantName => 'Пожалуйста, введите название';

  @override
  String get addingPlant => 'Добавляем растение...';

  @override
  String get analyzingPhoto => 'Анализируем фото...';

  @override
  String get plantUpdatedSuccessfully => 'Растение успешно обновлено! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Ошибка обновления растения: $error';
  }

  @override
  String get species => 'Вид';

  @override
  String get wateringFrequency => 'Частота полива';

  @override
  String everyNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Каждые $days дня',
      many: 'Каждые $days дней',
      few: 'Каждые $days дня',
      one: 'Каждый $days день',
    );
    return '$_temp0';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Выберите частоту полива';

  @override
  String get notes => 'Заметки';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get loadingImage => 'Загрузка изображения...';

  @override
  String get changeImage => 'Изменить фото';

  @override
  String errorDeletingPlant(Object error) {
    return 'Ошибка удаления растения: $error';
  }

  @override
  String get plantNotDueForWateringYet => 'Растение ещё не нуждается в поливе';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'Ошибка при открытии экрана растения: $error';
  }

  @override
  String get aiCare => 'ИИ-уход';

  @override
  String get aiAgent => 'ИИ-помощник';

  @override
  String get plantChatOpen => 'Открыть чат с растением';

  @override
  String plantChatTitle(Object plantName) {
    return 'Чат о $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return 'Привет! Я ваш помощник по уходу за $plantName. Спросите о поливе, признаках болезней или о том, что делать дальше.';
  }

  @override
  String get plantChatInputHint => 'Спросите об этом растении...';

  @override
  String get plantChatLoginAgain => 'Пожалуйста, войдите снова.';

  @override
  String get plantChatRequestFailed => 'Запрос к чату не выполнен';

  @override
  String get plantChatCouldNotGenerateResponse =>
      'Не удалось сгенерировать ответ. Попробуйте ещё раз.';

  @override
  String get plantChatConnectionError =>
      'Что-то пошло не так при соединении с помощником. Попробуйте ещё раз.';

  @override
  String get plantChatQuickWaterToday => 'Можно ли полить сегодня?';

  @override
  String get plantChatQuickYellowLeaves => 'Почему желтеют листья?';

  @override
  String get plantChatQuickWhatToDoNow => 'Что делать прямо сейчас?';

  @override
  String get plantChatImageQuotaReached =>
      'Дневной лимит фото достигнут. Попробуйте завтра.';

  @override
  String get splashTagline => 'Умный уход за растениями';

  @override
  String get getStarted => 'Начать';

  @override
  String get splashDescription =>
      'Следите за растениями, получайте персонализированные советы\nи отслеживайте их здоровье — всё в одном месте.';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get errorInvalidPin => 'Неверный код. Попробуйте ещё раз.';

  @override
  String get errorPinExpired => 'Срок действия кода истёк. Запросите новый.';

  @override
  String get errorPinNotFound => 'Код не найден. Запросите новый.';

  @override
  String get errorTooManyAttempts =>
      'Слишком много попыток. Запросите новый код.';

  @override
  String get errorSendFailed => 'Не удалось отправить код. Попробуйте ещё раз.';

  @override
  String get errorUserNotFound => 'Аккаунт с таким email не найден.';

  @override
  String get errorEmailAlreadyExists => 'Аккаунт с таким email уже существует.';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get resetYourPassword => 'Восстановить пароль';

  @override
  String get enterEmailForCode =>
      'Введите email аккаунта, чтобы получить код подтверждения.';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get enterVerificationCode => 'Введите код подтверждения';

  @override
  String get weSentACodeTo => 'Мы отправили 6-значный код на';

  @override
  String get verificationCodeSentAgain =>
      'Код подтверждения отправлен повторно.';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Отправить повторно через $secondsс';
  }

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get setNewPassword => 'Задать новый пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get updatePassword => 'Обновить пароль';

  @override
  String get passwordResetSuccess =>
      'Пароль успешно сброшен. Пожалуйста, войдите.';

  @override
  String get totalPlants => 'Всего растений';

  @override
  String get needWater => 'Нужен полив';

  @override
  String get healthy => 'Здоровые';

  @override
  String get yourPlants => 'Мои растения';

  @override
  String get plantCreatedSuccessfully => 'Растение успешно создано! 🌱';

  @override
  String get searchPlantsHint => 'Поиск по имени или виду';

  @override
  String get filterAll => 'Все';

  @override
  String get filterOverdue => 'Просрочено';

  @override
  String get noResultsTitle => 'Ничего не найдено';

  @override
  String get noResultsSub => 'Попробуйте другой запрос или фильтр.';

  @override
  String get edit => 'Редактировать';

  @override
  String get wateringRemindersBlockSub =>
      'Получайте уведомления о поливе растений.';

  @override
  String get emailRemindersTitle => 'Email-напоминания';

  @override
  String get emailRemindersSub => 'Напоминания о поливе на email';

  @override
  String get pushNotificationsTitle => 'Push-уведомления';

  @override
  String get pushNotificationsSub => 'Мгновенные оповещения на устройство';

  @override
  String get quietHoursLabel => 'Тихие часы';

  @override
  String get themeLabel => 'Тема';

  @override
  String get languageLabel => 'Язык';

  @override
  String get preferencesTitle => 'Настройки';

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get changePasswordTitleRow => 'Изменить пароль';

  @override
  String get changePasswordSubRow => 'Обновить пароль аккаунта';

  @override
  String get signOutSubRow => 'Выйти из аккаунта';

  @override
  String get aiAssistantOnline => 'ИИ-помощник по растениям · в сети';

  @override
  String get clearHistoryAction => 'Очистить историю';

  @override
  String get clearHistoryConfirm => 'Очистить историю чата?';

  @override
  String get saving => 'Сохранение…';

  @override
  String get plantPhoto => 'Фото растения';

  @override
  String get addPlantTitle => 'Добавить растение';

  @override
  String get addPlantSubtitle => 'Сфотографируйте, определите, сохраните';

  @override
  String get snapTitle => 'Сделайте фото';

  @override
  String get snapDescription =>
      'Чёткое фото поможет нашему ИИ определить\nваше растение и подобрать уход';

  @override
  String get useCamera => 'Камера';

  @override
  String get uploadFromGallery => 'Из галереи';

  @override
  String get analyzing => 'Анализ...';

  @override
  String get couldntIdentify => 'Не удалось определить растение';

  @override
  String get tryAnotherPhoto =>
      'Попробуйте другое фото или введите вид вручную ниже.';

  @override
  String get topMatch => 'Лучшее совпадение';

  @override
  String get useThisMatch => 'Выбрать это';

  @override
  String get manualNamePlaceholder => 'Название растения (напр. Ирис)';

  @override
  String get savePlantBtn => 'Сохранить растение';

  @override
  String get tagOverdue => 'ПРОСРОЧЕНО';

  @override
  String get tagDueSoon => 'СКОРО';

  @override
  String get tagHealthy => 'ЗДОРОВОЕ';

  @override
  String get wateringScheduleTitle => 'График полива';

  @override
  String get lastWatered => 'Последний полив';

  @override
  String get nextWatering => 'Следующий полив';

  @override
  String get frequency => 'Частота';

  @override
  String get waterNowAction => 'Полить сейчас';

  @override
  String get rescheduleAction => 'Перенести';

  @override
  String get careRecommendationsTitle => 'Рекомендации по уходу';

  @override
  String get careSectionCultivar => 'Культивар';

  @override
  String get careSectionGeneralDescription => 'Общее описание';

  @override
  String get careSectionSoil => 'Почва';

  @override
  String get careSectionSoilMoisture => 'Влажность почвы';

  @override
  String get careSectionMoistureCheck => 'Проверка влажности';

  @override
  String get careSectionWater => 'Полив';

  @override
  String get careSectionLight => 'Освещение';

  @override
  String get careSectionTemperature => 'Температура';

  @override
  String get careSectionFertilizer => 'Удобрения';

  @override
  String get careSectionGrowthRate => 'Скорость роста';

  @override
  String get careSectionToxicity => 'Токсичность';

  @override
  String get careSectionPlacement => 'Размещение';

  @override
  String get careSectionPersonality => 'Характер';

  @override
  String get aboutPlantTitle => 'О растении';

  @override
  String get askAssistantTitle => 'Спросить помощника';

  @override
  String get askAssistantSub => 'Персонализированные советы от Iris AI';

  @override
  String get openChat => 'Открыть чат';

  @override
  String get deletePlantAction => 'Удалить растение';

  @override
  String get reminderEmail => 'Email';

  @override
  String get reminderEmailSubtitle => 'Email-напоминания о поливе';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get pushNotificationsSubtitle =>
      'Уведомления в приложении (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'Просрочено $daysд';
  }

  @override
  String get wateringToday => 'Полив сегодня';

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
    return 'Ошибка полива: $error';
  }

  @override
  String get healthIssueDetected => 'Обнаружена проблема со здоровьем';

  @override
  String get recommendedActionsLabel => 'Рекомендуемые действия:';

  @override
  String get healthAlertNote =>
      'Уведомление будет отображаться до тех пор, пока следующая проверка не вернёт статус OK';

  @override
  String get addHealthCheckTooltip => 'Добавить проверку здоровья';

  @override
  String get noHealthChecksYet => 'Проверок здоровья пока нет';

  @override
  String get uploadPhotosToTrackHealth =>
      'Загружайте фото для отслеживания здоровья растения';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String nDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня назад',
      many: '$days дней назад',
      few: '$days дня назад',
      one: '$days день назад',
    );
    return '$_temp0';
  }

  @override
  String get healthStatusOk => 'ОК';

  @override
  String get healthStatusIssue => 'Проблема';

  @override
  String get assistantTyping => 'Помощник печатает...';

  @override
  String chatSourceLabel(Object source) {
    return 'Источник: $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'База знаний';

  @override
  String get chatSourceContext => 'Контекст';

  @override
  String get chatSourceAgent => 'Агент';

  @override
  String get chatAttachPhoto => 'Прикрепить фото';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit фото сегодня';
  }

  @override
  String get chatPhotoQuotaExhausted =>
      'Дневной лимит фото достигнут. Попробуйте завтра.';

  @override
  String get chatPhotoUploading => 'Загрузка фото...';

  @override
  String get chatPhotoUploadFailed =>
      'Не удалось загрузить фото. Попробуйте ещё раз.';

  @override
  String get chatRemovePhoto => 'Удалить фото';

  @override
  String get chatCopyMessage => 'Копировать';

  @override
  String get chatClearHistory => 'Новый чат';

  @override
  String get chatClearHistoryConfirm =>
      'Начать новый разговор? История будет удалена.';

  @override
  String get chatClearHistorySuccess => 'Новый разговор начат.';

  @override
  String get chatDateToday => 'Сегодня';

  @override
  String get chatDateYesterday => 'Вчера';

  @override
  String get choosePhoto => 'Выбрать фото';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String get analyzeHealth => 'Анализ здоровья';

  @override
  String get waterFirstLabel => 'Сначала полейте';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Следующая проверка через $days д';
  }

  @override
  String get imageReadyForAnalysis =>
      'Фото загружено! Готово к анализу здоровья.';

  @override
  String get healthCheckTitle => 'Проверка здоровья';

  @override
  String get healthCheckHistoryTitle => 'История проверок здоровья';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Загрузите фото $plantName для ИИ-анализа здоровья';
  }

  @override
  String get deletePlant => 'Удалить растение';

  @override
  String get deletePlantConfirm =>
      'Вы уверены, что хотите удалить это растение?';

  @override
  String get delete => 'Удалить';

  @override
  String get iHaveWatered => 'Я полил(а)';

  @override
  String get soilMoisture => 'Идеальная почва';

  @override
  String get lightLabel => 'Освещение';

  @override
  String get perDay => 'в день';

  @override
  String get hoursLabel => 'часов';

  @override
  String get interestingFactsTitle => 'Интересные факты';

  @override
  String get noCareRecommendationsYet =>
      'Рекомендации по уходу от ИИ пока недоступны для этого растения.';

  @override
  String get noInterestingFactsYet =>
      'Интересные факты от ИИ пока недоступны для этого растения.';

  @override
  String get noDescriptionYet => 'Описание ещё не добавлено.';

  @override
  String get swipeToSeeMore => 'Листайте, чтобы увидеть больше';

  @override
  String get uploadPhotosForHealthHistory =>
      'Загружайте фото для отслеживания здоровья растения';

  @override
  String plantDeletedMessage(Object plantName) {
    return 'Растение \"$plantName\" удалено';
  }

  @override
  String get noImageAvailable => 'Фото недоступно';

  @override
  String get addPhotoToSeeYourPlant =>
      'Добавьте фото, чтобы видеть своё растение';

  @override
  String get isThisYourPlant => 'Это ваше растение?';

  @override
  String get speciesPickSubtitle => 'Мы нашли варианты — выберите подходящий';

  @override
  String get noneOfThese => 'Ни один не подходит';

  @override
  String get typePlantNameRetry =>
      'Введите название растения, и мы попробуем снова';

  @override
  String get gettingCareRecommendations => 'Получаем рекомендации по уходу';

  @override
  String get imageUploadedAnalysisComplete =>
      'Фото загружено! ИИ-анализ завершён.';

  @override
  String get aiCareRecommendationsHeader => 'Рекомендации по уходу от ИИ';

  @override
  String get aiReady => 'ИИ готов';

  @override
  String get checkPlantButton => 'Проверить растение';

  @override
  String get plantCareAssistantTitle => 'Помощник по уходу за растениями';

  @override
  String get plantNeedsHelp => 'Растению нужна помощь!';

  @override
  String get whatToDoNow => 'Что делать сейчас';

  @override
  String get wateringLabel => 'Полив';

  @override
  String get nowLabel => 'Сейчас';

  @override
  String get nextIn1Day => 'Следующий через 1 день';

  @override
  String nextInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Следующий через $days дня',
      many: 'Следующий через $days дней',
      few: 'Следующий через $days дня',
      one: 'Следующий через $days день',
    );
    return '$_temp0';
  }

  @override
  String get wateringDone => 'Полив выполнен';

  @override
  String get moistureDry => 'Сухая';

  @override
  String get moistureWet => 'Влажная';

  @override
  String get moistureLevelVeryDry => 'Очень сухая';

  @override
  String get moistureLevelDry => 'Сухая';

  @override
  String get moistureLevelSlightlyMoist => 'Слегка влажная';

  @override
  String get moistureLevelMoist => 'Влажная';

  @override
  String get moistureLevelVeryMoist => 'Очень влажная';

  @override
  String bannerWaterTitle(String name) {
    return '$name нуждается в поливе';
  }

  @override
  String get bannerWaterSubtitle =>
      'Нажмите, чтобы полить или посмотреть детали';

  @override
  String get bannerTipTitle => 'Совет дня';

  @override
  String get bannerTipSubtitle => 'Нажмите для сезонных советов';

  @override
  String get tipsOfTheDay => 'Советы дня';

  @override
  String get tipsOfTheDaySub =>
      'Сезонные советы от ИИ · обновляются еженедельно';

  @override
  String get tipCategoryWatering => 'Полив';

  @override
  String get tipCategoryLight => 'Освещение';

  @override
  String get tipCategoryPests => 'Вредители';

  @override
  String get tipCategoryFertilizing => 'Удобрение';

  @override
  String get tipCategorySeasonal => 'Сезонные';

  @override
  String get tipCategoryGeneral => 'Общее';

  @override
  String get noTipsYet => 'Советы генерируются. Заходите позже!';

  @override
  String get waterNow => 'Полить сейчас';

  @override
  String get subscriptionUpgrade => 'Улучшить';

  @override
  String get subscriptionManage => 'Управление';

  @override
  String get subscriptionActiveTitle => 'Premium активен';

  @override
  String get subscriptionGrandfatheredTitle => 'Пожизненный доступ';

  @override
  String get subscriptionTrialTitle => 'Бесплатный пробный период';

  @override
  String get subscriptionExpiredTitle => 'Подписка истекла';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Активен до $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'Пробный период заканчивается $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Осталось $days дня',
      many: 'Осталось $days дней',
      few: 'Осталось $days дня',
      one: 'Остался $days день',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionExpiredMessage =>
      'Ваша подписка истекла. Оформите подписку, чтобы продолжить.';

  @override
  String get subscriptionPlantLimitReached => 'Лимит растений достигнут';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Достигнут лимит бесплатного плана. Перейдите на Premium — до $limit растений.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired =>
      'Оформите подписку, чтобы добавлять растения.';

  @override
  String get subscriptionReadOnlyNotice =>
      'Режим чтения. Оформите подписку для редактирования.';

  @override
  String get paywallTitle => 'Открыть Premium';

  @override
  String get paywallSubtitle => 'Получите максимум от коллекции растений';

  @override
  String paywallFeature1(int limit) {
    return 'До $limit растений';
  }

  @override
  String get paywallFeature2 => 'Неограниченные напоминания о поливе';

  @override
  String get paywallFeature3 => 'ИИ-помощник и проверки здоровья';

  @override
  String get paywallFeature4 => 'Полное редактирование и отслеживание';

  @override
  String get paywallMonthly => 'Ежемесячно';

  @override
  String get paywallAnnual => 'Ежегодно';

  @override
  String get paywallBestValue => 'Лучшая цена';

  @override
  String get paywallContinue => 'Продолжить';

  @override
  String get paywallRestore => 'Восстановить покупку';

  @override
  String get paywallRestoring => 'Восстановление…';

  @override
  String get paywallRestoreSuccess => 'Покупка восстановлена!';

  @override
  String get paywallRestoreNotFound => 'Предыдущие покупки не найдены.';

  @override
  String get paywallRestoreAlreadyActive => 'Ваша подписка уже активна.';

  @override
  String get paywallTerms =>
      'Подписка автоматически продлевается. Отмените в любое время в настройках App Store.';

  @override
  String get paywallLoading => 'Загружаем планы…';

  @override
  String get paywallPurchasing => 'Обработка…';

  @override
  String get paywallError => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get paywallHeroTitle => 'Расти без ограничений.';

  @override
  String get paywallHeroDescription =>
      'Ваш персональный ИИ-ассистент — напоминания о поливе, проверка здоровья, сезонные советы и всё необходимое для процветания ваших растений.';

  @override
  String get paywallChoosePlan => 'ВЫБЕРИТЕ ПЛАН';

  @override
  String paywallPerMonth(Object price) {
    return 'Всего $price / месяц';
  }

  @override
  String get paywallStartPremium => 'Начать Premium';

  @override
  String get paywallSecured => 'Защищено Stripe';

  @override
  String get paywallSecuredApple => 'Защищено';

  @override
  String get paywallCancelAnytime => 'Отмена в любое время';

  @override
  String get paywallAutoRenews => 'автопродление';

  @override
  String get stripeSuccessTitle => 'Подписка активирована!';

  @override
  String get stripeSuccessWaiting => 'Активируем вашу подписку';

  @override
  String get stripeSuccessSubtitle =>
      'Добро пожаловать в Botanly Premium! Теперь у вас есть доступ ко всем функциям.';

  @override
  String get stripeSuccessButton => 'К моим растениям';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'Не удалось открыть портал оплаты: $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Ошибка восстановления: $error';
  }

  @override
  String get emailCopied => 'Email скопирован: support@botanly.app';

  @override
  String get labelExpires => 'Истекает';

  @override
  String get labelNextRenewal => 'Следующее продление';

  @override
  String get labelAutoRenewal => 'Автопродление';

  @override
  String get labelRestorePurchases => 'Восстановить покупки';

  @override
  String get labelPlants => 'Растения';

  @override
  String get labelRenews => 'Продление';

  @override
  String get testWateringEmailQueued => 'Тестовый email о поливе отправлен.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'Не удалось отправить тестовый email: $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'Ошибка сохранения каналов напоминаний: $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'Ошибка обновления тихих часов: $error';
  }

  @override
  String get deleteAccountTitle => 'Удалить аккаунт';

  @override
  String get deleteAccountSubtitle => 'Навсегда отключить ваш аккаунт';

  @override
  String get deleteAccountConfirmBody =>
      'Ваш аккаунт будет навсегда отключён, и вы потеряете доступ к приложению. Данные о ваших растениях будут сохранены.\n\nЭто действие нельзя отменить.';

  @override
  String get deleteAccountAreYouSure => 'Вы уверены?';

  @override
  String get deleteAccountTypeConfirm => 'Введите DELETE для подтверждения:';

  @override
  String get deleteAccountConfirmBtn => 'Подтвердить удаление';

  @override
  String errorDeletingAccount(Object error) {
    return 'Не удалось удалить аккаунт: $error';
  }

  @override
  String get subPillPremium => 'Премиум';

  @override
  String get subPillEarlyMember => 'Ранний участник';

  @override
  String get subPillFreePlan => 'Бесплатный план';

  @override
  String get subPillFreeTrial => 'Пробный период';

  @override
  String get subMetaActivePlan => 'АКТИВНЫЙ ПЛАН';

  @override
  String get subMetaForeverPremium => 'ВЕЧНЫЙ ПРЕМИУМ';

  @override
  String get subMetaTrialEnded => 'ПРОБНЫЙ ПЕРИОД ЗАВЕРШЁН';

  @override
  String subMetaNDayPreview(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ПРЕДПРОСМОТР $n ДНЯ',
      many: 'ПРЕДПРОСМОТР $n ДНЕЙ',
      few: 'ПРЕДПРОСМОТР $n ДНЯ',
      one: 'ПРЕДПРОСМОТР $n ДЕНЬ',
    );
    return '$_temp0';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Обновляется через $days дн. · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Заканчивается через $days дн. · $date';
  }

  @override
  String get subActiveSubscription => 'Активная подписка';

  @override
  String get subGrantedEarlyMember =>
      'Предоставлен как раннему участнику Botanly';

  @override
  String get subDaysLeft => 'дней осталось';

  @override
  String get subUntilPreviewEnds => 'до конца\nпробного периода';

  @override
  String get subTrialEnded => 'пробный период\nзавершён';

  @override
  String get subAutoRenewOn => 'Автопродление включено  ·  Можно отменить';

  @override
  String get subAutoRenewOff =>
      'Автопродление выключено  ·  Доступ до истечения';

  @override
  String get subDetails => 'Детали';

  @override
  String get subReactivate => 'Возобновить';

  @override
  String get subNoChargesEver =>
      'Без оплаты навсегда  ·  Все возможности открыты';

  @override
  String get subLimitedAccess => 'Ограниченный доступ  ·  Без AI-ухода';

  @override
  String get subUnlimitedAccess =>
      'Без ограничений  ·  AI-уход  ·  Напоминания';

  @override
  String get subHeroYourePrefix => 'Вы ';

  @override
  String get subHeroGrowingWord => 'растёте';

  @override
  String get subHeroForeverWord => 'Навсегда';

  @override
  String get subHeroPremiumSuffix => ' Премиум';

  @override
  String get labelEnds => 'Истекает';

  @override
  String get labelPlan => 'План';

  @override
  String get labelPremium => 'Премиум';

  @override
  String get labelGrandfathered => 'Наследственный доступ';

  @override
  String get labelOn => 'Вкл';

  @override
  String get labelOff => 'Выкл';

  @override
  String get yourPlan => 'Ваш план';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get manageBillingWeb => 'Управление счётом';

  @override
  String get manageInAppStore => 'Управление в App Store';

  @override
  String get manageBillingSubtitleWeb =>
      'Отмените, обновите карту или просмотрите счета\nчерез портал Stripe.';

  @override
  String get manageBillingSubtitleAppStore =>
      'Для отключения автопродления или отмены перейдите\nв подписки App Store.';

  @override
  String get tipGoodLight => 'хорошее освещение';

  @override
  String get tipShowLeaves => 'покажите листья';

  @override
  String get tipSinglePlant => 'одно растение';

  @override
  String get snapYourSprout => 'Сфотографируйте свой росток';

  @override
  String get identifyingPlantPrefix => 'Определяем ваше ';

  @override
  String get identifyingPlantWord => 'растение';

  @override
  String get identifyingSubtitle => 'Изучаем листья, стебли и соседей рядом';

  @override
  String get specificIssues => 'Специфические проблемы';

  @override
  String get healthCheckPhotoHint =>
      'Добавьте до 3 фото — чем больше ракурсов, тем точнее анализ. Обязательно только первое фото.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Растение целиком';

  @override
  String get healthCheckSlot1Desc =>
      'Снимите растение полностью вместе с горшком — чтобы было видно землю и весь горшок.';

  @override
  String get healthCheckSlot1Tag => 'Обязательно';

  @override
  String get healthCheckSlot2Title => 'Крупный план';

  @override
  String get healthCheckSlot2Desc =>
      'Поднесите камеру ближе, без горшка — чтобы чётко видны листья и их фактура.';

  @override
  String get healthCheckSlot2Tag => 'По желанию';

  @override
  String get healthCheckSlot3Title => 'Проблемная зона';

  @override
  String get healthCheckSlot3Desc =>
      'Хотите показать что-то отдельно? Сфотографируйте пятно, вредителя или повреждённый лист.';

  @override
  String get healthCheckSlot3Tag => 'По желанию';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return 'Анализировать $count фото';
  }

  @override
  String get healthCheckError =>
      'Анализ не выполнен. Пожалуйста, попробуйте ещё раз.';

  @override
  String get healthCheckDefaultPraise =>
      '🌱 Ваше растение чувствует себя хорошо!';

  @override
  String get healthCheckDefaultFooter =>
      'Продолжайте ухаживать за растением согласно рекомендациям и отмечайте, когда поливаете.';

  @override
  String get addPlantWholePlantTitle => 'Растение целиком';

  @override
  String get addPlantWholePlantDesc => 'с горшком и землёй';

  @override
  String get addPlantWholePlantTag => 'Обязательно';

  @override
  String get addPlantCloseUpTitle => 'Крупный план';

  @override
  String get addPlantCloseUpDesc => 'листья в деталях';

  @override
  String get addPlantCloseUpTag => 'По желанию';

  @override
  String get addPlantDualHint =>
      'Два ракурса помогут ИИ точнее определить ваше растение.';

  @override
  String get addPlantAnalyzeButton => 'Анализировать растение';

  @override
  String get addPlantStepPhotosReceived => 'Фото получены';

  @override
  String get addPlantStepIdentifying => 'Определяем вид';

  @override
  String get addPlantStepCarePlan => 'Составляем план ухода';

  @override
  String get addPlantAnalyzingTitle => 'Анализируем ваше растение';

  @override
  String get addPlantAnalyzingSubtitle =>
      'Обычно это занимает несколько секунд…';

  @override
  String get addPlantAnalysisComplete => 'Анализ завершён';

  @override
  String get addPlantSeePlantProfile => 'Посмотреть профиль растения';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingGetStarted => 'Начать';

  @override
  String get onboarding1Eyebrow => 'Добро пожаловать';

  @override
  String get onboarding1Title => 'Знакомьтесь: ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body =>
      'Ваш ИИ-помощник для счастливых и здоровых растений — всегда под рукой.';

  @override
  String get onboarding2Eyebrow => 'Определение';

  @override
  String get onboarding2Title => 'Узнайте ';

  @override
  String get onboarding2TitleItalic => 'любое растение';

  @override
  String get onboarding2Body =>
      'Наведите камеру — ИИ определит вид, название и всё остальное за секунды.';

  @override
  String get onboarding3Eyebrow => 'Уход';

  @override
  String get onboarding3Title => 'Уход стал ';

  @override
  String get onboarding3TitleItalic => 'проще';

  @override
  String get onboarding3Body =>
      'Напоминания о поливе, освещении и почве — точно настроенные под каждое растение.';

  @override
  String get onboarding4Eyebrow => 'Проверка здоровья';

  @override
  String get onboarding4Title => 'Замечайте проблемы ';

  @override
  String get onboarding4TitleItalic => 'вовремя';

  @override
  String get onboarding4Body =>
      'Сфотографируйте — получите мгновенную проверку здоровья и чёткий план лечения.';

  @override
  String get onboarding5Eyebrow => 'Готово';

  @override
  String get onboarding5Title => 'Давайте ';

  @override
  String get onboarding5TitleItalic => 'расти вместе';

  @override
  String get onboarding5Body =>
      'Создайте свою коллекцию и никогда ничего не пропускайте. Ваша самая зелёная эра начинается сейчас.';

  @override
  String get tabCare => 'Уход';

  @override
  String get tabAbout => 'О растении';

  @override
  String get tabHistory => 'История';

  @override
  String nDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$_temp0';
  }

  @override
  String get cycleJustStarted => 'Цикл только начался';

  @override
  String cyclePercentComplete(int percent) {
    return 'Цикл пройден на $percent%';
  }

  @override
  String get wateringAmount => 'Объём';

  @override
  String get noDataAvailable => 'Пока нет данных';

  @override
  String get healthCheckHistoryEmptyHint =>
      'Загружай фото раз в пару недель — соберём таймлайн состояния растения';

  @override
  String milliliters(int count) {
    return '$count мл';
  }

  @override
  String get millilitersShort => 'МЛ';

  @override
  String nHours(String hours) {
    return '$hours ч';
  }

  @override
  String get lightDaily => 'В день';

  @override
  String get lightType => 'Тип';

  @override
  String get lightTypeDirect => 'Прямой';

  @override
  String get lightTypePartialSun => 'Полутень';

  @override
  String get lightTypeBrightIndirect => 'Яркий рассеянный';

  @override
  String get lightTypeLowLight => 'Слабый свет';

  @override
  String get everyDay => 'Каждый день';

  @override
  String get healthCheckSeverity => 'Серьёзность';

  @override
  String get healthCheckFollowUp => 'Повторная проверка';

  @override
  String get severityLow => 'Низкая';

  @override
  String get severityMedium => 'Средняя';

  @override
  String get severityHigh => 'Высокая';

  @override
  String get careKvFrequency => 'Частота';

  @override
  String get careKvSeason => 'Сезон';

  @override
  String get careKvOptimal => 'Оптимум';

  @override
  String get careKvMinimum => 'Минимум';

  @override
  String get careKvDose => 'Доза';

  @override
  String get healthAnalyzeCta => 'Проверить состояние';

  @override
  String get healthNeedsAttention => 'Требует внимания';

  @override
  String get healthStatusHealthy => 'Здоровое растение';

  @override
  String get healthWhatToDo => 'Что сделать';

  @override
  String get healthClose => 'Закрыть';

  @override
  String get healthNotSavedYet => 'Проверка ещё не в истории';

  @override
  String get healthAskAssistant => 'Спросить AI';

  @override
  String get healthAddedToPlan => 'Добавлено в план';

  @override
  String get healthLockedNeedsWatering =>
      'Отметьте полив, чтобы проверить снова';

  @override
  String get healthLockedLimitReached => 'Проверки на этот цикл исчерпаны';

  @override
  String get healthAdviceSub => 'Посмотреть, что сделать';

  @override
  String get healthAnalyzingTitle => 'Анализируем…';

  @override
  String get healthStepRecognize => 'Распознаём растение';

  @override
  String get healthStepCompare => 'Сравниваем с прошлыми проверками';

  @override
  String get healthStepAdvice => 'Формируем рекомендации';

  @override
  String healthStepPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото получено',
      few: '$count фото получено',
      one: '$count фото получено',
    );
    return '$_temp0';
  }

  @override
  String healthAdviceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рекомендаций после проверки',
      few: '$count рекомендации после проверки',
      one: '$count рекомендация после проверки',
    );
    return '$_temp0';
  }

  @override
  String get healthHistoryLoadFailed => 'Не удалось загрузить историю';

  @override
  String get healthUpToThreePhotos => 'До 3 фото';

  @override
  String get healthResultTitle => 'Результат';

  @override
  String get taskAllDone => 'Всё сделано — растение в порядке';

  @override
  String get taskBadgeScheduled => 'По расписанию';

  @override
  String get taskBadgeAnalysis => 'После анализа';

  @override
  String taskBadgeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Просрочено $days дня',
      many: 'Просрочено $days дней',
      few: 'Просрочено $days дня',
      one: 'Просрочено $days день',
    );
    return '$_temp0';
  }

  @override
  String get taskDone => 'Готово';

  @override
  String get taskDoneAlready => 'Сделано';

  @override
  String get taskLater => 'Позже';

  @override
  String get taskAskAssistant => 'Спросить ассистента';

  @override
  String taskAskQuestion(String title) {
    return 'Что нужно сделать по задаче «$title»?';
  }

  @override
  String get homeGardenTitleLead => 'Твой';

  @override
  String get homeGardenTitleAccent => 'сад';

  @override
  String get gardenHealthLabel => 'Здоровье сада';

  @override
  String get gardenAllGood => 'Все растения в порядке';

  @override
  String gardenOneWeak(String name) {
    return '$name тянет сад вниз';
  }

  @override
  String gardenManyWeak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count растениям нужен твой уход',
      few: '$count растениям нужен твой уход',
      one: '$count растению нужен твой уход',
    );
    return '$_temp0';
  }

  @override
  String get homeOrbitHint => 'Нажми на растение, чтобы открыть его';

  @override
  String get homeAllTasksLink => 'Все задачи';

  @override
  String get deckAllClearTitle => 'Сад в порядке';

  @override
  String taskOverdueShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$_temp0';
  }

  @override
  String get taskPostponed => 'Отложено';

  @override
  String get allTasksTitle => 'Все задачи';

  @override
  String allTasksSubtitle(int today, int later) {
    return '$today сегодня · $later дальше';
  }

  @override
  String get allTasksToday => 'Сегодня';

  @override
  String get allTasksLater => 'Дальше';

  @override
  String get allTasksRuleNote =>
      'Новые задачи не появятся, пока не разберёшься с сегодняшними.';

  @override
  String get allTasksNothingToday => 'На сегодня всё закрыто';

  @override
  String get whenTomorrow => 'Завтра';

  @override
  String get whenInAWeek => 'Через неделю';

  @override
  String whenInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days дней',
      few: 'Через $days дня',
      one: 'Через $days день',
    );
    return '$_temp0';
  }

  @override
  String careAskAbout(String title) {
    return 'Спросить ассистента про $title';
  }

  @override
  String careAskQuestion(String title) {
    return 'Расскажи подробнее про «$title» для моего растения';
  }

  @override
  String get healthAskQuestionIssue =>
      'Что сделать по результатам анализа в первую очередь?';

  @override
  String get healthAskQuestionOk =>
      'Анализ показал, что растение здорово — что можно улучшить?';

  @override
  String get glassesOne => '1 стакан';

  @override
  String glassesAmount(String value) {
    return '$value стакана';
  }

  @override
  String addPlantStepOf(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String get addPlantTitleLead => 'Добавить';

  @override
  String get addPlantTitleAccent => 'растение';

  @override
  String get addPlantNameHint =>
      'Как будешь звать этот цветок — Моня, Фикусыч, Monstera. Кубик придумает за тебя.';

  @override
  String get addPlantPhotosTitle => 'Фотографии';

  @override
  String get addPlantWholePlant => 'Всё растение';

  @override
  String get addPlantWholePlantHint => 'с горшком и почвой';

  @override
  String get addPlantRequired => 'Нужно';

  @override
  String get addPlantTwoAnglesHint =>
      'Два ракурса помогают точнее определить вид — второе фото не обязательно, но повышает точность.';

  @override
  String get addPlantTipLight => 'хороший свет';

  @override
  String get addPlantTipLeaves => 'видно листья';

  @override
  String get addPlantTipSingle => 'одно растение';

  @override
  String get addPlantIdentifyCta => 'Определить вид';

  @override
  String get addPlantRandomNames =>
      'Моня|Фикусыч|Зелёныш|Кактус Петрович|Листик|Бобо|Тихон|Пушок';

  @override
  String get addPlantIsThisYourPlant => 'Это твоё растение?';

  @override
  String get addPlantPickSpeciesHint =>
      'Выбери подходящий вариант — от этого зависит план ухода.';

  @override
  String get addPlantNoneMatch => 'Ничего не подходит — введу сам';

  @override
  String get addPlantManualHint =>
      'Введи название вида — поищем заново по нему.';

  @override
  String get addPlantManualPlaceholder => 'Например, Monstera deliciosa';

  @override
  String get addPlantBuildPlanCta => 'Составить план ухода';

  @override
  String addPlantStartingScore(int score) {
    return 'Стартовый балл $score';
  }

  @override
  String get addPlantPlanWatering => 'Полив';

  @override
  String get addPlantPlanLight => 'Свет';

  @override
  String get addPlantPlanSoil => 'Почва';

  @override
  String get addPlantSoilSlightlyMoist => 'Слегка влажная';

  @override
  String addPlantEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Раз в $days дней',
      few: 'Раз в $days дня',
      one: 'Раз в $days день',
    );
    return '$_temp0';
  }

  @override
  String get addPlantCarePlan => 'План ухода';

  @override
  String addPlantNTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задач',
      few: '$count задачи',
      one: '$count задача',
    );
    return '$_temp0';
  }

  @override
  String get addPlantFirstWatering => 'Первый полив';

  @override
  String get addPlantToday => 'сегодня';

  @override
  String get addPlantWaterToday => 'сегодня';

  @override
  String get addPlantFertilising => 'Подкормка';

  @override
  String get addPlantFertilisingDetail => 'Через 2 недели · половинная доза';

  @override
  String get addPlantHealthCheck => 'Проверка здоровья';

  @override
  String get addPlantHealthCheckDetail => 'Через месяц · 1–3 фото';

  @override
  String get addPlantAddToGarden => 'Добавить в сад';

  @override
  String get addPlantNoSpeciesFound =>
      'Не удалось распознать растение. Попробуй другое фото.';

  @override
  String get addPlantNoPlan =>
      'Не удалось составить план ухода. Попробуй ещё раз.';

  @override
  String get addPlantLoaderPhotos => 'Фото получены';

  @override
  String get addPlantLoaderIdentify => 'Определяем вид';

  @override
  String get addPlantLoaderPlan => 'Составляем план ухода';

  @override
  String get myPlantsTitleLead => 'Мои';

  @override
  String get myPlantsTitleAccent => 'растения';

  @override
  String myPlantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count растений',
      few: '$count растения',
      one: '$count растение',
    );
    return '$_temp0';
  }

  @override
  String get myPlantsEmptyLabel => 'Пока пусто';

  @override
  String get filterTomorrow => 'Завтра';

  @override
  String get filterNeedsCare => 'Нужен уход';

  @override
  String get myPlantsNothingFound => 'Ничего не найдено';

  @override
  String get myPlantsNothingFoundHint => 'Попробуйте другое имя или вид.';

  @override
  String get myPlantsAllClearTitle => 'Всё в порядке';

  @override
  String get myPlantsAllClearHint =>
      'Сейчас в этой группе пусто — не о чем беспокоиться.';

  @override
  String get addFirstPlantHint => 'Добавьте первое растение для начала';

  @override
  String get subHeroActiveLead => 'Сад';

  @override
  String get subHeroActiveAccent => 'под присмотром';

  @override
  String get subHeroForeverLead => 'Премиум';

  @override
  String get subHeroForeverAccent => 'навсегда';

  @override
  String get subHeroEndedLead => 'Пробный период';

  @override
  String get subHeroEndedAccent => 'завершён';

  @override
  String get subMetaNoCharges => 'Без списаний';

  @override
  String get subFootAutoRenew => 'Автопродление включено · Можно отменить';

  @override
  String get subFootTrial => 'Без ограничений · AI-уход · Напоминания';

  @override
  String get subFootForever => 'Все возможности открыты';

  @override
  String get subFootFree => 'Ограниченный доступ · Без AI-ухода';

  @override
  String get subCtaDetails => 'Детали';

  @override
  String get subCtaResume => 'Возобновить';

  @override
  String subTrialUntil(String date) {
    return 'Пробный период до $date';
  }

  @override
  String subEndedOn(String date) {
    return 'Закончился $date';
  }

  @override
  String get subscriptionManageTitle => 'Подписка';

  @override
  String get subscriptionPlanLabel => 'План';

  @override
  String get subscriptionNextChargeLabel => 'Следующее списание';

  @override
  String get subscriptionAutoRenewLabel => 'Автопродление';

  @override
  String get subscriptionAutoRenewOn => 'Включено';

  @override
  String get subscriptionAutoRenewOff => 'Выключено';

  @override
  String get subscriptionManageInStore =>
      'Списаниями управляет App Store. Изменить или отменить подписку можно в Настройках → Apple ID → Подписки.';

  @override
  String get deleteAccountContinue => 'Продолжить';

  @override
  String get deleteAccountKeyword => 'УДАЛИТЬ';

  @override
  String deleteAccountTypeWord(String word) {
    return 'Введите $word для подтверждения.';
  }

  @override
  String get settingsSavedToast => 'Настройки сохранены!';

  @override
  String get quietHoursUpdatedToast => 'Тихие часы обновлены!';

  @override
  String get signedInChip => 'Вы вошли';

  @override
  String get securityLabel => 'Безопасность';

  @override
  String get emailNotificationsLabel => 'Email';

  @override
  String get changePasswordHint => 'Минимум 6 символов';

  @override
  String get quietHoursNeedsPush =>
      'Включите push, чтобы использовать тихие часы';

  @override
  String get quietHoursFrom => 'С';

  @override
  String get quietHoursTo => 'До';

  @override
  String quietHoursSummary(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Уведомления не придут $hours часов подряд',
      few: 'Уведомления не придут $hours часа подряд',
      one: 'Уведомления не придут $hours час подряд',
    );
    return '$_temp0';
  }

  @override
  String get passwordTooShortError =>
      'Новый пароль должен быть не короче 6 символов.';

  @override
  String get passwordSameAsCurrentError =>
      'Новый пароль должен отличаться от текущего.';

  @override
  String get passwordsDoNotMatchError => 'Пароли не совпадают.';

  @override
  String get passwordCurrentWrongError => 'Текущий пароль неверный.';

  @override
  String get subscriptionLoading => 'Загружаем ваш план…';

  @override
  String get editPlantTitle => 'Редактирование';

  @override
  String get newPhotoBadge => 'Новое фото';

  @override
  String get revertPhoto => 'Вернуть прежнее фото';

  @override
  String get editPlantNameHint =>
      'Так растение будет называться в саду и в напоминаниях';

  @override
  String get aiManagedNote =>
      'Вид и план ухода определяет ИИ — они обновляются после нового анализа здоровья.';

  @override
  String get noPhotoYet => 'Фото пока нет';

  @override
  String get gardenLoadError =>
      'Не удалось загрузить сад. Проверь соединение и попробуй ещё раз.';

  @override
  String get pullToRefreshHint => 'Потяни вниз, чтобы обновить';

  @override
  String get refreshingGarden => 'Собираем данные сада…';

  @override
  String get refreshFailed => 'Не удалось обновить. Проверь соединение.';

  @override
  String addPlantHeaderPhoto(String accent) {
    return 'Добавить $accent';
  }

  @override
  String get addPlantHeaderPhotoAccent => 'растение';

  @override
  String addPlantHeaderSpecies(String accent) {
    return 'Уточним $accent';
  }

  @override
  String get addPlantHeaderSpeciesAccent => 'вид';

  @override
  String addPlantHeaderConditions(String accent) {
    return 'Про $accent';
  }

  @override
  String get addPlantHeaderConditionsAccent => 'условия';

  @override
  String addPlantHeaderPlan(String accent) {
    return 'План $accent';
  }

  @override
  String get addPlantHeaderPlanAccent => 'ухода';

  @override
  String get addPlantBack => 'Назад';

  @override
  String quizQuestionOf(int step, int total) {
    return 'Вопрос $step из $total';
  }

  @override
  String get quizNext => 'Далее';

  @override
  String get quizBuildPlan => 'Составить план';

  @override
  String quizPotQuestion(String accent) {
    return 'Какого $accent горшок?';
  }

  @override
  String get quizPotQuestionAccent => 'диаметра';

  @override
  String get quizPotWhy =>
      'От объёма грунта зависит, сколько воды нужно за один полив.';

  @override
  String get quizPotHint => 'Диаметр по краю горшка, а не по растению.';

  @override
  String get unitCm => 'см';

  @override
  String volumeMl(String value) {
    return '$value мл';
  }

  @override
  String volumeLitres(String value) {
    return '$value л';
  }

  @override
  String quizPotPerWatering(String volume) {
    return '$volume за полив';
  }

  @override
  String quizMaterialQuestion(String accent) {
    return 'Из чего горшок и есть ли $accent?';
  }

  @override
  String get quizMaterialQuestionAccent => 'дренаж';

  @override
  String get quizMaterialWhy =>
      'Терракота сохнет вдвое быстрее пластика. Без отверстий растёт риск корневой гнили.';

  @override
  String get quizMatPlastic => 'Пластик';

  @override
  String get quizMatPlasticDesc => 'Держит влагу дольше';

  @override
  String get quizMatCeramic => 'Керамика';

  @override
  String get quizMatCeramicDesc => 'С глазурью, не дышит';

  @override
  String get quizMatTerracotta => 'Терракота';

  @override
  String get quizMatTerracottaDesc => 'Дышит, сохнет быстро';

  @override
  String get quizMatUnknown => 'Не знаю';

  @override
  String get quizMatUnknownDesc => 'Возьмём среднее';

  @override
  String get quizDrainageLabel => 'Отверстия для воды';

  @override
  String get quizDrainageYes => 'Есть';

  @override
  String get quizDrainageYesDesc => 'Лишняя вода уходит в поддон';

  @override
  String get quizDrainageNo => 'Нет';

  @override
  String get quizDrainageNoDesc => 'Вода застаивается у корней';

  @override
  String quizPlaceQuestion(String accent) {
    return 'Где растение $accent?';
  }

  @override
  String get quizPlaceQuestionAccent => 'стоит';

  @override
  String get quizPlaceWhy =>
      'Так мы поймём, сколько света оно реально получает — и нужно ли притенение.';

  @override
  String get quizPlaceSouth => 'Юг';

  @override
  String get quizPlaceSouthDesc => 'Подоконник, много солнца';

  @override
  String get quizPlaceEast => 'Восток / запад';

  @override
  String get quizPlaceEastDesc => 'Мягкое утреннее солнце';

  @override
  String get quizPlaceNorth => 'Север';

  @override
  String get quizPlaceNorthDesc => 'Свет есть, солнца нет';

  @override
  String get quizPlaceRoom => 'В глубине комнаты';

  @override
  String get quizPlaceRoomDesc => 'Далеко от окна';

  @override
  String get quizPlaceBalcony => 'Балкон';

  @override
  String get quizPlaceBalconyDesc => 'Улица, сезонно';

  @override
  String get quizPlaceBath => 'Ванная';

  @override
  String get quizPlaceBathDesc => 'Влажно, мало света';

  @override
  String get quizHeatLabel => 'Рядом батарея или кондиционер';

  @override
  String get quizHeatNo => 'Нет';

  @override
  String get quizHeatNoDesc => 'Обычный воздух в комнате';

  @override
  String get quizHeatYes => 'Да';

  @override
  String get quizHeatYesDesc => 'Пересушивает грунт и воздух';

  @override
  String quizWaterQuestion(String accent) {
    return 'Когда $accent поливал?';
  }

  @override
  String get quizWaterQuestionAccent => 'последний раз';

  @override
  String get quizWaterWhy =>
      'От этого зависит дата первого полива — иначе задача поставится вслепую.';

  @override
  String get quizWaterToday => 'Сегодня';

  @override
  String get quizWaterTodayDesc => 'Грунт ещё влажный';

  @override
  String get quizWaterFewDays => '2–3 дня назад';

  @override
  String get quizWaterFewDaysDesc => 'Верхний слой подсох';

  @override
  String get quizWaterWeek => 'Около недели';

  @override
  String get quizWaterWeekDesc => 'Скорее всего пора поливать';

  @override
  String get quizWaterUnknown => 'Не знаю';

  @override
  String get quizWaterUnknownDesc => 'Проверим по фото и почве';

  @override
  String get addPlantPlanTuned => 'План собран по твоим ответам';

  @override
  String get addPlantCheckToday => 'проверим сегодня';

  @override
  String get placeLightSouth => '6–8 ч';

  @override
  String get placeLightEast => '4–6 ч';

  @override
  String get placeLightNorth => '2–3 ч';

  @override
  String get placeLightRoom => 'Мало света';

  @override
  String get placeLightBalcony => '6–9 ч';

  @override
  String get placeLightBath => '2–3 ч';

  @override
  String get soilModerate => 'Умеренно влажная';

  @override
  String get addPlantAddLight => 'Добавить света';

  @override
  String get addPlantAddLightDetail => 'Ближе к окну или фитолампа на 4–6 ч';

  @override
  String get addPlantAddDrainage => 'Сделать дренаж';

  @override
  String get addPlantAddDrainageDetail =>
      'Без отверстий вода застаивается у корней';

  @override
  String get addPlantMoveFromHeat => 'Отодвинуть от тепла';

  @override
  String get addPlantMoveFromHeatDetail => 'Батарея пересушивает грунт';

  @override
  String get lockedLabelTrial => 'Добавление на паузе';

  @override
  String get lockedLabelLimit => 'Лимит бесплатного плана';

  @override
  String get lockedLabelCancelled => 'Подписка отменена';

  @override
  String get lockedPillTrial => 'Пробный период завершён';

  @override
  String lockedPillLimit(int count, int limit) {
    return 'Бесплатный план · $count из $limit';
  }

  @override
  String get lockedPillCancelled => 'Доступ закончился';

  @override
  String lockedLeadTrial(String accent) {
    return 'Новые растения $accent';
  }

  @override
  String get lockedLeadTrialAccent => 'ждут подписки';

  @override
  String lockedLeadLimit(String accent) {
    return 'В бесплатном плане $accent';
  }

  @override
  String lockedLeadLimitAccent(int limit) {
    return '$limit растений';
  }

  @override
  String lockedLeadCancelled(String accent) {
    return 'Подписка $accent';
  }

  @override
  String get lockedLeadCancelledAccent => 'не активна';

  @override
  String lockedSubTrial(String date) {
    return 'Пробный период закончился $date';
  }

  @override
  String get lockedSubLimit =>
      'Подписка снимает лимит — растений может быть сколько угодно.';

  @override
  String lockedSubCancelled(String date) {
    return 'Премиум был активен до $date';
  }

  @override
  String get lockedKeepTitle => 'Что остаётся';

  @override
  String get lockedUnlockTitle => 'Что вернёт подписка';

  @override
  String lockedKeepPlants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count растений под присмотром',
      many: '$count растений под присмотром',
      few: '$count растения под присмотром',
      one: '$count растение под присмотром',
    );
    return '$_temp0';
  }

  @override
  String get lockedKeepPlantsDesc =>
      'Остаются в саду вместе с историей проверок';

  @override
  String get lockedKeepReminders => 'Напоминания о поливе';

  @override
  String get lockedKeepRemindersDesc => 'Продолжают приходить как раньше';

  @override
  String get lockedUnlockNewPlants => 'Новые растения';

  @override
  String get lockedUnlockNewPlantsDesc =>
      'Определение вида по фото и персональный план ухода';

  @override
  String get lockedUnlockHealth => 'Проверка здоровья';

  @override
  String get lockedUnlockHealthDesc =>
      'Анализ по фото, балл состояния и рекомендации';

  @override
  String get lockedUnlockChat => 'AI-ассистент';

  @override
  String get lockedUnlockChatDesc =>
      'Ответы по каждому растению с учётом его условий';

  @override
  String get lockedPlanYear => 'Год';

  @override
  String get lockedPlanMonth => 'Месяц';

  @override
  String get lockedPlanYearNote => '\$21,99 в год · \$1,83 в месяц';

  @override
  String get lockedPlanMonthNote => '\$1,99 в месяц · отмена в любой момент';

  @override
  String get lockedPlanBadge => 'Выгодно';

  @override
  String get lockedFinePrint =>
      'Подписка продлевается автоматически. Отменить можно в любой момент в настройках магазина.';

  @override
  String lockedCtaResume(String plan) {
    return 'Возобновить · $plan';
  }

  @override
  String lockedCtaUpgrade(String plan) {
    return 'Улучшить · $plan';
  }

  @override
  String get lockedRestore => 'Восстановить покупки';

  @override
  String get lockedRestoreDone => 'Покупки восстановлены';

  @override
  String get lockedRestoreNothing => 'На этом аккаунте нечего восстанавливать';

  @override
  String get billingIssueTitle => 'Не прошёл платёж';

  @override
  String get billingIssueBody =>
      'Проверьте способ оплаты — доступ работает, пока магазин повторяет попытки.';

  @override
  String get duplicateSubscriptionTitle => 'Найдены две подписки';

  @override
  String get duplicateSubscriptionBody =>
      'Вы платите одновременно в App Store и на сайте. Одну из подписок стоит отменить.';

  @override
  String get gateBarTitleTrial => 'Пробный период завершён';

  @override
  String get gateBarTitleExpired => 'Подписка не активна';

  @override
  String get gateBarBody => 'Полив работает, анализ и ассистент — по подписке';

  @override
  String get gateBarAction => 'Возобновить';

  @override
  String get gateStaleScore => 'Балл не обновляется — нужна проверка здоровья';

  @override
  String gateSheetHealth(String accent) {
    return 'Проверка здоровья $accent';
  }

  @override
  String gateSheetChat(String accent) {
    return 'AI-ассистент $accent';
  }

  @override
  String get gateSheetAccent => 'по подписке';

  @override
  String get gateSheetBody =>
      'Пробный период завершён. Растение и его уход остаются с тобой — вернётся только то, что считает AI.';

  @override
  String get gateSheetKeepWatering => 'Полив и напоминания работают';

  @override
  String get gateSheetKeepHistory =>
      'История проверок и карточки ухода открываются';

  @override
  String get gateSheetCta => 'Возобновить подписку';

  @override
  String get gateSheetLater => 'Позже';

  @override
  String get limitLabel => 'Все места заняты';

  @override
  String limitCountOf(int limit) {
    return 'из $limit мест';
  }

  @override
  String get limitPlanTrial => 'Пробный период';

  @override
  String get limitPlanFree => 'Бесплатный план';

  @override
  String get limitPlanPremium => 'Премиум';

  @override
  String get limitLegendUsed => 'Занято';

  @override
  String get limitLegendLocked => 'Откроется с Премиумом';

  @override
  String limitLeadTrial(String accent) {
    return 'Свободных мест $accent';
  }

  @override
  String get limitLeadTrialAccent => 'больше нет';

  @override
  String limitLeadFree(String accent) {
    return 'В бесплатном плане $accent';
  }

  @override
  String limitLeadFreeAccent(int limit) {
    return '$limit места';
  }

  @override
  String limitLeadPremium(String accent) {
    return 'Все десять мест $accent';
  }

  @override
  String get limitLeadPremiumAccent => 'заняты';

  @override
  String get limitBody => 'Освободи место или открой десять.';

  @override
  String get limitBodyPremium =>
      'Убери растение, которого больше нет, чтобы освободить место для нового.';

  @override
  String get limitPathUpgrade => 'Открыть 10 мест';

  @override
  String get limitPathUpgradeDesc =>
      'Вместе с проверкой здоровья и ассистентом';

  @override
  String get limitPathFree => 'Освободить место';

  @override
  String get limitPathFreeDesc => 'Убрать растение, которого больше нет';

  @override
  String get limitPremiumTitle => 'Премиум';

  @override
  String limitCtaUpgrade(String plan) {
    return 'Улучшить · $plan';
  }

  @override
  String get weatherDetectedByNetwork => 'Определено по сети';

  @override
  String get profileCityLabel => 'Город';

  @override
  String get profileCityHint => 'Влияет на рекомендации по уходу';

  @override
  String get unitsTemperature => 'Единицы температуры';

  @override
  String get unitsCelsius => '°C';

  @override
  String get unitsFahrenheit => '°F';

  @override
  String get unitsAutomatic => 'Автоматически';

  @override
  String weatherDegrees(String value) {
    return '$value°';
  }

  @override
  String get chatProposalApply => 'Применить';

  @override
  String get chatProposalDecline => 'Не надо';

  @override
  String get chatProposalApplied => 'Применено';

  @override
  String get chatProposalDeclined => 'Отклонено';

  @override
  String get chatProposalOutdated => 'Устарело';

  @override
  String get chatProposalPot => 'Горшок';

  @override
  String get chatProposalSpecies => 'Вид';

  @override
  String get chatProposalPause => 'Пауза напоминаний до';

  @override
  String chatProposalChange(String label, String from, String to) {
    return '$label: $from → $to';
  }

  @override
  String chatProposalSet(String label, String to) {
    return '$label: $to';
  }

  @override
  String get chatTopicWater => 'Полив';

  @override
  String get chatTopicSoil => 'Почва';

  @override
  String get chatTopicLight => 'Свет';

  @override
  String get chatTopicTemperature => 'Температура';

  @override
  String get chatTopicFertilizer => 'Удобрения';

  @override
  String get chatTopicDiagnostics => 'Диагностика';

  @override
  String get chatShowWholeConversation => 'Показать весь разговор';

  @override
  String chatTitleWithTopic(String topic) {
    return 'Ассистент · $topic';
  }

  @override
  String get plantChatQuickWaterEarly => 'Можно полить раньше?';

  @override
  String get plantChatQuickSoilSlowToDry => 'Почему земля долго сохнет?';

  @override
  String get plantChatQuickEnoughLight => 'Хватает ли ей света?';

  @override
  String get plantChatQuickLeggyGrowth => 'Почему листья вытягиваются?';

  @override
  String get plantChatQuickShouldMove => 'Стоит ли переставить?';

  @override
  String get plantChatQuickRepotWhen => 'Когда пересаживать?';

  @override
  String get plantChatQuickSoilCompacted => 'Почему земля уплотнилась?';

  @override
  String get plantChatQuickWhichSoil => 'Какой грунт лучше?';

  @override
  String get memoryTitle => 'Что ассистент знает';

  @override
  String get memoryExplainer =>
      'Записано из ваших сообщений в чате. Удалите всё неверное — это используется в каждом ответе.';

  @override
  String get memoryLoadFailed => 'Не удалось загрузить.';

  @override
  String get memorySuperseded => 'заменено';

  @override
  String get memoryForgetConfirm => 'Забыть это?';

  @override
  String get memoryForgetAction => 'Забыть';

  @override
  String get memoryKindPlacement => 'Где стоит';

  @override
  String get memoryKindContainer => 'Горшок';

  @override
  String get memoryKindWateringHabit => 'Привычки ухода';

  @override
  String get memoryKindSpecies => 'Вид';

  @override
  String get memoryKindEnvironment => 'Условия';

  @override
  String get memoryKindIntervention => 'Что делали';

  @override
  String get memoryKindSymptom => 'Симптом';

  @override
  String get memoryKindConstraint => 'Ограничение';

  @override
  String get memoryKindGoal => 'Цель';

  @override
  String get memoryKindPreference => 'Предпочтение';

  @override
  String memoryEmpty(String name) {
    return 'Пока ничего. Всё, что вы расскажете ассистенту про $name, будет здесь.';
  }

  @override
  String get chatTaskOffer => 'Поставить напоминание?';

  @override
  String chatTaskInDays(int days) {
    return 'через $days дн.';
  }

  @override
  String get chatTaskCreated => 'Напоминание создано';

  @override
  String chatCtxNextWatering(int days) {
    return 'Следующий полив через $days дн.';
  }

  @override
  String get chatCtxWaterToday => 'Полив сегодня';

  @override
  String chatCtxLastWatered(String date) {
    return 'Последний полив $date';
  }

  @override
  String chatCtxLight(String hours, String type) {
    return '$hours ч · $type';
  }

  @override
  String chatCtxTemperature(String value) {
    return 'Оптимум $value';
  }

  @override
  String chatCtxFertilizer(String value) {
    return 'Подкормка $value';
  }

  @override
  String get careDiscussWithAssistant => 'Обсудить с ассистентом';
}
