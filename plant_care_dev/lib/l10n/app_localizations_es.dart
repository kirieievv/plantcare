// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Cuidado de Plantas';

  @override
  String get loadingPlantCare => 'Cargando Cuidado de Plantas...';

  @override
  String get home => 'Inicio';

  @override
  String get myPlants => 'Mis Plantas';

  @override
  String get addPlant => 'Agregar Planta';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configuración';

  @override
  String get authenticationError => 'Error de autenticación';

  @override
  String get pleaseLoginAgain => 'Inicia sesión de nuevo para continuar';

  @override
  String get goToLogin => 'Ir al inicio de sesión';

  @override
  String get yourGardenOverview => 'Resumen del jardín';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get createYourAccount => 'Crea tu cuenta';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get pleaseEnterYourName => 'Ingresa tu nombre';

  @override
  String get pleaseEnterYourEmail => 'Ingresa tu correo electrónico';

  @override
  String get pleaseEnterValidEmail => 'Ingresa un correo válido';

  @override
  String get pleaseEnterYourPassword => 'Ingresa tu contraseña';

  @override
  String get pleaseConfirmYourPassword => 'Por favor confirma tu contraseña';

  @override
  String get passwordAtLeast6 => 'La contraseña debe tener al menos 6 caracteres';

  @override
  String get rememberMe30Days => 'Recuérdame durante 30 días';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get registration => 'Registrarse';

  @override
  String get dontHaveAccountRegistration => '¿No tienes cuenta? Regístrate';

  @override
  String get alreadyHaveAccountLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get loggedIn => 'Conectado';

  @override
  String get preferences => 'Preferencias';

  @override
  String get wateringReminders => 'Recordatorios de riego';

  @override
  String get getNotifiedWhenPlantsNeedWater => 'Recibe avisos cuando tus plantas necesiten agua';

  @override
  String get quietHours => 'Horas de silencio';

  @override
  String get maxNotificationsPerDay => 'Máx. notificaciones por día';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones',
      one: '$count notificación',
    );
    return '$_temp0';
  }

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get testNotifications => 'Probar notificaciones';

  @override
  String get checkNotificationSetupAndPermissions => 'Verifica la configuración y permisos de notificaciones';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get russian => 'Ruso';

  @override
  String get ukrainian => 'Ucraniano';

  @override
  String get savePreferences => 'Guardar preferencias';

  @override
  String get account => 'Cuenta';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get updateYourAccountPassword => 'Actualiza la contraseña de tu cuenta';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutOfYourAccount => 'Cerrar sesión de tu cuenta';

  @override
  String get preferencesSavedSuccessfully => '¡Preferencias guardadas correctamente!';

  @override
  String errorSavingPreferences(Object error) {
    return 'Error al guardar preferencias: $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => '¡Horas de silencio actualizadas correctamente!';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get enterCurrentPassword => 'Ingresa tu contraseña actual';

  @override
  String get enterNewPassword => 'Ingresa una nueva contraseña';

  @override
  String get newPasswordMustBeDifferent => 'La nueva contraseña debe ser diferente';

  @override
  String get confirmYourNewPassword => 'Confirma tu nueva contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get passwordChangedSuccessfully => 'Contraseña cambiada correctamente.';

  @override
  String errorChangingPassword(Object error) {
    return 'Error al cambiar la contraseña: $error';
  }

  @override
  String get signOutConfirmTitle => 'Cerrar sesión';

  @override
  String get signOutConfirmMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get userLabel => 'Usuario';

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String get profileUpdatedSuccessfully => '¡Perfil actualizado correctamente!';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Error al actualizar el perfil: $error';
  }

  @override
  String get plantLover => 'Amante de las plantas';

  @override
  String get profileInformation => 'Información del perfil';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Cuéntanos sobre tu experiencia cuidando plantas...';

  @override
  String get location => 'Ubicación';

  @override
  String get locationHint => '¿Dónde están tus plantas?';

  @override
  String get name => 'Nombre';

  @override
  String get notSet => 'No establecido';

  @override
  String get accountInfo => 'Información de la cuenta';

  @override
  String get memberSince => 'Miembro desde';

  @override
  String get lastLogin => 'Último acceso';

  @override
  String get notAvailable => 'N/D';

  @override
  String get actions => 'Acciones';

  @override
  String get errorLabel => 'Error';

  @override
  String get noPlantsYet => '¡Aún no hay plantas!';

  @override
  String get addFirstPlantToGetStarted => 'Agrega tu primera planta para comenzar';

  @override
  String get addYourFirstPlant => 'Añadir primera planta';

  @override
  String errorPickingImage(Object error) {
    return 'Error al seleccionar la imagen: $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'No se pudo analizar la foto de la planta: $statusCode';
  }

  @override
  String get aiAnalysisCompleted => '¡Análisis de IA completado! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'Falló el análisis de IA: $error';
  }

  @override
  String apiTestError(Object error) {
    return 'Error de prueba de API: $error';
  }

  @override
  String get aiAnalysisRefreshed => '¡Análisis de IA actualizado! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'Falló la actualización del análisis de IA: $error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get uploadPlantPhoto => 'Subir foto de la planta';

  @override
  String get notSpecified => 'No especificado';

  @override
  String get onceEvery7Days => 'Una vez cada 7 días';

  @override
  String get oncePerDay => 'Una vez al día';

  @override
  String get oncePerWeek => 'Una vez por semana';

  @override
  String onceEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Una vez cada $days días',
      one: 'Todos los días',
    );
    return '$_temp0';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Una vez cada $weeks semanas',
      one: 'Todas las semanas',
    );
    return '$_temp0';
  }

  @override
  String get low => 'Bajo';

  @override
  String get mediumLow => 'Medio-bajo';

  @override
  String get medium => 'Medio';

  @override
  String get mediumHigh => 'Medio-alto';

  @override
  String get high => 'Alto';

  @override
  String get userNotAuthenticated => 'Usuario no autenticado';

  @override
  String get pleaseUploadPlantImage => 'Por favor sube una imagen de la planta';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant => 'Espera a que termine el análisis de IA antes de agregar la planta';

  @override
  String get plantLowercase => 'planta';

  @override
  String get plantAddedSuccessfully => '¡Planta agregada correctamente! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Error al agregar la planta: $error';
  }

  @override
  String get generateRandomName => 'Generar nombre aleatorio';

  @override
  String get plantName => 'Nombre de la planta';

  @override
  String get plantNameHint => 'ej.: Monstera, Snake Plant';

  @override
  String get pleaseEnterPlantName => 'Por favor ingresa un nombre para la planta';

  @override
  String get addingPlant => 'Agregando planta...';

  @override
  String get analyzingPhoto => 'Analizando foto...';

  @override
  String get plantUpdatedSuccessfully => '¡Planta actualizada correctamente! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Error al actualizar la planta: $error';
  }

  @override
  String get species => 'Especie';

  @override
  String get wateringFrequency => 'Frecuencia de riego';

  @override
  String everyNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Cada $days días',
      one: 'Cada $days día',
    );
    return '$_temp0';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Por favor selecciona la frecuencia de riego';

  @override
  String get notes => 'Notas';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get loadingImage => 'Cargando imagen...';

  @override
  String get changeImage => 'Cambiar imagen';

  @override
  String errorDeletingPlant(Object error) {
    return 'Error al eliminar la planta: $error';
  }

  @override
  String get plantNotDueForWateringYet => 'A esta planta aún no le toca riego';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'Ocurrió un error al construir PlantDetailsScreen: $error';
  }

  @override
  String get aiCare => 'AI Care';

  @override
  String get aiAgent => 'AI Agent';

  @override
  String get plantChatOpen => 'Abrir chat de la planta';

  @override
  String plantChatTitle(Object plantName) {
    return 'Chat sobre $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return '¡Hola! Soy tu asistente para $plantName. Pregúntame sobre riego, señales de salud o qué hacer ahora.';
  }

  @override
  String get plantChatInputHint => 'Pregunta sobre esta planta...';

  @override
  String get plantChatLoginAgain => 'Inicia sesión de nuevo.';

  @override
  String get plantChatRequestFailed => 'Falló la solicitud del chat';

  @override
  String get plantChatCouldNotGenerateResponse => 'No pude generar una respuesta. Inténtalo de nuevo.';

  @override
  String get plantChatConnectionError => 'Algo salió mal al contactar al asistente de plantas. Inténtalo de nuevo.';

  @override
  String get plantChatQuickWaterToday => '¿Puedo regar hoy?';

  @override
  String get plantChatQuickYellowLeaves => '¿Por qué se ponen amarillas las hojas?';

  @override
  String get plantChatQuickWhatToDoNow => '¿Qué debo hacer ahora?';

  @override
  String get plantChatImageQuotaReached => 'Límite diario de fotos alcanzado. Inténtalo mañana.';

  @override
  String get splashTagline => 'Tu compañero inteligente de plantas';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get splashDescription => 'Supervisa tus plantas, obtén consejos de cuidado personalizados\ny sigue su salud — todo en un solo lugar.';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get errorInvalidPin => 'Código incorrecto. Por favor intenta de nuevo.';

  @override
  String get errorPinExpired => 'El código ha expirado. Por favor solicita uno nuevo.';

  @override
  String get errorPinNotFound => 'Código no encontrado. Por favor solicita uno nuevo.';

  @override
  String get errorTooManyAttempts => 'Demasiados intentos. Por favor solicita un nuevo código.';

  @override
  String get errorSendFailed => 'No se pudo enviar el código. Por favor intenta de nuevo.';

  @override
  String get errorUserNotFound => 'No se encontró ninguna cuenta con este correo.';

  @override
  String get errorEmailAlreadyExists => 'Ya existe una cuenta con este correo.';

  @override
  String get errorGeneric => 'Algo salió mal. Por favor intenta de nuevo.';

  @override
  String get resetYourPassword => 'Restablecer tu contraseña';

  @override
  String get enterEmailForCode => 'Introduce el correo de tu cuenta para recibir un código de verificación.';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get enterVerificationCode => 'Introduce el código de verificación';

  @override
  String get weSentACodeTo => 'Enviamos un código de 6 dígitos a';

  @override
  String get verificationCodeSentAgain => 'Código de verificación enviado de nuevo.';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get setNewPassword => 'Establecer una nueva contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get updatePassword => 'Actualizar contraseña';

  @override
  String get passwordResetSuccess => 'Contraseña restablecida con éxito. Por favor, inicia sesión.';

  @override
  String get totalPlants => 'Plantas totales';

  @override
  String get needWater => 'Necesitan agua';

  @override
  String get healthy => 'Saludables';

  @override
  String get yourPlants => 'Mis plantas';

  @override
  String get plantCreatedSuccessfully => '¡Planta creada con éxito! 🌱';

  @override
  String get searchPlantsHint => 'Buscar por nombre o especie';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterOverdue => 'Atrasadas';

  @override
  String get noResultsTitle => 'Sin resultados';

  @override
  String get noResultsSub => 'Prueba con otra búsqueda o filtro.';

  @override
  String get edit => 'Editar';

  @override
  String get wateringRemindersBlockSub => 'Recibe avisos cuando tus plantas necesiten agua.';

  @override
  String get emailRemindersTitle => 'Recordatorios por email';

  @override
  String get emailRemindersSub => 'Recibe recordatorios de riego por correo';

  @override
  String get pushNotificationsTitle => 'Notificaciones push';

  @override
  String get pushNotificationsSub => 'Alertas instantáneas en tu dispositivo';

  @override
  String get quietHoursLabel => 'Horario silencioso';

  @override
  String get themeLabel => 'Tema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get preferencesTitle => 'Preferencias';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get changePasswordTitleRow => 'Cambiar contraseña';

  @override
  String get changePasswordSubRow => 'Actualiza la contraseña de tu cuenta';

  @override
  String get signOutSubRow => 'Cerrar sesión';

  @override
  String get aiAssistantOnline => 'Asistente de plantas IA · en línea';

  @override
  String get clearHistoryAction => 'Borrar historial';

  @override
  String get clearHistoryConfirm => '¿Borrar el historial del chat?';

  @override
  String get saving => 'Guardando…';

  @override
  String get plantPhoto => 'Foto de la planta';

  @override
  String get addPlantTitle => 'Añadir planta';

  @override
  String get addPlantSubtitle => 'Captura, identifica y guarda';

  @override
  String get snapTitle => 'Toma una foto';

  @override
  String get snapDescription => 'Una foto clara ayuda a nuestra IA a identificar\ntu planta y personalizar el cuidado';

  @override
  String get useCamera => 'Usar la cámara';

  @override
  String get uploadFromGallery => 'Subir de la galería';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get couldntIdentify => 'No pudimos identificar esta planta';

  @override
  String get tryAnotherPhoto => 'Prueba con otra foto o introduce la especie manualmente.';

  @override
  String get topMatch => 'Mejor coincidencia';

  @override
  String get useThisMatch => 'Usar esta coincidencia';

  @override
  String get manualNamePlaceholder => 'Apodo de la planta (p. ej. Iris)';

  @override
  String get savePlantBtn => 'Guardar planta';

  @override
  String get tagOverdue => 'ATRASADA';

  @override
  String get tagDueSoon => 'PRÓXIMA';

  @override
  String get tagHealthy => 'SANA';

  @override
  String get wateringScheduleTitle => 'Calendario de riego';

  @override
  String get lastWatered => 'Último riego';

  @override
  String get nextWatering => 'Próximo riego';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get waterNowAction => 'Regar ahora';

  @override
  String get rescheduleAction => 'Reprogramar';

  @override
  String get careRecommendationsTitle => 'Recomendaciones de cuidado';

  @override
  String get careSectionCultivar => 'Cultivar';

  @override
  String get careSectionGeneralDescription => 'Descripción general';

  @override
  String get careSectionSoil => 'Suelo';

  @override
  String get careSectionSoilMoisture => 'Humedad del suelo';

  @override
  String get careSectionMoistureCheck => 'Verificación de humedad';

  @override
  String get careSectionWater => 'Agua';

  @override
  String get careSectionLight => 'Luz';

  @override
  String get careSectionTemperature => 'Temperatura';

  @override
  String get careSectionFertilizer => 'Fertilizante';

  @override
  String get careSectionGrowthRate => 'Tasa de crecimiento';

  @override
  String get careSectionToxicity => 'Toxicidad';

  @override
  String get careSectionPlacement => 'Ubicación';

  @override
  String get careSectionPersonality => 'Personalidad';

  @override
  String get aboutPlantTitle => 'Sobre esta planta';

  @override
  String get askAssistantTitle => 'Pregunta al asistente';

  @override
  String get askAssistantSub => 'Recibe consejos personalizados de Iris IA';

  @override
  String get openChat => 'Abrir chat';

  @override
  String get deletePlantAction => 'Eliminar planta';

  @override
  String get reminderEmail => 'Correo electrónico';

  @override
  String get reminderEmailSubtitle => 'Correos de recordatorio de riego';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsSubtitle => 'Alertas en la app (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'Atrasado ${days}d';
  }

  @override
  String get wateringToday => 'Riego hoy';

  @override
  String get wateringTomorrow => 'Riego mañana';

  @override
  String wateringInNDays(int days) {
    return 'Riego en ${days}d';
  }

  @override
  String plantWateredSuccess(Object plantName) {
    return '¡$plantName ha sido regada! 💧';
  }

  @override
  String errorWateringPlant(Object error) {
    return 'Error al regar la planta: $error';
  }

  @override
  String get healthIssueDetected => 'Problema de salud detectado';

  @override
  String get recommendedActionsLabel => 'Acciones recomendadas:';

  @override
  String get healthAlertNote => 'Esta alerta permanecerá visible hasta que una revisión de salud posterior indique OK';

  @override
  String get addHealthCheckTooltip => 'Agregar revisión de salud';

  @override
  String get noHealthChecksYet => 'Aún no hay revisiones de salud';

  @override
  String get uploadPhotosToTrackHealth => 'Sube fotos para seguir la salud de tu planta a lo largo del tiempo';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String nDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Hace $days días',
      one: 'Hace $days día',
    );
    return '$_temp0';
  }

  @override
  String get healthStatusOk => 'Bien';

  @override
  String get healthStatusIssue => 'Problema';

  @override
  String get assistantTyping => 'El asistente está escribiendo...';

  @override
  String chatSourceLabel(Object source) {
    return 'Fuente: $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'Base de conocimiento';

  @override
  String get chatSourceContext => 'Contexto';

  @override
  String get chatSourceAgent => 'Agente';

  @override
  String get chatAttachPhoto => 'Adjuntar foto';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit fotos hoy';
  }

  @override
  String get chatPhotoQuotaExhausted => 'Límite diario de fotos alcanzado. Inténtalo mañana.';

  @override
  String get chatPhotoUploading => 'Subiendo foto...';

  @override
  String get chatPhotoUploadFailed => 'Error al subir la foto. Inténtalo de nuevo.';

  @override
  String get chatRemovePhoto => 'Quitar foto';

  @override
  String get chatCopyMessage => 'Copiar';

  @override
  String get chatClearHistory => 'Nueva conversación';

  @override
  String get chatClearHistoryConfirm => '¿Iniciar una nueva conversación? Se eliminará el historial actual.';

  @override
  String get chatClearHistorySuccess => 'Nueva conversación iniciada.';

  @override
  String get chatDateToday => 'Hoy';

  @override
  String get chatDateYesterday => 'Ayer';

  @override
  String get choosePhoto => 'Elegir foto';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String get analyzeHealth => 'Analizar salud';

  @override
  String get waterFirstLabel => 'Riega primero';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Próximo check en $days d';
  }

  @override
  String get imageReadyForAnalysis => '¡Imagen subida con éxito! Lista para el análisis de salud.';

  @override
  String get healthCheckTitle => 'Revisión de salud';

  @override
  String get healthCheckHistoryTitle => 'Historial de salud';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Sube una foto de $plantName para el análisis de salud por IA';
  }

  @override
  String get deletePlant => 'Eliminar planta';

  @override
  String get deletePlantConfirm => '¿Estás seguro de que quieres eliminar esta planta?';

  @override
  String get delete => 'Eliminar';

  @override
  String get iHaveWatered => 'He regado';

  @override
  String get soilMoisture => 'Suelo ideal';

  @override
  String get lightLabel => 'Luz';

  @override
  String get perDay => 'por día';

  @override
  String get hoursLabel => 'horas';

  @override
  String get interestingFactsTitle => 'Datos interesantes';

  @override
  String get noCareRecommendationsYet => 'Las recomendaciones de cuidado generadas por IA aún no están disponibles para esta planta.';

  @override
  String get noInterestingFactsYet => 'Los datos interesantes generados por IA aún no están disponibles para esta planta.';

  @override
  String get noDescriptionYet => 'Aún no hay descripción disponible.';

  @override
  String get swipeToSeeMore => 'Desliza para ver más';

  @override
  String get uploadPhotosForHealthHistory => 'Sube fotos para seguir la salud de tu planta';

  @override
  String plantDeletedMessage(Object plantName) {
    return 'La planta \"$plantName\" ha sido eliminada';
  }

  @override
  String get noImageAvailable => 'No hay imagen disponible';

  @override
  String get addPhotoToSeeYourPlant => 'Agrega una foto para ver tu planta aquí';

  @override
  String get isThisYourPlant => '¿Es esta tu planta?';

  @override
  String get speciesPickSubtitle => 'Encontramos estas opciones — elige la que corresponde';

  @override
  String get noneOfThese => 'Ninguna de estas';

  @override
  String get typePlantNameRetry => 'Escribe el nombre de la planta e intentaremos de nuevo';

  @override
  String get gettingCareRecommendations => 'Obteniendo recomendaciones de cuidado';

  @override
  String get imageUploadedAnalysisComplete => '¡Imagen subida con éxito! Análisis de IA completo.';

  @override
  String get aiCareRecommendationsHeader => 'Recomendaciones de cuidado de IA';

  @override
  String get aiReady => 'IA lista';

  @override
  String get checkPlantButton => 'Revisar planta';

  @override
  String get plantCareAssistantTitle => 'Asistente de cuidado de plantas';

  @override
  String get plantNeedsHelp => '¡La planta necesita ayuda!';

  @override
  String get whatToDoNow => 'Qué hacer ahora';

  @override
  String get wateringLabel => 'Riego';

  @override
  String get nowLabel => 'Ahora';

  @override
  String get nextIn1Day => 'Siguiente en 1 día';

  @override
  String nextInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Siguiente en $days días',
      one: 'Siguiente en $days día',
    );
    return '$_temp0';
  }

  @override
  String get wateringDone => 'Riego completado';

  @override
  String get moistureDry => 'Seco';

  @override
  String get moistureWet => 'Húmedo';

  @override
  String get moistureLevelVeryDry => 'Muy seco';

  @override
  String get moistureLevelDry => 'Seco';

  @override
  String get moistureLevelSlightlyMoist => 'Ligeramente húmedo';

  @override
  String get moistureLevelMoist => 'Húmedo';

  @override
  String get moistureLevelVeryMoist => 'Muy húmedo';

  @override
  String bannerWaterTitle(String name) {
    return '$name necesita agua';
  }

  @override
  String get bannerWaterSubtitle => 'Toca para regar o ver detalles';

  @override
  String get bannerTipTitle => 'Consejo del día';

  @override
  String get bannerTipSubtitle => 'Toca para más consejos de temporada';

  @override
  String get tipsOfTheDay => 'Consejos del día';

  @override
  String get tipsOfTheDaySub => 'Consejos estacionales con IA · actualizados semanalmente';

  @override
  String get tipCategoryWatering => 'Riego';

  @override
  String get tipCategoryLight => 'Luz';

  @override
  String get tipCategoryPests => 'Plagas';

  @override
  String get tipCategoryFertilizing => 'Fertilización';

  @override
  String get tipCategorySeasonal => 'Estacional';

  @override
  String get tipCategoryGeneral => 'General';

  @override
  String get noTipsYet => 'Los consejos se están generando. ¡Vuelve pronto!';

  @override
  String get waterNow => 'Regar ahora';

  @override
  String get subscriptionUpgrade => 'Mejorar';

  @override
  String get subscriptionManage => 'Gestionar';

  @override
  String get subscriptionActiveTitle => 'Premium activo';

  @override
  String get subscriptionGrandfatheredTitle => 'Acceso de por vida';

  @override
  String get subscriptionTrialTitle => 'Prueba gratuita';

  @override
  String get subscriptionExpiredTitle => 'Suscripción caducada';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Activo hasta $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'La prueba termina el $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Quedan $days días',
      one: 'Queda $days día',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionExpiredMessage => 'Tu suscripción ha caducado. Mejora para continuar.';

  @override
  String get subscriptionPlantLimitReached => 'Límite de plantas alcanzado';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Límite del plan gratuito alcanzado. Pasa a Premium — hasta $limit plantas.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired => 'Suscríbete para añadir más plantas.';

  @override
  String get subscriptionReadOnlyNotice => 'Modo de solo lectura. Suscríbete para editar tus plantas.';

  @override
  String get paywallTitle => 'Desbloquear Premium';

  @override
  String get paywallSubtitle => 'Saca el máximo partido a tu colección de plantas';

  @override
  String paywallFeature1(int limit) {
    return 'Hasta $limit plantas';
  }

  @override
  String get paywallFeature2 => 'Recordatorios de riego ilimitados';

  @override
  String get paywallFeature3 => 'Asistente IA y análisis de salud';

  @override
  String get paywallFeature4 => 'Edición completa y seguimiento del cuidado';

  @override
  String get paywallMonthly => 'Mensual';

  @override
  String get paywallAnnual => 'Anual';

  @override
  String get paywallBestValue => 'Mejor valor';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallRestore => 'Restaurar compra';

  @override
  String get paywallRestoring => 'Restaurando…';

  @override
  String get paywallRestoreSuccess => '¡Compra restaurada!';

  @override
  String get paywallRestoreNotFound => 'No se encontró ninguna compra anterior.';

  @override
  String get paywallRestoreAlreadyActive => 'Tu suscripción ya está activa.';

  @override
  String get paywallTerms => 'La suscripción se renueva automáticamente. Cancela en cualquier momento en los ajustes de la App Store.';

  @override
  String get paywallLoading => 'Cargando planes…';

  @override
  String get paywallPurchasing => 'Procesando…';

  @override
  String get paywallError => 'Algo salió mal. Por favor, inténtalo de nuevo.';

  @override
  String get paywallHeroTitle => 'Crece sin límites.';

  @override
  String get paywallHeroDescription => 'Tu asistente personal con IA — recordatorios de riego, chequeos de salud, consejos de temporada y todo lo que necesitas para que tus plantas prosperen.';

  @override
  String get paywallChoosePlan => 'ELIGE TU PLAN';

  @override
  String paywallPerMonth(Object price) {
    return 'Solo $price / mes';
  }

  @override
  String get paywallStartPremium => 'Iniciar Premium';

  @override
  String get paywallSecured => 'Protegido por Stripe';

  @override
  String get paywallSecuredApple => 'Seguro';

  @override
  String get paywallCancelAnytime => 'Cancela cuando quieras';

  @override
  String get paywallAutoRenews => 'renovación automática';

  @override
  String get stripeSuccessTitle => '¡Suscripción activada!';

  @override
  String get stripeSuccessWaiting => 'Activando tu suscripción';

  @override
  String get stripeSuccessSubtitle => '¡Bienvenido a Botanly Premium! Ahora tienes acceso a todas las funciones.';

  @override
  String get stripeSuccessButton => 'Ir a mis plantas';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'No se pudo abrir el portal de facturación: $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get emailCopied => 'Correo copiado: support@botanly.app';

  @override
  String get labelExpires => 'Expira';

  @override
  String get labelNextRenewal => 'Próxima renovación';

  @override
  String get labelAutoRenewal => 'Renovación automática';

  @override
  String get labelRestorePurchases => 'Restaurar compras';

  @override
  String get labelPlants => 'Plantas';

  @override
  String get labelRenews => 'Renovación';

  @override
  String get testWateringEmailQueued => 'Correo de riego de prueba en cola.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'No se pudo enviar el correo de prueba: $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'No se pudieron guardar los canales de recordatorio: $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'No se pudieron actualizar las horas silenciosas: $error';
  }

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Desactivar permanentemente tu cuenta';

  @override
  String get deleteAccountConfirmBody => 'Tu cuenta será desactivada permanentemente y perderás el acceso a la aplicación. Tus datos de plantas se conservarán.\n\nEsta acción no se puede deshacer.';

  @override
  String get deleteAccountAreYouSure => '¿Estás seguro?';

  @override
  String get deleteAccountTypeConfirm => 'Escribe DELETE para confirmar:';

  @override
  String get deleteAccountConfirmBtn => 'Confirmar eliminación';

  @override
  String errorDeletingAccount(Object error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get subPillPremium => 'Premium';

  @override
  String get subPillEarlyMember => 'Miembro temprano';

  @override
  String get subPillFreePlan => 'Plan gratuito';

  @override
  String get subPillFreeTrial => 'Prueba gratuita';

  @override
  String get subMetaActivePlan => 'PLAN ACTIVO';

  @override
  String get subMetaForeverPremium => 'PREMIUM ETERNO';

  @override
  String get subMetaTrialEnded => 'PRUEBA FINALIZADA';

  @override
  String subMetaNDayPreview(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'VISTA PREVIA $n DÍAS',
      one: 'VISTA PREVIA $n DÍA',
    );
    return '$_temp0';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Se renueva en $days días · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Termina en $days días · $date';
  }

  @override
  String get subActiveSubscription => 'Suscripción activa';

  @override
  String get subGrantedEarlyMember => 'Otorgado como miembro temprano de Botanly';

  @override
  String get subDaysLeft => 'días restantes';

  @override
  String get subUntilPreviewEnds => 'hasta que termine\nla vista previa';

  @override
  String get subTrialEnded => 'prueba\nfinalizada';

  @override
  String get subAutoRenewOn => 'Renovación automática activada  ·  Cancela cuando quieras';

  @override
  String get subAutoRenewOff => 'Renovación automática desactivada  ·  Acceso hasta vencimiento';

  @override
  String get subDetails => 'Detalles';

  @override
  String get subReactivate => 'Reactivar';

  @override
  String get subNoChargesEver => 'Sin cargos, nunca  ·  Todos los beneficios desbloqueados';

  @override
  String get subLimitedAccess => 'Acceso limitado  ·  Sin cuidado IA';

  @override
  String get subUnlimitedAccess => 'Ilimitado  ·  Cuidado IA  ·  Recordatorios';

  @override
  String get subHeroYourePrefix => 'Estás ';

  @override
  String get subHeroGrowingWord => 'creciendo';

  @override
  String get subHeroForeverWord => 'Para siempre';

  @override
  String get subHeroPremiumSuffix => ' Premium';

  @override
  String get labelEnds => 'Termina';

  @override
  String get labelPlan => 'Plan';

  @override
  String get labelPremium => 'Premium';

  @override
  String get labelGrandfathered => 'Acceso heredado';

  @override
  String get labelOn => 'Activado';

  @override
  String get labelOff => 'Desactivado';

  @override
  String get yourPlan => 'Tu plan';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get manageBillingWeb => 'Gestionar facturación';

  @override
  String get manageInAppStore => 'Gestionar en App Store';

  @override
  String get manageBillingSubtitleWeb => 'Cancela, actualiza tu tarjeta o consulta facturas\na través del portal de facturación de Stripe.';

  @override
  String get manageBillingSubtitleAppStore => 'Para desactivar la renovación automática o cancelar,\nve a tus suscripciones en App Store.';

  @override
  String get tipGoodLight => 'buena luz';

  @override
  String get tipShowLeaves => 'mostrar las hojas';

  @override
  String get tipSinglePlant => 'planta sola';

  @override
  String get snapYourSprout => 'Fotografía tu brote';

  @override
  String get identifyingPlantPrefix => 'Identificando tu ';

  @override
  String get identifyingPlantWord => 'planta';

  @override
  String get identifyingSubtitle => 'Mirando hojas, tallos y vecinos cercanos';

  @override
  String get specificIssues => 'Problemas específicos';

  @override
  String get healthCheckPhotoHint => 'Añade hasta 3 fotos — más ángulos significa un análisis más preciso. Solo la primera foto es obligatoria.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Planta completa';

  @override
  String get healthCheckSlot1Desc => 'Fotografía toda la planta incluyendo la maceta — para que se vea la tierra y la maceta completa.';

  @override
  String get healthCheckSlot1Tag => 'Obligatorio';

  @override
  String get healthCheckSlot2Title => 'Primer plano';

  @override
  String get healthCheckSlot2Desc => 'Acerca la cámara, sin la maceta — para ver claramente las hojas y su textura.';

  @override
  String get healthCheckSlot2Tag => 'Opcional';

  @override
  String get healthCheckSlot3Title => 'Zona problemática';

  @override
  String get healthCheckSlot3Desc => '¿Quieres mostrar algo específico? Fotografía una mancha, plaga o hoja dañada.';

  @override
  String get healthCheckSlot3Tag => 'Opcional';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return 'Analizar $count foto(s)';
  }

  @override
  String get healthCheckError => 'El análisis falló. Por favor, inténtalo de nuevo.';

  @override
  String get healthCheckDefaultPraise => '🌱 ¡Tu planta está bien!';

  @override
  String get healthCheckDefaultFooter => 'Sigue cuidando tu planta según las recomendaciones y registra cuando riegues.';

  @override
  String get addPlantWholePlantTitle => 'Planta entera';

  @override
  String get addPlantWholePlantDesc => 'con la maceta y la tierra';

  @override
  String get addPlantWholePlantTag => 'Obligatorio';

  @override
  String get addPlantCloseUpTitle => 'Primer plano';

  @override
  String get addPlantCloseUpDesc => 'hojas en detalle';

  @override
  String get addPlantCloseUpTag => 'Opcional';

  @override
  String get addPlantDualHint => 'Dos ángulos ayudan a nuestra IA a identificar tu planta con mayor precisión.';

  @override
  String get addPlantAnalyzeButton => 'Analizar planta';

  @override
  String get addPlantStepPhotosReceived => 'Fotos recibidas';

  @override
  String get addPlantStepIdentifying => 'Identificando la especie';

  @override
  String get addPlantStepCarePlan => 'Creando un plan de cuidado';

  @override
  String get addPlantAnalyzingTitle => 'Analizando tu planta';

  @override
  String get addPlantAnalyzingSubtitle => 'Esto suele tardar unos segundos…';

  @override
  String get addPlantAnalysisComplete => 'Análisis completo';

  @override
  String get addPlantSeePlantProfile => 'Ver perfil de la planta';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboarding1Eyebrow => 'Bienvenido';

  @override
  String get onboarding1Title => 'Conoce ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body => 'Tu compañero de IA para plantas felices y saludables — siempre en tu bolsillo.';

  @override
  String get onboarding2Eyebrow => 'Identificar';

  @override
  String get onboarding2Title => 'Nombra ';

  @override
  String get onboarding2TitleItalic => 'cualquier planta';

  @override
  String get onboarding2Body => 'Apunta la cámara y deja que la IA la identifique en segundos — especie, nombre y todo.';

  @override
  String get onboarding3Eyebrow => 'Cuidado';

  @override
  String get onboarding3Title => 'Cuidado ';

  @override
  String get onboarding3TitleItalic => 'sin esfuerzo';

  @override
  String get onboarding3Body => 'Recordatorios de riego, luz y tierra — perfectamente ajustados a cada planta.';

  @override
  String get onboarding4Eyebrow => 'Chequeo';

  @override
  String get onboarding4Title => 'Detecta problemas ';

  @override
  String get onboarding4TitleItalic => 'pronto';

  @override
  String get onboarding4Body => 'Toma una foto y obtén un chequeo de salud instantáneo con un plan claro para solucionarlo.';

  @override
  String get onboarding5Eyebrow => 'Listo';

  @override
  String get onboarding5Title => 'Crezcamos ';

  @override
  String get onboarding5TitleItalic => 'juntos';

  @override
  String get onboarding5Body => 'Construye tu colección de plantas y no te pierdas nada. Tu era más verde empieza ahora.';

  @override
  String get tabCare => 'Cuidado';

  @override
  String get tabAbout => 'Info';

  @override
  String get tabHistory => 'Historial';

  @override
  String nDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get cycleJustStarted => 'El ciclo acaba de empezar';

  @override
  String cyclePercentComplete(int percent) {
    return 'Ciclo $percent% completado';
  }

  @override
  String get wateringAmount => 'Cantidad';

  @override
  String get noDataAvailable => 'Aún no hay datos';

  @override
  String get healthCheckHistoryEmptyHint => 'Sube una foto cada par de semanas y crearemos una cronología de salud';

  @override
  String milliliters(int count) {
    return '$count ml';
  }

  @override
  String get millilitersShort => 'ML';

  @override
  String nHours(String hours) {
    return '$hours h';
  }

  @override
  String get lightDaily => 'Al día';

  @override
  String get lightType => 'Tipo';

  @override
  String get lightTypeDirect => 'Directa';

  @override
  String get lightTypePartialSun => 'Sol parcial';

  @override
  String get lightTypeBrightIndirect => 'Brillante indirecta';

  @override
  String get lightTypeLowLight => 'Poca luz';

  @override
  String get everyDay => 'Cada día';

  @override
  String get healthCheckSeverity => 'Gravedad';

  @override
  String get healthCheckFollowUp => 'Seguimiento';

  @override
  String get severityLow => 'Baja';

  @override
  String get severityMedium => 'Media';

  @override
  String get severityHigh => 'Alta';

  @override
  String get careKvFrequency => 'Frecuencia';

  @override
  String get careKvSeason => 'Temporada';

  @override
  String get careKvOptimal => 'Óptima';

  @override
  String get careKvMinimum => 'Mínima';

  @override
  String get careKvDose => 'Dosis';

  @override
  String get healthAnalyzeCta => 'Analizar salud';

  @override
  String get healthNeedsAttention => 'Requiere atención';

  @override
  String get healthStatusHealthy => 'Planta saludable';

  @override
  String get healthWhatToDo => 'Qué hacer';

  @override
  String get healthClose => 'Cerrar';

  @override
  String get healthNotSavedYet => 'Aún no está en el historial';

  @override
  String get healthAskAssistant => 'Preguntar a la IA';

  @override
  String get healthAddedToPlan => 'Añadido al plan';

  @override
  String get healthLockedNeedsWatering => 'Registra un riego para volver a comprobar';

  @override
  String get healthLockedLimitReached => 'Comprobaciones agotadas para este ciclo';

  @override
  String get healthAdviceSub => 'Ver qué hacer';

  @override
  String get healthAnalyzingTitle => 'Analizando…';

  @override
  String get healthStepRecognize => 'Reconociendo la planta';

  @override
  String get healthStepCompare => 'Comparando con revisiones anteriores';

  @override
  String get healthStepAdvice => 'Preparando recomendaciones';

  @override
  String healthStepPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos recibidas',
      one: '1 foto recibida',
    );
    return '$_temp0';
  }

  @override
  String healthAdviceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recomendaciones tras la revisión',
      one: '1 recomendación tras la revisión',
    );
    return '$_temp0';
  }

  @override
  String get healthHistoryLoadFailed => 'No se pudo cargar el historial';

  @override
  String get healthUpToThreePhotos => 'Hasta 3 fotos';

  @override
  String get healthResultTitle => 'Resultado';

  @override
  String get taskAllDone => 'Todo hecho: la planta está bien';

  @override
  String get taskBadgeScheduled => 'Programado';

  @override
  String get taskBadgeAnalysis => 'Tras el análisis';

  @override
  String taskBadgeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días de retraso',
      one: '1 día de retraso',
    );
    return '$_temp0';
  }

  @override
  String get taskDone => 'Hecho';

  @override
  String get taskDoneAlready => 'Completado';

  @override
  String get taskLater => 'Más tarde';

  @override
  String get taskAskAssistant => 'Preguntar al asistente';

  @override
  String taskAskQuestion(String title) {
    return '¿Qué debo hacer con la tarea «$title»?';
  }

  @override
  String get homeGardenTitleLead => 'Tu';

  @override
  String get homeGardenTitleAccent => 'jardín';

  @override
  String get gardenHealthLabel => 'Salud del jardín';

  @override
  String get gardenAllGood => 'Todas las plantas están bien';

  @override
  String gardenOneWeak(String name) {
    return '$name baja la media del jardín';
  }

  @override
  String gardenManyWeak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas necesitan tu cuidado',
      one: '1 planta necesita tu cuidado',
    );
    return '$_temp0';
  }

  @override
  String get homeOrbitHint => 'Toca una planta para abrirla';

  @override
  String get homeAllTasksLink => 'Todas las tareas';

  @override
  String get deckAllClearTitle => 'El jardín está bien';

  @override
  String taskOverdueShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get taskPostponed => 'Aplazada';

  @override
  String get allTasksTitle => 'Todas las tareas';

  @override
  String allTasksSubtitle(int today, int later) {
    return '$today hoy · $later después';
  }

  @override
  String get allTasksToday => 'Hoy';

  @override
  String get allTasksLater => 'Después';

  @override
  String get allTasksRuleNote => 'No aparecerán tareas nuevas hasta que resuelvas las de hoy.';

  @override
  String get allTasksNothingToday => 'Nada pendiente para hoy';

  @override
  String get whenTomorrow => 'Mañana';

  @override
  String get whenInAWeek => 'En una semana';

  @override
  String whenInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'En $days días',
      one: 'En 1 día',
    );
    return '$_temp0';
  }

  @override
  String careAskAbout(String title) {
    return 'Preguntar al asistente sobre $title';
  }

  @override
  String careAskQuestion(String title) {
    return 'Cuéntame más sobre «$title» para mi planta';
  }

  @override
  String get healthAskQuestionIssue => '¿Qué hago primero según el análisis?';

  @override
  String get healthAskQuestionOk => 'El análisis dice que la planta está sana, ¿qué puedo mejorar?';

  @override
  String get glassesOne => '1 vaso';

  @override
  String glassesAmount(String value) {
    return '$value vasos';
  }

  @override
  String addPlantStepOf(int step, int total) {
    return 'Paso $step de $total';
  }

  @override
  String get addPlantTitleLead => 'Añadir una';

  @override
  String get addPlantTitleAccent => 'planta';

  @override
  String get addPlantNameHint => '¿Cómo la vas a llamar? Monty, Ficus Jr., Monstera. El dado elige por ti.';

  @override
  String get addPlantPhotosTitle => 'Fotos';

  @override
  String get addPlantWholePlant => 'Planta entera';

  @override
  String get addPlantWholePlantHint => 'con la maceta y la tierra';

  @override
  String get addPlantRequired => 'Necesaria';

  @override
  String get addPlantTwoAnglesHint => 'Dos ángulos identifican la especie con más precisión: la segunda foto es opcional, pero ayuda.';

  @override
  String get addPlantTipLight => 'buena luz';

  @override
  String get addPlantTipLeaves => 'hojas visibles';

  @override
  String get addPlantTipSingle => 'una planta';

  @override
  String get addPlantIdentifyCta => 'Identificar la especie';

  @override
  String get addPlantRandomNames => 'Monty|Brotecito|Ficus Jr.|Helechito|Albahaca Magna|Hojitas|Solete|Pip';

  @override
  String get addPlantIsThisYourPlant => '¿Es esta tu planta?';

  @override
  String get addPlantPickSpeciesHint => 'Elige la opción más parecida: de ahí sale el plan de cuidados.';

  @override
  String get addPlantNoneMatch => 'Ninguna coincide, la escribo yo';

  @override
  String get addPlantManualHint => 'Escribe el nombre de la especie y buscamos de nuevo.';

  @override
  String get addPlantManualPlaceholder => 'Por ejemplo, Monstera deliciosa';

  @override
  String get addPlantBuildPlanCta => 'Crear el plan de cuidados';

  @override
  String addPlantStartingScore(int score) {
    return 'Puntuación inicial $score';
  }

  @override
  String get addPlantPlanWatering => 'Riego';

  @override
  String get addPlantPlanLight => 'Luz';

  @override
  String get addPlantPlanSoil => 'Tierra';

  @override
  String get addPlantSoilSlightlyMoist => 'Ligeramente húmeda';

  @override
  String addPlantEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Cada $days días',
      one: 'Cada día',
    );
    return '$_temp0';
  }

  @override
  String get addPlantCarePlan => 'Plan de cuidados';

  @override
  String addPlantNTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tareas',
      one: '1 tarea',
    );
    return '$_temp0';
  }

  @override
  String get addPlantFirstWatering => 'Primer riego';

  @override
  String get addPlantToday => 'hoy';

  @override
  String get addPlantWaterToday => 'hoy';

  @override
  String get addPlantFertilising => 'Abono';

  @override
  String get addPlantFertilisingDetail => 'En dos semanas · media dosis';

  @override
  String get addPlantHealthCheck => 'Chequeo de salud';

  @override
  String get addPlantHealthCheckDetail => 'En un mes · 1–3 fotos';

  @override
  String get addPlantAddToGarden => 'Añadir al jardín';

  @override
  String get addPlantNoSpeciesFound => 'No se ha reconocido la planta. Prueba con otra foto.';

  @override
  String get addPlantNoPlan => 'No se ha podido crear el plan de cuidados. Inténtalo de nuevo.';

  @override
  String get addPlantLoaderPhotos => 'Fotos recibidas';

  @override
  String get addPlantLoaderIdentify => 'Determinando la especie';

  @override
  String get addPlantLoaderPlan => 'Creando el plan de cuidados';

  @override
  String get myPlantsTitleLead => 'Mis';

  @override
  String get myPlantsTitleAccent => 'plantas';

  @override
  String myPlantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas',
      one: '1 planta',
    );
    return '$_temp0';
  }

  @override
  String get myPlantsEmptyLabel => 'Aún no hay nada';

  @override
  String get filterTomorrow => 'Mañana';

  @override
  String get filterNeedsCare => 'Necesita cuidados';

  @override
  String get myPlantsNothingFound => 'No se ha encontrado nada';

  @override
  String get myPlantsNothingFoundHint => 'Prueba con otro nombre u otra especie.';

  @override
  String get myPlantsAllClearTitle => 'Todo en orden';

  @override
  String get myPlantsAllClearHint => 'Ahora mismo no hay nada en este grupo: no hay de qué preocuparse.';

  @override
  String get addFirstPlantHint => 'Add your first plant to get started';

  @override
  String get subHeroActiveLead => 'Tu jardín está';

  @override
  String get subHeroActiveAccent => 'bien cuidado';

  @override
  String get subHeroForeverLead => 'Premium';

  @override
  String get subHeroForeverAccent => 'para siempre';

  @override
  String get subHeroEndedLead => 'El periodo de prueba ha';

  @override
  String get subHeroEndedAccent => 'terminado';

  @override
  String get subMetaNoCharges => 'Sin cargos';

  @override
  String get subFootAutoRenew => 'Renovación automática activada · Cancela cuando quieras';

  @override
  String get subFootTrial => 'Sin límites · Cuidado con IA · Recordatorios';

  @override
  String get subFootForever => 'Todo desbloqueado';

  @override
  String get subFootFree => 'Acceso limitado · Sin cuidado con IA';

  @override
  String get subCtaDetails => 'Detalles';

  @override
  String get subCtaResume => 'Reanudar';

  @override
  String subTrialUntil(String date) {
    return 'Prueba hasta el $date';
  }

  @override
  String subEndedOn(String date) {
    return 'Terminó el $date';
  }

  @override
  String get subscriptionManageTitle => 'Suscripción';

  @override
  String get subscriptionPlanLabel => 'Plan';

  @override
  String get subscriptionNextChargeLabel => 'Próximo cargo';

  @override
  String get subscriptionAutoRenewLabel => 'Renovación automática';

  @override
  String get subscriptionAutoRenewOn => 'Activada';

  @override
  String get subscriptionAutoRenewOff => 'Desactivada';

  @override
  String get subscriptionManageInStore => 'La facturación la gestiona la App Store. Ve a Ajustes → ID de Apple → Suscripciones para cambiarla o cancelarla.';

  @override
  String get deleteAccountContinue => 'Continuar';

  @override
  String get deleteAccountKeyword => 'ELIMINAR';

  @override
  String deleteAccountTypeWord(String word) {
    return 'Escribe $word para confirmar.';
  }

  @override
  String get settingsSavedToast => '¡Ajustes guardados!';

  @override
  String get quietHoursUpdatedToast => '¡Horas de silencio actualizadas!';

  @override
  String get signedInChip => 'Sesión iniciada';

  @override
  String get securityLabel => 'Seguridad';

  @override
  String get emailNotificationsLabel => 'Email';

  @override
  String get changePasswordHint => 'Al menos 6 caracteres';

  @override
  String get quietHoursNeedsPush => 'Activa las push para usar las horas de silencio';

  @override
  String get quietHoursFrom => 'Desde';

  @override
  String get quietHoursTo => 'Hasta';

  @override
  String quietHoursSummary(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Sin notificaciones durante $hours horas seguidas',
      one: 'Sin notificaciones durante 1 hora seguida',
    );
    return '$_temp0';
  }

  @override
  String get passwordTooShortError => 'La nueva contraseña debe tener al menos 6 caracteres.';

  @override
  String get passwordSameAsCurrentError => 'La nueva contraseña debe ser distinta de la actual.';

  @override
  String get passwordsDoNotMatchError => 'Las contraseñas no coinciden.';

  @override
  String get passwordCurrentWrongError => 'La contraseña actual es incorrecta.';

  @override
  String get subscriptionLoading => 'Cargando tu plan…';

  @override
  String get editPlantTitle => 'Edición';

  @override
  String get newPhotoBadge => 'Nueva foto';

  @override
  String get revertPhoto => 'Restaurar la foto anterior';

  @override
  String get editPlantNameHint => 'Así aparecerá la planta en el jardín y en los recordatorios';

  @override
  String get aiManagedNote => 'La especie y el plan de cuidados los define la IA: se actualizan tras un nuevo análisis de salud.';

  @override
  String get noPhotoYet => 'Aún no hay foto';

  @override
  String get gardenLoadError => 'No se pudo cargar el jardín. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get pullToRefreshHint => 'Desliza hacia abajo para actualizar';

  @override
  String get refreshingGarden => 'Recopilando datos del jardín…';

  @override
  String get refreshFailed => 'No se pudo actualizar. Comprueba la conexión.';

  @override
  String addPlantHeaderPhoto(String accent) {
    return 'Añadir una $accent';
  }

  @override
  String get addPlantHeaderPhotoAccent => 'planta';

  @override
  String addPlantHeaderSpecies(String accent) {
    return 'Confirmar la $accent';
  }

  @override
  String get addPlantHeaderSpeciesAccent => 'especie';

  @override
  String addPlantHeaderConditions(String accent) {
    return 'Sobre las $accent';
  }

  @override
  String get addPlantHeaderConditionsAccent => 'condiciones';

  @override
  String addPlantHeaderPlan(String accent) {
    return '$accent de cuidados';
  }

  @override
  String get addPlantHeaderPlanAccent => 'Plan';

  @override
  String get addPlantBack => 'Atrás';

  @override
  String quizQuestionOf(int step, int total) {
    return 'Pregunta $step de $total';
  }

  @override
  String get quizNext => 'Siguiente';

  @override
  String get quizBuildPlan => 'Crear el plan';

  @override
  String quizPotQuestion(String accent) {
    return '¿Qué $accent tiene la maceta?';
  }

  @override
  String get quizPotQuestionAccent => 'diámetro';

  @override
  String get quizPotWhy => 'El volumen de sustrato decide cuánta agua necesita cada riego.';

  @override
  String get quizPotHint => 'Mide por el borde de la maceta, no la planta.';

  @override
  String get unitCm => 'cm';

  @override
  String volumeMl(String value) {
    return '$value ml';
  }

  @override
  String volumeLitres(String value) {
    return '$value l';
  }

  @override
  String quizPotPerWatering(String volume) {
    return '$volume por riego';
  }

  @override
  String quizMaterialQuestion(String accent) {
    return '¿De qué es la maceta y tiene $accent?';
  }

  @override
  String get quizMaterialQuestionAccent => 'drenaje';

  @override
  String get quizMaterialWhy => 'El barro se seca el doble de rápido que el plástico. Sin agujeros crece el riesgo de pudrición.';

  @override
  String get quizMatPlastic => 'Plástico';

  @override
  String get quizMatPlasticDesc => 'Retiene la humedad más tiempo';

  @override
  String get quizMatCeramic => 'Cerámica';

  @override
  String get quizMatCeramicDesc => 'Esmaltada, no transpira';

  @override
  String get quizMatTerracotta => 'Barro';

  @override
  String get quizMatTerracottaDesc => 'Transpira, se seca rápido';

  @override
  String get quizMatUnknown => 'No lo sé';

  @override
  String get quizMatUnknownDesc => 'Tomaremos la media';

  @override
  String get quizDrainageLabel => 'Agujeros de drenaje';

  @override
  String get quizDrainageYes => 'Sí';

  @override
  String get quizDrainageYesDesc => 'El agua sobrante cae al plato';

  @override
  String get quizDrainageNo => 'No';

  @override
  String get quizDrainageNoDesc => 'El agua se estanca en las raíces';

  @override
  String quizPlaceQuestion(String accent) {
    return '¿Dónde $accent la planta?';
  }

  @override
  String get quizPlaceQuestionAccent => 'está';

  @override
  String get quizPlaceWhy => 'Así sabremos cuánta luz recibe de verdad — y si necesita sombra.';

  @override
  String get quizPlaceSouth => 'Sur';

  @override
  String get quizPlaceSouthDesc => 'Alféizar, mucho sol';

  @override
  String get quizPlaceEast => 'Este / oeste';

  @override
  String get quizPlaceEastDesc => 'Sol suave de la mañana';

  @override
  String get quizPlaceNorth => 'Norte';

  @override
  String get quizPlaceNorthDesc => 'Hay luz, no sol';

  @override
  String get quizPlaceRoom => 'En el interior';

  @override
  String get quizPlaceRoomDesc => 'Lejos de la ventana';

  @override
  String get quizPlaceBalcony => 'Balcón';

  @override
  String get quizPlaceBalconyDesc => 'Al aire libre, por temporada';

  @override
  String get quizPlaceBath => 'Baño';

  @override
  String get quizPlaceBathDesc => 'Húmedo, poca luz';

  @override
  String get quizHeatLabel => 'Radiador o aire acondicionado cerca';

  @override
  String get quizHeatNo => 'No';

  @override
  String get quizHeatNoDesc => 'Aire normal de la habitación';

  @override
  String get quizHeatYes => 'Sí';

  @override
  String get quizHeatYesDesc => 'Reseca el sustrato y el aire';

  @override
  String quizWaterQuestion(String accent) {
    return '¿Cuándo la regaste por $accent?';
  }

  @override
  String get quizWaterQuestionAccent => 'última vez';

  @override
  String get quizWaterWhy => 'De esto depende la fecha del primer riego — si no, la tarea se fija a ciegas.';

  @override
  String get quizWaterToday => 'Hoy';

  @override
  String get quizWaterTodayDesc => 'El sustrato aún está húmedo';

  @override
  String get quizWaterFewDays => 'Hace 2–3 días';

  @override
  String get quizWaterFewDaysDesc => 'La capa superior se ha secado';

  @override
  String get quizWaterWeek => 'Hace una semana';

  @override
  String get quizWaterWeekDesc => 'Seguramente toca regar';

  @override
  String get quizWaterUnknown => 'No lo sé';

  @override
  String get quizWaterUnknownDesc => 'Lo comprobaremos con la foto y el sustrato';

  @override
  String get addPlantPlanTuned => 'Hecho con tus respuestas';

  @override
  String get addPlantCheckToday => 'lo comprobamos hoy';

  @override
  String get placeLightSouth => '6–8 h';

  @override
  String get placeLightEast => '4–6 h';

  @override
  String get placeLightNorth => '2–3 h';

  @override
  String get placeLightRoom => 'Poca luz';

  @override
  String get placeLightBalcony => '6–9 h';

  @override
  String get placeLightBath => '2–3 h';

  @override
  String get soilModerate => 'Moderadamente húmedo';

  @override
  String get addPlantAddLight => 'Añadir luz';

  @override
  String get addPlantAddLightDetail => 'Más cerca de la ventana o lámpara de cultivo 4–6 h';

  @override
  String get addPlantAddDrainage => 'Hacer drenaje';

  @override
  String get addPlantAddDrainageDetail => 'Sin agujeros el agua se estanca en las raíces';

  @override
  String get addPlantMoveFromHeat => 'Alejar del calor';

  @override
  String get addPlantMoveFromHeatDetail => 'El radiador reseca el sustrato';

  @override
  String get lockedLabelTrial => 'Añadir está en pausa';

  @override
  String get lockedLabelLimit => 'Límite del plan gratuito';

  @override
  String get lockedLabelCancelled => 'Suscripción cancelada';

  @override
  String get lockedPillTrial => 'Prueba finalizada';

  @override
  String lockedPillLimit(int count, int limit) {
    return 'Plan gratuito · $count de $limit';
  }

  @override
  String get lockedPillCancelled => 'El acceso ha terminado';

  @override
  String lockedLeadTrial(String accent) {
    return 'Las plantas nuevas $accent';
  }

  @override
  String get lockedLeadTrialAccent => 'esperan una suscripción';

  @override
  String lockedLeadLimit(String accent) {
    return 'El plan gratuito admite $accent';
  }

  @override
  String lockedLeadLimitAccent(int limit) {
    return '$limit plantas';
  }

  @override
  String lockedLeadCancelled(String accent) {
    return 'La suscripción $accent';
  }

  @override
  String get lockedLeadCancelledAccent => 'no está activa';

  @override
  String lockedSubTrial(String date) {
    return 'La prueba terminó el $date';
  }

  @override
  String get lockedSubLimit => 'La suscripción quita el límite: tantas plantas como quieras.';

  @override
  String lockedSubCancelled(String date) {
    return 'Premium estuvo activo hasta $date';
  }

  @override
  String get lockedKeepTitle => 'Lo que se queda';

  @override
  String get lockedUnlockTitle => 'Lo que devuelve la suscripción';

  @override
  String lockedKeepPlants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantas cuidadas',
      one: '1 planta cuidada',
    );
    return '$_temp0';
  }

  @override
  String get lockedKeepPlantsDesc => 'Se quedan en el jardín junto con su historial';

  @override
  String get lockedKeepReminders => 'Recordatorios de riego';

  @override
  String get lockedKeepRemindersDesc => 'Siguen llegando como antes';

  @override
  String get lockedUnlockNewPlants => 'Plantas nuevas';

  @override
  String get lockedUnlockNewPlantsDesc => 'Identificación por foto y un plan de cuidados propio';

  @override
  String get lockedUnlockHealth => 'Chequeo de salud';

  @override
  String get lockedUnlockHealthDesc => 'Análisis por foto, puntuación y recomendaciones';

  @override
  String get lockedUnlockChat => 'Asistente de IA';

  @override
  String get lockedUnlockChatDesc => 'Respuestas por planta, teniendo en cuenta sus condiciones';

  @override
  String get lockedPlanYear => 'Año';

  @override
  String get lockedPlanMonth => 'Mes';

  @override
  String get lockedPlanYearNote => '21,99 \$ al año · 1,83 \$ al mes';

  @override
  String get lockedPlanMonthNote => '1,99 \$ al mes · cancela cuando quieras';

  @override
  String get lockedPlanBadge => 'Mejor precio';

  @override
  String get lockedFinePrint => 'La suscripción se renueva automáticamente. Cancélala cuando quieras en los ajustes de la tienda.';

  @override
  String lockedCtaResume(String plan) {
    return 'Reanudar · $plan';
  }

  @override
  String lockedCtaUpgrade(String plan) {
    return 'Mejorar · $plan';
  }

  @override
  String get lockedRestore => 'Restaurar compras';

  @override
  String get lockedRestoreDone => 'Compras restauradas';

  @override
  String get lockedRestoreNothing => 'No hay nada que restaurar en esta cuenta';

  @override
  String get billingIssueTitle => 'Un pago no se completó';

  @override
  String get billingIssueBody => 'Revisa tu método de pago: el acceso sigue mientras la tienda lo reintenta.';

  @override
  String get duplicateSubscriptionTitle => 'Se encontraron dos suscripciones';

  @override
  String get duplicateSubscriptionBody => 'Estás pagando en la App Store y en la web a la vez. Cancela una de las dos.';

  @override
  String get gateBarTitleTrial => 'Prueba finalizada';

  @override
  String get gateBarTitleExpired => 'La suscripción no está activa';

  @override
  String get gateBarBody => 'El riego sigue; el análisis y el asistente requieren suscripción';

  @override
  String get gateBarAction => 'Reanudar';

  @override
  String get gateStaleScore => 'La puntuación no se actualiza: hace falta un chequeo de salud';

  @override
  String gateSheetHealth(String accent) {
    return 'Chequeo de salud $accent';
  }

  @override
  String gateSheetChat(String accent) {
    return 'El asistente de IA $accent';
  }

  @override
  String get gateSheetAccent => 'requiere suscripción';

  @override
  String get gateSheetBody => 'La prueba ha terminado. La planta y sus cuidados se quedan; solo vuelve lo que calcula la IA.';

  @override
  String get gateSheetKeepWatering => 'El riego y los recordatorios siguen funcionando';

  @override
  String get gateSheetKeepHistory => 'El historial y las fichas de cuidado siguen accesibles';

  @override
  String get gateSheetCta => 'Reanudar la suscripción';

  @override
  String get gateSheetLater => 'Más tarde';

  @override
  String get limitLabel => 'Todas las plazas ocupadas';

  @override
  String limitCountOf(int limit) {
    return 'de $limit plazas';
  }

  @override
  String get limitPlanTrial => 'Prueba';

  @override
  String get limitPlanFree => 'Plan gratuito';

  @override
  String get limitPlanPremium => 'Premium';

  @override
  String get limitLegendUsed => 'Ocupado';

  @override
  String get limitLegendLocked => 'Se abre con Premium';

  @override
  String limitLeadTrial(String accent) {
    return 'No $accent';
  }

  @override
  String get limitLeadTrialAccent => 'quedan plazas libres';

  @override
  String limitLeadFree(String accent) {
    return 'El plan gratuito tiene $accent';
  }

  @override
  String limitLeadFreeAccent(int limit) {
    return '$limit plazas';
  }

  @override
  String limitLeadPremium(String accent) {
    return 'Las diez plazas $accent';
  }

  @override
  String get limitLeadPremiumAccent => 'están ocupadas';

  @override
  String get limitBody => 'Libera una plaza o abre diez.';

  @override
  String get limitBodyPremium => 'Quita una planta que ya no tengas para hacer sitio.';

  @override
  String get limitPathUpgrade => 'Abrir 10 plazas';

  @override
  String get limitPathUpgradeDesc => 'Junto con el chequeo de salud y el asistente';

  @override
  String get limitPathFree => 'Liberar una plaza';

  @override
  String get limitPathFreeDesc => 'Quitar una planta que ya no tengas';

  @override
  String get limitPremiumTitle => 'Premium';

  @override
  String limitCtaUpgrade(String plan) {
    return 'Mejorar · $plan';
  }

  @override
  String get weatherDetectedByNetwork => 'Detectado por la red';

  @override
  String get profileCityLabel => 'Ciudad';

  @override
  String get profileCityHint => 'Influye en las recomendaciones de cuidado';

  @override
  String get unitsTemperature => 'Unidades de temperatura';

  @override
  String get unitsCelsius => '°C';

  @override
  String get unitsFahrenheit => '°F';

  @override
  String get unitsAutomatic => 'Automático';

  @override
  String weatherDegrees(String value) {
    return '$value°';
  }
}
