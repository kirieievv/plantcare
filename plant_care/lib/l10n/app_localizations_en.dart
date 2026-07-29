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
  String get yourGardenOverview => 'Garden Overview';

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
  String get pleaseConfirmYourPassword => 'Please confirm your password';

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
  String get russian => 'Russian';

  @override
  String get ukrainian => 'Ukrainian';

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
  String get addYourFirstPlant => 'Add your first plant';

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
  String get plantChatImageQuotaReached => 'Daily photo limit reached. Try again tomorrow.';

  @override
  String get splashTagline => 'Your smart plant companion';

  @override
  String get getStarted => 'Get Started';

  @override
  String get splashDescription => 'Monitor your plants, get personalised care tips,\nand track their health — all in one place.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get errorInvalidPin => 'Incorrect code. Please try again.';

  @override
  String get errorPinExpired => 'The code has expired. Please request a new one.';

  @override
  String get errorPinNotFound => 'No code found. Please request a new one.';

  @override
  String get errorTooManyAttempts => 'Too many attempts. Please request a new code.';

  @override
  String get errorSendFailed => 'Could not send the code. Please try again.';

  @override
  String get errorUserNotFound => 'No account found with this email.';

  @override
  String get errorEmailAlreadyExists => 'An account with this email already exists.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

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
  String resendCodeInSeconds(int seconds) {
    return 'Resend code in ${seconds}s';
  }

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
  String get yourPlants => 'My Plants';

  @override
  String get plantCreatedSuccessfully => 'Plant created successfully! 🌱';

  @override
  String get searchPlantsHint => 'Search plants…';

  @override
  String get filterAll => 'All';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get noResultsTitle => 'No matches';

  @override
  String get noResultsSub => 'Try another search or filter.';

  @override
  String get edit => 'Edit';

  @override
  String get wateringRemindersBlockSub => 'Get notified when your plants need water.';

  @override
  String get emailRemindersTitle => 'Email reminders';

  @override
  String get emailRemindersSub => 'Receive watering reminders by email';

  @override
  String get pushNotificationsTitle => 'Push notifications';

  @override
  String get pushNotificationsSub => 'Get instant alerts on your device';

  @override
  String get quietHoursLabel => 'Quiet hours';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get accountTitle => 'Account';

  @override
  String get changePasswordTitleRow => 'Change password';

  @override
  String get changePasswordSubRow => 'Update your account password';

  @override
  String get signOutSubRow => 'Sign out of your account';

  @override
  String get aiAssistantOnline => 'AI Plant Assistant · online';

  @override
  String get clearHistoryAction => 'Clear history';

  @override
  String get clearHistoryConfirm => 'Clear chat history?';

  @override
  String get saving => 'Saving…';

  @override
  String get plantPhoto => 'Plant photo';

  @override
  String get addPlantTitle => 'Add plant';

  @override
  String get addPlantSubtitle => 'Snap, identify, then save';

  @override
  String get snapTitle => 'Snap a photo';

  @override
  String get snapDescription => 'A clear photo helps our AI identify\nyour plant and tailor care';

  @override
  String get useCamera => 'Use camera';

  @override
  String get uploadFromGallery => 'Upload from gallery';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get couldntIdentify => 'We couldn\'t identify this plant';

  @override
  String get tryAnotherPhoto => 'Try another photo or enter the species manually below.';

  @override
  String get topMatch => 'Top match';

  @override
  String get useThisMatch => 'Use this match';

  @override
  String get manualNamePlaceholder => 'Plant nickname (e.g. Iris)';

  @override
  String get savePlantBtn => 'Save plant';

  @override
  String get tagOverdue => 'OVERDUE';

  @override
  String get tagDueSoon => 'DUE SOON';

  @override
  String get tagHealthy => 'HEALTHY';

  @override
  String get wateringScheduleTitle => 'Watering schedule';

  @override
  String get lastWatered => 'Last watered';

  @override
  String get nextWatering => 'Next watering';

  @override
  String get frequency => 'Frequency';

  @override
  String get waterNowAction => 'Water now';

  @override
  String get rescheduleAction => 'Reschedule';

  @override
  String get careRecommendationsTitle => 'Care Recommendations';

  @override
  String get careSectionCultivar => 'Cultivar';

  @override
  String get careSectionGeneralDescription => 'General Description';

  @override
  String get careSectionSoil => 'Soil';

  @override
  String get careSectionSoilMoisture => 'Soil Moisture';

  @override
  String get careSectionMoistureCheck => 'Moisture Check';

  @override
  String get careSectionWater => 'Water';

  @override
  String get careSectionLight => 'Light';

  @override
  String get careSectionTemperature => 'Temperature';

  @override
  String get careSectionFertilizer => 'Fertilizer';

  @override
  String get careSectionGrowthRate => 'Growth Rate';

  @override
  String get careSectionToxicity => 'Toxicity';

  @override
  String get careSectionPlacement => 'Placement';

  @override
  String get careSectionPersonality => 'Personality';

  @override
  String get aboutPlantTitle => 'About this plant';

  @override
  String get askAssistantTitle => 'Ask the assistant';

  @override
  String get askAssistantSub => 'Get tailored advice from Iris AI';

  @override
  String get openChat => 'Open chat';

  @override
  String get deletePlantAction => 'Delete plant';

  @override
  String get reminderEmail => 'Email';

  @override
  String get reminderEmailSubtitle => 'Watering reminder emails';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Alerts in the app (iOS / Android)';

  @override
  String wateringOverdueNDays(int days) {
    return 'Overdue ${days}d';
  }

  @override
  String get wateringToday => 'Watering today';

  @override
  String get wateringTomorrow => 'Watering tomorrow';

  @override
  String wateringInNDays(int days) {
    return 'Watering in ${days}d';
  }

  @override
  String plantWateredSuccess(Object plantName) {
    return '$plantName has been watered! 💧';
  }

  @override
  String errorWateringPlant(Object error) {
    return 'Error watering plant: $error';
  }

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
  String nDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get healthStatusOk => 'OK';

  @override
  String get healthStatusIssue => 'Issue';

  @override
  String get assistantTyping => 'Assistant is typing...';

  @override
  String chatSourceLabel(Object source) {
    return 'Source: $source';
  }

  @override
  String get chatSourceKnowledgeBase => 'Knowledge Base';

  @override
  String get chatSourceContext => 'Context';

  @override
  String get chatSourceAgent => 'Agent';

  @override
  String get chatAttachPhoto => 'Attach photo';

  @override
  String chatPhotoQuota(int used, int limit) {
    return '$used/$limit photos today';
  }

  @override
  String get chatPhotoQuotaExhausted => 'Daily photo limit reached. Try again tomorrow.';

  @override
  String get chatPhotoUploading => 'Uploading photo...';

  @override
  String get chatPhotoUploadFailed => 'Failed to upload photo. Please try again.';

  @override
  String get chatRemovePhoto => 'Remove photo';

  @override
  String get chatCopyMessage => 'Copy';

  @override
  String get chatClearHistory => 'New Chat';

  @override
  String get chatClearHistoryConfirm => 'Start a new conversation? This will delete the current history.';

  @override
  String get chatClearHistorySuccess => 'New conversation started.';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get analyzeHealth => 'Analyze Health';

  @override
  String get waterFirstLabel => 'Water first';

  @override
  String nextCheckAfterWatering(int days) {
    return 'Next check in $days d';
  }

  @override
  String get imageReadyForAnalysis => 'Image uploaded successfully! Ready for health analysis.';

  @override
  String get healthCheckTitle => 'Health Check';

  @override
  String get healthCheckHistoryTitle => 'Health Check History';

  @override
  String healthCheckUploadHint(Object plantName) {
    return 'Upload a photo of $plantName for AI health analysis';
  }

  @override
  String get deletePlant => 'Delete Plant';

  @override
  String get deletePlantConfirm => 'Are you sure you want to delete this plant?';

  @override
  String get delete => 'Delete';

  @override
  String get iHaveWatered => 'I have watered';

  @override
  String get soilMoisture => 'Ideal Soil';

  @override
  String get lightLabel => 'Light';

  @override
  String get perDay => 'per day';

  @override
  String get hoursLabel => 'hours';

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
  String plantDeletedMessage(Object plantName) {
    return 'Plant \"$plantName\" has been deleted';
  }

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

  @override
  String get wateringLabel => 'Watering';

  @override
  String get nowLabel => 'Now';

  @override
  String get nextIn1Day => 'Next in 1 day';

  @override
  String nextInNDays(int days) {
    return 'Next in $days days';
  }

  @override
  String get wateringDone => 'Watering done';

  @override
  String get moistureDry => 'Dry';

  @override
  String get moistureWet => 'Wet';

  @override
  String get moistureLevelVeryDry => 'Very dry';

  @override
  String get moistureLevelDry => 'Dry';

  @override
  String get moistureLevelSlightlyMoist => 'Slightly moist';

  @override
  String get moistureLevelMoist => 'Moist';

  @override
  String get moistureLevelVeryMoist => 'Very moist';

  @override
  String bannerWaterTitle(String name) {
    return '$name needs water';
  }

  @override
  String get bannerWaterSubtitle => 'Tap to water or check details';

  @override
  String get bannerTipTitle => 'Tip of the Day';

  @override
  String get bannerTipSubtitle => 'Tap for more seasonal tips';

  @override
  String get tipsOfTheDay => 'Tips of the Day';

  @override
  String get tipsOfTheDaySub => 'AI-powered seasonal advice · updated weekly';

  @override
  String get tipCategoryWatering => 'Watering';

  @override
  String get tipCategoryLight => 'Light';

  @override
  String get tipCategoryPests => 'Pests';

  @override
  String get tipCategoryFertilizing => 'Fertilizing';

  @override
  String get tipCategorySeasonal => 'Seasonal';

  @override
  String get tipCategoryGeneral => 'General';

  @override
  String get noTipsYet => 'Tips are being generated. Check back soon!';

  @override
  String get waterNow => 'Water now';

  @override
  String get subscriptionUpgrade => 'Upgrade';

  @override
  String get subscriptionManage => 'Manage';

  @override
  String get subscriptionActiveTitle => 'Premium Active';

  @override
  String get subscriptionGrandfatheredTitle => 'Lifetime Access';

  @override
  String get subscriptionTrialTitle => 'Free Trial';

  @override
  String get subscriptionExpiredTitle => 'Subscription Expired';

  @override
  String subscriptionActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String subscriptionTrialEndsOn(String date) {
    return 'Trial ends on $date';
  }

  @override
  String subscriptionTrialDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get subscriptionExpiredMessage => 'Your subscription has expired. Upgrade to continue.';

  @override
  String get subscriptionPlantLimitReached => 'Plant limit reached';

  @override
  String subscriptionPlantLimitBannerTrial(int limit) {
    return 'Free plan limit reached. Upgrade to Premium — up to $limit plants.';
  }

  @override
  String get subscriptionPlantLimitBannerExpired => 'Subscribe to add more plants.';

  @override
  String get subscriptionReadOnlyNotice => 'Read-only mode. Subscribe to edit your plants.';

  @override
  String get paywallTitle => 'Unlock Premium';

  @override
  String get paywallSubtitle => 'Get the most out of your plant collection';

  @override
  String paywallFeature1(int limit) {
    return 'Up to $limit plants';
  }

  @override
  String get paywallFeature2 => 'Unlimited watering reminders';

  @override
  String get paywallFeature3 => 'AI plant assistant & health checks';

  @override
  String get paywallFeature4 => 'Full editing & care tracking';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallAnnual => 'Annual';

  @override
  String get paywallBestValue => 'Best value';

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallRestore => 'Restore purchase';

  @override
  String get paywallRestoring => 'Restoring…';

  @override
  String get paywallRestoreSuccess => 'Purchase restored!';

  @override
  String get paywallRestoreNotFound => 'No previous purchase found.';

  @override
  String get paywallRestoreAlreadyActive => 'Your subscription is already active.';

  @override
  String get paywallTerms => 'Subscription auto-renews. Cancel anytime in App Store settings.';

  @override
  String get paywallLoading => 'Loading plans…';

  @override
  String get paywallPurchasing => 'Processing…';

  @override
  String get paywallError => 'Something went wrong. Please try again.';

  @override
  String get paywallHeroTitle => 'Grow without limits.';

  @override
  String get paywallHeroDescription => 'Your personal AI assistant — watering reminders, health checks, seasonal tips, and everything you need to keep plants thriving.';

  @override
  String get paywallChoosePlan => 'CHOOSE YOUR PLAN';

  @override
  String paywallPerMonth(Object price) {
    return 'Only $price / month';
  }

  @override
  String get paywallStartPremium => 'Start Premium';

  @override
  String get paywallSecured => 'Stripe secured';

  @override
  String get paywallSecuredApple => 'Secured';

  @override
  String get paywallCancelAnytime => 'Cancel anytime';

  @override
  String get paywallAutoRenews => 'auto-renews';

  @override
  String get stripeSuccessTitle => 'Subscription activated!';

  @override
  String get stripeSuccessWaiting => 'Activating your subscription';

  @override
  String get stripeSuccessSubtitle => 'Welcome to Botanly Premium! You now have access to all features.';

  @override
  String get stripeSuccessButton => 'Go to my plants';

  @override
  String errorOpeningBillingPortal(Object error) {
    return 'Could not open billing portal: $error';
  }

  @override
  String errorRestoring(Object error) {
    return 'Failed to restore: $error';
  }

  @override
  String get emailCopied => 'Email copied: support@botanly.app';

  @override
  String get labelExpires => 'Expires';

  @override
  String get labelNextRenewal => 'Next renewal';

  @override
  String get labelAutoRenewal => 'Auto-renewal';

  @override
  String get labelRestorePurchases => 'Restore Purchases';

  @override
  String get labelPlants => 'Plants';

  @override
  String get labelRenews => 'Renews';

  @override
  String get testWateringEmailQueued => 'Test watering email queued.';

  @override
  String errorSendingTestEmail(Object error) {
    return 'Could not send test email: $error';
  }

  @override
  String failedToSaveReminderChannels(Object error) {
    return 'Failed to save reminder channels: $error';
  }

  @override
  String failedToUpdateQuietHours(Object error) {
    return 'Failed to update quiet hours: $error';
  }

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountSubtitle => 'Permanently disable your account';

  @override
  String get deleteAccountConfirmBody => 'Your account will be permanently disabled and you will lose access to the app. Your plant data will be retained.\n\nThis action cannot be undone.';

  @override
  String get deleteAccountAreYouSure => 'Are you sure?';

  @override
  String get deleteAccountTypeConfirm => 'Type DELETE to confirm:';

  @override
  String get deleteAccountConfirmBtn => 'Confirm Delete';

  @override
  String errorDeletingAccount(Object error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get subPillPremium => 'Premium';

  @override
  String get subPillEarlyMember => 'Early member';

  @override
  String get subPillFreePlan => 'Free plan';

  @override
  String get subPillFreeTrial => 'Free trial';

  @override
  String get subMetaActivePlan => 'ACTIVE PLAN';

  @override
  String get subMetaForeverPremium => 'FOREVER PREMIUM';

  @override
  String get subMetaTrialEnded => 'TRIAL ENDED';

  @override
  String subMetaNDayPreview(int n) {
    return '$n-DAY PREVIEW';
  }

  @override
  String subRenewsInDays(int days, Object date) {
    return 'Renews in $days days · $date';
  }

  @override
  String subEndsInDays(int days, Object date) {
    return 'Ends in $days days · $date';
  }

  @override
  String get subActiveSubscription => 'Active subscription';

  @override
  String get subGrantedEarlyMember => 'Granted as an early Botanly member';

  @override
  String get subDaysLeft => 'days left';

  @override
  String get subUntilPreviewEnds => 'until your\npreview ends';

  @override
  String get subTrialEnded => 'trial ended';

  @override
  String get subAutoRenewOn => 'Auto-renew on  ·  Cancel anytime';

  @override
  String get subAutoRenewOff => 'Auto-renew off  ·  Access until expiry';

  @override
  String get subDetails => 'Details';

  @override
  String get subReactivate => 'Reactivate';

  @override
  String get subNoChargesEver => 'No charges, ever  ·  All perks unlocked';

  @override
  String get subLimitedAccess => 'Limited access  ·  No AI care';

  @override
  String get subUnlimitedAccess => 'Unlimited  ·  AI care  ·  Reminders';

  @override
  String get subHeroYourePrefix => 'You\'re ';

  @override
  String get subHeroGrowingWord => 'growing';

  @override
  String get subHeroForeverWord => 'Forever';

  @override
  String get subHeroPremiumSuffix => ' Premium';

  @override
  String get labelEnds => 'Ends';

  @override
  String get labelPlan => 'Plan';

  @override
  String get labelPremium => 'Premium';

  @override
  String get labelGrandfathered => 'Grandfathered (Legacy)';

  @override
  String get labelOn => 'On';

  @override
  String get labelOff => 'Off';

  @override
  String get yourPlan => 'Your Plan';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get manageBillingWeb => 'Manage Billing';

  @override
  String get manageInAppStore => 'Manage in App Store';

  @override
  String get manageBillingSubtitleWeb => 'Cancel, update your card or view invoices\nvia the Stripe billing portal.';

  @override
  String get manageBillingSubtitleAppStore => 'To turn off auto-renewal or cancel, go to your\nApp Store subscriptions.';

  @override
  String get tipGoodLight => 'good light';

  @override
  String get tipShowLeaves => 'show the leaves';

  @override
  String get tipSinglePlant => 'single plant';

  @override
  String get snapYourSprout => 'Snap your sprout';

  @override
  String get identifyingPlantPrefix => 'Identifying your ';

  @override
  String get identifyingPlantWord => 'plant';

  @override
  String get identifyingSubtitle => 'Looking at leaves, stems and friends nearby';

  @override
  String get specificIssues => 'Specific issues';

  @override
  String get healthCheckPhotoHint => 'Add up to 3 photos — more angles means a more accurate analysis. Only the first photo is required.';

  @override
  String healthCheckPhotoCounter(int count) {
    return '$count / 3';
  }

  @override
  String get healthCheckSlot1Title => 'Full plant';

  @override
  String get healthCheckSlot1Desc => 'Photograph the entire plant including the pot — so the soil and full pot are visible.';

  @override
  String get healthCheckSlot1Tag => 'Required';

  @override
  String get healthCheckSlot2Title => 'Close-up';

  @override
  String get healthCheckSlot2Desc => 'Bring the camera closer, without the pot — to clearly see the leaves and their texture.';

  @override
  String get healthCheckSlot2Tag => 'Optional';

  @override
  String get healthCheckSlot3Title => 'Problem area';

  @override
  String get healthCheckSlot3Desc => 'Want to show something specific? Photograph a spot, pest, or damaged leaf.';

  @override
  String get healthCheckSlot3Tag => 'Optional';

  @override
  String healthCheckAnalyzeNPhotos(int count) {
    return 'Analyze $count photo(s)';
  }

  @override
  String get healthCheckError => 'Analysis failed. Please try again.';

  @override
  String get healthCheckDefaultPraise => '🌱 Your plant is doing fine!';

  @override
  String get healthCheckDefaultFooter => 'Keep caring for your plant per the recommendations below and log when you water.';

  @override
  String get addPlantWholePlantTitle => 'Whole plant';

  @override
  String get addPlantWholePlantDesc => 'with the pot & soil';

  @override
  String get addPlantWholePlantTag => 'Required';

  @override
  String get addPlantCloseUpTitle => 'Close-up';

  @override
  String get addPlantCloseUpDesc => 'leaves in detail';

  @override
  String get addPlantCloseUpTag => 'Optional';

  @override
  String get addPlantDualHint => 'Two angles help our AI identify your plant more accurately.';

  @override
  String get addPlantAnalyzeButton => 'Analyze Plant';

  @override
  String get addPlantStepPhotosReceived => 'Photos received';

  @override
  String get addPlantStepIdentifying => 'Identifying species';

  @override
  String get addPlantStepCarePlan => 'Tailoring a care plan';

  @override
  String get addPlantAnalyzingTitle => 'Analyzing your plant';

  @override
  String get addPlantAnalyzingSubtitle => 'This usually takes a few seconds…';

  @override
  String get addPlantAnalysisComplete => 'Analysis complete';

  @override
  String get addPlantSeePlantProfile => 'See plant profile';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboarding1Eyebrow => 'Welcome';

  @override
  String get onboarding1Title => 'Meet ';

  @override
  String get onboarding1TitleItalic => 'Botanly';

  @override
  String get onboarding1Body => 'Your AI companion for happy, healthy plants — right in your pocket.';

  @override
  String get onboarding2Eyebrow => 'Identify';

  @override
  String get onboarding2Title => 'Name ';

  @override
  String get onboarding2TitleItalic => 'any plant';

  @override
  String get onboarding2Body => 'Point your camera and let AI identify it in seconds — species, name and all.';

  @override
  String get onboarding3Eyebrow => 'Care';

  @override
  String get onboarding3Title => 'Care made ';

  @override
  String get onboarding3TitleItalic => 'effortless';

  @override
  String get onboarding3Body => 'Watering, light and soil reminders — perfectly tuned to each plant you own.';

  @override
  String get onboarding4Eyebrow => 'Health Check';

  @override
  String get onboarding4Title => 'Spot problems ';

  @override
  String get onboarding4TitleItalic => 'early';

  @override
  String get onboarding4Body => 'Snap a photo and get an instant health check with a clear plan to fix it.';

  @override
  String get onboarding5Eyebrow => 'Ready';

  @override
  String get onboarding5Title => 'Let\'s ';

  @override
  String get onboarding5TitleItalic => 'grow together';

  @override
  String get onboarding5Body => 'Build your plant shelf and never miss a beat. Your greenest era starts now.';
}
