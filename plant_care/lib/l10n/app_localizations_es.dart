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
    return '$count notificaciones';
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
    return 'Una vez cada $days días';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    return 'Una vez cada $weeks semanas';
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
    return 'Cada $days día(s)';
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
  String get searchPlantsHint => 'Buscar plantas…';

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
    return 'Hace $days días';
  }

  @override
  String get healthStatusOk => 'OK';

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
    return 'Siguiente en $days días';
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
    return '$days días restantes';
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
    return 'VISTA PREVIA $n DÍAS';
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
}
