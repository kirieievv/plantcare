import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

/// Represents a single health check record
class HealthCheckRecord {
  final String id;
  final DateTime timestamp;
  final String status; // 'ok' or 'issue'
  final String message;
  final String? imageUrl; // Firebase Storage URL for the image
  final Uint8List? imageBytes; // Local image bytes for immediate display
  final Map<String, dynamic>? metadata; // Additional data like AI analysis details

  HealthCheckRecord({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.message,
    this.imageUrl,
    this.imageBytes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'message': message,
      'imageUrl': imageUrl,
      'metadata': metadata,
      // Note: imageBytes is not stored in Firestore, only used locally
    };
  }

  factory HealthCheckRecord.fromMap(Map<String, dynamic> map) {
    return HealthCheckRecord(
      id: map['id'],
      timestamp: Plant._parseTimestamp(map['timestamp']) ?? DateTime.now(),
      status: map['status'],
      message: map['message'],
      imageUrl: map['imageUrl'],
      imageBytes: null, // Will be loaded separately if needed
      metadata: map['metadata'],
    );
  }

  HealthCheckRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? status,
    String? message,
    String? imageUrl,
    Uint8List? imageBytes,
    Map<String, dynamic>? metadata,
  }) {
    return HealthCheckRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Plant {
  final String id;
  final String name;
  final String species;
  final String? imageUrl;
  final DateTime lastWatered;
  final DateTime nextWatering;
  final int wateringFrequency; // in days
  final String? notes;
  final DateTime createdAt;
  final String? userId;
  
  // AI-generated care recommendations
  final String? aiGeneralDescription;
  final String? aiName;
  final String? aiMoistureLevel;
  final String? aiLight;
  final String? aiSpecificIssues;
  final String? aiCareTips;
  
  // Health check data
  final String? healthStatus; // 'ok', 'issue', or null
  final String? healthMessage; // Friendly conversational message from Plant Care Assistant
  final DateTime? lastHealthCheck;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    this.imageUrl,
    required this.lastWatered,
    required this.nextWatering,
    required this.wateringFrequency,
    this.notes,
    required this.createdAt,
    this.userId,
    this.aiGeneralDescription,
    this.aiName,
    this.aiMoistureLevel,
    this.aiLight,
    this.aiSpecificIssues,
    this.aiCareTips,
    this.healthStatus,
    this.healthMessage,
    this.lastHealthCheck,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'imageUrl': imageUrl,
      'lastWatered': lastWatered.toIso8601String(),
      'nextWatering': nextWatering.toIso8601String(),
      'wateringFrequency': wateringFrequency,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'aiGeneralDescription': aiGeneralDescription,
      'aiName': aiName,
      'aiMoistureLevel': aiMoistureLevel,
      'aiLight': aiLight,
      'aiSpecificIssues': aiSpecificIssues,
      'aiCareTips': aiCareTips,
      'healthStatus': healthStatus,
      'healthMessage': healthMessage,
      'lastHealthCheck': lastHealthCheck?.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      imageUrl: map['imageUrl'],
      lastWatered: _parseTimestamp(map['lastWatered']) ?? DateTime.now(),
      nextWatering: _parseTimestamp(map['nextWatering']) ?? DateTime.now(),
      wateringFrequency: map['wateringFrequency'],
      notes: map['notes'],
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      userId: map['userId'],
      aiGeneralDescription: map['aiGeneralDescription'],
      aiName: map['aiName'],
      aiMoistureLevel: map['aiMoistureLevel'],
      aiLight: map['aiLight'],
      aiSpecificIssues: map['aiSpecificIssues'],
      aiCareTips: map['aiCareTips'],
      healthStatus: map['healthStatus'],
      healthMessage: map['healthMessage'],
      lastHealthCheck: _parseTimestamp(map['lastHealthCheck']),
    );
  }

  // Helper method to parse Firestore timestamps
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    return null;
  }

  // Copy with method for updates
  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? imageUrl,
    DateTime? lastWatered,
    DateTime? nextWatering,
    int? wateringFrequency,
    String? notes,
    DateTime? createdAt,
    String? userId,
    String? aiGeneralDescription,
    String? aiName,
    String? aiMoistureLevel,
    String? aiLight,
    String? aiSpecificIssues,
    String? aiCareTips,
    String? healthStatus,
    String? healthMessage,
    DateTime? lastHealthCheck,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imageUrl: imageUrl ?? this.imageUrl,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      aiGeneralDescription: aiGeneralDescription ?? this.aiGeneralDescription,
      aiName: aiName ?? this.aiName,
      aiMoistureLevel: aiMoistureLevel ?? this.aiMoistureLevel,
      aiLight: aiLight ?? this.aiLight,
      aiSpecificIssues: aiSpecificIssues ?? this.aiSpecificIssues,
      aiCareTips: aiCareTips ?? this.aiCareTips,
      healthStatus: healthStatus ?? this.healthStatus,
      healthMessage: healthMessage ?? this.healthMessage,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
    );
  }
} 