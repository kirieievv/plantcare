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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen',
      one: '$count Benachrichtigung',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Einmal alle $days Tage',
      one: 'Täglich',
    );
    return '$_temp0';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Einmal alle $weeks Wochen',
      one: 'Wöchentlich',
    );
    return '$_temp0';
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
  String get searchPlantsHint => 'Nach Name oder Art suchen';

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Vor $days Tagen',
      one: 'Vor $days Tag',
    );
    return '$_temp0';
  }

  @override
  String get healthStatusOk => 'In Ordnung';

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Nächste in $days Tagen',
      one: 'Nächste in $days Tag',
    );
    return '$_temp0';
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
  String get subscriptionUpgrade => 'Upgraden';

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
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage übrig',
      one: '$days Tag übrig',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-TAGE VORSCHAU',
      one: '$n-TAG VORSCHAU',
    );
    return '$_temp0';
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

  @override
  String get healthAnalyzeCta => 'Zustand prüfen';

  @override
  String get healthNeedsAttention => 'Braucht Aufmerksamkeit';

  @override
  String get healthStatusHealthy => 'Gesunde Pflanze';

  @override
  String get healthWhatToDo => 'Was zu tun ist';

  @override
  String get healthClose => 'Schließen';

  @override
  String get healthNotSavedYet => 'Noch nicht im Verlauf gespeichert';

  @override
  String get healthAskAssistant => 'Assistent fragen';

  @override
  String get healthAddedToPlan => 'Zum Plan hinzugefügt';

  @override
  String get healthLockedNeedsWatering => 'Gießen bestätigen, um erneut zu prüfen';

  @override
  String get healthLockedLimitReached => 'Prüfungen für diesen Zyklus aufgebraucht';

  @override
  String get healthAdviceSub => 'Sehen, was zu tun ist';

  @override
  String get healthAnalyzingTitle => 'Analyse läuft…';

  @override
  String get healthStepRecognize => 'Pflanze wird erkannt';

  @override
  String get healthStepCompare => 'Vergleich mit früheren Prüfungen';

  @override
  String get healthStepAdvice => 'Empfehlungen werden erstellt';

  @override
  String healthStepPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos erhalten',
      one: '1 Foto erhalten',
    );
    return '$_temp0';
  }

  @override
  String healthAdviceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Empfehlungen nach der Prüfung',
      one: '1 Empfehlung nach der Prüfung',
    );
    return '$_temp0';
  }

  @override
  String get healthHistoryLoadFailed => 'Verlauf konnte nicht geladen werden';

  @override
  String get healthUpToThreePhotos => 'Bis zu 3 Fotos';

  @override
  String get healthResultTitle => 'Ergebnis';

  @override
  String get taskAllDone => 'Alles erledigt — der Pflanze geht es gut';

  @override
  String get taskBadgeScheduled => 'Nach Plan';

  @override
  String get taskBadgeAnalysis => 'Nach der Analyse';

  @override
  String taskBadgeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage überfällig',
      one: '1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get taskDone => 'Fertig';

  @override
  String get taskDoneAlready => 'Erledigt';

  @override
  String get taskLater => 'Später';

  @override
  String get taskAskAssistant => 'Assistent fragen';

  @override
  String taskAskQuestion(String title) {
    return 'Was ist bei der Aufgabe „$title“ zu tun?';
  }

  @override
  String get homeGardenTitleLead => 'Dein';

  @override
  String get homeGardenTitleAccent => 'Garten';

  @override
  String get gardenHealthLabel => 'Gartengesundheit';

  @override
  String get gardenAllGood => 'Allen Pflanzen geht es gut';

  @override
  String gardenOneWeak(String name) {
    return '$name zieht den Garten runter';
  }

  @override
  String gardenManyWeak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen brauchen deine Pflege',
      one: '1 Pflanze braucht deine Pflege',
    );
    return '$_temp0';
  }

  @override
  String get homeOrbitHint => 'Tippe auf eine Pflanze, um sie zu öffnen';

  @override
  String get homeAllTasksLink => 'Alle Aufgaben';

  @override
  String get deckAllClearTitle => 'Der Garten ist in Ordnung';

  @override
  String taskOverdueShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get taskPostponed => 'Verschoben';

  @override
  String get allTasksTitle => 'Alle Aufgaben';

  @override
  String allTasksSubtitle(int today, int later) {
    return '$today heute · $later später';
  }

  @override
  String get allTasksToday => 'Heute';

  @override
  String get allTasksLater => 'Später';

  @override
  String get allTasksRuleNote => 'Neue Aufgaben erscheinen erst, wenn die heutigen erledigt sind.';

  @override
  String get allTasksNothingToday => 'Für heute ist nichts mehr offen';

  @override
  String get whenTomorrow => 'Morgen';

  @override
  String get whenInAWeek => 'In einer Woche';

  @override
  String whenInNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen',
      one: 'In 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String careAskAbout(String title) {
    return 'Assistent zu $title fragen';
  }

  @override
  String careAskQuestion(String title) {
    return 'Erzähl mir mehr über „$title“ für meine Pflanze';
  }

  @override
  String get healthAskQuestionIssue => 'Was soll ich nach der Analyse zuerst tun?';

  @override
  String get healthAskQuestionOk => 'Die Prüfung sagt, die Pflanze ist gesund — was ließe sich verbessern?';

  @override
  String get glassesOne => '1 Glas';

  @override
  String glassesAmount(String value) {
    return '$value Gläser';
  }

  @override
  String addPlantStepOf(int step, int total) {
    return 'Schritt $step von $total';
  }

  @override
  String get addPlantTitleLead => 'Pflanze';

  @override
  String get addPlantTitleAccent => 'hinzufügen';

  @override
  String get addPlantNameHint => 'Wie soll sie heißen — Monty, Ficus junior, Monstera. Der Würfel wählt für dich.';

  @override
  String get addPlantPhotosTitle => 'Fotos';

  @override
  String get addPlantWholePlant => 'Ganze Pflanze';

  @override
  String get addPlantWholePlantHint => 'mit Topf und Erde';

  @override
  String get addPlantRequired => 'Nötig';

  @override
  String get addPlantTwoAnglesHint => 'Zwei Perspektiven bestimmen die Art genauer — das zweite Foto ist optional, hilft aber.';

  @override
  String get addPlantTipLight => 'gutes Licht';

  @override
  String get addPlantTipLeaves => 'Blätter sichtbar';

  @override
  String get addPlantTipSingle => 'eine Pflanze';

  @override
  String get addPlantIdentifyCta => 'Art bestimmen';

  @override
  String get addPlantRandomNames => 'Monty|Sprössling|Ficus junior|Farni|Basilikus|Blattmann|Sonnie|Pip';

  @override
  String get addPlantIsThisYourPlant => 'Ist das deine Pflanze?';

  @override
  String get addPlantPickSpeciesHint => 'Wähle die passendste Variante — davon hängt der Pflegeplan ab.';

  @override
  String get addPlantNoneMatch => 'Nichts passt — ich gebe sie ein';

  @override
  String get addPlantManualHint => 'Gib den Artnamen ein, wir suchen erneut.';

  @override
  String get addPlantManualPlaceholder => 'Zum Beispiel, Monstera deliciosa';

  @override
  String get addPlantBuildPlanCta => 'Pflegeplan erstellen';

  @override
  String addPlantStartingScore(int score) {
    return 'Startwert $score';
  }

  @override
  String get addPlantPlanWatering => 'Gießen';

  @override
  String get addPlantPlanLight => 'Licht';

  @override
  String get addPlantPlanSoil => 'Erde';

  @override
  String get addPlantSoilSlightlyMoist => 'Leicht feucht';

  @override
  String addPlantEveryNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Alle $days Tage',
      one: 'Täglich',
    );
    return '$_temp0';
  }

  @override
  String get addPlantCarePlan => 'Pflegeplan';

  @override
  String addPlantNTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben',
      one: '1 Aufgabe',
    );
    return '$_temp0';
  }

  @override
  String get addPlantFirstWatering => 'Erstes Gießen';

  @override
  String get addPlantToday => 'heute';

  @override
  String get addPlantWaterToday => 'heute';

  @override
  String get addPlantFertilising => 'Düngen';

  @override
  String get addPlantFertilisingDetail => 'In zwei Wochen · halbe Dosis';

  @override
  String get addPlantHealthCheck => 'Gesundheitscheck';

  @override
  String get addPlantHealthCheckDetail => 'In einem Monat · 1–3 Fotos';

  @override
  String get addPlantAddToGarden => 'Zum Garten hinzufügen';

  @override
  String get addPlantNoSpeciesFound => 'Die Pflanze wurde nicht erkannt. Versuch ein anderes Foto.';

  @override
  String get addPlantNoPlan => 'Der Pflegeplan konnte nicht erstellt werden. Versuch es noch einmal.';

  @override
  String get addPlantLoaderPhotos => 'Fotos erhalten';

  @override
  String get addPlantLoaderIdentify => 'Art wird bestimmt';

  @override
  String get addPlantLoaderPlan => 'Pflegeplan wird erstellt';

  @override
  String get myPlantsTitleLead => 'Meine';

  @override
  String get myPlantsTitleAccent => 'Pflanzen';

  @override
  String myPlantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen',
      one: '1 Pflanze',
    );
    return '$_temp0';
  }

  @override
  String get myPlantsEmptyLabel => 'Noch nichts da';

  @override
  String get filterTomorrow => 'Morgen';

  @override
  String get filterNeedsCare => 'Braucht Pflege';

  @override
  String get myPlantsNothingFound => 'Nichts gefunden';

  @override
  String get myPlantsNothingFoundHint => 'Versuch einen anderen Namen oder eine andere Art.';

  @override
  String get myPlantsAllClearTitle => 'Alles in Ordnung';

  @override
  String get myPlantsAllClearHint => 'In dieser Gruppe ist gerade nichts — kein Grund zur Sorge.';

  @override
  String get addFirstPlantHint => 'Add your first plant to get started';

  @override
  String get subHeroActiveLead => 'Dein Garten ist';

  @override
  String get subHeroActiveAccent => 'in guten Händen';

  @override
  String get subHeroForeverLead => 'Premium';

  @override
  String get subHeroForeverAccent => 'für immer';

  @override
  String get subHeroEndedLead => 'Der Testzeitraum ist';

  @override
  String get subHeroEndedAccent => 'vorbei';

  @override
  String get subMetaNoCharges => 'Keine Abbuchungen';

  @override
  String get subFootAutoRenew => 'Automatische Verlängerung an · Jederzeit kündbar';

  @override
  String get subFootTrial => 'Ohne Limits · KI-Pflege · Erinnerungen';

  @override
  String get subFootForever => 'Alle Funktionen freigeschaltet';

  @override
  String get subFootFree => 'Eingeschränkter Zugang · Ohne KI-Pflege';

  @override
  String get subCtaDetails => 'Details';

  @override
  String get subCtaResume => 'Fortsetzen';

  @override
  String subTrialUntil(String date) {
    return 'Testzeitraum bis $date';
  }

  @override
  String subEndedOn(String date) {
    return 'Beendet am $date';
  }

  @override
  String get subscriptionManageTitle => 'Abo';

  @override
  String get subscriptionPlanLabel => 'Tarif';

  @override
  String get subscriptionNextChargeLabel => 'Nächste Abbuchung';

  @override
  String get subscriptionAutoRenewLabel => 'Automatische Verlängerung';

  @override
  String get subscriptionAutoRenewOn => 'An';

  @override
  String get subscriptionAutoRenewOff => 'Aus';

  @override
  String get subscriptionManageInStore => 'Die Abrechnung läuft über den App Store. Ändern oder kündigen unter Einstellungen → Apple-ID → Abos.';

  @override
  String get deleteAccountContinue => 'Weiter';

  @override
  String get deleteAccountKeyword => 'LÖSCHEN';

  @override
  String deleteAccountTypeWord(String word) {
    return 'Gib zur Bestätigung $word ein.';
  }

  @override
  String get settingsSavedToast => 'Einstellungen gespeichert!';

  @override
  String get quietHoursUpdatedToast => 'Ruhezeiten aktualisiert!';

  @override
  String get signedInChip => 'Angemeldet';

  @override
  String get securityLabel => 'Sicherheit';

  @override
  String get emailNotificationsLabel => 'Email';

  @override
  String get changePasswordHint => 'Mindestens 6 Zeichen';

  @override
  String get quietHoursNeedsPush => 'Schalte Push ein, um Ruhezeiten zu nutzen';

  @override
  String get quietHoursFrom => 'Von';

  @override
  String get quietHoursTo => 'Bis';

  @override
  String quietHoursSummary(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden am Stück keine Benachrichtigungen',
      one: '1 Stunde am Stück keine Benachrichtigungen',
    );
    return '$_temp0';
  }

  @override
  String get passwordTooShortError => 'Das neue Passwort muss mindestens 6 Zeichen haben.';

  @override
  String get passwordSameAsCurrentError => 'Das neue Passwort muss sich vom aktuellen unterscheiden.';

  @override
  String get passwordsDoNotMatchError => 'Die Passwörter stimmen nicht überein.';

  @override
  String get passwordCurrentWrongError => 'Das aktuelle Passwort ist falsch.';

  @override
  String get subscriptionLoading => 'Plan wird geladen…';

  @override
  String get editPlantTitle => 'Bearbeiten';

  @override
  String get newPhotoBadge => 'Neues Foto';

  @override
  String get revertPhoto => 'Vorheriges Foto wiederherstellen';

  @override
  String get editPlantNameHint => 'So heißt die Pflanze im Garten und in den Erinnerungen';

  @override
  String get aiManagedNote => 'Art und Pflegeplan bestimmt die KI — sie werden nach einem neuen Gesundheitscheck aktualisiert.';

  @override
  String get noPhotoYet => 'Noch kein Foto';

  @override
  String get gardenLoadError => 'Der Garten konnte nicht geladen werden. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get pullToRefreshHint => 'Zum Aktualisieren nach unten ziehen';

  @override
  String get refreshingGarden => 'Gartendaten werden gesammelt…';

  @override
  String get refreshFailed => 'Aktualisieren fehlgeschlagen. Prüfe die Verbindung.';

  @override
  String addPlantHeaderPhoto(String accent) {
    return '$accent hinzufügen';
  }

  @override
  String get addPlantHeaderPhotoAccent => 'Pflanze';

  @override
  String addPlantHeaderSpecies(String accent) {
    return '$accent bestätigen';
  }

  @override
  String get addPlantHeaderSpeciesAccent => 'Art';

  @override
  String addPlantHeaderConditions(String accent) {
    return 'Zu den $accent';
  }

  @override
  String get addPlantHeaderConditionsAccent => 'Bedingungen';

  @override
  String addPlantHeaderPlan(String accent) {
    return '${accent}plan';
  }

  @override
  String get addPlantHeaderPlanAccent => 'Pflege';

  @override
  String get addPlantBack => 'Zurück';

  @override
  String quizQuestionOf(int step, int total) {
    return 'Frage $step von $total';
  }

  @override
  String get quizNext => 'Weiter';

  @override
  String get quizBuildPlan => 'Plan erstellen';

  @override
  String quizPotQuestion(String accent) {
    return 'Welchen $accent hat der Topf?';
  }

  @override
  String get quizPotQuestionAccent => 'Durchmesser';

  @override
  String get quizPotWhy => 'Das Erdvolumen bestimmt, wie viel Wasser eine Gabe braucht.';

  @override
  String get quizPotHint => 'Am Topfrand messen, nicht an der Pflanze.';

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
    return '$volume pro Gabe';
  }

  @override
  String quizMaterialQuestion(String accent) {
    return 'Woraus ist der Topf, und hat er $accent?';
  }

  @override
  String get quizMaterialQuestionAccent => 'Abzugslöcher';

  @override
  String get quizMaterialWhy => 'Terrakotta trocknet doppelt so schnell wie Kunststoff. Ohne Löcher steigt das Risiko von Wurzelfäule.';

  @override
  String get quizMatPlastic => 'Kunststoff';

  @override
  String get quizMatPlasticDesc => 'Hält Feuchtigkeit länger';

  @override
  String get quizMatCeramic => 'Keramik';

  @override
  String get quizMatCeramicDesc => 'Glasiert, atmet nicht';

  @override
  String get quizMatTerracotta => 'Terrakotta';

  @override
  String get quizMatTerracottaDesc => 'Atmet, trocknet schnell';

  @override
  String get quizMatUnknown => 'Weiß ich nicht';

  @override
  String get quizMatUnknownDesc => 'Wir nehmen den Mittelwert';

  @override
  String get quizDrainageLabel => 'Abzugslöcher';

  @override
  String get quizDrainageYes => 'Ja';

  @override
  String get quizDrainageYesDesc => 'Überschüssiges Wasser läuft in den Untersetzer';

  @override
  String get quizDrainageNo => 'Nein';

  @override
  String get quizDrainageNoDesc => 'Wasser steht an den Wurzeln';

  @override
  String quizPlaceQuestion(String accent) {
    return 'Wo $accent die Pflanze?';
  }

  @override
  String get quizPlaceQuestionAccent => 'steht';

  @override
  String get quizPlaceWhy => 'So wissen wir, wie viel Licht sie wirklich bekommt — und ob sie Schatten braucht.';

  @override
  String get quizPlaceSouth => 'Süden';

  @override
  String get quizPlaceSouthDesc => 'Fensterbank, viel Sonne';

  @override
  String get quizPlaceEast => 'Osten / Westen';

  @override
  String get quizPlaceEastDesc => 'Sanfte Morgensonne';

  @override
  String get quizPlaceNorth => 'Norden';

  @override
  String get quizPlaceNorthDesc => 'Licht ja, Sonne nein';

  @override
  String get quizPlaceRoom => 'Mitten im Raum';

  @override
  String get quizPlaceRoomDesc => 'Weit vom Fenster';

  @override
  String get quizPlaceBalcony => 'Balkon';

  @override
  String get quizPlaceBalconyDesc => 'Draußen, saisonal';

  @override
  String get quizPlaceBath => 'Badezimmer';

  @override
  String get quizPlaceBathDesc => 'Feucht, wenig Licht';

  @override
  String get quizHeatLabel => 'Heizung oder Klimaanlage in der Nähe';

  @override
  String get quizHeatNo => 'Nein';

  @override
  String get quizHeatNoDesc => 'Normale Raumluft';

  @override
  String get quizHeatYes => 'Ja';

  @override
  String get quizHeatYesDesc => 'Trocknet Erde und Luft aus';

  @override
  String quizWaterQuestion(String accent) {
    return 'Wann hast du $accent gegossen?';
  }

  @override
  String get quizWaterQuestionAccent => 'zuletzt';

  @override
  String get quizWaterWhy => 'Davon hängt das Datum der ersten Gabe ab — sonst wird die Aufgabe blind gesetzt.';

  @override
  String get quizWaterToday => 'Heute';

  @override
  String get quizWaterTodayDesc => 'Die Erde ist noch feucht';

  @override
  String get quizWaterFewDays => 'Vor 2–3 Tagen';

  @override
  String get quizWaterFewDaysDesc => 'Die obere Schicht ist trocken';

  @override
  String get quizWaterWeek => 'Vor etwa einer Woche';

  @override
  String get quizWaterWeekDesc => 'Wahrscheinlich Zeit zu gießen';

  @override
  String get quizWaterUnknown => 'Weiß ich nicht';

  @override
  String get quizWaterUnknownDesc => 'Wir prüfen Foto und Erde';

  @override
  String get addPlantPlanTuned => 'Nach deinen Antworten erstellt';

  @override
  String get addPlantCheckToday => 'heute prüfen';

  @override
  String get placeLightSouth => '6–8 Std.';

  @override
  String get placeLightEast => '4–6 Std.';

  @override
  String get placeLightNorth => '2–3 Std.';

  @override
  String get placeLightRoom => 'Wenig Licht';

  @override
  String get placeLightBalcony => '6–9 Std.';

  @override
  String get placeLightBath => '2–3 Std.';

  @override
  String get soilModerate => 'Mäßig feucht';

  @override
  String get addPlantAddLight => 'Mehr Licht';

  @override
  String get addPlantAddLightDetail => 'Näher ans Fenster oder Pflanzenlampe für 4–6 Std.';

  @override
  String get addPlantAddDrainage => 'Für Abzug sorgen';

  @override
  String get addPlantAddDrainageDetail => 'Ohne Löcher steht das Wasser an den Wurzeln';

  @override
  String get addPlantMoveFromHeat => 'Von der Wärme wegstellen';

  @override
  String get addPlantMoveFromHeatDetail => 'Die Heizung trocknet die Erde aus';

  @override
  String get lockedLabelTrial => 'Hinzufügen pausiert';

  @override
  String get lockedLabelLimit => 'Limit des Gratisplans';

  @override
  String get lockedLabelCancelled => 'Abo gekündigt';

  @override
  String get lockedPillTrial => 'Testphase beendet';

  @override
  String lockedPillLimit(int count, int limit) {
    return 'Gratisplan · $count von $limit';
  }

  @override
  String get lockedPillCancelled => 'Zugang beendet';

  @override
  String lockedLeadTrial(String accent) {
    return 'Neue Pflanzen $accent';
  }

  @override
  String get lockedLeadTrialAccent => 'warten auf ein Abo';

  @override
  String lockedLeadLimit(String accent) {
    return 'Der Gratisplan fasst $accent';
  }

  @override
  String lockedLeadLimitAccent(int limit) {
    return '$limit Pflanzen';
  }

  @override
  String lockedLeadCancelled(String accent) {
    return 'Das Abo $accent';
  }

  @override
  String get lockedLeadCancelledAccent => 'ist nicht aktiv';

  @override
  String lockedSubTrial(String date) {
    return 'Die Testphase endete am $date';
  }

  @override
  String get lockedSubLimit => 'Ein Abo hebt das Limit auf — beliebig viele Pflanzen.';

  @override
  String lockedSubCancelled(String date) {
    return 'Premium war aktiv bis $date';
  }

  @override
  String get lockedKeepTitle => 'Was bleibt';

  @override
  String get lockedUnlockTitle => 'Was ein Abo zurückbringt';

  @override
  String lockedKeepPlants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen in Obhut',
      one: '1 Pflanze in Obhut',
    );
    return '$_temp0';
  }

  @override
  String get lockedKeepPlantsDesc => 'Sie bleiben im Garten samt ihrer Prüf-Historie';

  @override
  String get lockedKeepReminders => 'Gieß-Erinnerungen';

  @override
  String get lockedKeepRemindersDesc => 'Kommen weiterhin wie bisher';

  @override
  String get lockedUnlockNewPlants => 'Neue Pflanzen';

  @override
  String get lockedUnlockNewPlantsDesc => 'Art per Foto bestimmen und ein eigener Pflegeplan';

  @override
  String get lockedUnlockHealth => 'Gesundheitscheck';

  @override
  String get lockedUnlockHealthDesc => 'Fotoanalyse, Zustandswert und Empfehlungen';

  @override
  String get lockedUnlockChat => 'KI-Assistent';

  @override
  String get lockedUnlockChatDesc => 'Antworten zu jeder Pflanze samt ihrer Bedingungen';

  @override
  String get lockedPlanYear => 'Jahr';

  @override
  String get lockedPlanMonth => 'Monat';

  @override
  String get lockedPlanYearNote => '21,99 \$ pro Jahr · 1,83 \$ pro Monat';

  @override
  String get lockedPlanMonthNote => '1,99 \$ pro Monat · jederzeit kündbar';

  @override
  String get lockedPlanBadge => 'Günstiger';

  @override
  String get lockedFinePrint => 'Das Abo verlängert sich automatisch. Jederzeit in den Store-Einstellungen kündbar.';

  @override
  String lockedCtaResume(String plan) {
    return 'Fortsetzen · $plan';
  }

  @override
  String lockedCtaUpgrade(String plan) {
    return 'Upgraden · $plan';
  }

  @override
  String get lockedRestore => 'Käufe wiederherstellen';

  @override
  String get lockedRestoreDone => 'Käufe wiederhergestellt';

  @override
  String get lockedRestoreNothing => 'Auf diesem Konto gibt es nichts wiederherzustellen';

  @override
  String get billingIssueTitle => 'Eine Zahlung ist fehlgeschlagen';

  @override
  String get billingIssueBody => 'Prüfen Sie Ihre Zahlungsmethode — der Zugang bleibt, solange der Store es erneut versucht.';

  @override
  String get duplicateSubscriptionTitle => 'Zwei Abos gefunden';

  @override
  String get duplicateSubscriptionBody => 'Sie zahlen gleichzeitig im App Store und im Web. Kündigen Sie eines davon.';

  @override
  String get gateBarTitleTrial => 'Testphase beendet';

  @override
  String get gateBarTitleExpired => 'Abo ist nicht aktiv';

  @override
  String get gateBarBody => 'Gießen läuft weiter; Analyse und Assistent brauchen ein Abo';

  @override
  String get gateBarAction => 'Fortsetzen';

  @override
  String get gateStaleScore => 'Der Wert wird nicht aktualisiert — dafür braucht es einen Gesundheitscheck';

  @override
  String gateSheetHealth(String accent) {
    return 'Gesundheitscheck $accent';
  }

  @override
  String gateSheetChat(String accent) {
    return 'Der KI-Assistent $accent';
  }

  @override
  String get gateSheetAccent => 'braucht ein Abo';

  @override
  String get gateSheetBody => 'Die Testphase ist beendet. Die Pflanze und ihre Pflege bleiben — zurück kommt nur das, was die KI berechnet.';

  @override
  String get gateSheetKeepWatering => 'Gießen und Erinnerungen laufen weiter';

  @override
  String get gateSheetKeepHistory => 'Prüf-Historie und Pflegekarten bleiben zugänglich';

  @override
  String get gateSheetCta => 'Abo fortsetzen';

  @override
  String get gateSheetLater => 'Später';

  @override
  String get limitLabel => 'Alle Plätze belegt';

  @override
  String limitCountOf(int limit) {
    return 'von $limit Plätzen';
  }

  @override
  String get limitPlanTrial => 'Testphase';

  @override
  String get limitPlanFree => 'Gratisplan';

  @override
  String get limitPlanPremium => 'Premium';

  @override
  String get limitLegendUsed => 'Belegt';

  @override
  String get limitLegendLocked => 'Öffnet sich mit Premium';

  @override
  String limitLeadTrial(String accent) {
    return 'Es gibt $accent';
  }

  @override
  String get limitLeadTrialAccent => 'keine freien Plätze mehr';

  @override
  String limitLeadFree(String accent) {
    return 'Der Gratisplan hat $accent';
  }

  @override
  String limitLeadFreeAccent(int limit) {
    return '$limit Plätze';
  }

  @override
  String limitLeadPremium(String accent) {
    return 'Alle zehn Plätze $accent';
  }

  @override
  String get limitLeadPremiumAccent => 'sind belegt';

  @override
  String get limitBody => 'Machen Sie einen Platz frei oder öffnen Sie zehn.';

  @override
  String get limitBodyPremium => 'Entfernen Sie eine Pflanze, die Sie nicht mehr haben, um Platz zu schaffen.';

  @override
  String get limitPathUpgrade => '10 Plätze öffnen';

  @override
  String get limitPathUpgradeDesc => 'Zusammen mit Gesundheitscheck und Assistent';

  @override
  String get limitPathFree => 'Platz frei machen';

  @override
  String get limitPathFreeDesc => 'Eine Pflanze entfernen, die Sie nicht mehr haben';

  @override
  String get limitPremiumTitle => 'Premium';

  @override
  String limitCtaUpgrade(String plan) {
    return 'Upgraden · $plan';
  }

  @override
  String get weatherDetectedByNetwork => 'Über das Netzwerk ermittelt';

  @override
  String get profileCityLabel => 'Stadt';

  @override
  String get profileCityHint => 'Beeinflusst die Pflegeempfehlungen';

  @override
  String get unitsTemperature => 'Temperatureinheiten';

  @override
  String get unitsCelsius => '°C';

  @override
  String get unitsFahrenheit => '°F';

  @override
  String get unitsAutomatic => 'Automatisch';

  @override
  String weatherDegrees(String value) {
    return '$value°';
  }

  @override
  String get chatProposalApply => 'Übernehmen';

  @override
  String get chatProposalDecline => 'Nein danke';

  @override
  String get chatProposalApplied => 'Übernommen';

  @override
  String get chatProposalDeclined => 'Abgelehnt';

  @override
  String get chatProposalOutdated => 'Veraltet';

  @override
  String get chatProposalPot => 'Topf';

  @override
  String get chatProposalSpecies => 'Art';

  @override
  String get chatProposalPause => 'Erinnerungen pausieren bis';

  @override
  String chatProposalChange(String label, String from, String to) {
    return '$label: $from → $to';
  }

  @override
  String chatProposalSet(String label, String to) {
    return '$label: $to';
  }

  @override
  String get chatTopicWater => 'Gießen';

  @override
  String get chatTopicSoil => 'Erde';

  @override
  String get chatTopicLight => 'Licht';

  @override
  String get chatTopicTemperature => 'Temperatur';

  @override
  String get chatTopicFertilizer => 'Dünger';

  @override
  String get chatTopicDiagnostics => 'Diagnose';

  @override
  String get chatShowWholeConversation => 'Ganzes Gespräch anzeigen';

  @override
  String chatTitleWithTopic(String topic) {
    return 'Assistent · $topic';
  }

  @override
  String get plantChatQuickWaterEarly => 'Kann ich früher gießen?';

  @override
  String get plantChatQuickSoilSlowToDry => 'Warum trocknet die Erde so langsam?';

  @override
  String get plantChatQuickEnoughLight => 'Bekommt sie genug Licht?';

  @override
  String get plantChatQuickLeggyGrowth => 'Warum wird sie so lang?';

  @override
  String get plantChatQuickShouldMove => 'Sollte ich sie umstellen?';

  @override
  String get plantChatQuickRepotWhen => 'Wann sollte ich umtopfen?';

  @override
  String get plantChatQuickSoilCompacted => 'Warum ist die Erde hart geworden?';

  @override
  String get plantChatQuickWhichSoil => 'Welche Erde ist am besten?';

  @override
  String get memoryTitle => 'Was der Assistent weiß';

  @override
  String get memoryExplainer => 'Aus Ihren Nachrichten im Chat übernommen. Entfernen Sie Falsches — es fließt in jede Antwort ein.';

  @override
  String get memoryLoadFailed => 'Konnte nicht geladen werden.';

  @override
  String get memorySuperseded => 'ersetzt';

  @override
  String get memoryForgetConfirm => 'Das vergessen?';

  @override
  String get memoryForgetAction => 'Vergessen';

  @override
  String get memoryKindPlacement => 'Standort';

  @override
  String get memoryKindContainer => 'Topf';

  @override
  String get memoryKindWateringHabit => 'Pflegegewohnheiten';

  @override
  String get memoryKindSpecies => 'Art';

  @override
  String get memoryKindEnvironment => 'Bedingungen';

  @override
  String get memoryKindIntervention => 'Durchgeführt';

  @override
  String get memoryKindSymptom => 'Symptom';

  @override
  String get memoryKindConstraint => 'Einschränkung';

  @override
  String get memoryKindGoal => 'Ziel';

  @override
  String get memoryKindPreference => 'Vorliebe';

  @override
  String memoryEmpty(String name) {
    return 'Noch nichts. Was Sie dem Assistenten über $name erzählen, steht hier.';
  }

  @override
  String get chatTaskOffer => 'Erinnerung setzen?';

  @override
  String chatTaskInDays(int days) {
    return 'in $days Tagen';
  }

  @override
  String get chatTaskCreated => 'Erinnerung gesetzt';
}
