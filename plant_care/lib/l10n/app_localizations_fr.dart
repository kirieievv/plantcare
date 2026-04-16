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
  String get yourGardenOverview => 'Aperçu de votre jardin';

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
  String get splashTagline => 'Votre compagnon végétal intelligent';

  @override
  String get getStarted => 'Commencer';

  @override
  String get splashDescription => 'Surveillez vos plantes, obtenez des conseils de soin personnalisés\net suivez leur santé — tout en un seul endroit.';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

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
  String resendCodeInSeconds(int seconds) => 'Renvoyer le code dans ${seconds}s';

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
  String get yourPlants => 'Vos plantes';

  @override
  String get plantCreatedSuccessfully => 'Plante créée avec succès ! 🌱';

  @override
  String get reminderEmail => 'E-mail';

  @override
  String get reminderEmailSubtitle => 'E-mails de rappel d\'arrosage';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get pushNotificationsSubtitle => 'Alertes dans l\'application (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) => 'En retard ${days}j';

  @override
  String get wateringToday => 'Arrosage aujourd\'hui';

  @override
  String get wateringTomorrow => 'Arrosage demain';

  @override
  String wateringInNDays(int days) => 'Arrosage dans ${days}j';

  @override
  String plantWateredSuccess(Object plantName) => '$plantName a été arrosée ! 💧';

  @override
  String errorWateringPlant(Object error) => 'Erreur lors de l\'arrosage de la plante : $error';

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
  String nDaysAgo(int days) => 'Il y a $days jours';

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Problème';

  @override
  String get assistantTyping => 'L\'assistant est en train d\'écrire...';

  @override
  String chatSourceLabel(Object source) => 'Source : $source';

  @override
  String get chatSourceKnowledgeBase => 'Base de connaissances';

  @override
  String get chatSourceContext => 'Contexte';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Appareil photo';

  @override
  String get analyzeHealth => 'Analyser la santé';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get imageReadyForAnalysis => 'Image téléversée avec succès ! Prête pour l\'analyse de santé.';

  @override
  String get healthCheckTitle => 'Contrôle de santé';

  @override
  String get healthCheckHistoryTitle => 'Historique des contrôles de santé';

  @override
  String healthCheckUploadHint(Object plantName) => 'Téléversez une photo de $plantName pour l\'analyse de santé par IA';

  @override
  String get deletePlant => 'Supprimer la plante';

  @override
  String get deletePlantConfirm => 'Êtes-vous sûr de vouloir supprimer cette plante ?';

  @override
  String get delete => 'Supprimer';

  @override
  String get iHaveWatered => 'J\'ai arrosé';

  @override
  String get soilMoisture => 'Humidité du sol';

  @override
  String get lightLabel => 'Lumière';

  @override
  String get perDay => 'par jour';

  @override
  String get hoursLabel => 'heures';

  @override
  String get careRecommendationsTitle => 'Conseils de soin';

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
  String plantDeletedMessage(Object plantName) => 'La plante « $plantName » a été supprimée';

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
  String get wateringLabel => 'Arrosage';
  String get nowLabel => 'Maintenant';
  String get nextIn1Day => 'Suivant dans 1 jour';
  String nextInNDays(int days) => 'Suivant dans $days jours';
  String get wateringDone => 'Arrosage effectué';
  String get moistureDry => 'Sec';
  String get moistureWet => 'Humide';
  String get moistureLevelVeryDry => 'Très sec';
  String get moistureLevelDry => 'Sec';
  String get moistureLevelSlightlyMoist => 'Légèrement humide';
  String get moistureLevelMoist => 'Humide';
  String get moistureLevelVeryMoist => 'Très humide';
}
