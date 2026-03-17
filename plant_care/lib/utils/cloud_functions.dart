import 'package:firebase_core/firebase_core.dart';

/// Base URL for Cloud Functions. Uses current Firebase project selected by app config.
String get analyzePlantPhotoUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/analyzePlantPhoto';
}

/// Dedicated Health Check agent endpoint (context-aware + retries).
String get analyzeHealthCheckAgentUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/analyzeHealthCheckAgent';
}

/// Conversational endpoint for plant-specific assistant chat.
String get chatPlantAssistantUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/chatPlantAssistant';
}

/// Request one-time reset PIN for password recovery.
String get requestPasswordResetPinUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/requestPasswordResetPin';
}

/// Confirm one-time reset PIN and set new password.
String get confirmPasswordResetPinUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/confirmPasswordResetPin';
}

/// Verify one-time reset PIN before entering new password.
String get verifyPasswordResetPinUrl {
  final projectId = Firebase.app().options.projectId;
  return 'https://us-central1-$projectId.cloudfunctions.net/verifyPasswordResetPin';
}
