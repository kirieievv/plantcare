// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Pflanzenpflege';

  @override
  String get loadingPlantCare => 'Pflanzenpflege wird geladen...';

  @override
  String get home => 'Startseite';

  @override
  String get myPlants => 'Meine Pflanzen';

  @override
  String get addPlant => 'Pflanze hinzufügen';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get authenticationError => 'Authentifizierungsfehler';

  @override
  String get pleaseLoginAgain => 'Bitte melden Sie sich erneut an, um fortzufahren';

  @override
  String get goToLogin => 'Zur Anmeldung';

  @override
  String get yourGardenOverview => 'Übersicht Ihres Gartens';

  @override
  String get welcomeBack => 'Willkommen zurück!';

  @override
  String get createYourAccount => 'Konto erstellen';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get pleaseEnterYourName => 'Bitte geben Sie Ihren Namen ein';

  @override
  String get pleaseEnterYourEmail => 'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get pleaseEnterValidEmail => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get pleaseEnterYourPassword => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String get passwordAtLeast6 => 'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get rememberMe30Days => '30 Tage angemeldet bleiben';

  @override
  String get logIn => 'Anmelden';

  @override
  String get registration => 'Registrierung';

  @override
  String get dontHaveAccountRegistration => 'Noch kein Konto? Registrierung';

  @override
  String get alreadyHaveAccountLogin => 'Bereits ein Konto? Anmelden';

  @override
  String get loggedIn => 'Angemeldet';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get wateringReminders => 'Bewässerungserinnerungen';

  @override
  String get getNotifiedWhenPlantsNeedWater => 'Benachrichtigung erhalten, wenn Pflanzen Wasser brauchen';

  @override
  String get quietHours => 'Ruhestunden';

  @override
  String get maxNotificationsPerDay => 'Max. Benachrichtigungen pro Tag';

  @override
  String notificationsCount(int count) {
    return '$count Benachrichtigungen';
  }

  @override
  String get theme => 'Design';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get testNotifications => 'Benachrichtigungen testen';

  @override
  String get checkNotificationSetupAndPermissions => 'Benachrichtigungseinrichtung und Berechtigungen prüfen';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get savePreferences => 'Einstellungen speichern';

  @override
  String get account => 'Konto';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get updateYourAccountPassword => 'Kontopasswort aktualisieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutOfYourAccount => 'Von Ihrem Konto abmelden';

  @override
  String get preferencesSavedSuccessfully => 'Einstellungen erfolgreich gespeichert!';

  @override
  String errorSavingPreferences(Object error) {
    return 'Fehler beim Speichern der Einstellungen: $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => 'Ruhestunden erfolgreich aktualisiert!';

  @override
  String get changePasswordTitle => 'Passwort ändern';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get enterCurrentPassword => 'Aktuelles Passwort eingeben';

  @override
  String get enterNewPassword => 'Neues Passwort eingeben';

  @override
  String get newPasswordMustBeDifferent => 'Das neue Passwort muss sich vom alten unterscheiden';

  @override
  String get confirmYourNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get passwordChangedSuccessfully => 'Passwort erfolgreich geändert.';

  @override
  String errorChangingPassword(Object error) {
    return 'Fehler beim Ändern des Passworts: $error';
  }

  @override
  String get signOutConfirmTitle => 'Abmelden';

  @override
  String get signOutConfirmMessage => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get userLabel => 'Benutzer';

  @override
  String get nameCannotBeEmpty => 'Name darf nicht leer sein';

  @override
  String get profileUpdatedSuccessfully => 'Profil erfolgreich aktualisiert!';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Fehler beim Aktualisieren des Profils: $error';
  }

  @override
  String get plantLover => 'Pflanzenliebhaber';

  @override
  String get profileInformation => 'Profilinformationen';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Erzählen Sie uns von Ihrer Pflanzenpflege-Erfahrung...';

  @override
  String get location => 'Standort';

  @override
  String get locationHint => 'Wo befinden sich Ihre Pflanzen?';

  @override
  String get name => 'Name';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get accountInfo => 'Kontoinformationen';

  @override
  String get memberSince => 'Mitglied seit';

  @override
  String get lastLogin => 'Letzte Anmeldung';

  @override
  String get notAvailable => 'N/V';

  @override
  String get actions => 'Aktionen';

  @override
  String get errorLabel => 'Fehler';

  @override
  String get noPlantsYet => 'Noch keine Pflanzen!';

  @override
  String get addFirstPlantToGetStarted => 'Fügen Sie Ihre erste Pflanze hinzu, um zu beginnen';

  @override
  String errorPickingImage(Object error) {
    return 'Fehler beim Auswählen des Bildes: $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'Analyse des Pflanzenfotos fehlgeschlagen: $statusCode';
  }

  @override
  String get aiAnalysisCompleted => 'KI-Analyse abgeschlossen! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'KI-Analyse fehlgeschlagen: $error';
  }

  @override
  String apiTestError(Object error) {
    return 'API-Testfehler: $error';
  }

  @override
  String get aiAnalysisRefreshed => 'KI-Analyse aktualisiert! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'Aktualisierung der KI-Analyse fehlgeschlagen: $error';
  }

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get uploadPlantPhoto => 'Pflanzenfoto hochladen';

  @override
  String get notSpecified => 'Nicht angegeben';

  @override
  String get onceEvery7Days => 'Einmal alle 7 Tage';

  @override
  String get oncePerDay => 'Einmal täglich';

  @override
  String get oncePerWeek => 'Einmal wöchentlich';

  @override
  String onceEveryNDays(int days) {
    return 'Einmal alle $days Tage';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    return 'Einmal alle $weeks Wochen';
  }

  @override
  String get low => 'Niedrig';

  @override
  String get mediumLow => 'Mittel-Niedrig';

  @override
  String get medium => 'Mittel';

  @override
  String get mediumHigh => 'Mittel-Hoch';

  @override
  String get high => 'Hoch';

  @override
  String get userNotAuthenticated => 'Benutzer nicht authentifiziert';

  @override
  String get pleaseUploadPlantImage => 'Bitte laden Sie ein Pflanzenbild hoch';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant => 'Bitte warten Sie, bis die KI-Analyse abgeschlossen ist, bevor Sie die Pflanze hinzufügen';

  @override
  String get plantLowercase => 'pflanze';

  @override
  String get plantAddedSuccessfully => 'Pflanze erfolgreich hinzugefügt! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Fehler beim Hinzufügen der Pflanze: $error';
  }

  @override
  String get generateRandomName => 'Zufälligen Namen generieren';

  @override
  String get plantName => 'Pflanzenname';

  @override
  String get plantNameHint => 'z. B. Monstera, Sansevierie';

  @override
  String get pleaseEnterPlantName => 'Bitte geben Sie einen Pflanzennamen ein';

  @override
  String get addingPlant => 'Pflanze wird hinzugefügt...';

  @override
  String get analyzingPhoto => 'Foto wird analysiert...';

  @override
  String get plantUpdatedSuccessfully => 'Pflanze erfolgreich aktualisiert! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Fehler beim Aktualisieren der Pflanze: $error';
  }

  @override
  String get species => 'Art';

  @override
  String get wateringFrequency => 'Bewässerungshäufigkeit';

  @override
  String everyNDays(int days) {
    return 'Alle $days Tag(e)';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Bitte wählen Sie die Bewässerungshäufigkeit';

  @override
  String get notes => 'Notizen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get loadingImage => 'Bild wird geladen...';

  @override
  String get changeImage => 'Bild ändern';

  @override
  String errorDeletingPlant(Object error) {
    return 'Fehler beim Löschen der Pflanze: $error';
  }

  @override
  String get plantNotDueForWateringYet => 'Diese Pflanze muss noch nicht bewässert werden';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'Fehler beim Laden des Pflanzendetailbildschirms: $error';
  }

  @override
  String get aiCare => 'KI-Pflege';

  @override
  String get aiAgent => 'KI-Agent';

  @override
  String get plantChatOpen => 'Pflanzenchat öffnen';

  @override
  String plantChatTitle(Object plantName) {
    return 'Chat über $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return 'Hallo! Ich bin Ihr Pflanzenassistent für $plantName. Fragen Sie mich alles über Bewässerung, Gesundheitszeichen oder was als Nächstes zu tun ist.';
  }

  @override
  String get plantChatInputHint => 'Fragen Sie über diese Pflanze...';

  @override
  String get plantChatLoginAgain => 'Bitte melden Sie sich erneut an.';

  @override
  String get plantChatRequestFailed => 'Chat-Anfrage fehlgeschlagen';

  @override
  String get plantChatCouldNotGenerateResponse => 'Ich konnte keine Antwort generieren. Bitte versuchen Sie es erneut.';

  @override
  String get plantChatConnectionError => 'Beim Kontaktieren des Pflanzenassistenten ist etwas schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get plantChatQuickWaterToday => 'Kann ich heute gießen?';

  @override
  String get plantChatQuickYellowLeaves => 'Warum werden die Blätter gelb?';

  @override
  String get plantChatQuickWhatToDoNow => 'Was soll ich jetzt tun?';

  @override
  String get splashTagline => 'Dein intelligenter Pflanzenbegleiter';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get splashDescription => 'Beobachte deine Pflanzen, erhalte personalisierte Pflegetipps\nund verfolge ihre Gesundheit — alles an einem Ort.';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetYourPassword => 'Passwort zurücksetzen';

  @override
  String get enterEmailForCode => 'Gib deine Konto-E-Mail-Adresse ein, um einen Bestätigungscode zu erhalten.';

  @override
  String get sendCode => 'Code senden';

  @override
  String get enterVerificationCode => 'Bestätigungscode eingeben';

  @override
  String get weSentACodeTo => 'Wir haben einen 6-stelligen Code gesendet an';

  @override
  String get verificationCodeSentAgain => 'Bestätigungscode erneut gesendet.';

  @override
  String resendCodeInSeconds(int seconds) => 'Code in ${seconds}s erneut senden';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String get setNewPassword => 'Neues Passwort festlegen';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get updatePassword => 'Passwort aktualisieren';

  @override
  String get passwordResetSuccess => 'Passwort erfolgreich zurückgesetzt. Bitte melden Sie sich an.';

  @override
  String get totalPlants => 'Pflanzen gesamt';

  @override
  String get needWater => 'Brauchen Wasser';

  @override
  String get healthy => 'Gesund';

  @override
  String get yourPlants => 'Deine Pflanzen';

  @override
  String get plantCreatedSuccessfully => 'Pflanze erfolgreich erstellt! 🌱';

  @override
  String get reminderEmail => 'E-Mail';

  @override
  String get reminderEmailSubtitle => 'E-Mails zur Bewässerungserinnerung';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get pushNotificationsSubtitle => 'Benachrichtigungen in der App (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) => 'Überfällig ${days}T';

  @override
  String get wateringToday => 'Gießen heute';

  @override
  String get wateringTomorrow => 'Gießen morgen';

  @override
  String wateringInNDays(int days) => 'Gießen in ${days}T';

  @override
  String plantWateredSuccess(Object plantName) => '$plantName wurde gegossen! 💧';

  @override
  String errorWateringPlant(Object error) => 'Fehler beim Gießen der Pflanze: $error';

  @override
  String get healthIssueDetected => 'Gesundheitsproblem erkannt';

  @override
  String get recommendedActionsLabel => 'Empfohlene Maßnahmen:';

  @override
  String get healthAlertNote => 'Diese Warnung bleibt sichtbar, bis ein späterer Gesundheitscheck OK ergibt';

  @override
  String get addHealthCheckTooltip => 'Gesundheitscheck hinzufügen';

  @override
  String get noHealthChecksYet => 'Noch keine Gesundheitschecks';

  @override
  String get uploadPhotosToTrackHealth => 'Lade Fotos hoch, um die Gesundheit deiner Pflanze im Laufe der Zeit zu verfolgen';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String nDaysAgo(int days) => 'Vor $days Tagen';

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Problem';

  @override
  String get assistantTyping => 'Assistent schreibt...';

  @override
  String chatSourceLabel(Object source) => 'Quelle: $source';

  @override
  String get chatSourceKnowledgeBase => 'Wissensdatenbank';

  @override
  String get chatSourceContext => 'Kontext';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get choosePhoto => 'Foto wählen';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Kamera';

  @override
  String get analyzeHealth => 'Gesundheit analysieren';

  @override
  String get analyzing => 'Analysieren...';

  @override
  String get imageReadyForAnalysis => 'Bild erfolgreich hochgeladen! Bereit für die Gesundheitsanalyse.';

  @override
  String get healthCheckTitle => 'Gesundheitscheck';

  @override
  String get healthCheckHistoryTitle => 'Gesundheitscheck-Verlauf';

  @override
  String healthCheckUploadHint(Object plantName) => 'Lade ein Foto von $plantName für die KI-Gesundheitsanalyse hoch';

  @override
  String get deletePlant => 'Pflanze löschen';

  @override
  String get deletePlantConfirm => 'Möchten Sie diese Pflanze wirklich löschen?';

  @override
  String get delete => 'Löschen';

  @override
  String get iHaveWatered => 'Ich habe gegossen';

  @override
  String get soilMoisture => 'Bodenfeuchtigkeit';

  @override
  String get lightLabel => 'Licht';

  @override
  String get perDay => 'pro Tag';

  @override
  String get hoursLabel => 'Stunden';

  @override
  String get careRecommendationsTitle => 'Pflegeempfehlungen';

  @override
  String get interestingFactsTitle => 'Interessante Fakten';

  @override
  String get noCareRecommendationsYet => 'KI-generierte Pflegeempfehlungen sind für diese Pflanze noch nicht verfügbar.';

  @override
  String get noInterestingFactsYet => 'KI-generierte interessante Fakten sind für diese Pflanze noch nicht verfügbar.';

  @override
  String get noDescriptionYet => 'Noch keine Beschreibung verfügbar.';

  @override
  String get swipeToSeeMore => 'Wischen für mehr';

  @override
  String get uploadPhotosForHealthHistory => 'Lade Fotos hoch, um die Gesundheit deiner Pflanze zu verfolgen';

  @override
  String plantDeletedMessage(Object plantName) => 'Pflanze "$plantName" wurde gelöscht';

  @override
  String get noImageAvailable => 'Kein Bild verfügbar';

  @override
  String get addPhotoToSeeYourPlant => 'Füge ein Foto hinzu, um deine Pflanze hier zu sehen';

  @override
  String get isThisYourPlant => 'Ist das Ihre Pflanze?';

  @override
  String get speciesPickSubtitle => 'Wir haben diese Optionen gefunden — wählen Sie die passende';

  @override
  String get noneOfThese => 'Keine davon';

  @override
  String get typePlantNameRetry => 'Gib den Pflanzennamen ein und wir versuchen es erneut';

  @override
  String get gettingCareRecommendations => 'Pflegeempfehlungen werden abgerufen';

  @override
  String get imageUploadedAnalysisComplete => 'Bild erfolgreich hochgeladen! KI-Analyse abgeschlossen.';

  @override
  String get aiCareRecommendationsHeader => 'KI-Pflegeempfehlungen';

  @override
  String get aiReady => 'KI bereit';

  @override
  String get checkPlantButton => 'Pflanze prüfen';

  @override
  String get plantCareAssistantTitle => 'Pflanzenpflege-Assistent';

  @override
  String get plantNeedsHelp => 'Pflanze braucht Hilfe!';

  @override
  String get whatToDoNow => 'Was jetzt zu tun ist';
  String get wateringLabel => 'Bewässerung';
  String get nowLabel => 'Jetzt';
  String get nextIn1Day => 'Nächste in 1 Tag';
  String nextInNDays(int days) => 'Nächste in $days Tagen';
  String get wateringDone => 'Bewässerung abgeschlossen';
  String get moistureDry => 'Trocken';
  String get moistureWet => 'Feucht';
  String get moistureLevelVeryDry => 'Sehr trocken';
  String get moistureLevelDry => 'Trocken';
  String get moistureLevelSlightlyMoist => 'Leicht feucht';
  String get moistureLevelMoist => 'Feucht';
  String get moistureLevelVeryMoist => 'Sehr feucht';
}
