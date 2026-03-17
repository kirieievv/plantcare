import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Care'**
  String get appTitle;

  /// No description provided for @loadingPlantCare.
  ///
  /// In en, this message translates to:
  /// **'Loading Plant Care...'**
  String get loadingPlantCare;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myPlants.
  ///
  /// In en, this message translates to:
  /// **'My Plants'**
  String get myPlants;

  /// No description provided for @addPlant.
  ///
  /// In en, this message translates to:
  /// **'Add Plant'**
  String get addPlant;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get authenticationError;

  /// No description provided for @pleaseLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to continue'**
  String get pleaseLoginAgain;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @yourGardenOverview.
  ///
  /// In en, this message translates to:
  /// **'Your Garden Overview'**
  String get yourGardenOverview;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordAtLeast6;

  /// No description provided for @rememberMe30Days.
  ///
  /// In en, this message translates to:
  /// **'Remember me for 30 days'**
  String get rememberMe30Days;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @dontHaveAccountRegistration.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Registration'**
  String get dontHaveAccountRegistration;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @loggedIn.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get loggedIn;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @wateringReminders.
  ///
  /// In en, this message translates to:
  /// **'Watering Reminders'**
  String get wateringReminders;

  /// No description provided for @getNotifiedWhenPlantsNeedWater.
  ///
  /// In en, this message translates to:
  /// **'Get notified when plants need water'**
  String get getNotifiedWhenPlantsNeedWater;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @maxNotificationsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Max Notifications Per Day'**
  String get maxNotificationsPerDay;

  /// No description provided for @notificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications'**
  String notificationsCount(int count);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @checkNotificationSetupAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Check notification setup and permissions'**
  String get checkNotificationSetupAndPermissions;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @updateYourAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateYourAccountPassword;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfYourAccount;

  /// No description provided for @preferencesSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully!'**
  String get preferencesSavedSuccessfully;

  /// No description provided for @errorSavingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Error saving preferences: {error}'**
  String errorSavingPreferences(Object error);

  /// No description provided for @quietHoursUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours updated successfully!'**
  String get quietHoursUpdatedSuccessfully;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get enterNewPassword;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @confirmYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmYourNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get passwordChangedSuccessfully;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error changing password: {error}'**
  String errorChangingPassword(Object error);

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorUpdatingProfile(Object error);

  /// No description provided for @plantLover.
  ///
  /// In en, this message translates to:
  /// **'Plant Lover'**
  String get plantLover;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your plant care journey...'**
  String get bioHint;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Where are your plants located?'**
  String get locationHint;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @noPlantsYet.
  ///
  /// In en, this message translates to:
  /// **'No plants yet!'**
  String get noPlantsYet;

  /// No description provided for @addFirstPlantToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant to get started'**
  String get addFirstPlantToGetStarted;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(Object error);

  /// No description provided for @failedToAnalyzePlantPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze plant photo: {statusCode}'**
  String failedToAnalyzePlantPhoto(int statusCode);

  /// No description provided for @aiAnalysisCompleted.
  ///
  /// In en, this message translates to:
  /// **'AI analysis completed! 🌱'**
  String get aiAnalysisCompleted;

  /// No description provided for @aiAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'AI analysis failed: {error}'**
  String aiAnalysisFailed(Object error);

  /// No description provided for @apiTestError.
  ///
  /// In en, this message translates to:
  /// **'API test error: {error}'**
  String apiTestError(Object error);

  /// No description provided for @aiAnalysisRefreshed.
  ///
  /// In en, this message translates to:
  /// **'AI analysis refreshed! 🔄'**
  String get aiAnalysisRefreshed;

  /// No description provided for @aiAnalysisRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'AI analysis refresh failed: {error}'**
  String aiAnalysisRefreshFailed(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @uploadPlantPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Plant Photo'**
  String get uploadPlantPhoto;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @onceEvery7Days.
  ///
  /// In en, this message translates to:
  /// **'Once every 7 days'**
  String get onceEvery7Days;

  /// No description provided for @oncePerDay.
  ///
  /// In en, this message translates to:
  /// **'Once per day'**
  String get oncePerDay;

  /// No description provided for @oncePerWeek.
  ///
  /// In en, this message translates to:
  /// **'Once per week'**
  String get oncePerWeek;

  /// No description provided for @onceEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Once every {days} days'**
  String onceEveryNDays(int days);

  /// No description provided for @onceEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Once every {weeks} weeks'**
  String onceEveryNWeeks(int weeks);

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @mediumLow.
  ///
  /// In en, this message translates to:
  /// **'Medium-Low'**
  String get mediumLow;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @mediumHigh.
  ///
  /// In en, this message translates to:
  /// **'Medium-High'**
  String get mediumHigh;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @pleaseUploadPlantImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload a plant image'**
  String get pleaseUploadPlantImage;

  /// No description provided for @pleaseWaitForAiAnalysisBeforeAddingPlant.
  ///
  /// In en, this message translates to:
  /// **'Please wait for AI analysis to complete before adding the plant'**
  String get pleaseWaitForAiAnalysisBeforeAddingPlant;

  /// No description provided for @plantLowercase.
  ///
  /// In en, this message translates to:
  /// **'plant'**
  String get plantLowercase;

  /// No description provided for @plantAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Plant added successfully! 🌱'**
  String get plantAddedSuccessfully;

  /// No description provided for @errorAddingPlant.
  ///
  /// In en, this message translates to:
  /// **'Error adding plant: {error}'**
  String errorAddingPlant(Object error);

  /// No description provided for @generateRandomName.
  ///
  /// In en, this message translates to:
  /// **'Generate random name'**
  String get generateRandomName;

  /// No description provided for @plantName.
  ///
  /// In en, this message translates to:
  /// **'Plant Name'**
  String get plantName;

  /// No description provided for @plantNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Monstera, Snake Plant'**
  String get plantNameHint;

  /// No description provided for @pleaseEnterPlantName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a plant name'**
  String get pleaseEnterPlantName;

  /// No description provided for @addingPlant.
  ///
  /// In en, this message translates to:
  /// **'Adding Plant...'**
  String get addingPlant;

  /// No description provided for @analyzingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Photo...'**
  String get analyzingPhoto;

  /// No description provided for @plantUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Plant updated successfully! 🌱'**
  String get plantUpdatedSuccessfully;

  /// No description provided for @errorUpdatingPlant.
  ///
  /// In en, this message translates to:
  /// **'Error updating plant: {error}'**
  String errorUpdatingPlant(Object error);

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @wateringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Watering Frequency'**
  String get wateringFrequency;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days} day(s)'**
  String everyNDays(int days);

  /// No description provided for @pleaseSelectWateringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Please select watering frequency'**
  String get pleaseSelectWateringFrequency;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @loadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get loadingImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @errorDeletingPlant.
  ///
  /// In en, this message translates to:
  /// **'Error deleting plant: {error}'**
  String errorDeletingPlant(Object error);

  /// No description provided for @plantNotDueForWateringYet.
  ///
  /// In en, this message translates to:
  /// **'This plant is not due for watering yet'**
  String get plantNotDueForWateringYet;

  /// No description provided for @errorBuildingPlantDetailsScreen.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while building the PlantDetailsScreen: {error}'**
  String errorBuildingPlantDetailsScreen(Object error);

  /// No description provided for @aiCare.
  ///
  /// In en, this message translates to:
  /// **'AI Care'**
  String get aiCare;

  /// No description provided for @aiAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get aiAgent;

  /// No description provided for @plantChatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open plant chat'**
  String get plantChatOpen;

  /// No description provided for @plantChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat about {plantName}'**
  String plantChatTitle(Object plantName);

  /// No description provided for @plantChatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi! I am your plant assistant for {plantName}. Ask me anything about watering, health signs, or what to do next.'**
  String plantChatWelcome(Object plantName);

  /// No description provided for @plantChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about this plant...'**
  String get plantChatInputHint;

  /// No description provided for @plantChatLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get plantChatLoginAgain;

  /// No description provided for @plantChatRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Chat request failed'**
  String get plantChatRequestFailed;

  /// No description provided for @plantChatCouldNotGenerateResponse.
  ///
  /// In en, this message translates to:
  /// **'I could not generate a response. Please try again.'**
  String get plantChatCouldNotGenerateResponse;

  /// No description provided for @plantChatConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while contacting the plant assistant. Please try again.'**
  String get plantChatConnectionError;

  /// No description provided for @plantChatQuickWaterToday.
  ///
  /// In en, this message translates to:
  /// **'Can I water today?'**
  String get plantChatQuickWaterToday;

  /// No description provided for @plantChatQuickYellowLeaves.
  ///
  /// In en, this message translates to:
  /// **'Why are leaves turning yellow?'**
  String get plantChatQuickYellowLeaves;

  /// No description provided for @plantChatQuickWhatToDoNow.
  ///
  /// In en, this message translates to:
  /// **'What should I do now?'**
  String get plantChatQuickWhatToDoNow;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
