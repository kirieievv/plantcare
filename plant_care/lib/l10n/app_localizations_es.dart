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
  String get yourGardenOverview => 'Resumen de tu jardín';

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
  String get splashTagline => 'Tu compañero inteligente de plantas';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get splashDescription => 'Supervisa tus plantas, obtén consejos de cuidado personalizados\ny sigue su salud — todo en un solo lugar.';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

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
  String resendCodeInSeconds(int seconds) => 'Reenviar código en ${seconds}s';

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
  String get yourPlants => 'Tus plantas';

  @override
  String get plantCreatedSuccessfully => '¡Planta creada con éxito! 🌱';

  @override
  String get reminderEmail => 'Correo electrónico';

  @override
  String get reminderEmailSubtitle => 'Correos de recordatorio de riego';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsSubtitle => 'Alertas en la app (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) => 'Atrasado ${days}d';

  @override
  String get wateringToday => 'Riego hoy';

  @override
  String get wateringTomorrow => 'Riego mañana';

  @override
  String wateringInNDays(int days) => 'Riego en ${days}d';

  @override
  String plantWateredSuccess(Object plantName) => '¡$plantName ha sido regada! 💧';

  @override
  String errorWateringPlant(Object error) => 'Error al regar la planta: $error';

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
  String nDaysAgo(int days) => 'Hace $days días';

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Problema';

  @override
  String get assistantTyping => 'El asistente está escribiendo...';

  @override
  String chatSourceLabel(Object source) => 'Fuente: $source';

  @override
  String get chatSourceKnowledgeBase => 'Base de conocimiento';

  @override
  String get chatSourceContext => 'Contexto';

  @override
  String get chatSourceAgent => 'Agente';

  @override
  String get choosePhoto => 'Elegir foto';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String get analyzeHealth => 'Analizar salud';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get imageReadyForAnalysis => '¡Imagen subida con éxito! Lista para el análisis de salud.';

  @override
  String get healthCheckTitle => 'Revisión de salud';

  @override
  String get healthCheckHistoryTitle => 'Historial de salud';

  @override
  String healthCheckUploadHint(Object plantName) => 'Sube una foto de $plantName para el análisis de salud por IA';

  @override
  String get deletePlant => 'Eliminar planta';

  @override
  String get deletePlantConfirm => '¿Estás seguro de que quieres eliminar esta planta?';

  @override
  String get delete => 'Eliminar';

  @override
  String get iHaveWatered => 'He regado';

  @override
  String get soilMoisture => 'Humedad del suelo';

  @override
  String get lightLabel => 'Luz';

  @override
  String get perDay => 'por día';

  @override
  String get hoursLabel => 'horas';

  @override
  String get careRecommendationsTitle => 'Recomendaciones de cuidado';

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
  String plantDeletedMessage(Object plantName) => 'La planta "$plantName" ha sido eliminada';

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
  String get wateringLabel => 'Riego';
  String get nowLabel => 'Ahora';
  String get nextIn1Day => 'Siguiente en 1 día';
  String nextInNDays(int days) => 'Siguiente en $days días';
  String get wateringDone => 'Riego completado';
  String get moistureDry => 'Seco';
  String get moistureWet => 'Húmedo';
  String get moistureLevelVeryDry => 'Muy seco';
  String get moistureLevelDry => 'Seco';
  String get moistureLevelSlightlyMoist => 'Ligeramente húmedo';
  String get moistureLevelMoist => 'Húmedo';
  String get moistureLevelVeryMoist => 'Muy húmedo';
}
