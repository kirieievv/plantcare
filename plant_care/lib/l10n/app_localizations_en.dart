// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plant Care';

  @override
  String get loadingPlantCare => 'Loading Plant Care...';

  @override
  String get home => 'Home';

  @override
  String get myPlants => 'My Plants';

  @override
  String get addPlant => 'Add Plant';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get authenticationError => 'Authentication Error';

  @override
  String get pleaseLoginAgain => 'Please log in again to continue';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get yourGardenOverview => 'Your Garden Overview';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordAtLeast6 => 'Password must be at least 6 characters';

  @override
  String get rememberMe30Days => 'Remember me for 30 days';

  @override
  String get logIn => 'Log in';

  @override
  String get registration => 'Registration';

  @override
  String get dontHaveAccountRegistration => 'Don\'t have an account? Registration';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Log in';

  @override
  String get loggedIn => 'Logged in';

  @override
  String get preferences => 'Preferences';

  @override
  String get wateringReminders => 'Watering Reminders';

  @override
  String get getNotifiedWhenPlantsNeedWater => 'Get notified when plants need water';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get maxNotificationsPerDay => 'Max Notifications Per Day';

  @override
  String notificationsCount(int count) {
    return '$count notifications';
  }

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get checkNotificationSetupAndPermissions => 'Check notification setup and permissions';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get updateYourAccountPassword => 'Update your account password';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutOfYourAccount => 'Sign out of your account';

  @override
  String get preferencesSavedSuccessfully => 'Preferences saved successfully!';

  @override
  String errorSavingPreferences(Object error) {
    return 'Error saving preferences: $error';
  }

  @override
  String get quietHoursUpdatedSuccessfully => 'Quiet hours updated successfully!';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get enterNewPassword => 'Enter a new password';

  @override
  String get newPasswordMustBeDifferent => 'New password must be different';

  @override
  String get confirmYourNewPassword => 'Confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully.';

  @override
  String errorChangingPassword(Object error) {
    return 'Error changing password: $error';
  }

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get userLabel => 'User';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String errorUpdatingProfile(Object error) {
    return 'Error updating profile: $error';
  }

  @override
  String get plantLover => 'Plant Lover';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get bio => 'Bio';

  @override
  String get bioHint => 'Tell us about your plant care journey...';

  @override
  String get location => 'Location';

  @override
  String get locationHint => 'Where are your plants located?';

  @override
  String get name => 'Name';

  @override
  String get notSet => 'Not set';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get memberSince => 'Member Since';

  @override
  String get lastLogin => 'Last Login';

  @override
  String get notAvailable => 'N/A';

  @override
  String get actions => 'Actions';

  @override
  String get errorLabel => 'Error';

  @override
  String get noPlantsYet => 'No plants yet!';

  @override
  String get addFirstPlantToGetStarted => 'Add your first plant to get started';

  @override
  String errorPickingImage(Object error) {
    return 'Error picking image: $error';
  }

  @override
  String failedToAnalyzePlantPhoto(int statusCode) {
    return 'Failed to analyze plant photo: $statusCode';
  }

  @override
  String get aiAnalysisCompleted => 'AI analysis completed! 🌱';

  @override
  String aiAnalysisFailed(Object error) {
    return 'AI analysis failed: $error';
  }

  @override
  String apiTestError(Object error) {
    return 'API test error: $error';
  }

  @override
  String get aiAnalysisRefreshed => 'AI analysis refreshed! 🔄';

  @override
  String aiAnalysisRefreshFailed(Object error) {
    return 'AI analysis refresh failed: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get uploadPlantPhoto => 'Upload Plant Photo';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get onceEvery7Days => 'Once every 7 days';

  @override
  String get oncePerDay => 'Once per day';

  @override
  String get oncePerWeek => 'Once per week';

  @override
  String onceEveryNDays(int days) {
    return 'Once every $days days';
  }

  @override
  String onceEveryNWeeks(int weeks) {
    return 'Once every $weeks weeks';
  }

  @override
  String get low => 'Low';

  @override
  String get mediumLow => 'Medium-Low';

  @override
  String get medium => 'Medium';

  @override
  String get mediumHigh => 'Medium-High';

  @override
  String get high => 'High';

  @override
  String get userNotAuthenticated => 'User not authenticated';

  @override
  String get pleaseUploadPlantImage => 'Please upload a plant image';

  @override
  String get pleaseWaitForAiAnalysisBeforeAddingPlant => 'Please wait for AI analysis to complete before adding the plant';

  @override
  String get plantLowercase => 'plant';

  @override
  String get plantAddedSuccessfully => 'Plant added successfully! 🌱';

  @override
  String errorAddingPlant(Object error) {
    return 'Error adding plant: $error';
  }

  @override
  String get generateRandomName => 'Generate random name';

  @override
  String get plantName => 'Plant Name';

  @override
  String get plantNameHint => 'e.g., Monstera, Snake Plant';

  @override
  String get pleaseEnterPlantName => 'Please enter a plant name';

  @override
  String get addingPlant => 'Adding Plant...';

  @override
  String get analyzingPhoto => 'Analyzing Photo...';

  @override
  String get plantUpdatedSuccessfully => 'Plant updated successfully! 🌱';

  @override
  String errorUpdatingPlant(Object error) {
    return 'Error updating plant: $error';
  }

  @override
  String get species => 'Species';

  @override
  String get wateringFrequency => 'Watering Frequency';

  @override
  String everyNDays(int days) {
    return 'Every $days day(s)';
  }

  @override
  String get pleaseSelectWateringFrequency => 'Please select watering frequency';

  @override
  String get notes => 'Notes';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get loadingImage => 'Loading image...';

  @override
  String get changeImage => 'Change Image';

  @override
  String errorDeletingPlant(Object error) {
    return 'Error deleting plant: $error';
  }

  @override
  String get plantNotDueForWateringYet => 'This plant is not due for watering yet';

  @override
  String errorBuildingPlantDetailsScreen(Object error) {
    return 'An error occurred while building the PlantDetailsScreen: $error';
  }

  @override
  String get aiCare => 'AI Care';

  @override
  String get aiAgent => 'AI Agent';

  @override
  String get plantChatOpen => 'Open plant chat';

  @override
  String plantChatTitle(Object plantName) {
    return 'Chat about $plantName';
  }

  @override
  String plantChatWelcome(Object plantName) {
    return 'Hi! I am your plant assistant for $plantName. Ask me anything about watering, health signs, or what to do next.';
  }

  @override
  String get plantChatInputHint => 'Ask about this plant...';

  @override
  String get plantChatLoginAgain => 'Please log in again.';

  @override
  String get plantChatRequestFailed => 'Chat request failed';

  @override
  String get plantChatCouldNotGenerateResponse => 'I could not generate a response. Please try again.';

  @override
  String get plantChatConnectionError => 'Something went wrong while contacting the plant assistant. Please try again.';

  @override
  String get plantChatQuickWaterToday => 'Can I water today?';

  @override
  String get plantChatQuickYellowLeaves => 'Why are leaves turning yellow?';

  @override
  String get plantChatQuickWhatToDoNow => 'What should I do now?';

  @override
  String get splashTagline => 'Your smart plant companion';

  @override
  String get getStarted => 'Get Started';

  @override
  String get splashDescription => 'Monitor your plants, get personalised care tips,\nand track their health — all in one place.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetYourPassword => 'Reset your password';

  @override
  String get enterEmailForCode => 'Enter your account email to receive a verification code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String get weSentACodeTo => 'We sent a 6-digit code to';

  @override
  String get verificationCodeSentAgain => 'Verification code sent again.';

  @override
  String resendCodeInSeconds(int seconds) => 'Resend code in ${seconds}s';

  @override
  String get resendCode => 'Resend code';

  @override
  String get setNewPassword => 'Set a new password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get passwordResetSuccess => 'Password reset successfully. Please sign in.';

  @override
  String get totalPlants => 'Total Plants';

  @override
  String get needWater => 'Need Water';

  @override
  String get healthy => 'Healthy';

  @override
  String get yourPlants => 'Your Plants';

  @override
  String get plantCreatedSuccessfully => 'Plant created successfully! 🌱';

  @override
  String get reminderEmail => 'Email';

  @override
  String get reminderEmailSubtitle => 'Watering reminder emails';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Alerts in the app (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) => 'Overdue ${days}d';

  @override
  String get wateringToday => 'Watering today';

  @override
  String get wateringTomorrow => 'Watering tomorrow';

  @override
  String wateringInNDays(int days) => 'Watering in ${days}d';

  @override
  String plantWateredSuccess(Object plantName) => '$plantName has been watered! 💧';

  @override
  String errorWateringPlant(Object error) => 'Error watering plant: $error';

  @override
  String get healthIssueDetected => 'Health Issue Detected';

  @override
  String get recommendedActionsLabel => 'Recommended Actions:';

  @override
  String get healthAlertNote => 'This alert will remain visible until a subsequent health check returns OK';

  @override
  String get addHealthCheckTooltip => 'Add Health Check';

  @override
  String get noHealthChecksYet => 'No health checks yet';

  @override
  String get uploadPhotosToTrackHealth => 'Upload photos to track your plant\'s health over time';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String nDaysAgo(int days) => '$days days ago';

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Issue';

  @override
  String get assistantTyping => 'Assistant is typing...';

  @override
  String chatSourceLabel(Object source) => 'Source: $source';

  @override
  String get chatSourceKnowledgeBase => 'Knowledge Base';

  @override
  String get chatSourceContext => 'Context';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get analyzeHealth => 'Analyze Health';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get imageReadyForAnalysis => 'Image uploaded successfully! Ready for health analysis.';

  @override
  String get healthCheckTitle => 'Health Check';

  @override
  String get healthCheckHistoryTitle => 'Health Check History';

  @override
  String healthCheckUploadHint(Object plantName) => 'Upload a photo of $plantName for AI health analysis';

  @override
  String get deletePlant => 'Delete Plant';

  @override
  String get deletePlantConfirm => 'Are you sure you want to delete this plant?';

  @override
  String get delete => 'Delete';

  @override
  String get iHaveWatered => 'I have watered';

  @override
  String get soilMoisture => 'Soil Moisture';

  @override
  String get lightLabel => 'Light';

  @override
  String get perDay => 'per day';

  @override
  String get hoursLabel => 'hours';

  @override
  String get careRecommendationsTitle => 'Care Recommendations';

  @override
  String get interestingFactsTitle => 'Interesting Facts';

  @override
  String get noCareRecommendationsYet => 'AI-generated care recommendations are not available for this plant yet.';

  @override
  String get noInterestingFactsYet => 'AI-generated interesting facts are not available for this plant yet.';

  @override
  String get noDescriptionYet => 'No description available yet.';

  @override
  String get swipeToSeeMore => 'Swipe to see more';

  @override
  String get uploadPhotosForHealthHistory => 'Upload photos to track your plant\'s health';

  @override
  String plantDeletedMessage(Object plantName) => 'Plant "$plantName" has been deleted';

  @override
  String get noImageAvailable => 'No Image Available';

  @override
  String get addPhotoToSeeYourPlant => 'Add a photo to see your plant here';

  @override
  String get isThisYourPlant => 'Is this your plant?';

  @override
  String get speciesPickSubtitle => 'We found these options — pick the one that matches';

  @override
  String get noneOfThese => 'None of these';

  @override
  String get typePlantNameRetry => 'Type the plant name and we\'ll try again';

  @override
  String get gettingCareRecommendations => 'Getting care recommendations';

  @override
  String get imageUploadedAnalysisComplete => 'Image uploaded successfully! AI analysis complete.';

  @override
  String get aiCareRecommendationsHeader => 'AI Care Recommendations';

  @override
  String get aiReady => 'AI Ready';

  @override
  String get checkPlantButton => 'Check Plant';

  @override
  String get plantCareAssistantTitle => 'Plant Care Assistant';

  @override
  String get plantNeedsHelp => 'Plant Needs Help!';

  @override
  String get whatToDoNow => 'What to do now';
  String get wateringLabel => 'Watering';
  String get nowLabel => 'Now';
  String get nextIn1Day => 'Next in 1 day';
  String nextInNDays(int days) => 'Next in $days days';
  String get wateringDone => 'Watering done';
  String get moistureDry => 'Dry';
  String get moistureWet => 'Wet';
  String get moistureLevelVeryDry => 'Very dry';
  String get moistureLevelDry => 'Dry';
  String get moistureLevelSlightlyMoist => 'Slightly moist';
  String get moistureLevelMoist => 'Moist';
  String get moistureLevelVeryMoist => 'Very moist';
}
