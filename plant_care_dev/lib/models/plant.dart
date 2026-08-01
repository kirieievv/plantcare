import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

/// Represents a single health check record
class HealthCheckRecord {
  final String id;
  final DateTime timestamp;
  final String status; // 'ok' or 'issue'
  final String message;
  final String? imageUrl; // Firebase Storage URL for the primary image (legacy / compat)
  final Uint8List? imageBytes; // Local bytes for primary image (immediate display)
  final List<String?> imageUrls; // Up to 3 Firebase Storage URLs
  final List<Uint8List?> imageBytesList; // Up to 3 local byte arrays
  final Map<String, dynamic>? metadata; // Additional data like AI analysis details

  HealthCheckRecord({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.message,
    this.imageUrl,
    this.imageBytes,
    List<String?>? imageUrls,
    List<Uint8List?>? imageBytesList,
    this.metadata,
  })  : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []),
        imageBytesList = imageBytesList ?? (imageBytes != null ? [imageBytes] : []);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'message': message,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
      'imageUrls': imageUrls,
      'metadata': metadata,
      // imageBytes / imageBytesList not stored in Firestore, only used locally
    };
  }

  factory HealthCheckRecord.fromMap(Map<String, dynamic> map) {
    try {
      if (map['id'] == null || map['id'].toString().isEmpty) {
        throw Exception('HealthCheckRecord: id is required');
      }
      if (map['status'] == null || map['status'].toString().isEmpty) {
        throw Exception('HealthCheckRecord: status is required');
      }
      if (map['message'] == null || map['message'].toString().isEmpty) {
        throw Exception('HealthCheckRecord: message is required');
      }

      final timestamp = Plant._parseTimestamp(map['timestamp']);
      if (timestamp == null) {
        throw Exception('HealthCheckRecord: invalid timestamp');
      }

      // Support both legacy single imageUrl and new imageUrls list
      List<String?> imageUrls;
      if (map['imageUrls'] is List) {
        imageUrls = (map['imageUrls'] as List).map((e) => e?.toString()).toList();
      } else if (map['imageUrl'] != null) {
        imageUrls = [map['imageUrl'].toString()];
      } else {
        imageUrls = [];
      }

      return HealthCheckRecord(
        id: map['id'].toString(),
        timestamp: timestamp,
        status: map['status'].toString(),
        message: map['message'].toString(),
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
      );
    } catch (e) {
      print('❌ HealthCheckRecord.fromMap error: $e');
      print('❌ Map data: $map');
      rethrow;
    }
  }

  HealthCheckRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? status,
    String? message,
    String? imageUrl,
    Uint8List? imageBytes,
    List<String?>? imageUrls,
    List<Uint8List?>? imageBytesList,
    Map<String, dynamic>? metadata,
  }) {
    return HealthCheckRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrls: imageUrls ?? this.imageUrls,
      imageBytesList: imageBytesList ?? this.imageBytesList,
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
  final String? aiWateringAmount; // AI-provided watering amount in ml
  final String? aiSpecificIssues;
  final String? aiCareTips;
  /// Compact labels from `care_recommendations.details` — the key-value cells
  /// in the care sheets. Keyed by `CareDetail`; null for plants analysed
  /// before the analyzer started returning them.
  final Map<String, String>? careDetails;
  final List<String>? interestingFacts;
  
  // Plant size assessment from AI analysis
  final String? aiPlantSize;
  final String? aiPotSize;
  final String? aiGrowthStage;
  
  // Scientific watering calculation fields
  final int? wateringAmountMl; // Calculated amount in milliliters
  final List<int>? wateringRangeMl; // [min, max] range in ml
  final int? nextAfterWateringHours; // Hours until next watering after today's watering
  final int? nextCheckHours; // Hours until next check (if soil is wet)
  final String? wateringMode; // 'after_watering' or 'recheck_only'
  
  // Health check data
  final String? healthStatus; // 'ok', 'issue', or null
  final String? healthMessage; // Friendly conversational message from Plant Care Assistant
  final DateTime? lastHealthCheck;
  final String? lastHealthCheckImageUrl; // URL of the most recent health check image
  
  // Watering notification fields
  final DateTime? lastWateredAt; // Replaces lastWatered for clarity
  final int? wateringIntervalDays; // Replaces wateringFrequency for clarity
  final String? preferredTime; // HH:mm format (e.g., "18:00")
  final DateTime? nextDueAt; // When the next watering is actually due (with preferred time applied)
  final DateTime? nextNotificationAt; // When to send the next notification
  final String notificationState; // 'ok', 'due', or 'overdue'
  final DateTime? snoozedUntil; // Nullable - when snooze expires
  final bool muted; // If true, no reminders for this plant
  final int overdueStreak; // Count of overdue reminders sent
  final bool shouldWaterNow; // From AI: true = water now, false = water later
  final DateTime? deletedAt; // Soft delete timestamp (null = active)

  // Ideal soil moisture range from AI (e.g. 10–20%)
  final int? idealSoilMoistureMin;
  final int? idealSoilMoistureMax;

  bool get isDeleted => deletedAt != null;

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
    this.aiWateringAmount,
    this.aiSpecificIssues,
    this.aiCareTips,
    this.careDetails,
    this.interestingFacts,
    this.aiPlantSize,
    this.aiPotSize,
    this.aiGrowthStage,
    this.wateringAmountMl,
    this.wateringRangeMl,
    this.nextAfterWateringHours,
    this.nextCheckHours,
    this.wateringMode,
    this.healthStatus,
    this.healthMessage,
    this.lastHealthCheck,
    this.lastHealthCheckImageUrl,
    this.lastWateredAt,
    this.wateringIntervalDays,
    this.preferredTime,
    this.nextDueAt,
    this.nextNotificationAt,
    String? notificationState,
    this.snoozedUntil,
    bool? muted,
    int? overdueStreak,
    bool? shouldWaterNow,
    this.deletedAt,
    this.idealSoilMoistureMin,
    this.idealSoilMoistureMax,
  })  : notificationState = notificationState ?? 'ok',
        muted = muted ?? false,
        overdueStreak = overdueStreak ?? 0,
        shouldWaterNow = shouldWaterNow ?? false;

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
      'aiWateringAmount': aiWateringAmount,
      'aiSpecificIssues': aiSpecificIssues,
      'aiCareTips': aiCareTips,
      'careDetails': careDetails,
      'interestingFacts': interestingFacts,
      'aiPlantSize': aiPlantSize,
      'aiPotSize': aiPotSize,
      'aiGrowthStage': aiGrowthStage,
      'wateringAmountMl': wateringAmountMl,
      'wateringRangeMl': wateringRangeMl,
      'nextAfterWateringHours': nextAfterWateringHours,
      'nextCheckHours': nextCheckHours,
      'wateringMode': wateringMode,
      'healthStatus': healthStatus,
      'healthMessage': healthMessage,
      'lastHealthCheck': lastHealthCheck?.toIso8601String(),
      'lastHealthCheckImageUrl': lastHealthCheckImageUrl,
      'lastWateredAt': lastWateredAt?.toIso8601String(),
      'wateringIntervalDays': wateringIntervalDays,
      'preferredTime': preferredTime,
      'nextDueAt': nextDueAt?.toIso8601String(),
      'nextNotificationAt': nextNotificationAt?.toIso8601String(),
      'notificationState': notificationState,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
      'muted': muted,
      'overdueStreak': overdueStreak,
      'shouldWaterNow': shouldWaterNow,
      'deletedAt': deletedAt?.toIso8601String(),
      'idealSoilMoistureMin': idealSoilMoistureMin,
      'idealSoilMoistureMax': idealSoilMoistureMax,
    };
  }

  // Create from Map (from Firestore)
  factory Plant.fromMap(Map<String, dynamic> map) {
    try {
      // Validate required fields
      if (map['id'] == null || map['id'].toString().isEmpty) {
        throw Exception('Plant: id is required');
      }
      if (map['name'] == null || map['name'].toString().isEmpty) {
        throw Exception('Plant: name is required');
      }
      if (map['species'] == null || map['species'].toString().isEmpty) {
        throw Exception('Plant: species is required');
      }
      if (map['wateringFrequency'] == null) {
        throw Exception('Plant: wateringFrequency is required');
      }
      
      return Plant(
        id: map['id'].toString(),
        name: map['name'].toString(),
        species: map['species'].toString(),
        imageUrl: map['imageUrl']?.toString(),
        lastWatered: _parseTimestamp(map['lastWatered']) ?? DateTime.now(),
        nextWatering: _parseTimestamp(map['nextWatering']) ?? DateTime.now(),
        wateringFrequency: map['wateringFrequency'] is int 
            ? map['wateringFrequency'] 
            : int.tryParse(map['wateringFrequency'].toString()) ?? 7,
        notes: map['notes']?.toString(),
        createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
        userId: map['userId']?.toString(),
        aiGeneralDescription: map['aiGeneralDescription']?.toString(),
        aiName: map['aiName']?.toString(),
        aiMoistureLevel: map['aiMoistureLevel']?.toString(),
        aiLight: map['aiLight']?.toString(),
        aiWateringAmount: map['aiWateringAmount']?.toString(),
        aiSpecificIssues: map['aiSpecificIssues']?.toString(),
        aiCareTips: map['aiCareTips']?.toString(),
        careDetails: map['careDetails'] is Map
            ? Map<String, String>.from((map['careDetails'] as Map)
                .map((k, v) => MapEntry(k.toString(), v.toString())))
            : null,
        interestingFacts: map['interestingFacts'] is List ? List<String>.from(map['interestingFacts']) : null,
        aiPlantSize: map['aiPlantSize']?.toString(),
        aiPotSize: map['aiPotSize']?.toString(),
        aiGrowthStage: map['aiGrowthStage']?.toString(),
        wateringAmountMl: map['wateringAmountMl'] is int 
            ? map['wateringAmountMl'] 
            : (map['wateringAmountMl'] != null ? int.tryParse(map['wateringAmountMl'].toString()) : null),
        wateringRangeMl: map['wateringRangeMl'] is List 
            ? List<int>.from(map['wateringRangeMl'].map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0))
            : null,
        nextAfterWateringHours: map['nextAfterWateringHours'] is int
            ? map['nextAfterWateringHours']
            : (map['nextAfterWateringHours'] != null ? int.tryParse(map['nextAfterWateringHours'].toString()) : null),
        nextCheckHours: map['nextCheckHours'] is int
            ? map['nextCheckHours']
            : (map['nextCheckHours'] != null ? int.tryParse(map['nextCheckHours'].toString()) : null),
        wateringMode: map['wateringMode']?.toString(),
        healthStatus: map['healthStatus']?.toString(),
        healthMessage: map['healthMessage']?.toString(),
        lastHealthCheck: _parseTimestamp(map['lastHealthCheck']),
        lastHealthCheckImageUrl: map['lastHealthCheckImageUrl']?.toString(),
        lastWateredAt: _parseTimestamp(map['lastWateredAt']),
        wateringIntervalDays: map['wateringIntervalDays'] is int
            ? map['wateringIntervalDays']
            : (map['wateringIntervalDays'] != null ? int.tryParse(map['wateringIntervalDays'].toString()) : null),
        preferredTime: map['preferredTime']?.toString(),
        nextDueAt: _parseTimestamp(map['nextDueAt']),
        nextNotificationAt: _parseTimestamp(map['nextNotificationAt']),
        notificationState: map['notificationState']?.toString(),
        snoozedUntil: _parseTimestamp(map['snoozedUntil']),
        muted: map['muted'] == true,
        overdueStreak: map['overdueStreak'] is int
            ? map['overdueStreak']
            : (map['overdueStreak'] != null ? int.tryParse(map['overdueStreak'].toString()) ?? 0 : 0),
        shouldWaterNow: map['shouldWaterNow'] is bool 
            ? (map['shouldWaterNow'] as bool)
            : false,
        deletedAt: _parseTimestamp(map['deletedAt']),
        idealSoilMoistureMin: map['idealSoilMoistureMin'] is int
            ? map['idealSoilMoistureMin']
            : (map['idealSoilMoistureMin'] != null ? int.tryParse(map['idealSoilMoistureMin'].toString()) : null),
        idealSoilMoistureMax: map['idealSoilMoistureMax'] is int
            ? map['idealSoilMoistureMax']
            : (map['idealSoilMoistureMax'] != null ? int.tryParse(map['idealSoilMoistureMax'].toString()) : null),
      );
    } catch (e) {
      print('❌ Plant.fromMap error: $e');
      print('❌ Map data: $map');
      rethrow;
    }
  }

  // Helper method to parse Firestore timestamps
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    try {
      if (timestamp is String) {
        if (timestamp.isEmpty) return null;
        return DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
    } catch (e) {
      print('❌ Error parsing timestamp: $e');
      print('❌ Timestamp value: $timestamp');
      return null;
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
    String? aiWateringAmount,
    String? aiSpecificIssues,
    String? aiCareTips,
    Map<String, String>? careDetails,
    List<String>? interestingFacts,
    String? aiPlantSize,
    String? aiPotSize,
    String? aiGrowthStage,
    int? wateringAmountMl,
    List<int>? wateringRangeMl,
    int? nextAfterWateringHours,
    int? nextCheckHours,
    String? wateringMode,
    String? healthStatus,
    String? healthMessage,
    DateTime? lastHealthCheck,
    String? lastHealthCheckImageUrl,
    DateTime? lastWateredAt,
    int? wateringIntervalDays,
    String? preferredTime,
    DateTime? nextDueAt,
    DateTime? nextNotificationAt,
    String? notificationState,
    DateTime? snoozedUntil,
    bool? muted,
    int? overdueStreak,
    bool? shouldWaterNow,
    DateTime? deletedAt,
    int? idealSoilMoistureMin,
    int? idealSoilMoistureMax,
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
      aiWateringAmount: aiWateringAmount ?? this.aiWateringAmount,
      aiSpecificIssues: aiSpecificIssues ?? this.aiSpecificIssues,
      aiCareTips: aiCareTips ?? this.aiCareTips,
      careDetails: careDetails ?? this.careDetails,
      interestingFacts: interestingFacts ?? this.interestingFacts,
      aiPlantSize: aiPlantSize ?? this.aiPlantSize,
      aiPotSize: aiPotSize ?? this.aiPotSize,
      aiGrowthStage: aiGrowthStage ?? this.aiGrowthStage,
      wateringAmountMl: wateringAmountMl ?? this.wateringAmountMl,
      wateringRangeMl: wateringRangeMl ?? this.wateringRangeMl,
      nextAfterWateringHours: nextAfterWateringHours ?? this.nextAfterWateringHours,
      nextCheckHours: nextCheckHours ?? this.nextCheckHours,
      wateringMode: wateringMode ?? this.wateringMode,
      healthStatus: healthStatus ?? this.healthStatus,
      healthMessage: healthMessage ?? this.healthMessage,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
      lastHealthCheckImageUrl: lastHealthCheckImageUrl ?? this.lastHealthCheckImageUrl,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      preferredTime: preferredTime ?? this.preferredTime,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      nextNotificationAt: nextNotificationAt ?? this.nextNotificationAt,
      notificationState: notificationState ?? this.notificationState,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      muted: muted ?? this.muted,
      overdueStreak: overdueStreak ?? this.overdueStreak,
      shouldWaterNow: shouldWaterNow ?? this.shouldWaterNow,
      deletedAt: deletedAt ?? this.deletedAt,
      idealSoilMoistureMin: idealSoilMoistureMin ?? this.idealSoilMoistureMin,
      idealSoilMoistureMax: idealSoilMoistureMax ?? this.idealSoilMoistureMax,
    );
  }
} 