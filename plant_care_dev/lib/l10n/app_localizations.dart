import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('uk')
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
  /// **'Garden Overview'**
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

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

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
  /// **'{count, plural, one{{count} notification} other{{count} notifications}}'**
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

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get ukrainian;

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

  /// No description provided for @addYourFirstPlant.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant'**
  String get addYourFirstPlant;

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
  /// **'{days, plural, one{Every day} other{Once every {days} days}}'**
  String onceEveryNDays(int days);

  /// No description provided for @onceEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, one{Every week} other{Once every {weeks} weeks}}'**
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
  /// **'{days, plural, one{Every {days} day} other{Every {days} days}}'**
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

  /// No description provided for @plantChatImageQuotaReached.
  ///
  /// In en, this message translates to:
  /// **'Daily photo limit reached. Try again tomorrow.'**
  String get plantChatImageQuotaReached;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your smart plant companion'**
  String get splashTagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @splashDescription.
  ///
  /// In en, this message translates to:
  /// **'Monitor your plants, get personalised care tips,\nand track their health — all in one place.'**
  String get splashDescription;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @errorInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. Please try again.'**
  String get errorInvalidPin;

  /// No description provided for @errorPinExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired. Please request a new one.'**
  String get errorPinExpired;

  /// No description provided for @errorPinNotFound.
  ///
  /// In en, this message translates to:
  /// **'No code found. Please request a new one.'**
  String get errorPinNotFound;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please request a new code.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Please try again.'**
  String get errorSendFailed;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// No description provided for @errorEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailAlreadyExists;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetYourPassword;

  /// No description provided for @enterEmailForCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email to receive a verification code.'**
  String get enterEmailForCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @weSentACodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get weSentACodeTo;

  /// No description provided for @verificationCodeSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent again.'**
  String get verificationCodeSentAgain;

  /// No description provided for @resendCodeInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeInSeconds(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully. Please sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @totalPlants.
  ///
  /// In en, this message translates to:
  /// **'Total Plants'**
  String get totalPlants;

  /// No description provided for @needWater.
  ///
  /// In en, this message translates to:
  /// **'Need Water'**
  String get needWater;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @yourPlants.
  ///
  /// In en, this message translates to:
  /// **'My Plants'**
  String get yourPlants;

  /// No description provided for @plantCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Plant created successfully! 🌱'**
  String get plantCreatedSuccessfully;

  /// No description provided for @searchPlantsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or species'**
  String get searchPlantsHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noResultsTitle;

  /// No description provided for @noResultsSub.
  ///
  /// In en, this message translates to:
  /// **'Try another search or filter.'**
  String get noResultsSub;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @wateringRemindersBlockSub.
  ///
  /// In en, this message translates to:
  /// **'Get notified when your plants need water.'**
  String get wateringRemindersBlockSub;

  /// No description provided for @emailRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Email reminders'**
  String get emailRemindersTitle;

  /// No description provided for @emailRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Receive watering reminders by email'**
  String get emailRemindersSub;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotificationsTitle;

  /// No description provided for @pushNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Get instant alerts on your device'**
  String get pushNotificationsSub;

  /// No description provided for @quietHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHoursLabel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @changePasswordTitleRow.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitleRow;

  /// No description provided for @changePasswordSubRow.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubRow;

  /// No description provided for @signOutSubRow.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutSubRow;

  /// No description provided for @aiAssistantOnline.
  ///
  /// In en, this message translates to:
  /// **'AI Plant Assistant · online'**
  String get aiAssistantOnline;

  /// No description provided for @clearHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryAction;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history?'**
  String get clearHistoryConfirm;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @plantPhoto.
  ///
  /// In en, this message translates to:
  /// **'Plant photo'**
  String get plantPhoto;

  /// No description provided for @addPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Add plant'**
  String get addPlantTitle;

  /// No description provided for @addPlantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap, identify, then save'**
  String get addPlantSubtitle;

  /// No description provided for @snapTitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo'**
  String get snapTitle;

  /// No description provided for @snapDescription.
  ///
  /// In en, this message translates to:
  /// **'A clear photo helps our AI identify\nyour plant and tailor care'**
  String get snapDescription;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get useCamera;

  /// No description provided for @uploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from gallery'**
  String get uploadFromGallery;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @couldntIdentify.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t identify this plant'**
  String get couldntIdentify;

  /// No description provided for @tryAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Try another photo or enter the species manually below.'**
  String get tryAnotherPhoto;

  /// No description provided for @topMatch.
  ///
  /// In en, this message translates to:
  /// **'Top match'**
  String get topMatch;

  /// No description provided for @useThisMatch.
  ///
  /// In en, this message translates to:
  /// **'Use this match'**
  String get useThisMatch;

  /// No description provided for @manualNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Plant nickname (e.g. Iris)'**
  String get manualNamePlaceholder;

  /// No description provided for @savePlantBtn.
  ///
  /// In en, this message translates to:
  /// **'Save plant'**
  String get savePlantBtn;

  /// No description provided for @tagOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get tagOverdue;

  /// No description provided for @tagDueSoon.
  ///
  /// In en, this message translates to:
  /// **'DUE SOON'**
  String get tagDueSoon;

  /// No description provided for @tagHealthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get tagHealthy;

  /// No description provided for @wateringScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Watering schedule'**
  String get wateringScheduleTitle;

  /// No description provided for @lastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered'**
  String get lastWatered;

  /// No description provided for @nextWatering.
  ///
  /// In en, this message translates to:
  /// **'Next watering'**
  String get nextWatering;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @waterNowAction.
  ///
  /// In en, this message translates to:
  /// **'Water now'**
  String get waterNowAction;

  /// No description provided for @rescheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleAction;

  /// No description provided for @careRecommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Recommendations'**
  String get careRecommendationsTitle;

  /// No description provided for @careSectionCultivar.
  ///
  /// In en, this message translates to:
  /// **'Cultivar'**
  String get careSectionCultivar;

  /// No description provided for @careSectionGeneralDescription.
  ///
  /// In en, this message translates to:
  /// **'General Description'**
  String get careSectionGeneralDescription;

  /// No description provided for @careSectionSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get careSectionSoil;

  /// No description provided for @careSectionSoilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get careSectionSoilMoisture;

  /// No description provided for @careSectionMoistureCheck.
  ///
  /// In en, this message translates to:
  /// **'Moisture Check'**
  String get careSectionMoistureCheck;

  /// No description provided for @careSectionWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get careSectionWater;

  /// No description provided for @careSectionLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get careSectionLight;

  /// No description provided for @careSectionTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get careSectionTemperature;

  /// No description provided for @careSectionFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get careSectionFertilizer;

  /// No description provided for @careSectionGrowthRate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate'**
  String get careSectionGrowthRate;

  /// No description provided for @careSectionToxicity.
  ///
  /// In en, this message translates to:
  /// **'Toxicity'**
  String get careSectionToxicity;

  /// No description provided for @careSectionPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get careSectionPlacement;

  /// No description provided for @careSectionPersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get careSectionPersonality;

  /// No description provided for @aboutPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'About this plant'**
  String get aboutPlantTitle;

  /// No description provided for @askAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant'**
  String get askAssistantTitle;

  /// No description provided for @askAssistantSub.
  ///
  /// In en, this message translates to:
  /// **'Get tailored advice from Iris AI'**
  String get askAssistantSub;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @deletePlantAction.
  ///
  /// In en, this message translates to:
  /// **'Delete plant'**
  String get deletePlantAction;

  /// No description provided for @reminderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get reminderEmail;

  /// No description provided for @reminderEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watering reminder emails'**
  String get reminderEmailSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts in the app (iOS / Android)'**
  String get pushNotificationsSubtitle;

  /// No description provided for @wateringOverdueNDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue {days}d'**
  String wateringOverdueNDays(int days);

  /// No description provided for @wateringToday.
  ///
  /// In en, this message translates to:
  /// **'Watering today'**
  String get wateringToday;

  /// No description provided for @wateringTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Watering tomorrow'**
  String get wateringTomorrow;

  /// No description provided for @wateringInNDays.
  ///
  /// In en, this message translates to:
  /// **'Watering in {days}d'**
  String wateringInNDays(int days);

  /// No description provided for @plantWateredSuccess.
  ///
  /// In en, this message translates to:
  /// **'{plantName} has been watered! 💧'**
  String plantWateredSuccess(Object plantName);

  /// No description provided for @errorWateringPlant.
  ///
  /// In en, this message translates to:
  /// **'Error watering plant: {error}'**
  String errorWateringPlant(Object error);

  /// No description provided for @healthIssueDetected.
  ///
  /// In en, this message translates to:
  /// **'Health Issue Detected'**
  String get healthIssueDetected;

  /// No description provided for @recommendedActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended Actions:'**
  String get recommendedActionsLabel;

  /// No description provided for @healthAlertNote.
  ///
  /// In en, this message translates to:
  /// **'This alert will remain visible until a subsequent health check returns OK'**
  String get healthAlertNote;

  /// No description provided for @addHealthCheckTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Health Check'**
  String get addHealthCheckTooltip;

  /// No description provided for @noHealthChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No health checks yet'**
  String get noHealthChecksYet;

  /// No description provided for @uploadPhotosToTrackHealth.
  ///
  /// In en, this message translates to:
  /// **'Upload photos to track your plant\'s health over time'**
  String get uploadPhotosToTrackHealth;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @nDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day ago} other{{days} days ago}}'**
  String nDaysAgo(int days);

  /// No description provided for @healthStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get healthStatusOk;

  /// No description provided for @healthStatusIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get healthStatusIssue;

  /// No description provided for @assistantTyping.
  ///
  /// In en, this message translates to:
  /// **'Assistant is typing...'**
  String get assistantTyping;

  /// No description provided for @chatSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String chatSourceLabel(Object source);

  /// No description provided for @chatSourceKnowledgeBase.
  ///
  /// In en, this message translates to:
  /// **'Knowledge Base'**
  String get chatSourceKnowledgeBase;

  /// No description provided for @chatSourceContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get chatSourceContext;

  /// No description provided for @chatSourceAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get chatSourceAgent;

  /// No description provided for @chatAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get chatAttachPhoto;

  /// No description provided for @chatPhotoQuota.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} photos today'**
  String chatPhotoQuota(int used, int limit);

  /// No description provided for @chatPhotoQuotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'Daily photo limit reached. Try again tomorrow.'**
  String get chatPhotoQuotaExhausted;

  /// No description provided for @chatPhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get chatPhotoUploading;

  /// No description provided for @chatPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo. Please try again.'**
  String get chatPhotoUploadFailed;

  /// No description provided for @chatRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get chatRemovePhoto;

  /// No description provided for @chatCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopyMessage;

  /// No description provided for @chatClearHistory.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatClearHistory;

  /// No description provided for @chatClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation? This will delete the current history.'**
  String get chatClearHistoryConfirm;

  /// No description provided for @chatClearHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'New conversation started.'**
  String get chatClearHistorySuccess;

  /// No description provided for @chatDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDateToday;

  /// No description provided for @chatDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @analyzeHealth.
  ///
  /// In en, this message translates to:
  /// **'Analyze Health'**
  String get analyzeHealth;

  /// No description provided for @waterFirstLabel.
  ///
  /// In en, this message translates to:
  /// **'Water first'**
  String get waterFirstLabel;

  /// No description provided for @nextCheckAfterWatering.
  ///
  /// In en, this message translates to:
  /// **'Next check in {days} d'**
  String nextCheckAfterWatering(int days);

  /// No description provided for @imageReadyForAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully! Ready for health analysis.'**
  String get imageReadyForAnalysis;

  /// No description provided for @healthCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get healthCheckTitle;

  /// No description provided for @healthCheckHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Check History'**
  String get healthCheckHistoryTitle;

  /// No description provided for @healthCheckUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo of {plantName} for AI health analysis'**
  String healthCheckUploadHint(Object plantName);

  /// No description provided for @deletePlant.
  ///
  /// In en, this message translates to:
  /// **'Delete Plant'**
  String get deletePlant;

  /// No description provided for @deletePlantConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this plant?'**
  String get deletePlantConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @iHaveWatered.
  ///
  /// In en, this message translates to:
  /// **'I have watered'**
  String get iHaveWatered;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Ideal Soil'**
  String get soilMoisture;

  /// No description provided for @lightLabel.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightLabel;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get perDay;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursLabel;

  /// No description provided for @interestingFactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interesting Facts'**
  String get interestingFactsTitle;

  /// No description provided for @noCareRecommendationsYet.
  ///
  /// In en, this message translates to:
  /// **'AI-generated care recommendations are not available for this plant yet.'**
  String get noCareRecommendationsYet;

  /// No description provided for @noInterestingFactsYet.
  ///
  /// In en, this message translates to:
  /// **'AI-generated interesting facts are not available for this plant yet.'**
  String get noInterestingFactsYet;

  /// No description provided for @noDescriptionYet.
  ///
  /// In en, this message translates to:
  /// **'No description available yet.'**
  String get noDescriptionYet;

  /// No description provided for @swipeToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see more'**
  String get swipeToSeeMore;

  /// No description provided for @uploadPhotosForHealthHistory.
  ///
  /// In en, this message translates to:
  /// **'Upload photos to track your plant\'s health'**
  String get uploadPhotosForHealthHistory;

  /// No description provided for @plantDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Plant \"{plantName}\" has been deleted'**
  String plantDeletedMessage(Object plantName);

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Image Available'**
  String get noImageAvailable;

  /// No description provided for @addPhotoToSeeYourPlant.
  ///
  /// In en, this message translates to:
  /// **'Add a photo to see your plant here'**
  String get addPhotoToSeeYourPlant;

  /// No description provided for @isThisYourPlant.
  ///
  /// In en, this message translates to:
  /// **'Is this your plant?'**
  String get isThisYourPlant;

  /// No description provided for @speciesPickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We found these options — pick the one that matches'**
  String get speciesPickSubtitle;

  /// No description provided for @noneOfThese.
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get noneOfThese;

  /// No description provided for @typePlantNameRetry.
  ///
  /// In en, this message translates to:
  /// **'Type the plant name and we\'ll try again'**
  String get typePlantNameRetry;

  /// No description provided for @gettingCareRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Getting care recommendations'**
  String get gettingCareRecommendations;

  /// No description provided for @imageUploadedAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully! AI analysis complete.'**
  String get imageUploadedAnalysisComplete;

  /// No description provided for @aiCareRecommendationsHeader.
  ///
  /// In en, this message translates to:
  /// **'AI Care Recommendations'**
  String get aiCareRecommendationsHeader;

  /// No description provided for @aiReady.
  ///
  /// In en, this message translates to:
  /// **'AI Ready'**
  String get aiReady;

  /// No description provided for @checkPlantButton.
  ///
  /// In en, this message translates to:
  /// **'Check Plant'**
  String get checkPlantButton;

  /// No description provided for @plantCareAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant Care Assistant'**
  String get plantCareAssistantTitle;

  /// No description provided for @plantNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'Plant Needs Help!'**
  String get plantNeedsHelp;

  /// No description provided for @whatToDoNow.
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get whatToDoNow;

  /// No description provided for @wateringLabel.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get wateringLabel;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @nextIn1Day.
  ///
  /// In en, this message translates to:
  /// **'Next in 1 day'**
  String get nextIn1Day;

  /// No description provided for @nextInNDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Next in {days} day} other{Next in {days} days}}'**
  String nextInNDays(int days);

  /// No description provided for @wateringDone.
  ///
  /// In en, this message translates to:
  /// **'Watering done'**
  String get wateringDone;

  /// No description provided for @moistureDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get moistureDry;

  /// No description provided for @moistureWet.
  ///
  /// In en, this message translates to:
  /// **'Wet'**
  String get moistureWet;

  /// No description provided for @moistureLevelVeryDry.
  ///
  /// In en, this message translates to:
  /// **'Very dry'**
  String get moistureLevelVeryDry;

  /// No description provided for @moistureLevelDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get moistureLevelDry;

  /// No description provided for @moistureLevelSlightlyMoist.
  ///
  /// In en, this message translates to:
  /// **'Slightly moist'**
  String get moistureLevelSlightlyMoist;

  /// No description provided for @moistureLevelMoist.
  ///
  /// In en, this message translates to:
  /// **'Moist'**
  String get moistureLevelMoist;

  /// No description provided for @moistureLevelVeryMoist.
  ///
  /// In en, this message translates to:
  /// **'Very moist'**
  String get moistureLevelVeryMoist;

  /// No description provided for @bannerWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} needs water'**
  String bannerWaterTitle(String name);

  /// No description provided for @bannerWaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to water or check details'**
  String get bannerWaterSubtitle;

  /// No description provided for @bannerTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip of the Day'**
  String get bannerTipTitle;

  /// No description provided for @bannerTipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap for more seasonal tips'**
  String get bannerTipSubtitle;

  /// No description provided for @tipsOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Tips of the Day'**
  String get tipsOfTheDay;

  /// No description provided for @tipsOfTheDaySub.
  ///
  /// In en, this message translates to:
  /// **'AI-powered seasonal advice · updated weekly'**
  String get tipsOfTheDaySub;

  /// No description provided for @tipCategoryWatering.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get tipCategoryWatering;

  /// No description provided for @tipCategoryLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get tipCategoryLight;

  /// No description provided for @tipCategoryPests.
  ///
  /// In en, this message translates to:
  /// **'Pests'**
  String get tipCategoryPests;

  /// No description provided for @tipCategoryFertilizing.
  ///
  /// In en, this message translates to:
  /// **'Fertilizing'**
  String get tipCategoryFertilizing;

  /// No description provided for @tipCategorySeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get tipCategorySeasonal;

  /// No description provided for @tipCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get tipCategoryGeneral;

  /// No description provided for @noTipsYet.
  ///
  /// In en, this message translates to:
  /// **'Tips are being generated. Check back soon!'**
  String get noTipsYet;

  /// No description provided for @waterNow.
  ///
  /// In en, this message translates to:
  /// **'Water now'**
  String get waterNow;

  /// No description provided for @subscriptionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get subscriptionUpgrade;

  /// No description provided for @subscriptionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get subscriptionManage;

  /// No description provided for @subscriptionActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Active'**
  String get subscriptionActiveTitle;

  /// No description provided for @subscriptionGrandfatheredTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Access'**
  String get subscriptionGrandfatheredTitle;

  /// No description provided for @subscriptionTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get subscriptionTrialTitle;

  /// No description provided for @subscriptionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpiredTitle;

  /// No description provided for @subscriptionActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Active until {date}'**
  String subscriptionActiveUntil(String date);

  /// No description provided for @subscriptionTrialEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Trial ends on {date}'**
  String subscriptionTrialEndsOn(String date);

  /// No description provided for @subscriptionTrialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day left} other{{days} days left}}'**
  String subscriptionTrialDaysLeft(int days);

  /// No description provided for @subscriptionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has expired. Upgrade to continue.'**
  String get subscriptionExpiredMessage;

  /// No description provided for @subscriptionPlantLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Plant limit reached'**
  String get subscriptionPlantLimitReached;

  /// No description provided for @subscriptionPlantLimitBannerTrial.
  ///
  /// In en, this message translates to:
  /// **'Free plan limit reached. Upgrade to Premium — up to {limit} plants.'**
  String subscriptionPlantLimitBannerTrial(int limit);

  /// No description provided for @subscriptionPlantLimitBannerExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to add more plants.'**
  String get subscriptionPlantLimitBannerExpired;

  /// No description provided for @subscriptionReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only mode. Subscribe to edit your plants.'**
  String get subscriptionReadOnlyNotice;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get the most out of your plant collection'**
  String get paywallSubtitle;

  /// No description provided for @paywallFeature1.
  ///
  /// In en, this message translates to:
  /// **'Up to {limit} plants'**
  String paywallFeature1(int limit);

  /// No description provided for @paywallFeature2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited watering reminders'**
  String get paywallFeature2;

  /// No description provided for @paywallFeature3.
  ///
  /// In en, this message translates to:
  /// **'AI plant assistant & health checks'**
  String get paywallFeature3;

  /// No description provided for @paywallFeature4.
  ///
  /// In en, this message translates to:
  /// **'Full editing & care tracking'**
  String get paywallFeature4;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywallAnnual;

  /// No description provided for @paywallBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get paywallBestValue;

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get paywallRestore;

  /// No description provided for @paywallRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get paywallRestoring;

  /// No description provided for @paywallRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase restored!'**
  String get paywallRestoreSuccess;

  /// No description provided for @paywallRestoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found.'**
  String get paywallRestoreNotFound;

  /// No description provided for @paywallRestoreAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is already active.'**
  String get paywallRestoreAlreadyActive;

  /// No description provided for @paywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscription auto-renews. Cancel anytime in App Store settings.'**
  String get paywallTerms;

  /// No description provided for @paywallLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading plans…'**
  String get paywallLoading;

  /// No description provided for @paywallPurchasing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get paywallPurchasing;

  /// No description provided for @paywallError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get paywallError;

  /// No description provided for @paywallHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow without limits.'**
  String get paywallHeroTitle;

  /// No description provided for @paywallHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Your personal AI assistant — watering reminders, health checks, seasonal tips, and everything you need to keep plants thriving.'**
  String get paywallHeroDescription;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR PLAN'**
  String get paywallChoosePlan;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Only {price} / month'**
  String paywallPerMonth(Object price);

  /// No description provided for @paywallStartPremium.
  ///
  /// In en, this message translates to:
  /// **'Start Premium'**
  String get paywallStartPremium;

  /// No description provided for @paywallSecured.
  ///
  /// In en, this message translates to:
  /// **'Stripe secured'**
  String get paywallSecured;

  /// No description provided for @paywallSecuredApple.
  ///
  /// In en, this message translates to:
  /// **'Secured'**
  String get paywallSecuredApple;

  /// No description provided for @paywallCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get paywallCancelAnytime;

  /// No description provided for @paywallAutoRenews.
  ///
  /// In en, this message translates to:
  /// **'auto-renews'**
  String get paywallAutoRenews;

  /// No description provided for @stripeSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated!'**
  String get stripeSuccessTitle;

  /// No description provided for @stripeSuccessWaiting.
  ///
  /// In en, this message translates to:
  /// **'Activating your subscription'**
  String get stripeSuccessWaiting;

  /// No description provided for @stripeSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Botanly Premium! You now have access to all features.'**
  String get stripeSuccessSubtitle;

  /// No description provided for @stripeSuccessButton.
  ///
  /// In en, this message translates to:
  /// **'Go to my plants'**
  String get stripeSuccessButton;

  /// No description provided for @errorOpeningBillingPortal.
  ///
  /// In en, this message translates to:
  /// **'Could not open billing portal: {error}'**
  String errorOpeningBillingPortal(Object error);

  /// No description provided for @errorRestoring.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore: {error}'**
  String errorRestoring(Object error);

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied: support@botanly.app'**
  String get emailCopied;

  /// No description provided for @labelExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get labelExpires;

  /// No description provided for @labelNextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next renewal'**
  String get labelNextRenewal;

  /// No description provided for @labelAutoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Auto-renewal'**
  String get labelAutoRenewal;

  /// No description provided for @labelRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get labelRestorePurchases;

  /// No description provided for @labelPlants.
  ///
  /// In en, this message translates to:
  /// **'Plants'**
  String get labelPlants;

  /// No description provided for @labelRenews.
  ///
  /// In en, this message translates to:
  /// **'Renews'**
  String get labelRenews;

  /// No description provided for @testWateringEmailQueued.
  ///
  /// In en, this message translates to:
  /// **'Test watering email queued.'**
  String get testWateringEmailQueued;

  /// No description provided for @errorSendingTestEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not send test email: {error}'**
  String errorSendingTestEmail(Object error);

  /// No description provided for @failedToSaveReminderChannels.
  ///
  /// In en, this message translates to:
  /// **'Failed to save reminder channels: {error}'**
  String failedToSaveReminderChannels(Object error);

  /// No description provided for @failedToUpdateQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Failed to update quiet hours: {error}'**
  String failedToUpdateQuietHours(Object error);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently disable your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be permanently disabled and you will lose access to the app. Your plant data will be retained.\n\nThis action cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountAreYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAccountAreYouSure;

  /// No description provided for @deleteAccountTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get deleteAccountTypeConfirm;

  /// No description provided for @deleteAccountConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteAccountConfirmBtn;

  /// No description provided for @errorDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String errorDeletingAccount(Object error);

  /// No description provided for @subPillPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subPillPremium;

  /// No description provided for @subPillEarlyMember.
  ///
  /// In en, this message translates to:
  /// **'Early member'**
  String get subPillEarlyMember;

  /// No description provided for @subPillFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get subPillFreePlan;

  /// No description provided for @subPillFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get subPillFreeTrial;

  /// No description provided for @subMetaActivePlan.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE PLAN'**
  String get subMetaActivePlan;

  /// No description provided for @subMetaForeverPremium.
  ///
  /// In en, this message translates to:
  /// **'FOREVER PREMIUM'**
  String get subMetaForeverPremium;

  /// No description provided for @subMetaTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'TRIAL ENDED'**
  String get subMetaTrialEnded;

  /// No description provided for @subMetaNDayPreview.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n}-DAY PREVIEW} other{{n}-DAY PREVIEW}}'**
  String subMetaNDayPreview(int n);

  /// No description provided for @subRenewsInDays.
  ///
  /// In en, this message translates to:
  /// **'Renews in {days} days · {date}'**
  String subRenewsInDays(int days, Object date);

  /// No description provided for @subEndsInDays.
  ///
  /// In en, this message translates to:
  /// **'Ends in {days} days · {date}'**
  String subEndsInDays(int days, Object date);

  /// No description provided for @subActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active subscription'**
  String get subActiveSubscription;

  /// No description provided for @subGrantedEarlyMember.
  ///
  /// In en, this message translates to:
  /// **'Granted as an early Botanly member'**
  String get subGrantedEarlyMember;

  /// No description provided for @subDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get subDaysLeft;

  /// No description provided for @subUntilPreviewEnds.
  ///
  /// In en, this message translates to:
  /// **'until your\npreview ends'**
  String get subUntilPreviewEnds;

  /// No description provided for @subTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'trial ended'**
  String get subTrialEnded;

  /// No description provided for @subAutoRenewOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew on  ·  Cancel anytime'**
  String get subAutoRenewOn;

  /// No description provided for @subAutoRenewOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew off  ·  Access until expiry'**
  String get subAutoRenewOff;

  /// No description provided for @subDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get subDetails;

  /// No description provided for @subReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get subReactivate;

  /// No description provided for @subNoChargesEver.
  ///
  /// In en, this message translates to:
  /// **'No charges, ever  ·  All perks unlocked'**
  String get subNoChargesEver;

  /// No description provided for @subLimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Limited access  ·  No AI care'**
  String get subLimitedAccess;

  /// No description provided for @subUnlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited  ·  AI care  ·  Reminders'**
  String get subUnlimitedAccess;

  /// No description provided for @subHeroYourePrefix.
  ///
  /// In en, this message translates to:
  /// **'You\'re '**
  String get subHeroYourePrefix;

  /// No description provided for @subHeroGrowingWord.
  ///
  /// In en, this message translates to:
  /// **'growing'**
  String get subHeroGrowingWord;

  /// No description provided for @subHeroForeverWord.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get subHeroForeverWord;

  /// No description provided for @subHeroPremiumSuffix.
  ///
  /// In en, this message translates to:
  /// **' Premium'**
  String get subHeroPremiumSuffix;

  /// No description provided for @labelEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get labelEnds;

  /// No description provided for @labelPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get labelPlan;

  /// No description provided for @labelPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get labelPremium;

  /// No description provided for @labelGrandfathered.
  ///
  /// In en, this message translates to:
  /// **'Grandfathered (Legacy)'**
  String get labelGrandfathered;

  /// No description provided for @labelOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get labelOn;

  /// No description provided for @labelOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get labelOff;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Plan'**
  String get yourPlan;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @manageBillingWeb.
  ///
  /// In en, this message translates to:
  /// **'Manage Billing'**
  String get manageBillingWeb;

  /// No description provided for @manageInAppStore.
  ///
  /// In en, this message translates to:
  /// **'Manage in App Store'**
  String get manageInAppStore;

  /// No description provided for @manageBillingSubtitleWeb.
  ///
  /// In en, this message translates to:
  /// **'Cancel, update your card or view invoices\nvia the Stripe billing portal.'**
  String get manageBillingSubtitleWeb;

  /// No description provided for @manageBillingSubtitleAppStore.
  ///
  /// In en, this message translates to:
  /// **'To turn off auto-renewal or cancel, go to your\nApp Store subscriptions.'**
  String get manageBillingSubtitleAppStore;

  /// No description provided for @tipGoodLight.
  ///
  /// In en, this message translates to:
  /// **'good light'**
  String get tipGoodLight;

  /// No description provided for @tipShowLeaves.
  ///
  /// In en, this message translates to:
  /// **'show the leaves'**
  String get tipShowLeaves;

  /// No description provided for @tipSinglePlant.
  ///
  /// In en, this message translates to:
  /// **'single plant'**
  String get tipSinglePlant;

  /// No description provided for @snapYourSprout.
  ///
  /// In en, this message translates to:
  /// **'Snap your sprout'**
  String get snapYourSprout;

  /// No description provided for @identifyingPlantPrefix.
  ///
  /// In en, this message translates to:
  /// **'Identifying your '**
  String get identifyingPlantPrefix;

  /// No description provided for @identifyingPlantWord.
  ///
  /// In en, this message translates to:
  /// **'plant'**
  String get identifyingPlantWord;

  /// No description provided for @identifyingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looking at leaves, stems and friends nearby'**
  String get identifyingSubtitle;

  /// No description provided for @specificIssues.
  ///
  /// In en, this message translates to:
  /// **'Specific issues'**
  String get specificIssues;

  /// No description provided for @healthCheckPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 photos — more angles means a more accurate analysis. Only the first photo is required.'**
  String get healthCheckPhotoHint;

  /// No description provided for @healthCheckPhotoCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} / 3'**
  String healthCheckPhotoCounter(int count);

  /// No description provided for @healthCheckSlot1Title.
  ///
  /// In en, this message translates to:
  /// **'Full plant'**
  String get healthCheckSlot1Title;

  /// No description provided for @healthCheckSlot1Desc.
  ///
  /// In en, this message translates to:
  /// **'Photograph the entire plant including the pot — so the soil and full pot are visible.'**
  String get healthCheckSlot1Desc;

  /// No description provided for @healthCheckSlot1Tag.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get healthCheckSlot1Tag;

  /// No description provided for @healthCheckSlot2Title.
  ///
  /// In en, this message translates to:
  /// **'Close-up'**
  String get healthCheckSlot2Title;

  /// No description provided for @healthCheckSlot2Desc.
  ///
  /// In en, this message translates to:
  /// **'Bring the camera closer, without the pot — to clearly see the leaves and their texture.'**
  String get healthCheckSlot2Desc;

  /// No description provided for @healthCheckSlot2Tag.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get healthCheckSlot2Tag;

  /// No description provided for @healthCheckSlot3Title.
  ///
  /// In en, this message translates to:
  /// **'Problem area'**
  String get healthCheckSlot3Title;

  /// No description provided for @healthCheckSlot3Desc.
  ///
  /// In en, this message translates to:
  /// **'Want to show something specific? Photograph a spot, pest, or damaged leaf.'**
  String get healthCheckSlot3Desc;

  /// No description provided for @healthCheckSlot3Tag.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get healthCheckSlot3Tag;

  /// No description provided for @healthCheckAnalyzeNPhotos.
  ///
  /// In en, this message translates to:
  /// **'Analyze {count} photo(s)'**
  String healthCheckAnalyzeNPhotos(int count);

  /// No description provided for @healthCheckError.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please try again.'**
  String get healthCheckError;

  /// No description provided for @healthCheckDefaultPraise.
  ///
  /// In en, this message translates to:
  /// **'🌱 Your plant is doing fine!'**
  String get healthCheckDefaultPraise;

  /// No description provided for @healthCheckDefaultFooter.
  ///
  /// In en, this message translates to:
  /// **'Keep caring for your plant per the recommendations below and log when you water.'**
  String get healthCheckDefaultFooter;

  /// No description provided for @addPlantWholePlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Whole plant'**
  String get addPlantWholePlantTitle;

  /// No description provided for @addPlantWholePlantDesc.
  ///
  /// In en, this message translates to:
  /// **'with the pot & soil'**
  String get addPlantWholePlantDesc;

  /// No description provided for @addPlantWholePlantTag.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get addPlantWholePlantTag;

  /// No description provided for @addPlantCloseUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Close-up'**
  String get addPlantCloseUpTitle;

  /// No description provided for @addPlantCloseUpDesc.
  ///
  /// In en, this message translates to:
  /// **'leaves in detail'**
  String get addPlantCloseUpDesc;

  /// No description provided for @addPlantCloseUpTag.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get addPlantCloseUpTag;

  /// No description provided for @addPlantDualHint.
  ///
  /// In en, this message translates to:
  /// **'Two angles help our AI identify your plant more accurately.'**
  String get addPlantDualHint;

  /// No description provided for @addPlantAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze Plant'**
  String get addPlantAnalyzeButton;

  /// No description provided for @addPlantStepPhotosReceived.
  ///
  /// In en, this message translates to:
  /// **'Photos received'**
  String get addPlantStepPhotosReceived;

  /// No description provided for @addPlantStepIdentifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying species'**
  String get addPlantStepIdentifying;

  /// No description provided for @addPlantStepCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Tailoring a care plan'**
  String get addPlantStepCarePlan;

  /// No description provided for @addPlantAnalyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your plant'**
  String get addPlantAnalyzingTitle;

  /// No description provided for @addPlantAnalyzingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds…'**
  String get addPlantAnalyzingSubtitle;

  /// No description provided for @addPlantAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'Analysis complete'**
  String get addPlantAnalysisComplete;

  /// No description provided for @addPlantSeePlantProfile.
  ///
  /// In en, this message translates to:
  /// **'See plant profile'**
  String get addPlantSeePlantProfile;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboarding1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboarding1Eyebrow;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Meet '**
  String get onboarding1Title;

  /// No description provided for @onboarding1TitleItalic.
  ///
  /// In en, this message translates to:
  /// **'Botanly'**
  String get onboarding1TitleItalic;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Your AI companion for happy, healthy plants — right in your pocket.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Identify'**
  String get onboarding2Eyebrow;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Name '**
  String get onboarding2Title;

  /// No description provided for @onboarding2TitleItalic.
  ///
  /// In en, this message translates to:
  /// **'any plant'**
  String get onboarding2TitleItalic;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Point your camera and let AI identify it in seconds — species, name and all.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get onboarding3Eyebrow;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Care made '**
  String get onboarding3Title;

  /// No description provided for @onboarding3TitleItalic.
  ///
  /// In en, this message translates to:
  /// **'effortless'**
  String get onboarding3TitleItalic;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Watering, light and soil reminders — perfectly tuned to each plant you own.'**
  String get onboarding3Body;

  /// No description provided for @onboarding4Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get onboarding4Eyebrow;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Spot problems '**
  String get onboarding4Title;

  /// No description provided for @onboarding4TitleItalic.
  ///
  /// In en, this message translates to:
  /// **'early'**
  String get onboarding4TitleItalic;

  /// No description provided for @onboarding4Body.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo and get an instant health check with a clear plan to fix it.'**
  String get onboarding4Body;

  /// No description provided for @onboarding5Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get onboarding5Eyebrow;

  /// No description provided for @onboarding5Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s '**
  String get onboarding5Title;

  /// No description provided for @onboarding5TitleItalic.
  ///
  /// In en, this message translates to:
  /// **'grow together'**
  String get onboarding5TitleItalic;

  /// No description provided for @onboarding5Body.
  ///
  /// In en, this message translates to:
  /// **'Build your plant shelf and never miss a beat. Your greenest era starts now.'**
  String get onboarding5Body;

  /// No description provided for @tabCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get tabCare;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @nDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String nDays(int days);

  /// No description provided for @cycleJustStarted.
  ///
  /// In en, this message translates to:
  /// **'Cycle just started'**
  String get cycleJustStarted;

  /// No description provided for @cyclePercentComplete.
  ///
  /// In en, this message translates to:
  /// **'Cycle {percent}% complete'**
  String cyclePercentComplete(int percent);

  /// No description provided for @wateringAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get wateringAmount;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available yet'**
  String get noDataAvailable;

  /// No description provided for @healthCheckHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo every couple of weeks — we\'ll build a health timeline'**
  String get healthCheckHistoryEmptyHint;

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'{count} ml'**
  String milliliters(int count);

  /// No description provided for @millilitersShort.
  ///
  /// In en, this message translates to:
  /// **'ML'**
  String get millilitersShort;

  /// No description provided for @nHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String nHours(String hours);

  /// No description provided for @lightDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get lightDaily;

  /// No description provided for @lightType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get lightType;

  /// No description provided for @lightTypeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get lightTypeDirect;

  /// No description provided for @lightTypePartialSun.
  ///
  /// In en, this message translates to:
  /// **'Partial sun'**
  String get lightTypePartialSun;

  /// No description provided for @lightTypeBrightIndirect.
  ///
  /// In en, this message translates to:
  /// **'Bright indirect'**
  String get lightTypeBrightIndirect;

  /// No description provided for @lightTypeLowLight.
  ///
  /// In en, this message translates to:
  /// **'Low light'**
  String get lightTypeLowLight;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @healthCheckSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get healthCheckSeverity;

  /// No description provided for @healthCheckFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get healthCheckFollowUp;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @careKvFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get careKvFrequency;

  /// No description provided for @careKvSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get careKvSeason;

  /// No description provided for @careKvOptimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get careKvOptimal;

  /// No description provided for @careKvMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get careKvMinimum;

  /// No description provided for @careKvDose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get careKvDose;

  /// No description provided for @healthAnalyzeCta.
  ///
  /// In en, this message translates to:
  /// **'Analyze health'**
  String get healthAnalyzeCta;

  /// No description provided for @healthNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get healthNeedsAttention;

  /// No description provided for @healthStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthStatusHealthy;

  /// No description provided for @healthWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get healthWhatToDo;

  /// No description provided for @healthClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get healthClose;

  /// No description provided for @healthNotSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Not saved to history yet'**
  String get healthNotSavedYet;

  /// No description provided for @healthAskAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask assistant'**
  String get healthAskAssistant;

  /// No description provided for @healthAddedToPlan.
  ///
  /// In en, this message translates to:
  /// **'Added to plan'**
  String get healthAddedToPlan;

  /// No description provided for @healthLockedNeedsWatering.
  ///
  /// In en, this message translates to:
  /// **'Log a watering to check again'**
  String get healthLockedNeedsWatering;

  /// No description provided for @healthLockedLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Checks for this cycle are used up'**
  String get healthLockedLimitReached;

  /// No description provided for @healthAdviceSub.
  ///
  /// In en, this message translates to:
  /// **'See what to do'**
  String get healthAdviceSub;

  /// No description provided for @healthAnalyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get healthAnalyzingTitle;

  /// No description provided for @healthStepRecognize.
  ///
  /// In en, this message translates to:
  /// **'Recognizing the plant'**
  String get healthStepRecognize;

  /// No description provided for @healthStepCompare.
  ///
  /// In en, this message translates to:
  /// **'Comparing with previous checks'**
  String get healthStepCompare;

  /// No description provided for @healthStepAdvice.
  ///
  /// In en, this message translates to:
  /// **'Preparing recommendations'**
  String get healthStepAdvice;

  /// No description provided for @healthStepPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo received} other{{count} photos received}}'**
  String healthStepPhotos(int count);

  /// No description provided for @healthAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recommendation after the check} other{{count} recommendations after the check}}'**
  String healthAdviceTitle(int count);

  /// No description provided for @healthHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history'**
  String get healthHistoryLoadFailed;

  /// No description provided for @healthUpToThreePhotos.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 photos'**
  String get healthUpToThreePhotos;

  /// No description provided for @healthResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get healthResultTitle;

  /// No description provided for @taskAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done — this plant is fine'**
  String get taskAllDone;

  /// No description provided for @taskBadgeScheduled.
  ///
  /// In en, this message translates to:
  /// **'On schedule'**
  String get taskBadgeScheduled;

  /// No description provided for @taskBadgeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'After analysis'**
  String get taskBadgeAnalysis;

  /// No description provided for @taskBadgeOverdue.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day overdue} other{{days} days overdue}}'**
  String taskBadgeOverdue(int days);

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @taskDoneAlready.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskDoneAlready;

  /// No description provided for @taskLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get taskLater;

  /// No description provided for @taskAskAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask assistant'**
  String get taskAskAssistant;

  /// No description provided for @taskAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should I do about the “{title}” task?'**
  String taskAskQuestion(String title);

  /// No description provided for @homeGardenTitleLead.
  ///
  /// In en, this message translates to:
  /// **'Your'**
  String get homeGardenTitleLead;

  /// No description provided for @homeGardenTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'garden'**
  String get homeGardenTitleAccent;

  /// No description provided for @gardenHealthLabel.
  ///
  /// In en, this message translates to:
  /// **'Garden health'**
  String get gardenHealthLabel;

  /// No description provided for @gardenAllGood.
  ///
  /// In en, this message translates to:
  /// **'Every plant is fine'**
  String get gardenAllGood;

  /// No description provided for @gardenOneWeak.
  ///
  /// In en, this message translates to:
  /// **'{name} is pulling the garden down'**
  String gardenOneWeak(String name);

  /// No description provided for @gardenManyWeak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plant needs your care} other{{count} plants need your care}}'**
  String gardenManyWeak(int count);

  /// No description provided for @homeOrbitHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a plant to open it'**
  String get homeOrbitHint;

  /// No description provided for @homeAllTasksLink.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get homeAllTasksLink;

  /// No description provided for @deckAllClearTitle.
  ///
  /// In en, this message translates to:
  /// **'The garden is fine'**
  String get deckAllClearTitle;

  /// No description provided for @taskOverdueShort.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String taskOverdueShort(int days);

  /// No description provided for @taskPostponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get taskPostponed;

  /// No description provided for @allTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasksTitle;

  /// No description provided for @allTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{today} today · {later} later'**
  String allTasksSubtitle(int today, int later);

  /// No description provided for @allTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get allTasksToday;

  /// No description provided for @allTasksLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get allTasksLater;

  /// No description provided for @allTasksRuleNote.
  ///
  /// In en, this message translates to:
  /// **'New tasks will not appear until you deal with today\'s.'**
  String get allTasksRuleNote;

  /// No description provided for @allTasksNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing left for today'**
  String get allTasksNothingToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get whenTomorrow;

  /// No description provided for @whenInAWeek.
  ///
  /// In en, this message translates to:
  /// **'In a week'**
  String get whenInAWeek;

  /// No description provided for @whenInNDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{In 1 day} other{In {days} days}}'**
  String whenInNDays(int days);

  /// No description provided for @careAskAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask assistant about {title}'**
  String careAskAbout(String title);

  /// No description provided for @careAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Tell me more about “{title}” for my plant'**
  String careAskQuestion(String title);

  /// No description provided for @healthAskQuestionIssue.
  ///
  /// In en, this message translates to:
  /// **'What should I do first based on the analysis?'**
  String get healthAskQuestionIssue;

  /// No description provided for @healthAskQuestionOk.
  ///
  /// In en, this message translates to:
  /// **'The check says the plant is healthy — what could I improve?'**
  String get healthAskQuestionOk;

  /// No description provided for @glassesOne.
  ///
  /// In en, this message translates to:
  /// **'1 glass'**
  String get glassesOne;

  /// No description provided for @glassesAmount.
  ///
  /// In en, this message translates to:
  /// **'{value} glasses'**
  String glassesAmount(String value);

  /// No description provided for @addPlantStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String addPlantStepOf(int step, int total);

  /// No description provided for @addPlantTitleLead.
  ///
  /// In en, this message translates to:
  /// **'Add a'**
  String get addPlantTitleLead;

  /// No description provided for @addPlantTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'plant'**
  String get addPlantTitleAccent;

  /// No description provided for @addPlantNameHint.
  ///
  /// In en, this message translates to:
  /// **'What will you call it — Monty, Ficus Jr., Monstera. The dice will pick for you.'**
  String get addPlantNameHint;

  /// No description provided for @addPlantPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get addPlantPhotosTitle;

  /// No description provided for @addPlantWholePlant.
  ///
  /// In en, this message translates to:
  /// **'Whole plant'**
  String get addPlantWholePlant;

  /// No description provided for @addPlantWholePlantHint.
  ///
  /// In en, this message translates to:
  /// **'with the pot and soil'**
  String get addPlantWholePlantHint;

  /// No description provided for @addPlantRequired.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get addPlantRequired;

  /// No description provided for @addPlantTwoAnglesHint.
  ///
  /// In en, this message translates to:
  /// **'Two angles pin the species down more accurately — the second photo is optional but helps.'**
  String get addPlantTwoAnglesHint;

  /// No description provided for @addPlantTipLight.
  ///
  /// In en, this message translates to:
  /// **'good light'**
  String get addPlantTipLight;

  /// No description provided for @addPlantTipLeaves.
  ///
  /// In en, this message translates to:
  /// **'leaves visible'**
  String get addPlantTipLeaves;

  /// No description provided for @addPlantTipSingle.
  ///
  /// In en, this message translates to:
  /// **'one plant'**
  String get addPlantTipSingle;

  /// No description provided for @addPlantIdentifyCta.
  ///
  /// In en, this message translates to:
  /// **'Identify the species'**
  String get addPlantIdentifyCta;

  /// No description provided for @addPlantRandomNames.
  ///
  /// In en, this message translates to:
  /// **'Monty|Sprout|Ficus Jr.|Fernie|Basil the Great|Leafy|Sunny|Pip'**
  String get addPlantRandomNames;

  /// No description provided for @addPlantIsThisYourPlant.
  ///
  /// In en, this message translates to:
  /// **'Is this your plant?'**
  String get addPlantIsThisYourPlant;

  /// No description provided for @addPlantPickSpeciesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the closest match — the care plan follows from it.'**
  String get addPlantPickSpeciesHint;

  /// No description provided for @addPlantNoneMatch.
  ///
  /// In en, this message translates to:
  /// **'None of these — I\'ll type it'**
  String get addPlantNoneMatch;

  /// No description provided for @addPlantManualHint.
  ///
  /// In en, this message translates to:
  /// **'Type the species name and we\'ll search again.'**
  String get addPlantManualHint;

  /// No description provided for @addPlantManualPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example, Monstera deliciosa'**
  String get addPlantManualPlaceholder;

  /// No description provided for @addPlantBuildPlanCta.
  ///
  /// In en, this message translates to:
  /// **'Build the care plan'**
  String get addPlantBuildPlanCta;

  /// No description provided for @addPlantStartingScore.
  ///
  /// In en, this message translates to:
  /// **'Starting score {score}'**
  String addPlantStartingScore(int score);

  /// No description provided for @addPlantPlanWatering.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get addPlantPlanWatering;

  /// No description provided for @addPlantPlanLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get addPlantPlanLight;

  /// No description provided for @addPlantPlanSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get addPlantPlanSoil;

  /// No description provided for @addPlantSoilSlightlyMoist.
  ///
  /// In en, this message translates to:
  /// **'Slightly moist'**
  String get addPlantSoilSlightlyMoist;

  /// No description provided for @addPlantEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Every day} other{Every {days} days}}'**
  String addPlantEveryNDays(int days);

  /// No description provided for @addPlantCarePlan.
  ///
  /// In en, this message translates to:
  /// **'Care plan'**
  String get addPlantCarePlan;

  /// No description provided for @addPlantNTasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String addPlantNTasks(int count);

  /// No description provided for @addPlantFirstWatering.
  ///
  /// In en, this message translates to:
  /// **'First watering'**
  String get addPlantFirstWatering;

  /// No description provided for @addPlantToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get addPlantToday;

  /// No description provided for @addPlantWaterToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get addPlantWaterToday;

  /// No description provided for @addPlantFertilising.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get addPlantFertilising;

  /// No description provided for @addPlantFertilisingDetail.
  ///
  /// In en, this message translates to:
  /// **'In two weeks · half dose'**
  String get addPlantFertilisingDetail;

  /// No description provided for @addPlantHealthCheck.
  ///
  /// In en, this message translates to:
  /// **'Health check'**
  String get addPlantHealthCheck;

  /// No description provided for @addPlantHealthCheckDetail.
  ///
  /// In en, this message translates to:
  /// **'In a month · 1–3 photos'**
  String get addPlantHealthCheckDetail;

  /// No description provided for @addPlantAddToGarden.
  ///
  /// In en, this message translates to:
  /// **'Add to the garden'**
  String get addPlantAddToGarden;

  /// No description provided for @addPlantNoSpeciesFound.
  ///
  /// In en, this message translates to:
  /// **'Could not recognise the plant. Try another photo.'**
  String get addPlantNoSpeciesFound;

  /// No description provided for @addPlantNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Could not build the care plan. Try again.'**
  String get addPlantNoPlan;

  /// No description provided for @addPlantLoaderPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos received'**
  String get addPlantLoaderPhotos;

  /// No description provided for @addPlantLoaderIdentify.
  ///
  /// In en, this message translates to:
  /// **'Working out the species'**
  String get addPlantLoaderIdentify;

  /// No description provided for @addPlantLoaderPlan.
  ///
  /// In en, this message translates to:
  /// **'Writing the care plan'**
  String get addPlantLoaderPlan;

  /// No description provided for @myPlantsTitleLead.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get myPlantsTitleLead;

  /// No description provided for @myPlantsTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'plants'**
  String get myPlantsTitleAccent;

  /// No description provided for @myPlantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plant} other{{count} plants}}'**
  String myPlantsCount(int count);

  /// No description provided for @myPlantsEmptyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get myPlantsEmptyLabel;

  /// No description provided for @filterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get filterTomorrow;

  /// No description provided for @filterNeedsCare.
  ///
  /// In en, this message translates to:
  /// **'Needs care'**
  String get filterNeedsCare;

  /// No description provided for @myPlantsNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get myPlantsNothingFound;

  /// No description provided for @myPlantsNothingFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or species.'**
  String get myPlantsNothingFoundHint;

  /// No description provided for @myPlantsAllClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get myPlantsAllClearTitle;

  /// No description provided for @myPlantsAllClearHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this group right now — nothing to worry about.'**
  String get myPlantsAllClearHint;

  /// No description provided for @addFirstPlantHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first plant to get started'**
  String get addFirstPlantHint;

  /// No description provided for @subHeroActiveLead.
  ///
  /// In en, this message translates to:
  /// **'Your garden is'**
  String get subHeroActiveLead;

  /// No description provided for @subHeroActiveAccent.
  ///
  /// In en, this message translates to:
  /// **'looked after'**
  String get subHeroActiveAccent;

  /// No description provided for @subHeroForeverLead.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subHeroForeverLead;

  /// No description provided for @subHeroForeverAccent.
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get subHeroForeverAccent;

  /// No description provided for @subHeroEndedLead.
  ///
  /// In en, this message translates to:
  /// **'The trial has'**
  String get subHeroEndedLead;

  /// No description provided for @subHeroEndedAccent.
  ///
  /// In en, this message translates to:
  /// **'ended'**
  String get subHeroEndedAccent;

  /// No description provided for @subMetaNoCharges.
  ///
  /// In en, this message translates to:
  /// **'No charges'**
  String get subMetaNoCharges;

  /// No description provided for @subFootAutoRenew.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew on · Cancel anytime'**
  String get subFootAutoRenew;

  /// No description provided for @subFootTrial.
  ///
  /// In en, this message translates to:
  /// **'No limits · AI care · Reminders'**
  String get subFootTrial;

  /// No description provided for @subFootForever.
  ///
  /// In en, this message translates to:
  /// **'Everything is unlocked'**
  String get subFootForever;

  /// No description provided for @subFootFree.
  ///
  /// In en, this message translates to:
  /// **'Limited access · No AI care'**
  String get subFootFree;

  /// No description provided for @subCtaDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get subCtaDetails;

  /// No description provided for @subCtaResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get subCtaResume;

  /// No description provided for @subTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Trial until {date}'**
  String subTrialUntil(String date);

  /// No description provided for @subEndedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended on {date}'**
  String subEndedOn(String date);

  /// No description provided for @subscriptionManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionManageTitle;

  /// No description provided for @subscriptionPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subscriptionPlanLabel;

  /// No description provided for @subscriptionNextChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Next charge'**
  String get subscriptionNextChargeLabel;

  /// No description provided for @subscriptionAutoRenewLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-renew'**
  String get subscriptionAutoRenewLabel;

  /// No description provided for @subscriptionAutoRenewOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get subscriptionAutoRenewOn;

  /// No description provided for @subscriptionAutoRenewOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get subscriptionAutoRenewOff;

  /// No description provided for @subscriptionManageInStore.
  ///
  /// In en, this message translates to:
  /// **'Billing is handled by the App Store. Open Settings → Apple ID → Subscriptions to change or cancel it.'**
  String get subscriptionManageInStore;

  /// No description provided for @deleteAccountContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get deleteAccountContinue;

  /// No description provided for @deleteAccountKeyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountKeyword;

  /// No description provided for @deleteAccountTypeWord.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm.'**
  String deleteAccountTypeWord(String word);

  /// No description provided for @settingsSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSavedToast;

  /// No description provided for @quietHoursUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours updated!'**
  String get quietHoursUpdatedToast;

  /// No description provided for @signedInChip.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInChip;

  /// No description provided for @securityLabel.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityLabel;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailNotificationsLabel;

  /// No description provided for @changePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get changePasswordHint;

  /// No description provided for @quietHoursNeedsPush.
  ///
  /// In en, this message translates to:
  /// **'Turn push on to use quiet hours'**
  String get quietHoursNeedsPush;

  /// No description provided for @quietHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quietHoursFrom;

  /// No description provided for @quietHoursTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quietHoursTo;

  /// No description provided for @quietHoursSummary.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{No notifications for 1 hour straight} other{No notifications for {hours} hours straight}}'**
  String quietHoursSummary(int hours);

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'The new password must be at least 6 characters.'**
  String get passwordTooShortError;

  /// No description provided for @passwordSameAsCurrentError.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get passwordSameAsCurrentError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordsDoNotMatchError;

  /// No description provided for @passwordCurrentWrongError.
  ///
  /// In en, this message translates to:
  /// **'The current password is wrong.'**
  String get passwordCurrentWrongError;

  /// No description provided for @subscriptionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your plan…'**
  String get subscriptionLoading;

  /// No description provided for @editPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editPlantTitle;

  /// No description provided for @newPhotoBadge.
  ///
  /// In en, this message translates to:
  /// **'New photo'**
  String get newPhotoBadge;

  /// No description provided for @revertPhoto.
  ///
  /// In en, this message translates to:
  /// **'Restore previous photo'**
  String get revertPhoto;

  /// No description provided for @editPlantNameHint.
  ///
  /// In en, this message translates to:
  /// **'This is how the plant appears in your garden and in reminders'**
  String get editPlantNameHint;

  /// No description provided for @aiManagedNote.
  ///
  /// In en, this message translates to:
  /// **'The species and care plan are set by AI — they update after a new health check.'**
  String get aiManagedNote;

  /// No description provided for @noPhotoYet.
  ///
  /// In en, this message translates to:
  /// **'No photo yet'**
  String get noPhotoYet;

  /// No description provided for @gardenLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your garden. Check the connection and try again.'**
  String get gardenLoadError;

  /// No description provided for @pullToRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefreshHint;

  /// No description provided for @refreshingGarden.
  ///
  /// In en, this message translates to:
  /// **'Gathering your garden…'**
  String get refreshingGarden;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Check your connection.'**
  String get refreshFailed;

  /// No description provided for @addPlantHeaderPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a {accent}'**
  String addPlantHeaderPhoto(String accent);

  /// No description provided for @addPlantHeaderPhotoAccent.
  ///
  /// In en, this message translates to:
  /// **'plant'**
  String get addPlantHeaderPhotoAccent;

  /// No description provided for @addPlantHeaderSpecies.
  ///
  /// In en, this message translates to:
  /// **'Confirm the {accent}'**
  String addPlantHeaderSpecies(String accent);

  /// No description provided for @addPlantHeaderSpeciesAccent.
  ///
  /// In en, this message translates to:
  /// **'species'**
  String get addPlantHeaderSpeciesAccent;

  /// No description provided for @addPlantHeaderConditions.
  ///
  /// In en, this message translates to:
  /// **'About the {accent}'**
  String addPlantHeaderConditions(String accent);

  /// No description provided for @addPlantHeaderConditionsAccent.
  ///
  /// In en, this message translates to:
  /// **'conditions'**
  String get addPlantHeaderConditionsAccent;

  /// No description provided for @addPlantHeaderPlan.
  ///
  /// In en, this message translates to:
  /// **'Care {accent}'**
  String addPlantHeaderPlan(String accent);

  /// No description provided for @addPlantHeaderPlanAccent.
  ///
  /// In en, this message translates to:
  /// **'plan'**
  String get addPlantHeaderPlanAccent;

  /// No description provided for @addPlantBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get addPlantBack;

  /// No description provided for @quizQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {step} of {total}'**
  String quizQuestionOf(int step, int total);

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// No description provided for @quizBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'Build the plan'**
  String get quizBuildPlan;

  /// No description provided for @quizPotQuestion.
  ///
  /// In en, this message translates to:
  /// **'What {accent} is the pot?'**
  String quizPotQuestion(String accent);

  /// No description provided for @quizPotQuestionAccent.
  ///
  /// In en, this message translates to:
  /// **'diameter'**
  String get quizPotQuestionAccent;

  /// No description provided for @quizPotWhy.
  ///
  /// In en, this message translates to:
  /// **'The volume of soil decides how much water one watering needs.'**
  String get quizPotWhy;

  /// No description provided for @quizPotHint.
  ///
  /// In en, this message translates to:
  /// **'Measure across the rim of the pot, not the plant.'**
  String get quizPotHint;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @volumeMl.
  ///
  /// In en, this message translates to:
  /// **'{value} ml'**
  String volumeMl(String value);

  /// No description provided for @volumeLitres.
  ///
  /// In en, this message translates to:
  /// **'{value} l'**
  String volumeLitres(String value);

  /// No description provided for @quizPotPerWatering.
  ///
  /// In en, this message translates to:
  /// **'{volume} per watering'**
  String quizPotPerWatering(String volume);

  /// No description provided for @quizMaterialQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is the pot made of, and does it have {accent}?'**
  String quizMaterialQuestion(String accent);

  /// No description provided for @quizMaterialQuestionAccent.
  ///
  /// In en, this message translates to:
  /// **'drainage'**
  String get quizMaterialQuestionAccent;

  /// No description provided for @quizMaterialWhy.
  ///
  /// In en, this message translates to:
  /// **'Terracotta dries twice as fast as plastic. Without holes, root rot gets likely.'**
  String get quizMaterialWhy;

  /// No description provided for @quizMatPlastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic'**
  String get quizMatPlastic;

  /// No description provided for @quizMatPlasticDesc.
  ///
  /// In en, this message translates to:
  /// **'Holds moisture longer'**
  String get quizMatPlasticDesc;

  /// No description provided for @quizMatCeramic.
  ///
  /// In en, this message translates to:
  /// **'Ceramic'**
  String get quizMatCeramic;

  /// No description provided for @quizMatCeramicDesc.
  ///
  /// In en, this message translates to:
  /// **'Glazed, does not breathe'**
  String get quizMatCeramicDesc;

  /// No description provided for @quizMatTerracotta.
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get quizMatTerracotta;

  /// No description provided for @quizMatTerracottaDesc.
  ///
  /// In en, this message translates to:
  /// **'Breathes, dries fast'**
  String get quizMatTerracottaDesc;

  /// No description provided for @quizMatUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get quizMatUnknown;

  /// No description provided for @quizMatUnknownDesc.
  ///
  /// In en, this message translates to:
  /// **'We will take an average'**
  String get quizMatUnknownDesc;

  /// No description provided for @quizDrainageLabel.
  ///
  /// In en, this message translates to:
  /// **'Drainage holes'**
  String get quizDrainageLabel;

  /// No description provided for @quizDrainageYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get quizDrainageYes;

  /// No description provided for @quizDrainageYesDesc.
  ///
  /// In en, this message translates to:
  /// **'Extra water runs into the saucer'**
  String get quizDrainageYesDesc;

  /// No description provided for @quizDrainageNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get quizDrainageNo;

  /// No description provided for @quizDrainageNoDesc.
  ///
  /// In en, this message translates to:
  /// **'Water sits at the roots'**
  String get quizDrainageNoDesc;

  /// No description provided for @quizPlaceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where does the plant {accent}?'**
  String quizPlaceQuestion(String accent);

  /// No description provided for @quizPlaceQuestionAccent.
  ///
  /// In en, this message translates to:
  /// **'stand'**
  String get quizPlaceQuestionAccent;

  /// No description provided for @quizPlaceWhy.
  ///
  /// In en, this message translates to:
  /// **'This tells us how much light it really gets — and whether it needs shading.'**
  String get quizPlaceWhy;

  /// No description provided for @quizPlaceSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get quizPlaceSouth;

  /// No description provided for @quizPlaceSouthDesc.
  ///
  /// In en, this message translates to:
  /// **'Windowsill, plenty of sun'**
  String get quizPlaceSouthDesc;

  /// No description provided for @quizPlaceEast.
  ///
  /// In en, this message translates to:
  /// **'East / west'**
  String get quizPlaceEast;

  /// No description provided for @quizPlaceEastDesc.
  ///
  /// In en, this message translates to:
  /// **'Gentle morning sun'**
  String get quizPlaceEastDesc;

  /// No description provided for @quizPlaceNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get quizPlaceNorth;

  /// No description provided for @quizPlaceNorthDesc.
  ///
  /// In en, this message translates to:
  /// **'Light, but no direct sun'**
  String get quizPlaceNorthDesc;

  /// No description provided for @quizPlaceRoom.
  ///
  /// In en, this message translates to:
  /// **'Away from the window'**
  String get quizPlaceRoom;

  /// No description provided for @quizPlaceRoomDesc.
  ///
  /// In en, this message translates to:
  /// **'Far from any window'**
  String get quizPlaceRoomDesc;

  /// No description provided for @quizPlaceBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get quizPlaceBalcony;

  /// No description provided for @quizPlaceBalconyDesc.
  ///
  /// In en, this message translates to:
  /// **'Outdoors, seasonal'**
  String get quizPlaceBalconyDesc;

  /// No description provided for @quizPlaceBath.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get quizPlaceBath;

  /// No description provided for @quizPlaceBathDesc.
  ///
  /// In en, this message translates to:
  /// **'Humid, little light'**
  String get quizPlaceBathDesc;

  /// No description provided for @quizHeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Radiator or air conditioner nearby'**
  String get quizHeatLabel;

  /// No description provided for @quizHeatNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get quizHeatNo;

  /// No description provided for @quizHeatNoDesc.
  ///
  /// In en, this message translates to:
  /// **'Ordinary room air'**
  String get quizHeatNoDesc;

  /// No description provided for @quizHeatYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get quizHeatYes;

  /// No description provided for @quizHeatYesDesc.
  ///
  /// In en, this message translates to:
  /// **'Dries out the soil and the air'**
  String get quizHeatYesDesc;

  /// No description provided for @quizWaterQuestion.
  ///
  /// In en, this message translates to:
  /// **'When did you {accent} water it?'**
  String quizWaterQuestion(String accent);

  /// No description provided for @quizWaterQuestionAccent.
  ///
  /// In en, this message translates to:
  /// **'last'**
  String get quizWaterQuestionAccent;

  /// No description provided for @quizWaterWhy.
  ///
  /// In en, this message translates to:
  /// **'The first watering date depends on it — otherwise the task is set blind.'**
  String get quizWaterWhy;

  /// No description provided for @quizWaterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quizWaterToday;

  /// No description provided for @quizWaterTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'The soil is still damp'**
  String get quizWaterTodayDesc;

  /// No description provided for @quizWaterFewDays.
  ///
  /// In en, this message translates to:
  /// **'2–3 days ago'**
  String get quizWaterFewDays;

  /// No description provided for @quizWaterFewDaysDesc.
  ///
  /// In en, this message translates to:
  /// **'The top layer has dried out'**
  String get quizWaterFewDaysDesc;

  /// No description provided for @quizWaterWeek.
  ///
  /// In en, this message translates to:
  /// **'About a week ago'**
  String get quizWaterWeek;

  /// No description provided for @quizWaterWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Probably time to water'**
  String get quizWaterWeekDesc;

  /// No description provided for @quizWaterUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get quizWaterUnknown;

  /// No description provided for @quizWaterUnknownDesc.
  ///
  /// In en, this message translates to:
  /// **'We will check the photo and the soil'**
  String get quizWaterUnknownDesc;

  /// No description provided for @addPlantPlanTuned.
  ///
  /// In en, this message translates to:
  /// **'Built from your answers'**
  String get addPlantPlanTuned;

  /// No description provided for @addPlantCheckToday.
  ///
  /// In en, this message translates to:
  /// **'check the soil today'**
  String get addPlantCheckToday;

  /// No description provided for @placeLightSouth.
  ///
  /// In en, this message translates to:
  /// **'6–8 h'**
  String get placeLightSouth;

  /// No description provided for @placeLightEast.
  ///
  /// In en, this message translates to:
  /// **'4–6 h'**
  String get placeLightEast;

  /// No description provided for @placeLightNorth.
  ///
  /// In en, this message translates to:
  /// **'2–3 h'**
  String get placeLightNorth;

  /// No description provided for @placeLightRoom.
  ///
  /// In en, this message translates to:
  /// **'Little light'**
  String get placeLightRoom;

  /// No description provided for @placeLightBalcony.
  ///
  /// In en, this message translates to:
  /// **'6–9 h'**
  String get placeLightBalcony;

  /// No description provided for @placeLightBath.
  ///
  /// In en, this message translates to:
  /// **'2–3 h'**
  String get placeLightBath;

  /// No description provided for @soilModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately damp'**
  String get soilModerate;

  /// No description provided for @addPlantAddLight.
  ///
  /// In en, this message translates to:
  /// **'Add light'**
  String get addPlantAddLight;

  /// No description provided for @addPlantAddLightDetail.
  ///
  /// In en, this message translates to:
  /// **'Closer to a window, or a grow lamp for 4–6 h'**
  String get addPlantAddLightDetail;

  /// No description provided for @addPlantAddDrainage.
  ///
  /// In en, this message translates to:
  /// **'Add drainage'**
  String get addPlantAddDrainage;

  /// No description provided for @addPlantAddDrainageDetail.
  ///
  /// In en, this message translates to:
  /// **'Without holes the water sits at the roots'**
  String get addPlantAddDrainageDetail;

  /// No description provided for @addPlantMoveFromHeat.
  ///
  /// In en, this message translates to:
  /// **'Move away from the heat'**
  String get addPlantMoveFromHeat;

  /// No description provided for @addPlantMoveFromHeatDetail.
  ///
  /// In en, this message translates to:
  /// **'A radiator dries the soil out'**
  String get addPlantMoveFromHeatDetail;

  /// No description provided for @lockedLabelTrial.
  ///
  /// In en, this message translates to:
  /// **'Adding is paused'**
  String get lockedLabelTrial;

  /// No description provided for @lockedLabelLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan limit'**
  String get lockedLabelLimit;

  /// No description provided for @lockedLabelCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get lockedLabelCancelled;

  /// No description provided for @lockedPillTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial finished'**
  String get lockedPillTrial;

  /// No description provided for @lockedPillLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan · {count} of {limit}'**
  String lockedPillLimit(int count, int limit);

  /// No description provided for @lockedPillCancelled.
  ///
  /// In en, this message translates to:
  /// **'Access has ended'**
  String get lockedPillCancelled;

  /// No description provided for @lockedLeadTrial.
  ///
  /// In en, this message translates to:
  /// **'New plants {accent}'**
  String lockedLeadTrial(String accent);

  /// No description provided for @lockedLeadTrialAccent.
  ///
  /// In en, this message translates to:
  /// **'are waiting on a subscription'**
  String get lockedLeadTrialAccent;

  /// No description provided for @lockedLeadLimit.
  ///
  /// In en, this message translates to:
  /// **'The free plan holds {accent}'**
  String lockedLeadLimit(String accent);

  /// No description provided for @lockedLeadLimitAccent.
  ///
  /// In en, this message translates to:
  /// **'{limit} plants'**
  String lockedLeadLimitAccent(int limit);

  /// No description provided for @lockedLeadCancelled.
  ///
  /// In en, this message translates to:
  /// **'The subscription {accent}'**
  String lockedLeadCancelled(String accent);

  /// No description provided for @lockedLeadCancelledAccent.
  ///
  /// In en, this message translates to:
  /// **'is not active'**
  String get lockedLeadCancelledAccent;

  /// No description provided for @lockedSubTrial.
  ///
  /// In en, this message translates to:
  /// **'The trial ended on {date}'**
  String lockedSubTrial(String date);

  /// No description provided for @lockedSubLimit.
  ///
  /// In en, this message translates to:
  /// **'A subscription removes the limit — keep as many plants as you like.'**
  String get lockedSubLimit;

  /// No description provided for @lockedSubCancelled.
  ///
  /// In en, this message translates to:
  /// **'Premium was active until {date}'**
  String lockedSubCancelled(String date);

  /// No description provided for @lockedKeepTitle.
  ///
  /// In en, this message translates to:
  /// **'What stays'**
  String get lockedKeepTitle;

  /// No description provided for @lockedUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'What a subscription brings back'**
  String get lockedUnlockTitle;

  /// No description provided for @lockedKeepPlants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plant looked after} other{{count} plants looked after}}'**
  String lockedKeepPlants(int count);

  /// No description provided for @lockedKeepPlantsDesc.
  ///
  /// In en, this message translates to:
  /// **'They stay in the garden along with their check history'**
  String get lockedKeepPlantsDesc;

  /// No description provided for @lockedKeepReminders.
  ///
  /// In en, this message translates to:
  /// **'Watering reminders'**
  String get lockedKeepReminders;

  /// No description provided for @lockedKeepRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep arriving just as before'**
  String get lockedKeepRemindersDesc;

  /// No description provided for @lockedUnlockNewPlants.
  ///
  /// In en, this message translates to:
  /// **'New plants'**
  String get lockedUnlockNewPlants;

  /// No description provided for @lockedUnlockNewPlantsDesc.
  ///
  /// In en, this message translates to:
  /// **'Species from a photo and a care plan of their own'**
  String get lockedUnlockNewPlantsDesc;

  /// No description provided for @lockedUnlockHealth.
  ///
  /// In en, this message translates to:
  /// **'Health check'**
  String get lockedUnlockHealth;

  /// No description provided for @lockedUnlockHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Photo analysis, a score and what to do about it'**
  String get lockedUnlockHealthDesc;

  /// No description provided for @lockedUnlockChat.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get lockedUnlockChat;

  /// No description provided for @lockedUnlockChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Answers for each plant, aware of its conditions'**
  String get lockedUnlockChatDesc;

  /// No description provided for @lockedPlanYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get lockedPlanYear;

  /// No description provided for @lockedPlanMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get lockedPlanMonth;

  /// No description provided for @lockedPlanYearNote.
  ///
  /// In en, this message translates to:
  /// **'\$21.99 a year · \$1.83 a month'**
  String get lockedPlanYearNote;

  /// No description provided for @lockedPlanMonthNote.
  ///
  /// In en, this message translates to:
  /// **'\$1.99 a month · cancel any time'**
  String get lockedPlanMonthNote;

  /// No description provided for @lockedPlanBadge.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get lockedPlanBadge;

  /// No description provided for @lockedFinePrint.
  ///
  /// In en, this message translates to:
  /// **'The subscription renews automatically. Cancel any time in your store settings.'**
  String get lockedFinePrint;

  /// No description provided for @lockedCtaResume.
  ///
  /// In en, this message translates to:
  /// **'Resume · {plan}'**
  String lockedCtaResume(String plan);

  /// No description provided for @lockedCtaUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade · {plan}'**
  String lockedCtaUpgrade(String plan);

  /// No description provided for @lockedRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get lockedRestore;

  /// No description provided for @lockedRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get lockedRestoreDone;

  /// No description provided for @lockedRestoreNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account'**
  String get lockedRestoreNothing;

  /// No description provided for @billingIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'A payment did not go through'**
  String get billingIssueTitle;

  /// No description provided for @billingIssueBody.
  ///
  /// In en, this message translates to:
  /// **'Check your payment method — access stays on while the store retries.'**
  String get billingIssueBody;

  /// No description provided for @duplicateSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Two subscriptions found'**
  String get duplicateSubscriptionTitle;

  /// No description provided for @duplicateSubscriptionBody.
  ///
  /// In en, this message translates to:
  /// **'You are paying in the App Store and on the web at the same time. Cancel one of them.'**
  String get duplicateSubscriptionBody;

  /// No description provided for @gateBarTitleTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial finished'**
  String get gateBarTitleTrial;

  /// No description provided for @gateBarTitleExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription is not active'**
  String get gateBarTitleExpired;

  /// No description provided for @gateBarBody.
  ///
  /// In en, this message translates to:
  /// **'Watering keeps working; analysis and the assistant need a subscription'**
  String get gateBarBody;

  /// No description provided for @gateBarAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get gateBarAction;

  /// No description provided for @gateStaleScore.
  ///
  /// In en, this message translates to:
  /// **'The score is not updating — it needs a health check'**
  String get gateStaleScore;

  /// No description provided for @gateSheetHealth.
  ///
  /// In en, this message translates to:
  /// **'Health check {accent}'**
  String gateSheetHealth(String accent);

  /// No description provided for @gateSheetChat.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant {accent}'**
  String gateSheetChat(String accent);

  /// No description provided for @gateSheetAccent.
  ///
  /// In en, this message translates to:
  /// **'needs a subscription'**
  String get gateSheetAccent;

  /// No description provided for @gateSheetBody.
  ///
  /// In en, this message translates to:
  /// **'The trial has finished. The plant and its care stay with you — only what the AI works out comes back with a subscription.'**
  String get gateSheetBody;

  /// No description provided for @gateSheetKeepWatering.
  ///
  /// In en, this message translates to:
  /// **'Watering and reminders keep working'**
  String get gateSheetKeepWatering;

  /// No description provided for @gateSheetKeepHistory.
  ///
  /// In en, this message translates to:
  /// **'Check history and care cards stay open'**
  String get gateSheetKeepHistory;

  /// No description provided for @gateSheetCta.
  ///
  /// In en, this message translates to:
  /// **'Resume subscription'**
  String get gateSheetCta;

  /// No description provided for @gateSheetLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get gateSheetLater;

  /// No description provided for @limitLabel.
  ///
  /// In en, this message translates to:
  /// **'Every slot is taken'**
  String get limitLabel;

  /// No description provided for @limitCountOf.
  ///
  /// In en, this message translates to:
  /// **'of {limit} slots'**
  String limitCountOf(int limit);

  /// No description provided for @limitPlanTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get limitPlanTrial;

  /// No description provided for @limitPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get limitPlanFree;

  /// No description provided for @limitPlanPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get limitPlanPremium;

  /// No description provided for @limitLegendUsed.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get limitLegendUsed;

  /// No description provided for @limitLegendLocked.
  ///
  /// In en, this message translates to:
  /// **'Opens with Premium'**
  String get limitLegendLocked;

  /// No description provided for @limitLeadTrial.
  ///
  /// In en, this message translates to:
  /// **'There are {accent}'**
  String limitLeadTrial(String accent);

  /// No description provided for @limitLeadTrialAccent.
  ///
  /// In en, this message translates to:
  /// **'no free slots left'**
  String get limitLeadTrialAccent;

  /// No description provided for @limitLeadFree.
  ///
  /// In en, this message translates to:
  /// **'The free plan has {accent}'**
  String limitLeadFree(String accent);

  /// No description provided for @limitLeadFreeAccent.
  ///
  /// In en, this message translates to:
  /// **'{limit} slots'**
  String limitLeadFreeAccent(int limit);

  /// No description provided for @limitLeadPremium.
  ///
  /// In en, this message translates to:
  /// **'All ten slots {accent}'**
  String limitLeadPremium(String accent);

  /// No description provided for @limitLeadPremiumAccent.
  ///
  /// In en, this message translates to:
  /// **'are taken'**
  String get limitLeadPremiumAccent;

  /// No description provided for @limitBody.
  ///
  /// In en, this message translates to:
  /// **'Free up a slot or open ten of them.'**
  String get limitBody;

  /// No description provided for @limitBodyPremium.
  ///
  /// In en, this message translates to:
  /// **'Remove a plant you no longer keep to make room for a new one.'**
  String get limitBodyPremium;

  /// No description provided for @limitPathUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Open 10 slots'**
  String get limitPathUpgrade;

  /// No description provided for @limitPathUpgradeDesc.
  ///
  /// In en, this message translates to:
  /// **'Health checks and the assistant come with it'**
  String get limitPathUpgradeDesc;

  /// No description provided for @limitPathFree.
  ///
  /// In en, this message translates to:
  /// **'Free up a slot'**
  String get limitPathFree;

  /// No description provided for @limitPathFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove a plant you no longer keep'**
  String get limitPathFreeDesc;

  /// No description provided for @limitPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get limitPremiumTitle;

  /// No description provided for @limitCtaUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade · {plan}'**
  String limitCtaUpgrade(String plan);

  /// No description provided for @weatherDetectedByNetwork.
  ///
  /// In en, this message translates to:
  /// **'Detected from network'**
  String get weatherDetectedByNetwork;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileCityHint.
  ///
  /// In en, this message translates to:
  /// **'Affects care recommendations'**
  String get profileCityHint;

  /// No description provided for @unitsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature units'**
  String get unitsTemperature;

  /// No description provided for @unitsCelsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get unitsCelsius;

  /// No description provided for @unitsFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'°F'**
  String get unitsFahrenheit;

  /// No description provided for @unitsAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get unitsAutomatic;

  /// No description provided for @weatherDegrees.
  ///
  /// In en, this message translates to:
  /// **'{value}°'**
  String weatherDegrees(String value);

  /// No description provided for @chatProposalApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get chatProposalApply;

  /// No description provided for @chatProposalDecline.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get chatProposalDecline;

  /// No description provided for @chatProposalApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get chatProposalApplied;

  /// No description provided for @chatProposalDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get chatProposalDeclined;

  /// No description provided for @chatProposalOutdated.
  ///
  /// In en, this message translates to:
  /// **'Outdated'**
  String get chatProposalOutdated;

  /// No description provided for @chatProposalPot.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get chatProposalPot;

  /// No description provided for @chatProposalSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get chatProposalSpecies;

  /// No description provided for @chatProposalPause.
  ///
  /// In en, this message translates to:
  /// **'Pause reminders until'**
  String get chatProposalPause;

  /// No description provided for @chatProposalChange.
  ///
  /// In en, this message translates to:
  /// **'{label}: {from} → {to}'**
  String chatProposalChange(String label, String from, String to);

  /// No description provided for @chatProposalSet.
  ///
  /// In en, this message translates to:
  /// **'{label}: {to}'**
  String chatProposalSet(String label, String to);

  /// No description provided for @chatTopicWater.
  ///
  /// In en, this message translates to:
  /// **'Watering'**
  String get chatTopicWater;

  /// No description provided for @chatTopicSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get chatTopicSoil;

  /// No description provided for @chatTopicLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get chatTopicLight;

  /// No description provided for @chatTopicTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get chatTopicTemperature;

  /// No description provided for @chatTopicFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertiliser'**
  String get chatTopicFertilizer;

  /// No description provided for @chatTopicDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get chatTopicDiagnostics;

  /// No description provided for @chatShowWholeConversation.
  ///
  /// In en, this message translates to:
  /// **'Show whole conversation'**
  String get chatShowWholeConversation;

  /// No description provided for @chatTitleWithTopic.
  ///
  /// In en, this message translates to:
  /// **'Assistant · {topic}'**
  String chatTitleWithTopic(String topic);

  /// No description provided for @plantChatQuickWaterEarly.
  ///
  /// In en, this message translates to:
  /// **'Can I water it earlier?'**
  String get plantChatQuickWaterEarly;

  /// No description provided for @plantChatQuickSoilSlowToDry.
  ///
  /// In en, this message translates to:
  /// **'Why is the soil slow to dry?'**
  String get plantChatQuickSoilSlowToDry;

  /// No description provided for @plantChatQuickEnoughLight.
  ///
  /// In en, this message translates to:
  /// **'Is it getting enough light?'**
  String get plantChatQuickEnoughLight;

  /// No description provided for @plantChatQuickLeggyGrowth.
  ///
  /// In en, this message translates to:
  /// **'Why is it getting leggy?'**
  String get plantChatQuickLeggyGrowth;

  /// No description provided for @plantChatQuickShouldMove.
  ///
  /// In en, this message translates to:
  /// **'Should I move it?'**
  String get plantChatQuickShouldMove;

  /// No description provided for @plantChatQuickRepotWhen.
  ///
  /// In en, this message translates to:
  /// **'When should I repot it?'**
  String get plantChatQuickRepotWhen;

  /// No description provided for @plantChatQuickSoilCompacted.
  ///
  /// In en, this message translates to:
  /// **'Why has the soil gone hard?'**
  String get plantChatQuickSoilCompacted;

  /// No description provided for @plantChatQuickWhichSoil.
  ///
  /// In en, this message translates to:
  /// **'Which soil is best for it?'**
  String get plantChatQuickWhichSoil;

  /// No description provided for @memoryTitle.
  ///
  /// In en, this message translates to:
  /// **'What the assistant knows'**
  String get memoryTitle;

  /// No description provided for @memoryExplainer.
  ///
  /// In en, this message translates to:
  /// **'Written from what you tell the assistant in chat. Remove anything that is wrong — it is used in every answer.'**
  String get memoryExplainer;

  /// No description provided for @memoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load.'**
  String get memoryLoadFailed;

  /// No description provided for @memorySuperseded.
  ///
  /// In en, this message translates to:
  /// **'replaced'**
  String get memorySuperseded;

  /// No description provided for @memoryForgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget this?'**
  String get memoryForgetConfirm;

  /// No description provided for @memoryForgetAction.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get memoryForgetAction;

  /// No description provided for @memoryKindPlacement.
  ///
  /// In en, this message translates to:
  /// **'Where it stands'**
  String get memoryKindPlacement;

  /// No description provided for @memoryKindContainer.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get memoryKindContainer;

  /// No description provided for @memoryKindWateringHabit.
  ///
  /// In en, this message translates to:
  /// **'Care habits'**
  String get memoryKindWateringHabit;

  /// No description provided for @memoryKindSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get memoryKindSpecies;

  /// No description provided for @memoryKindEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get memoryKindEnvironment;

  /// No description provided for @memoryKindIntervention.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get memoryKindIntervention;

  /// No description provided for @memoryKindSymptom.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get memoryKindSymptom;

  /// No description provided for @memoryKindConstraint.
  ///
  /// In en, this message translates to:
  /// **'Constraint'**
  String get memoryKindConstraint;

  /// No description provided for @memoryKindGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get memoryKindGoal;

  /// No description provided for @memoryKindPreference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get memoryKindPreference;

  /// No description provided for @memoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. As you talk about {name}, what you tell the assistant is kept here.'**
  String memoryEmpty(String name);

  /// No description provided for @chatTaskOffer.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder?'**
  String get chatTaskOffer;

  /// No description provided for @chatTaskInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String chatTaskInDays(int days);

  /// No description provided for @chatTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get chatTaskCreated;

  /// No description provided for @chatCtxNextWatering.
  ///
  /// In en, this message translates to:
  /// **'Next watering in {days} d.'**
  String chatCtxNextWatering(int days);

  /// No description provided for @chatCtxWaterToday.
  ///
  /// In en, this message translates to:
  /// **'Watering due today'**
  String get chatCtxWaterToday;

  /// No description provided for @chatCtxLastWatered.
  ///
  /// In en, this message translates to:
  /// **'Last watered {date}'**
  String chatCtxLastWatered(String date);

  /// No description provided for @chatCtxLight.
  ///
  /// In en, this message translates to:
  /// **'{hours} h · {type}'**
  String chatCtxLight(String hours, String type);

  /// No description provided for @chatCtxTemperature.
  ///
  /// In en, this message translates to:
  /// **'Optimum {value}'**
  String chatCtxTemperature(String value);

  /// No description provided for @chatCtxFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Feed {value}'**
  String chatCtxFertilizer(String value);

  /// No description provided for @careDiscussWithAssistant.
  ///
  /// In en, this message translates to:
  /// **'Discuss with the assistant'**
  String get careDiscussWithAssistant;

  /// No description provided for @chatProposalNextWatering.
  ///
  /// In en, this message translates to:
  /// **'Next watering'**
  String get chatProposalNextWatering;

  /// No description provided for @chatProposalToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get chatProposalToday;

  /// No description provided for @cityPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing a city'**
  String get cityPickerHint;

  /// No description provided for @cityPickerStartTyping.
  ///
  /// In en, this message translates to:
  /// **'Type at least two letters'**
  String get cityPickerStartTyping;

  /// No description provided for @cityPickerSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get cityPickerSearching;

  /// No description provided for @cityPickerNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No city found by that name'**
  String get cityPickerNothingFound;

  /// No description provided for @cityUpdated.
  ///
  /// In en, this message translates to:
  /// **'City updated'**
  String get cityUpdated;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'ru': return AppLocalizationsRu();
    case 'uk': return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
