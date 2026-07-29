// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Soin des Plantes';

  @override
  String get loadingPlantCare => 'Chargement de Soin des Plantes...';

  @override
  String get home => 'Accueil';

  @override
  String get myPlants => 'Mes Plantes';

  @override
  String get addPlant => 'Ajouter une plante';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get authenticationError => 'Erreur d\'authentification';

  @override
  String get pleaseLoginAgain => 'Veuillez vous reconnecter pour continuer';

  @override
  String get goToLogin => 'Aller à la connexion';

  @override
  String get yourGardenOverview => 'Aperçu du jardin';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get fullName => 'Nom complet';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get pleaseEnterYourName => 'Veuillez saisir votre nom';

  @override
  String get pleaseEnterYourEmail => 'Veuillez saisir votre e-mail';

  @override
  String get pleaseEnterValidEmail => 'Veuillez saisir un e-mail valide';

  @override
  String get pleaseEnterYourPassword => 'Veuillez saisir votre mot de passe';

  @override
  String get pleaseConfirmYourPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordAtLeast6 => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get rememberMe30Days => 'Se souvenir de moi pendant 30 jours';

  @override
  String get logIn => 'Se connecter';

  @override
  String get registration => 'Inscription';

  @override
  String get dontHaveAccountRegistration => 'Vous n\'avez pas de compte ? Inscription';

  @override
  String get alreadyHaveAccountLogin => 'Vous avez déjà un compte ? Se connecter';

  @override
  String get loggedIn => 'Connecté';

  @override
  String get preferences => 'Préférences';

  @override
  String get wateringReminders => 'Rappels d\'arrosage';

  @override
  String get getNotifiedWhenPlantsNeedWater => 'Recevez une notification quand les plantes ont besoin d\'eau';

  @override
  String get quietHours => 'Heures calmes';

  @override
  String get maxNotificationsPerDay => 'Max notifications par jour';

  @override
  String notificationsCount(int count) {
    return '$count notifications';
  }

  @override
  String get theme => 'Thème';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get testNotifications => 'Tester les notifications';

  @override
  String get checkNotificationSetupAndPermissions => 'Vérifier la configuration et les autorisations des notifications';

  @override
  String get language => 'Langue';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get russian => 'Russe';

  @override
  String get ukrainian => 'Ukrainien';

  @override
  String get savePreferences => 'Enregistrer les préférences';

  @override
  String get account => 'Compte';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get updateYourAccountPassword => 'Mettez à jour le mot de passe de votre compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutOfYourAccount => 'Se déconnecter de votre compte';

  @override
  String get preferencesSavedSuccessfully => 'Préférences enregistrées avec succès !';

  @override
  String errorSavingPreferences(Object error) {
    return 'Erreur lors de l\'enregistrement des préférences : $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => 'Heures calmes mises à jour avec succès !';

  @override
  String get changePasswordTitle => 'Changer le mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get enterCurrentPassword => 'Saisissez votre mot de passe actuel';

  @override
  String get enterNewPassword => 'Saisissez un nouveau mot de passe';

  @override
  String get newPasswordMustBeDifferent => 'Le nouveau mot de passe doit être différent';

  @override
  String get confirmYourNewPassword => 'Confirmez votre nouveau mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get passwordChangedSuccessfully => 'Mot de passe modifié avec succès.';

  @override
  String errorChangingPassword(Object error) {
    return 'Erreur lors du changement de mot de passe : $error';
  }

  @override
  String get signOutConfirmTitle => 'Se déconnecter';

  @override
  String get signOutConfirmMessage => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get userLabel => 'Utilisateur';

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès !';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Erreur lors de la mise à jour du profil : $error';
  }

  @override
  String get plantLover => 'Passionné de plantes';

  @override
  String get profileInformation => 'Informations du profil';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Parlez-nous de votre parcours de soin des plantes...';

  @override
  String get location => 'Localisation';

  @override
  String get locationHint => 'Où se trouvent vos plantes ?';

  @override
  String get name => 'Nom';

  @override
  String get notSet => 'Non défini';

  @override
  String get accountInfo => 'Infos du compte';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get lastLogin => 'Dernière connexion';

  @override
  String get notAvailable => 'N/D';

  @override
  String get actions => 'Actions';

  @override
  String get errorLabel => 'Erreur';

  @override
  String get noPlantsYet => 'Pas encore de plantes !';

  @override
  String get addFirstPlantToGetStarted => 'Ajoutez votre première plante pour commencer';

  @override
  String get addYourFirstPlant => 'Ajouter ma première plante';

  @override
  String errorPickingImage(Object error) {
    return 'Erreur lors de la sélection de l\'image : $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'Échec de l\'analyse de la photo de la plante : $statusCode';
  }

  @override
  String get aiAnalysisCompleted => 'Analyse IA terminée ! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'Échec de l\'analyse IA : $error';
  }

  @override
  String apiTestError(Object error) {
    return 'Erreur de test API : $error';
  }

  @override
  String get aiAnalysisRefreshed => 'Analyse IA actualisée ! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'Échec de l\'actualisation de l\'analyse IA : $error';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String get uploadPlantPhoto => 'Téléverser une photo de plante';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get onceEvery7Days => 'Une fois tous les 7 jours';

  @override
  String get oncePerDay => 'Une fois par jour';

  @override
  String get oncePerWeek => 'Une fois par semaine';

  @override
  String onceEveryNDays(int days) {
    return 'Une fois tous les $days jours';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    return 'Une fois toutes les $weeks semaines';
  }

  @override
  String get low => 'Faible';

  @override
  String get mediumLow => 'Moyen-faible';

  @override
  String get medium => 'Moyen';

  @override
  String get mediumHigh => 'Moyen-élevé';

  @override
  String get high => 'Élevé';

  @override
  String get userNotAuthenticated => 'Utilisateur non authentifié';

  @override
  String get pleaseUploadPlantImage => 'Veuillez téléverser une image de plante';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant => 'Veuillez attendre la fin de l\'analyse IA avant d\'ajouter la plante';

  @override
  String get plantLowercase => 'plante';

  @override
  String get plantAddedSuccessfully => 'Plante ajoutée avec succès ! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Erreur lors de l\'ajout de la plante : $error';
  }

  @override
  String get generateRandomName => 'Générer un nom aléatoire';

  @override
  String get plantName => 'Nom de la plante';

  @override
  String get plantNameHint => 'ex. : Monstera, Snake Plant';

  @override
  String get pleaseEnterPlantName => 'Veuillez saisir un nom de plante';

  @override
  String get addingPlant => 'Ajout de la plante...';

  @override
  String get analyzingPhoto => 'Analyse de la photo...';

  @override
  String get plantUpdatedSuccessfully => 'Plante mise à jour avec succès ! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Erreur lors de la mise à jour de la plante : $error';
  }

  @override
  String get species => 'Espèce';

  @override
  String get wateringFrequency => 'Fréquence d\'arrosage';

  @override
  String everyNDays(int days) {
    return 'Tous les $days jour(s)';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Veuillez sélectionner la fréquence d\'arrosage';

  @override
  String get notes => 'Notes';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get loadingImage => 'Chargement de l\'image...';

  @override
  String get changeImage => 'Changer l\'image';

  @override
  String errorDeletingPlant(Object error) {
    return 'Erreur lors de la suppression de la plante : $error';
  }

  @override
  String get plantNotDueForWateringYet => 'Cette plante n\'est pas encore à arroser';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'Une erreur est survenue lors de la construction de PlantDetailsScreen : $error';
  }

  @override
  String get aiCare => 'AI Care';

  @override
  String get aiAgent => 'AI Agent';

  @override
  String get plantChatOpen => 'Ouvrir le chat de la plante';

  @override
  String plantChatTitle(Object plantName) {
    return 'Chat sur $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return 'Bonjour ! Je suis votre assistant pour $plantName. Demandez-moi tout sur l\'arrosage, les signes de santé ou les prochaines actions.';
  }

  @override
  String get plantChatInputHint => 'Posez une question sur cette plante...';

  @override
  String get plantChatLoginAgain => 'Veuillez vous reconnecter.';

  @override
  String get plantChatRequestFailed => 'La requête du chat a échoué';

  @override
  String get plantChatCouldNotGenerateResponse => 'Je n\'ai pas pu générer de réponse. Veuillez réessayer.';

  @override
  String get plantChatConnectionError => 'Un problème est survenu lors du contact avec l\'assistant plante. Veuillez réessayer.';

  @override
  String get plantChatQuickWaterToday => 'Puis-je arroser aujourd\'hui ?';

  @override
  String get plantChatQuickYellowLeaves => 'Pourquoi les feuilles jaunissent-elles ?';

  @override
  String get plantChatQuickWhatToDoNow => 'Que dois-je faire maintenant ?';

  @override
  String get plantChatImageQuotaReached => 'Limite quotidienne de photos atteinte. Réessayez demain.';

  @override
  String get splashTagline => 'Votre compagnon végétal intelligent';

  @override
  String get getStarted => 'Commencer';

  @override
  String get splashDescription => 'Surveillez vos plantes, obtenez des conseils de soin personnalisés\net suivez leur santé — tout en un seul endroit.';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get errorInvalidPin => 'Code incorrect. Veuillez réessayer.';

  @override
  String get errorPinExpired => 'Le code a expiré. Veuillez en demander un nouveau.';

  @override
  String get errorPinNotFound => 'Code introuvable. Veuillez en demander un nouveau.';

  @override
  String get errorTooManyAttempts => 'Trop de tentatives. Veuillez demander un nouveau code.';

  @override
  String get errorSendFailed => 'Impossible d\'envoyer le code. Veuillez réessayer.';

  @override
  String get errorUserNotFound => 'Aucun compte trouvé avec cet e-mail.';

  @override
  String get errorEmailAlreadyExists => 'Un compte avec cet e-mail existe déjà.';

  @override
  String get errorGeneric => 'Quelque chose s\'est mal passé. Veuillez réessayer.';

  @override
  String get resetYourPassword => 'Réinitialiser votre mot de passe';

  @override
  String get enterEmailForCode => 'Saisissez l\'e-mail de votre compte pour recevoir un code de vérification.';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get enterVerificationCode => 'Saisissez le code de vérification';

  @override
  String get weSentACodeTo => 'Nous avons envoyé un code à 6 chiffres à';

  @override
  String get verificationCodeSentAgain => 'Code de vérification renvoyé.';

  @override
  String resendCodeInSeconds(int seconds) {
    return 'Renvoyer le code dans ${seconds}s';
  }

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get setNewPassword => 'Définir un nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get updatePassword => 'Mettre à jour le mot de passe';

  @override
  String get passwordResetSuccess => 'Mot de passe réinitialisé avec succès. Veuillez vous connecter.';

  @override
  String get totalPlants => 'Total des plantes';

  @override
  String get needWater => 'Besoin d\'eau';

  @override
  String get healthy => 'En bonne santé';

  @override
  String get yourPlants => 'Mes plantes';

  @override
  String get plantCreatedSuccessfully => 'Plante créée avec succès ! 🌱';

  @override
  String get searchPlantsHint => 'Rechercher des plantes…';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterOverdue => 'En retard';

  @override
  String get noResultsTitle => 'Aucun résultat';

  @override
  String get noResultsSub => 'Essayez une autre recherche ou un autre filtre.';

  @override
  String get edit => 'Modifier';

  @override
  String get wateringRemindersBlockSub => 'Soyez averti·e quand vos plantes ont besoin d\'eau.';

  @override
  String get emailRemindersTitle => 'Rappels par e-mail';

  @override
  String get emailRemindersSub => 'Recevez les rappels d\'arrosage par e-mail';

  @override
  String get pushNotificationsTitle => 'Notifications push';

  @override
  String get pushNotificationsSub => 'Alertes instantanées sur votre appareil';

  @override
  String get quietHoursLabel => 'Heures silencieuses';

  @override
  String get themeLabel => 'Thème';

  @override
  String get languageLabel => 'Langue';

  @override
  String get preferencesTitle => 'Préférences';

  @override
  String get accountTitle => 'Compte';

  @override
  String get changePasswordTitleRow => 'Changer le mot de passe';

  @override
  String get changePasswordSubRow => 'Mettez à jour le mot de passe du compte';

  @override
  String get signOutSubRow => 'Se déconnecter du compte';

  @override
  String get aiAssistantOnline => 'Assistant IA des plantes · en ligne';

  @override
  String get clearHistoryAction => 'Effacer l\'historique';

  @override
  String get clearHistoryConfirm => 'Effacer l\'historique du chat ?';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get plantPhoto => 'Photo de la plante';

  @override
  String get addPlantTitle => 'Ajouter une plante';

  @override
  String get addPlantSubtitle => 'Photographiez, identifiez et enregistrez';

  @override
  String get snapTitle => 'Prendre une photo';

  @override
  String get snapDescription => 'Une photo nette aide notre IA à identifier\nvotre plante et personnaliser les soins';

  @override
  String get useCamera => 'Utiliser l\'appareil photo';

  @override
  String get uploadFromGallery => 'Importer depuis la galerie';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get couldntIdentify => 'Impossible d\'identifier cette plante';

  @override
  String get tryAnotherPhoto => 'Essayez une autre photo ou saisissez l\'espèce manuellement.';

  @override
  String get topMatch => 'Meilleure correspondance';

  @override
  String get useThisMatch => 'Utiliser celle-ci';

  @override
  String get manualNamePlaceholder => 'Surnom de la plante (ex. Iris)';

  @override
  String get savePlantBtn => 'Enregistrer la plante';

  @override
  String get tagOverdue => 'EN RETARD';

  @override
  String get tagDueSoon => 'BIENTÔT';

  @override
  String get tagHealthy => 'EN BONNE SANTÉ';

  @override
  String get wateringScheduleTitle => 'Calendrier d\'arrosage';

  @override
  String get lastWatered => 'Dernier arrosage';

  @override
  String get nextWatering => 'Prochain arrosage';

  @override
  String get frequency => 'Fréquence';

  @override
  String get waterNowAction => 'Arroser maintenant';

  @override
  String get rescheduleAction => 'Replanifier';

  @override
  String get careRecommendationsTitle => 'Conseils de soin';

  @override
  String get careSectionCultivar => 'Cultivar';

  @override
  String get careSectionGeneralDescription => 'Description générale';

  @override
  String get careSectionSoil => 'Sol';

  @override
  String get careSectionSoilMoisture => 'Humidité du sol';

  @override
  String get careSectionMoistureCheck => 'Vérification de l\'humidité';

  @override
  String get careSectionWater => 'Eau';

  @override
  String get careSectionLight => 'Lumière';

  @override
  String get careSectionTemperature => 'Température';

  @override
  String get careSectionFertilizer => 'Engrais';

  @override
  String get careSectionGrowthRate => 'Taux de croissance';

  @override
  String get careSectionToxicity => 'Toxicité';

  @override
  String get careSectionPlacement => 'Emplacement';

  @override
  String get careSectionPersonality => 'Personnalité';

  @override
  String get aboutPlantTitle => 'À propos de cette plante';

  @override
  String get askAssistantTitle => 'Demander à l\'assistant';

  @override
  String get askAssistantSub => 'Recevez des conseils de l\'IA Iris';

  @override
  String get openChat => 'Ouvrir le chat';

  @override
  String get deletePlantAction => 'Supprimer la plante';

  @override
  String get reminderEmail => 'E-mail';

  @override
  String get reminderEmailSubtitle => 'E-mails de rappel d\'arrosage';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get pushNotificationsSubtitle => 'Alertes dans l\'application (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'En retard ${days}j';
  }

  @override
  String get wateringToday => 'Arrosage aujourd\'hui';

  @override
  String get wateringTomorrow => 'Arrosage demain';

  @override
  String wateringInNDays(int days) {
    return 'Arrosage dans ${days}j';
  }

  @override
  String plantWateredSuccess(Object plantName) {
    return '$plantName a été arrosée ! 💧';
  }

  @override
  String errorWateringPlant(Object error) {
    return 'Erreur lors de l\'arrosage de la plante : $error';
  }

  @override
  String get healthIssueDetected => 'Problème de santé détecté';

  @override
  String get recommendedActionsLabel => 'Actions recommandées :';

  @override
  String get healthAlertNote => 'Cette alerte restera visible jusqu\'à ce qu\'un contrôle de santé ultérieur indique OK';

  @override
  String get addHealthCheckTooltip => 'Ajouter un contrôle de santé';

  @override
  String get noHealthChecksYet => 'Aucun contrôle de santé pour l\'instant';

  @override
  String get uploadPhotosToTrackHealth => 'Téléversez des photos pour suivre la santé de votre plante dans le temps';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String nDaysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Problème';

  @override
  String get assistantTyping => 'L\'assistant est en train d\'écrire...';

  @override
  String chatSourceLabel(Object source) {
    return 'Source : $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'Base de connaissances';

  @override
  String get chatSourceContext => 'Contexte';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get chatAttachPhoto => 'Joindre une photo';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit photos aujourd\'hui';
  }

  @override
  String get chatPhotoQuotaExhausted => 'Limite quotidienne de photos atteinte. Réessayez demain.';

  @override
  String get chatPhotoUploading => 'Téléchargement de la photo...';

  @override
  String get chatPhotoUploadFailed => 'Échec du téléchargement. Veuillez réessayer.';

  @override
  String get chatRemovePhoto => 'Supprimer la photo';

  @override
  String get chatCopyMessage => 'Copier';

  @override
  String get chatClearHistory => 'Nouvelle conversation';

  @override
  String get chatClearHistoryConfirm => 'Démarrer une nouvelle conversation ? L\'historique actuel sera supprimé.';

  @override
  String get chatClearHistorySuccess => 'Nouvelle conversation démarrée.';

  @override
  String get chatDateToday => 'Aujourd\'hui';

  @override
  String get chatDateYesterday => 'Hier';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Appareil photo';

  @override
  String get analyzeHealth => 'Analyser la santé';

  @override
  String get waterFirstLabel => 'Arrosez d\'abord';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Prochain check dans $days j';
  }

  @override
  String get imageReadyForAnalysis => 'Image téléversée avec succès ! Prête pour l\'analyse de santé.';

  @override
  String get healthCheckTitle => 'Contrôle de santé';

  @override
  String get healthCheckHistoryTitle => 'Historique des contrôles de santé';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Téléversez une photo de $plantName pour l\'analyse de santé par IA';
  }

  @override
  String get deletePlant => 'Supprimer la plante';

  @override
  String get deletePlantConfirm => 'Êtes-vous sûr de vouloir supprimer cette plante ?';

  @override
  String get delete => 'Supprimer';

  @override
  String get iHaveWatered => 'J\'ai arrosé';

  @override
  String get soilMoisture => 'Sol idéal';

  @override
  String get lightLabel => 'Lumière';

  @override
  String get perDay => 'par jour';

  @override
  String get hoursLabel => 'heures';

  @override
  String get interestingFactsTitle => 'Faits intéressants';

  @override
  String get noCareRecommendationsYet => 'Les conseils de soin générés par IA ne sont pas encore disponibles pour cette plante.';

  @override
  String get noInterestingFactsYet => 'Les faits intéressants générés par IA ne sont pas encore disponibles pour cette plante.';

  @override
  String get noDescriptionYet => 'Pas de description disponible pour l\'instant.';

  @override
  String get swipeToSeeMore => 'Glissez pour voir plus';

  @override
  String get uploadPhotosForHealthHistory => 'Téléversez des photos pour suivre la santé de votre plante';

  @override
  String plantDeletedMessage(Object plantName) {
    return 'La plante « $plantName » a été supprimée';
  }

  @override
  String get noImageAvailable => 'Aucune image disponible';

  @override
  String get addPhotoToSeeYourPlant => 'Ajoutez une photo pour voir votre plante ici';

  @override
  String get isThisYourPlant => 'Est-ce votre plante ?';

  @override
  String get speciesPickSubtitle => 'Nous avons trouvé ces options — choisissez celle qui correspond';

  @override
  String get noneOfThese => 'Aucune de celles-ci';

  @override
  String get typePlantNameRetry => 'Tapez le nom de la plante et nous réessayerons';

  @override
  String get gettingCareRecommendations => 'Récupération des conseils de soin';

  @override
  String get imageUploadedAnalysisComplete => 'Image téléversée avec succès ! Analyse IA terminée.';

  @override
  String get aiCareRecommendationsHeader => 'Recommandations de soin par IA';

  @override
  String get aiReady => 'IA prête';

  @override
  String get checkPlantButton => 'Vérifier la plante';

  @override
  String get plantCareAssistantTitle => 'Assistant de soin des plantes';

  @override
  String get plantNeedsHelp => 'La plante a besoin d\'aide !';

  @override
  String get whatToDoNow => 'Que faire maintenant';

  @override
  String get wateringLabel => 'Arrosage';

  @override
  String get nowLabel => 'Maintenant';

  @override
  String get nextIn1Day => 'Suivant dans 1 jour';

  @override
  String nextInNDays(int days) {
    return 'Suivant dans $days jours';
  }

  @override
  String get wateringDone => 'Arrosage effectué';

  @override
  String get moistureDry => 'Sec';

  @override
  String get moistureWet => 'Humide';

  @override
  String get moistureLevelVeryDry => 'Très sec';

  @override
  String get moistureLevelDry => 'Sec';

  @override
  String get moistureLevelSlightlyMoist => 'Légèrement humide';

  @override
  String get moistureLevelMoist => 'Humide';

  @override
  String get moistureLevelVeryMoist => 'Très humide';

  @override
  String bannerWaterTitle(String name) {
    return '$name a besoin d\'eau';
  }

  @override
  String get bannerWaterSubtitle => 'Appuyez pour arroser ou voir les détails';

  @override
  String get bannerTipTitle => 'Conseil du jour';

  @override
  String get bannerTipSubtitle => 'Appuyez pour plus de conseils saisonniers';

  @override
  String get tipsOfTheDay => 'Conseils du jour';

  @override
  String get tipsOfTheDaySub => 'Conseils saisonniers IA · mis à jour chaque semaine';

  @override
  String get tipCategoryWatering => 'Arrosage';

  @override
  String get tipCategoryLight => 'Lumière';

  @override
  String get tipCategoryPests => 'Parasites';

  @override
  String get tipCategoryFertilizing => 'Engrais';

  @override
  String get tipCategorySeasonal => 'Saisonnier';

  @override
  String get tipCategoryGeneral => 'Général';

  @override
  String get noTipsYet => 'Les conseils sont en cours de génération. Revenez bientôt !';

  @override
  String get waterNow => 'Arroser maintenant';

  @override
  String get subscriptionUpgrade => 'Passer à Premium';

  @override
  String get subscriptionManage => 'Gérer';

  @override
  String get subscriptionActiveTitle => 'Premium actif';

  @override
  String get subscriptionGrandfatheredTitle => 'Accès à vie';

  @override
  String get subscriptionTrialTitle => 'Essai gratuit';

  @override
  String get subscriptionExpiredTitle => 'Abonnement expiré';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Actif jusqu\'au $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'L\'essai se termine le $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String get subscriptionExpiredMessage => 'Votre abonnement a expiré. Passez à Premium pour continuer.';

  @override
  String get subscriptionPlantLimitReached => 'Limite de plantes atteinte';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Limite du plan gratuit atteinte. Passez à Premium — jusqu\'à $limit plantes.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired => 'Abonnez-vous pour ajouter d\'autres plantes.';

  @override
  String get subscriptionReadOnlyNotice => 'Mode lecture seule. Abonnez-vous pour modifier vos plantes.';

  @override
  String get paywallTitle => 'Débloquer Premium';

  @override
  String get paywallSubtitle => 'Profitez pleinement de votre collection de plantes';

  @override
  String paywallFeature1(int limit) {
    return 'Jusqu\'à $limit plantes';
  }

  @override
  String get paywallFeature2 => 'Rappels d\'arrosage illimités';

  @override
  String get paywallFeature3 => 'Assistant IA et bilans de santé';

  @override
  String get paywallFeature4 => 'Édition complète et suivi des soins';

  @override
  String get paywallMonthly => 'Mensuel';

  @override
  String get paywallAnnual => 'Annuel';

  @override
  String get paywallBestValue => 'Meilleure offre';

  @override
  String get paywallContinue => 'Continuer';

  @override
  String get paywallRestore => 'Restaurer l\'achat';

  @override
  String get paywallRestoring => 'Restauration…';

  @override
  String get paywallRestoreSuccess => 'Achat restauré !';

  @override
  String get paywallRestoreNotFound => 'Aucun achat précédent trouvé.';

  @override
  String get paywallRestoreAlreadyActive => 'Votre abonnement est déjà actif.';

  @override
  String get paywallTerms => 'L\'abonnement se renouvelle automatiquement. Annulez à tout moment dans les réglages de l\'App Store.';

  @override
  String get paywallLoading => 'Chargement des offres…';

  @override
  String get paywallPurchasing => 'Traitement en cours…';

  @override
  String get paywallError => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get paywallHeroTitle => 'Grandis sans limites.';

  @override
  String get paywallHeroDescription => 'Votre assistant IA personnel — rappels d\'arrosage, bilans de santé, conseils saisonniers et tout ce qu\'il vous faut pour que vos plantes s\'épanouissent.';

  @override
  String get paywallChoosePlan => 'CHOISISSEZ VOTRE OFFRE';

  @override
  String paywallPerMonth(Object price) {
    return 'Seulement $price / mois';
  }

  @override
  String get paywallStartPremium => 'Démarrer Premium';

  @override
  String get paywallSecured => 'Sécurisé par Stripe';

  @override
  String get paywallSecuredApple => 'Sécurisé';

  @override
  String get paywallCancelAnytime => 'Annulez à tout moment';

  @override
  String get paywallAutoRenews => 'renouvellement automatique';

  @override
  String get stripeSuccessTitle => 'Abonnement activé !';

  @override
  String get stripeSuccessWaiting => 'Activation de votre abonnement';

  @override
  String get stripeSuccessSubtitle => 'Bienvenue sur Botanly Premium ! Vous avez maintenant accès à toutes les fonctionnalités.';

  @override
  String get stripeSuccessButton => 'Aller à mes plantes';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'Impossible d\'ouvrir le portail de facturation : $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get emailCopied => 'E-mail copié : support@botanly.app';

  @override
  String get labelExpires => 'Expire';

  @override
  String get labelNextRenewal => 'Prochain renouvellement';

  @override
  String get labelAutoRenewal => 'Renouvellement automatique';

  @override
  String get labelRestorePurchases => 'Restaurer les achats';

  @override
  String get labelPlants => 'Plantes';

  @override
  String get labelRenews => 'Renouvellement';

  @override
  String get testWateringEmailQueued => 'E-mail d\'arrosage test en attente.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'Impossible d\'envoyer l\'e-mail test : $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'Impossible de sauvegarder les canaux de rappel : $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'Impossible de mettre à jour les heures silencieuses : $error';
  }

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle => 'Désactiver définitivement votre compte';

  @override
  String get deleteAccountConfirmBody => 'Votre compte sera désactivé définitivement et vous perdrez l\'accès à l\'application. Vos données de plantes seront conservées.\n\nCette action est irréversible.';

  @override
  String get deleteAccountAreYouSure => 'Êtes-vous sûr ?';

  @override
  String get deleteAccountTypeConfirm => 'Tapez DELETE pour confirmer :';

  @override
  String get deleteAccountConfirmBtn => 'Confirmer la suppression';

  @override
  String errorDeletingAccount(Object error) {
    return 'Impossible de supprimer le compte : $error';
  }

  @override
  String get subPillPremium => 'Premium';

  @override
  String get subPillEarlyMember => 'Membre fondateur';

  @override
  String get subPillFreePlan => 'Plan gratuit';

  @override
  String get subPillFreeTrial => 'Essai gratuit';

  @override
  String get subMetaActivePlan => 'PLAN ACTIF';

  @override
  String get subMetaForeverPremium => 'PREMIUM ÉTERNEL';

  @override
  String get subMetaTrialEnded => 'ESSAI TERMINÉ';

  @override
  String subMetaNDayPreview(int n) {
    return 'APERÇU $n JOURS';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Renouvellement dans $days jours · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Se termine dans $days jours · $date';
  }

  @override
  String get subActiveSubscription => 'Abonnement actif';

  @override
  String get subGrantedEarlyMember => 'Accordé en tant que membre fondateur Botanly';

  @override
  String get subDaysLeft => 'jours restants';

  @override
  String get subUntilPreviewEnds => 'jusqu\'à la fin\nde l\'aperçu';

  @override
  String get subTrialEnded => 'essai\nterminé';

  @override
  String get subAutoRenewOn => 'Renouvellement auto activé  ·  Annulez à tout moment';

  @override
  String get subAutoRenewOff => 'Renouvellement auto désactivé  ·  Accès jusqu\'à expiration';

  @override
  String get subDetails => 'Détails';

  @override
  String get subReactivate => 'Réactiver';

  @override
  String get subNoChargesEver => 'Aucun frais, jamais  ·  Tous les avantages débloqués';

  @override
  String get subLimitedAccess => 'Accès limité  ·  Sans soins IA';

  @override
  String get subUnlimitedAccess => 'Illimité  ·  Soins IA  ·  Rappels';

  @override
  String get subHeroYourePrefix => 'Vous ';

  @override
  String get subHeroGrowingWord => 'grandissez';

  @override
  String get subHeroForeverWord => 'Pour toujours';

  @override
  String get subHeroPremiumSuffix => ' Premium';

  @override
  String get labelEnds => 'Se termine';

  @override
  String get labelPlan => 'Plan';

  @override
  String get labelPremium => 'Premium';

  @override
  String get labelGrandfathered => 'Accès hérité';

  @override
  String get labelOn => 'Activé';

  @override
  String get labelOff => 'Désactivé';

  @override
  String get yourPlan => 'Votre plan';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get manageBillingWeb => 'Gérer la facturation';

  @override
  String get manageInAppStore => 'Gérer dans l\'App Store';

  @override
  String get manageBillingSubtitleWeb => 'Annulez, mettez à jour votre carte ou consultez les factures\nvia le portail de facturation Stripe.';

  @override
  String get manageBillingSubtitleAppStore => 'Pour désactiver le renouvellement automatique ou annuler,\nrendez-vous dans vos abonnements App Store.';

  @override
  String get tipGoodLight => 'bonne lumière';

  @override
  String get tipShowLeaves => 'montrez les feuilles';

  @override
  String get tipSinglePlant => 'plante seule';

  @override
  String get snapYourSprout => 'Photographiez votre pousse';

  @override
  String get identifyingPlantPrefix => 'Identification de votre ';

  @override
  String get identifyingPlantWord => 'plante';

  @override
  String get identifyingSubtitle => 'Examen des feuilles, tiges et plantes voisines';

  @override
  String get specificIssues => 'Problèmes spécifiques';

  @override
  String get healthCheckPhotoHint => 'Ajoutez jusqu\'à 3 photos — plus d\'angles signifie une analyse plus précise. Seule la première photo est obligatoire.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Plante entière';

  @override
  String get healthCheckSlot1Desc => 'Photographiez la plante entière avec le pot — pour voir la terre et le pot en entier.';

  @override
  String get healthCheckSlot1Tag => 'Obligatoire';

  @override
  String get healthCheckSlot2Title => 'Gros plan';

  @override
  String get healthCheckSlot2Desc => 'Rapprochez l\'appareil photo, sans le pot — pour voir clairement les feuilles et leur texture.';

  @override
  String get healthCheckSlot2Tag => 'Facultatif';

  @override
  String get healthCheckSlot3Title => 'Zone problématique';

  @override
  String get healthCheckSlot3Desc => 'Vous voulez montrer quelque chose de précis ? Photographiez une tache, un parasite ou une feuille endommagée.';

  @override
  String get healthCheckSlot3Tag => 'Facultatif';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return 'Analyser $count photo(s)';
  }

  @override
  String get healthCheckError => "L'analyse a échoué. Veuillez réessayer.";

  @override
  String get healthCheckDefaultPraise => '🌱 Votre plante se porte bien !';

  @override
  String get healthCheckDefaultFooter => 'Continuez à prendre soin de votre plante selon les recommandations et notez quand vous arrosez.';

  @override
  String get addPlantWholePlantTitle => 'Plante entière';

  @override
  String get addPlantWholePlantDesc => 'avec le pot et la terre';

  @override
  String get addPlantWholePlantTag => 'Obligatoire';

  @override
  String get addPlantCloseUpTitle => 'Gros plan';

  @override
  String get addPlantCloseUpDesc => 'feuilles en détail';

  @override
  String get addPlantCloseUpTag => 'Facultatif';

  @override
  String get addPlantDualHint => 'Deux angles aident notre IA à identifier votre plante plus précisément.';

  @override
  String get addPlantAnalyzeButton => 'Analyser la plante';

  @override
  String get addPlantStepPhotosReceived => 'Photos reçues';

  @override
  String get addPlantStepIdentifying => 'Identification de l\'espèce';

  @override
  String get addPlantStepCarePlan => 'Création du plan de soins';

  @override
  String get addPlantAnalyzingTitle => 'Analyse de votre plante';

  @override
  String get addPlantAnalyzingSubtitle => 'Cela prend généralement quelques secondes…';

  @override
  String get addPlantAnalysisComplete => 'Analyse terminée';

  @override
  String get addPlantSeePlantProfile => 'Voir le profil de la plante';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboarding1Eyebrow => 'Bienvenue';

  @override
  String get onboarding1Title => 'Découvrez ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body => 'Votre compagnon IA pour des plantes heureuses et saines — toujours dans votre poche.';

  @override
  String get onboarding2Eyebrow => 'Identifier';

  @override
  String get onboarding2Title => 'Nommez ';

  @override
  String get onboarding2TitleItalic => 'n\'importe quelle plante';

  @override
  String get onboarding2Body => 'Pointez votre caméra et laissez l\'IA l\'identifier en quelques secondes — espèce, nom et tout.';

  @override
  String get onboarding3Eyebrow => 'Soin';

  @override
  String get onboarding3Title => 'Des soins ';

  @override
  String get onboarding3TitleItalic => 'sans effort';

  @override
  String get onboarding3Body => 'Rappels d\'arrosage, de lumière et de sol — parfaitement adaptés à chaque plante.';

  @override
  String get onboarding4Eyebrow => 'Bilan de santé';

  @override
  String get onboarding4Title => 'Détectez les problèmes ';

  @override
  String get onboarding4TitleItalic => 'tôt';

  @override
  String get onboarding4Body => 'Prenez une photo et obtenez un bilan de santé instantané avec un plan clair pour y remédier.';

  @override
  String get onboarding5Eyebrow => 'Prêt';

  @override
  String get onboarding5Title => 'Grandissons ';

  @override
  String get onboarding5TitleItalic => 'ensemble';

  @override
  String get onboarding5Body => 'Constituez votre collection de plantes et ne ratez jamais rien. Votre ère la plus verte commence maintenant.';
}
