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
  String get yourGardenOverview => 'Gartenübersicht';

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
  String get pleaseConfirmYourPassword => 'Bitte bestätigen Sie Ihr Passwort';

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
  String get russian => 'Russisch';

  @override
  String get ukrainian => 'Ukrainisch';

  @override
  String get savePreferences => 'Einstellungen speichern';

  @override
  String get account => 'Konto';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get updateYourAccountPassword => 'Kontpasswort aktualisieren';

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
  String get addYourFirstPlant => 'Erste Pflanze hinzufügen';

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Alle $days Tage',
      one: 'Alle $days Tag',
    );
    return '$_temp0';
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
  String get plantChatImageQuotaReached => 'Tägliches Fotolimit erreicht. Versuche es morgen erneut.';

  @override
  String get splashTagline => 'Dein intelligenter Pflanzenbegleiter';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get splashDescription => 'Beobachte deine Pflanzen, erhalte personalisierte Pflegetipps\nund verfolge ihre Gesundheit — alles an einem Ort.';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get errorInvalidPin => 'Falscher Code. Bitte versuche es erneut.';

  @override
  String get errorPinExpired => 'Der Code ist abgelaufen. Bitte fordere einen neuen an.';

  @override
  String get errorPinNotFound => 'Kein Code gefunden. Bitte fordere einen neuen an.';

  @override
  String get errorTooManyAttempts => 'Zu viele Versuche. Bitte fordere einen neuen Code an.';

  @override
  String get errorSendFailed => 'Code konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get errorUserNotFound => 'Kein Konto mit dieser E-Mail gefunden.';

  @override
  String get errorEmailAlreadyExists => 'Ein Konto mit dieser E-Mail existiert bereits.';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

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
  String resendCodeInSeconds(int seconds) {
    return 'Code in ${seconds}s erneut senden';
  }

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
  String get yourPlants => 'Meine Pflanzen';

  @override
  String get plantCreatedSuccessfully => 'Pflanze erfolgreich erstellt! 🌱';

  @override
  String get searchPlantsHint => 'Pflanzen suchen…';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterOverdue => 'Überfällig';

  @override
  String get noResultsTitle => 'Keine Treffer';

  @override
  String get noResultsSub => 'Versuche eine andere Suche oder einen anderen Filter.';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get wateringRemindersBlockSub => 'Werde benachrichtigt, wenn deine Pflanzen Wasser brauchen.';

  @override
  String get emailRemindersTitle => 'E-Mail-Erinnerungen';

  @override
  String get emailRemindersSub => 'Bewässerungserinnerungen per E-Mail';

  @override
  String get pushNotificationsTitle => 'Push-Benachrichtigungen';

  @override
  String get pushNotificationsSub => 'Sofortige Hinweise auf deinem Gerät';

  @override
  String get quietHoursLabel => 'Ruhezeiten';

  @override
  String get themeLabel => 'Design';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get preferencesTitle => 'Einstellungen';

  @override
  String get accountTitle => 'Konto';

  @override
  String get changePasswordTitleRow => 'Passwort ändern';

  @override
  String get changePasswordSubRow => 'Aktualisiere dein Konto-Passwort';

  @override
  String get signOutSubRow => 'Vom Konto abmelden';

  @override
  String get aiAssistantOnline => 'KI-Pflanzen-Assistent · online';

  @override
  String get clearHistoryAction => 'Verlauf löschen';

  @override
  String get clearHistoryConfirm => 'Chat-Verlauf löschen?';

  @override
  String get saving => 'Wird gespeichert …';

  @override
  String get plantPhoto => 'Pflanzenfoto';

  @override
  String get addPlantTitle => 'Pflanze hinzufügen';

  @override
  String get addPlantSubtitle => 'Foto machen, erkennen, speichern';

  @override
  String get snapTitle => 'Foto aufnehmen';

  @override
  String get snapDescription => 'Ein klares Foto hilft unserer KI, deine Pflanze zu\nidentifizieren und die Pflege anzupassen';

  @override
  String get useCamera => 'Kamera verwenden';

  @override
  String get uploadFromGallery => 'Aus der Galerie laden';

  @override
  String get analyzing => 'Analysieren...';

  @override
  String get couldntIdentify => 'Wir konnten diese Pflanze nicht erkennen';

  @override
  String get tryAnotherPhoto => 'Versuche ein anderes Foto oder gib die Art manuell ein.';

  @override
  String get topMatch => 'Beste Übereinstimmung';

  @override
  String get useThisMatch => 'Diese verwenden';

  @override
  String get manualNamePlaceholder => 'Spitzname (z. B. Iris)';

  @override
  String get savePlantBtn => 'Pflanze speichern';

  @override
  String get tagOverdue => 'ÜBERFÄLLIG';

  @override
  String get tagDueSoon => 'BALD FÄLLIG';

  @override
  String get tagHealthy => 'GESUND';

  @override
  String get wateringScheduleTitle => 'Bewässerungsplan';

  @override
  String get lastWatered => 'Zuletzt gegossen';

  @override
  String get nextWatering => 'Nächstes Gießen';

  @override
  String get frequency => 'Häufigkeit';

  @override
  String get waterNowAction => 'Jetzt gießen';

  @override
  String get rescheduleAction => 'Neu planen';

  @override
  String get careRecommendationsTitle => 'Pflegeempfehlungen';

  @override
  String get careSectionCultivar => 'Kultivar';

  @override
  String get careSectionGeneralDescription => 'Allgemeine Beschreibung';

  @override
  String get careSectionSoil => 'Erde';

  @override
  String get careSectionSoilMoisture => 'Bodenfeuchtigkeit';

  @override
  String get careSectionMoistureCheck => 'Feuchtigkeitsprüfung';

  @override
  String get careSectionWater => 'Wasser';

  @override
  String get careSectionLight => 'Licht';

  @override
  String get careSectionTemperature => 'Temperatur';

  @override
  String get careSectionFertilizer => 'Dünger';

  @override
  String get careSectionGrowthRate => 'Wachstumsrate';

  @override
  String get careSectionToxicity => 'Toxizität';

  @override
  String get careSectionPlacement => 'Standort';

  @override
  String get careSectionPersonality => 'Charakter';

  @override
  String get aboutPlantTitle => 'Über diese Pflanze';

  @override
  String get askAssistantTitle => 'Assistent fragen';

  @override
  String get askAssistantSub => 'Erhalte Tipps vom Iris-KI-Assistenten';

  @override
  String get openChat => 'Chat öffnen';

  @override
  String get deletePlantAction => 'Pflanze löschen';

  @override
  String get reminderEmail => 'E-Mail';

  @override
  String get reminderEmailSubtitle => 'E-Mails zur Bewässerungserinnerung';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get pushNotificationsSubtitle => 'Benachrichtigungen in der App (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'Überfällig ${days}T';
  }

  @override
  String get wateringToday => 'Gießen heute';

  @override
  String get wateringTomorrow => 'Gießen morgen';

  @override
  String wateringInNDays(int days) {
    return 'Gießen in ${days}T';
  }

  @override
  String plantWateredSuccess(Object plantName) {
    return '$plantName wurde gegossen! 💧';
  }

  @override
  String errorWateringPlant(Object error) {
    return 'Fehler beim Gießen der Pflanze: $error';
  }

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
  String nDaysAgo(int days) {
    return 'Vor $days Tagen';
  }

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Problem';

  @override
  String get assistantTyping => 'Assistent schreibt...';

  @override
  String chatSourceLabel(Object source) {
    return 'Quelle: $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'Wissensdatenbank';

  @override
  String get chatSourceContext => 'Kontext';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get chatAttachPhoto => 'Foto anhängen';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit Fotos heute';
  }

  @override
  String get chatPhotoQuotaExhausted => 'Tägliches Fotolimit erreicht. Morgen erneut versuchen.';

  @override
  String get chatPhotoUploading => 'Foto hochladen...';

  @override
  String get chatPhotoUploadFailed => 'Foto konnte nicht hochgeladen werden. Bitte versuche es erneut.';

  @override
  String get chatRemovePhoto => 'Foto entfernen';

  @override
  String get chatCopyMessage => 'Kopieren';

  @override
  String get chatClearHistory => 'Neues Gespräch';

  @override
  String get chatClearHistoryConfirm => 'Neues Gespräch starten? Der aktuelle Verlauf wird gelöscht.';

  @override
  String get chatClearHistorySuccess => 'Neues Gespräch gestartet.';

  @override
  String get chatDateToday => 'Heute';

  @override
  String get chatDateYesterday => 'Gestern';

  @override
  String get choosePhoto => 'Foto wählen';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Kamera';

  @override
  String get analyzeHealth => 'Gesundheit analysieren';

  @override
  String get waterFirstLabel => 'Zuerst gießen';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Nächster Check in $days T.';
  }

  @override
  String get imageReadyForAnalysis => 'Bild erfolgreich hochgeladen! Bereit für die Gesundheitsanalyse.';

  @override
  String get healthCheckTitle => 'Gesundheitscheck';

  @override
  String get healthCheckHistoryTitle => 'Gesundheitscheck-Verlauf';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Lade ein Foto von $plantName für die KI-Gesundheitsanalyse hoch';
  }

  @override
  String get deletePlant => 'Pflanze löschen';

  @override
  String get deletePlantConfirm => 'Möchten Sie diese Pflanze wirklich löschen?';

  @override
  String get delete => 'Löschen';

  @override
  String get iHaveWatered => 'Ich habe gegossen';

  @override
  String get soilMoisture => 'Idealer Boden';

  @override
  String get lightLabel => 'Licht';

  @override
  String get perDay => 'pro Tag';

  @override
  String get hoursLabel => 'Stunden';

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
  String plantDeletedMessage(Object plantName) {
    return 'Pflanze \"$plantName\" wurde gelöscht';
  }

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

  @override
  String get wateringLabel => 'Bewässerung';

  @override
  String get nowLabel => 'Jetzt';

  @override
  String get nextIn1Day => 'Nächste in 1 Tag';

  @override
  String nextInNDays(int days) {
    return 'Nächste in $days Tagen';
  }

  @override
  String get wateringDone => 'Bewässerung abgeschlossen';

  @override
  String get moistureDry => 'Trocken';

  @override
  String get moistureWet => 'Feucht';

  @override
  String get moistureLevelVeryDry => 'Sehr trocken';

  @override
  String get moistureLevelDry => 'Trocken';

  @override
  String get moistureLevelSlightlyMoist => 'Leicht feucht';

  @override
  String get moistureLevelMoist => 'Feucht';

  @override
  String get moistureLevelVeryMoist => 'Sehr feucht';

  @override
  String bannerWaterTitle(String name) {
    return '$name braucht Wasser';
  }

  @override
  String get bannerWaterSubtitle => 'Tippen zum Gießen oder Details ansehen';

  @override
  String get bannerTipTitle => 'Tipp des Tages';

  @override
  String get bannerTipSubtitle => 'Tippen für weitere saisonale Tipps';

  @override
  String get tipsOfTheDay => 'Tipps des Tages';

  @override
  String get tipsOfTheDaySub => 'KI-gestützte saisonale Ratschläge · wöchentlich aktualisiert';

  @override
  String get tipCategoryWatering => 'Gießen';

  @override
  String get tipCategoryLight => 'Licht';

  @override
  String get tipCategoryPests => 'Schädlinge';

  @override
  String get tipCategoryFertilizing => 'Düngen';

  @override
  String get tipCategorySeasonal => 'Saisonal';

  @override
  String get tipCategoryGeneral => 'Allgemein';

  @override
  String get noTipsYet => 'Tipps werden gerade erstellt. Schau bald wieder vorbei!';

  @override
  String get waterNow => 'Jetzt gießen';

  @override
  String get subscriptionUpgrade => 'Upgrade';

  @override
  String get subscriptionManage => 'Verwalten';

  @override
  String get subscriptionActiveTitle => 'Premium aktiv';

  @override
  String get subscriptionGrandfatheredTitle => 'Lebenslanger Zugang';

  @override
  String get subscriptionTrialTitle => 'Kostenlose Testversion';

  @override
  String get subscriptionExpiredTitle => 'Abo abgelaufen';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Aktiv bis $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'Testversion endet am $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    return '$days Tage übrig';
  }

  @override
  String get subscriptionExpiredMessage => 'Dein Abo ist abgelaufen. Upgrade, um fortzufahren.';

  @override
  String get subscriptionPlantLimitReached => 'Pflanzenlimit erreicht';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Limit des kostenlosen Plans erreicht. Wechsle zu Premium — bis zu $limit Pflanzen.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired => 'Abonniere, um weitere Pflanzen hinzuzufügen.';

  @override
  String get subscriptionReadOnlyNotice => 'Nur-Lesen-Modus. Abonniere, um Pflanzen zu bearbeiten.';

  @override
  String get paywallTitle => 'Premium freischalten';

  @override
  String get paywallSubtitle => 'Hol das Beste aus deiner Pflanzensammlung heraus';

  @override
  String paywallFeature1(int limit) {
    return 'Bis zu $limit Pflanzen';
  }

  @override
  String get paywallFeature2 => 'Unbegrenzte Gießerinnerungen';

  @override
  String get paywallFeature3 => 'KI-Pflanzenassistent & Gesundheitschecks';

  @override
  String get paywallFeature4 => 'Vollständige Bearbeitung & Pflege-Tracking';

  @override
  String get paywallMonthly => 'Monatlich';

  @override
  String get paywallAnnual => 'Jährlich';

  @override
  String get paywallBestValue => 'Bestes Angebot';

  @override
  String get paywallContinue => 'Weiter';

  @override
  String get paywallRestore => 'Kauf wiederherstellen';

  @override
  String get paywallRestoring => 'Wird wiederhergestellt…';

  @override
  String get paywallRestoreSuccess => 'Kauf wiederhergestellt!';

  @override
  String get paywallRestoreNotFound => 'Kein vorheriger Kauf gefunden.';

  @override
  String get paywallRestoreAlreadyActive => 'Dein Abonnement ist bereits aktiv.';

  @override
  String get paywallTerms => 'Abonnement verlängert sich automatisch. Jederzeit in den App-Store-Einstellungen kündigen.';

  @override
  String get paywallLoading => 'Pläne werden geladen…';

  @override
  String get paywallPurchasing => 'Wird verarbeitet…';

  @override
  String get paywallError => 'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get paywallHeroTitle => 'Wachse ohne Grenzen.';

  @override
  String get paywallHeroDescription => 'Dein persönlicher KI-Assistent — Bewässerungserinnerungen, Gesundheitschecks, saisonale Tipps und alles, was du brauchst, damit deine Pflanzen gedeihen.';

  @override
  String get paywallChoosePlan => 'PLAN WÄHLEN';

  @override
  String paywallPerMonth(Object price) {
    return 'Nur $price / Monat';
  }

  @override
  String get paywallStartPremium => 'Premium starten';

  @override
  String get paywallSecured => 'Stripe gesichert';

  @override
  String get paywallSecuredApple => 'Gesichert';

  @override
  String get paywallCancelAnytime => 'Jederzeit kündbar';

  @override
  String get paywallAutoRenews => 'automatische Verlängerung';

  @override
  String get stripeSuccessTitle => 'Abonnement aktiviert!';

  @override
  String get stripeSuccessWaiting => 'Dein Abonnement wird aktiviert';

  @override
  String get stripeSuccessSubtitle => 'Willkommen bei Botanly Premium! Du hast jetzt Zugang zu allen Funktionen.';

  @override
  String get stripeSuccessButton => 'Zu meinen Pflanzen';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'Abrechnungsportal konnte nicht geöffnet werden: $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Wiederherstellung fehlgeschlagen: $error';
  }

  @override
  String get emailCopied => 'E-Mail kopiert: support@botanly.app';

  @override
  String get labelExpires => 'Läuft ab';

  @override
  String get labelNextRenewal => 'Nächste Verlängerung';

  @override
  String get labelAutoRenewal => 'Automatische Verlängerung';

  @override
  String get labelRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get labelPlants => 'Pflanzen';

  @override
  String get labelRenews => 'Verlängerung';

  @override
  String get testWateringEmailQueued => 'Test-Bewässerungs-E-Mail in der Warteschlange.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'Test-E-Mail konnte nicht gesendet werden: $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'Erinnerungskanäle konnten nicht gespeichert werden: $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'Ruhestunden konnten nicht aktualisiert werden: $error';
  }

  @override
  String get deleteAccountTitle => 'Konto löschen';

  @override
  String get deleteAccountSubtitle => 'Konto dauerhaft deaktivieren';

  @override
  String get deleteAccountConfirmBody => 'Ihr Konto wird dauerhaft deaktiviert und Sie verlieren den Zugang zur App. Ihre Pflanzendaten bleiben erhalten.\n\nDiese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountAreYouSure => 'Sind Sie sicher?';

  @override
  String get deleteAccountTypeConfirm => 'Geben Sie DELETE zur Bestätigung ein:';

  @override
  String get deleteAccountConfirmBtn => 'Löschen bestätigen';

  @override
  String errorDeletingAccount(Object error) {
    return 'Konto konnte nicht gelöscht werden: $error';
  }

  @override
  String get subPillPremium => 'Premium';

  @override
  String get subPillEarlyMember => 'Frühes Mitglied';

  @override
  String get subPillFreePlan => 'Kostenloser Plan';

  @override
  String get subPillFreeTrial => 'Testphase';

  @override
  String get subMetaActivePlan => 'AKTIVER PLAN';

  @override
  String get subMetaForeverPremium => 'EWIGES PREMIUM';

  @override
  String get subMetaTrialEnded => 'TESTPHASE BEENDET';

  @override
  String subMetaNDayPreview(int n) {
    return '$n-TAGE VORSCHAU';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Verlängert in $days Tagen · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Endet in $days Tagen · $date';
  }

  @override
  String get subActiveSubscription => 'Aktives Abonnement';

  @override
  String get subGrantedEarlyMember => 'Als frühes Botanly-Mitglied gewährt';

  @override
  String get subDaysLeft => 'Tage übrig';

  @override
  String get subUntilPreviewEnds => 'bis zum Ende\nder Vorschau';

  @override
  String get subTrialEnded => 'Testphase\nbeendet';

  @override
  String get subAutoRenewOn => 'Automatische Verlängerung an  ·  Jederzeit kündbar';

  @override
  String get subAutoRenewOff => 'Automatische Verlängerung aus  ·  Zugang bis Ablauf';

  @override
  String get subDetails => 'Details';

  @override
  String get subReactivate => 'Reaktivieren';

  @override
  String get subNoChargesEver => 'Keine Gebühren, jemals  ·  Alle Vorteile freigeschaltet';

  @override
  String get subLimitedAccess => 'Eingeschränkter Zugang  ·  Kein KI-Care';

  @override
  String get subUnlimitedAccess => 'Unbegrenzt  ·  KI-Care  ·  Erinnerungen';

  @override
  String get subHeroYourePrefix => 'Du ';

  @override
  String get subHeroGrowingWord => 'wächst';

  @override
  String get subHeroForeverWord => 'Für immer';

  @override
  String get subHeroPremiumSuffix => ' Premium';

  @override
  String get labelEnds => 'Endet';

  @override
  String get labelPlan => 'Plan';

  @override
  String get labelPremium => 'Premium';

  @override
  String get labelGrandfathered => 'Übertragener Zugang';

  @override
  String get labelOn => 'An';

  @override
  String get labelOff => 'Aus';

  @override
  String get yourPlan => 'Dein Plan';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get manageBillingWeb => 'Abrechnung verwalten';

  @override
  String get manageInAppStore => 'Im App Store verwalten';

  @override
  String get manageBillingSubtitleWeb => 'Kündigen, Karte aktualisieren oder Rechnungen einsehen\nüber das Stripe-Abrechnungsportal.';

  @override
  String get manageBillingSubtitleAppStore => 'Um die automatische Verlängerung zu deaktivieren oder zu kündigen,\ngehen Sie zu Ihren App Store-Abonnements.';

  @override
  String get tipGoodLight => 'gutes Licht';

  @override
  String get tipShowLeaves => 'Blätter zeigen';

  @override
  String get tipSinglePlant => 'einzelne Pflanze';

  @override
  String get snapYourSprout => 'Fotografiere deinen Spross';

  @override
  String get identifyingPlantPrefix => 'Identifiziere deine ';

  @override
  String get identifyingPlantWord => 'Pflanze';

  @override
  String get identifyingSubtitle => 'Schaue uns Blätter, Stängel und benachbarte Pflanzen an';

  @override
  String get specificIssues => 'Spezifische Probleme';

  @override
  String get healthCheckPhotoHint => 'Füge bis zu 3 Fotos hinzu — mehr Blickwinkel bedeuten eine genauere Analyse. Nur das erste Foto ist erforderlich.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Ganze Pflanze';

  @override
  String get healthCheckSlot1Desc => 'Fotografiere die gesamte Pflanze einschließlich Topf — damit Erde und ganzer Topf sichtbar sind.';

  @override
  String get healthCheckSlot1Tag => 'Erforderlich';

  @override
  String get healthCheckSlot2Title => 'Nahaufnahme';

  @override
  String get healthCheckSlot2Desc => 'Komm näher heran, ohne Topf — damit Blätter und ihre Struktur klar sichtbar sind.';

  @override
  String get healthCheckSlot2Tag => 'Optional';

  @override
  String get healthCheckSlot3Title => 'Problembereich';

  @override
  String get healthCheckSlot3Desc => 'Möchtest du etwas Bestimmtes zeigen? Fotografiere einen Fleck, Schädling oder beschädigtes Blatt.';

  @override
  String get healthCheckSlot3Tag => 'Optional';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return '$count Foto(s) analysieren';
  }

  @override
  String get healthCheckError => 'Analyse fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get healthCheckDefaultPraise => '🌱 Deiner Pflanze geht es gut!';

  @override
  String get healthCheckDefaultFooter => 'Kümmere dich weiterhin um deine Pflanze gemäß den Empfehlungen und notiere, wenn du gießt.';

  @override
  String get addPlantWholePlantTitle => 'Ganze Pflanze';

  @override
  String get addPlantWholePlantDesc => 'mit Topf und Erde';

  @override
  String get addPlantWholePlantTag => 'Erforderlich';

  @override
  String get addPlantCloseUpTitle => 'Nahaufnahme';

  @override
  String get addPlantCloseUpDesc => 'Blätter im Detail';

  @override
  String get addPlantCloseUpTag => 'Optional';

  @override
  String get addPlantDualHint => 'Zwei Winkel helfen unserer KI, deine Pflanze genauer zu bestimmen.';

  @override
  String get addPlantAnalyzeButton => 'Pflanze analysieren';

  @override
  String get addPlantStepPhotosReceived => 'Fotos erhalten';

  @override
  String get addPlantStepIdentifying => 'Art bestimmen';

  @override
  String get addPlantStepCarePlan => 'Pflegeplan erstellen';

  @override
  String get addPlantAnalyzingTitle => 'Deine Pflanze wird analysiert';

  @override
  String get addPlantAnalyzingSubtitle => 'Das dauert normalerweise ein paar Sekunden…';

  @override
  String get addPlantAnalysisComplete => 'Analyse abgeschlossen';

  @override
  String get addPlantSeePlantProfile => 'Pflanzenprofil ansehen';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get onboarding1Eyebrow => 'Willkommen';

  @override
  String get onboarding1Title => 'Lern ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body => 'Dein KI-Begleiter für glückliche, gesunde Pflanzen — immer griffbereit.';

  @override
  String get onboarding2Eyebrow => 'Erkennen';

  @override
  String get onboarding2Title => 'Erkenne ';

  @override
  String get onboarding2TitleItalic => 'jede Pflanze';

  @override
  String get onboarding2Body => 'Halte die Kamera drauf — die KI bestimmt Art und Namen in Sekunden.';

  @override
  String get onboarding3Eyebrow => 'Pflege';

  @override
  String get onboarding3Title => 'Pflege leicht ';

  @override
  String get onboarding3TitleItalic => 'gemacht';

  @override
  String get onboarding3Body => 'Gieß-, Licht- und Erderinnerungen — perfekt auf jede deiner Pflanzen abgestimmt.';

  @override
  String get onboarding4Eyebrow => 'Gesundheits-Check';

  @override
  String get onboarding4Title => 'Probleme früh ';

  @override
  String get onboarding4TitleItalic => 'erkennen';

  @override
  String get onboarding4Body => 'Foto machen und sofort einen Gesundheits-Check mit klarem Lösungsplan erhalten.';

  @override
  String get onboarding5Eyebrow => 'Bereit';

  @override
  String get onboarding5Title => 'Lass uns ';

  @override
  String get onboarding5TitleItalic => 'zusammen wachsen';

  @override
  String get onboarding5Body => 'Bau dein Pflanzenregal auf und verpasse nichts mehr. Deine grünste Ära beginnt jetzt.';

  @override
  String get tabCare => 'Pflege';

  @override
  String get tabAbout => 'Info';

  @override
  String get tabHistory => 'Verlauf';

  @override
  String nDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get cycleJustStarted => 'Zyklus gerade gestartet';

  @override
  String cyclePercentComplete(int percent) {
    return 'Zyklus $percent% abgeschlossen';
  }

  @override
  String get wateringAmount => 'Menge';

  @override
  String get noDataAvailable => 'Noch keine Daten';

  @override
  String get healthCheckHistoryEmptyHint => 'Lade alle zwei Wochen ein Foto hoch — wir erstellen einen Gesundheitsverlauf';

  @override
  String milliliters(int count) {
    return '$count ml';
  }

  @override
  String get millilitersShort => 'ML';

  @override
  String nHours(String hours) {
    return '$hours Std.';
  }

  @override
  String get lightDaily => 'Täglich';

  @override
  String get lightType => 'Art';

  @override
  String get lightTypeDirect => 'Direkt';

  @override
  String get lightTypePartialSun => 'Halbschatten';

  @override
  String get lightTypeBrightIndirect => 'Hell indirekt';

  @override
  String get lightTypeLowLight => 'Wenig Licht';

  @override
  String get everyDay => 'Täglich';

  @override
  String get healthCheckSeverity => 'Schweregrad';

  @override
  String get healthCheckFollowUp => 'Nachkontrolle';

  @override
  String get severityLow => 'Niedrig';

  @override
  String get severityMedium => 'Mittel';

  @override
  String get severityHigh => 'Hoch';

  @override
  String get careKvFrequency => 'Häufigkeit';

  @override
  String get careKvSeason => 'Saison';

  @override
  String get careKvOptimal => 'Optimal';

  @override
  String get careKvMinimum => 'Minimum';

  @override
  String get careKvDose => 'Dosis';
}
