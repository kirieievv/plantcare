import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? healthProblem;
  final List<String>? healthIndicators;
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
    this.healthProblem,
    this.healthIndicators,
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
      'healthProblem': healthProblem,
      'healthIndicators': healthIndicators,
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
      healthProblem: map['healthProblem'],
      healthIndicators: map['healthIndicators'] != null 
          ? List<String>.from(map['healthIndicators'])
          : null,
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
    String? healthProblem,
    List<String>? healthIndicators,
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
      healthProblem: healthProblem ?? this.healthProblem,
      healthIndicators: healthIndicators ?? this.healthIndicators,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
    );
  }
} 