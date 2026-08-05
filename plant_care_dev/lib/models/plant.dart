import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

/// One observation the analyzer made about the plant in a health check.
///
/// [category] is a fixed English key the analyzer picks from a closed set — it
/// selects the icon and tint, so unknown values must not reach the UI. The
/// backend already coerces anything unexpected to `leaves`; [fromMap] repeats
/// that guard for records written before the field existed.
class HealthFinding {
  static const categories = {'light', 'water', 'soil', 'leaves', 'pests'};

  final String category;
  final String title;
  final String text;

  const HealthFinding({
    required this.category,
    required this.title,
    required this.text,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'title': title,
        'text': text,
      };

  factory HealthFinding.fromMap(Map<String, dynamic> map) {
    final raw = map['category']?.toString().toLowerCase() ?? '';
    return HealthFinding(
      category: categories.contains(raw) ? raw : 'leaves',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
    );
  }
}

/// A single action from the "what to do" checklist of a health check.
///
/// [done] is owned by the user, not the analyzer: it is toggled from the result
/// screen and written back into the same health-check document, so reopening an
/// old check shows which steps were already taken.
class HealthRecommendation {
  final int priority; // 1 = most important, 3 = optional
  final String title;
  final String explanation;
  final String actionLabel;
  final bool done;

  const HealthRecommendation({
    required this.priority,
    required this.title,
    this.explanation = '',
    this.actionLabel = '',
    this.done = false,
  });

  Map<String, dynamic> toMap() => {
        'priority': priority,
        'title': title,
        'explanation': explanation,
        'action_label': actionLabel,
        'done': done,
      };

  factory HealthRecommendation.fromMap(Map<String, dynamic> map) {
    final raw = map['priority'];
    final parsed = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    return HealthRecommendation(
      priority: (parsed ?? 1).clamp(1, 3),
      title: map['title']?.toString() ?? '',
      explanation: map['explanation']?.toString() ?? '',
      actionLabel: map['action_label']?.toString() ?? '',
      done: map['done'] == true,
    );
  }

  HealthRecommendation copyWith({bool? done}) => HealthRecommendation(
        priority: priority,
        title: title,
        explanation: explanation,
        actionLabel: actionLabel,
        done: done ?? this.done,
      );
}

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

  /// 0–100 overall condition. Null for checks recorded before scoring existed —
  /// the UI hides the ring rather than inventing a number.
  final int? score;
  final List<HealthFinding> findings;
  final List<HealthRecommendation> recommendations;

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
    this.score,
    List<HealthFinding>? findings,
    List<HealthRecommendation>? recommendations,
  })  : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []),
        imageBytesList = imageBytesList ?? (imageBytes != null ? [imageBytes] : []),
        findings = findings ?? const [],
        recommendations = recommendations ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'message': message,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'score': score,
      'findings': findings.map((f) => f.toMap()).toList(),
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      // imageBytes / imageBytesList not stored in Firestore, only used locally
    };
  }

  /// Reads a stored check back.
  ///
  /// Deliberately forgiving about everything except identity: callers map this
  /// over a Firestore query and drop entries that throw, so a strict parse turns
  /// one blank field into a check that silently vanishes from History while
  /// still being counted against the per-cycle budget. A record that exists must
  /// stay visible — an empty verdict is better than a missing row.
  factory HealthCheckRecord.fromMap(Map<String, dynamic> map) {
    try {
      if (map['id'] == null || map['id'].toString().isEmpty) {
        throw Exception('HealthCheckRecord: id is required');
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
        // Unknown status reads as 'ok' so the row renders neutrally instead of
        // claiming a problem the analyzer never reported.
        status: map['status']?.toString().isNotEmpty == true
            ? map['status'].toString()
            : 'ok',
        message: map['message']?.toString() ?? '',
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
        metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
        score: map['score'] is int
            ? map['score']
            : (map['score'] != null ? int.tryParse(map['score'].toString()) : null),
        findings: _mapList(map['findings'], HealthFinding.fromMap),
        recommendations: _mapList(map['recommendations'], HealthRecommendation.fromMap),
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
    int? score,
    List<HealthFinding>? findings,
    List<HealthRecommendation>? recommendations,
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
      score: score ?? this.score,
      findings: findings ?? this.findings,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  /// Firestore hands back `List<dynamic>` of `Map<Object?, Object?>`; a malformed
  /// entry drops out instead of failing the whole record.
  static List<T> _mapList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) build,
  ) {
    if (raw is! List) return const [];
    final out = <T>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        out.add(build(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip the bad entry, keep the rest of the check readable.
      }
    }
    return out;
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

  // ── Growing conditions, answered by the user when the plant was added ──────
  //
  // Long-lived context: every AI call about this plant should see them, because
  // none of it can be read off a photo. A plastic pot with no drainage and a
  // terracotta one with drainage produce the same picture and opposite advice.
  //
  // All nullable on purpose — plants added before the quiz have none of this,
  // and every reader has to survive that.
  final int? potDiameterCm; // 8..40
  final String? potMaterial; // 'plastic' | 'ceramic' | 'terracotta' | 'unknown'
  final bool? hasDrainage;
  final String? placement; // 'south' | 'east' | 'north' | 'room' | 'balcony' | 'bath'
  final bool? nearHeatSource; // radiator or air conditioner
  final DateTime? conditionsUpdatedAt; // last time the user refined the answers

  /// True once the quiz has been answered — used to decide whether the AI
  /// prompt gets a conditions block at all, instead of sending "unknown" five
  /// times and inviting the model to guess.
  bool get hasConditions =>
      potDiameterCm != null ||
      potMaterial != null ||
      hasDrainage != null ||
      placement != null ||
      nearHeatSource != null;

  /// Score of the last analysis, 0–100 (SPEC 1.1).
  ///
  /// Set when the plant is added and re-set by every health check. The live
  /// score is this minus current penalties, so closing tasks can never lift a
  /// plant above what its last scan actually saw.
  final int? scanScore;

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
    this.potDiameterCm,
    this.potMaterial,
    this.hasDrainage,
    this.placement,
    this.nearHeatSource,
    this.conditionsUpdatedAt,
    this.scanScore,
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
      'potDiameterCm': potDiameterCm,
      'potMaterial': potMaterial,
      'hasDrainage': hasDrainage,
      'placement': placement,
      'nearHeatSource': nearHeatSource,
      'conditionsUpdatedAt': conditionsUpdatedAt?.toIso8601String(),
      'scanScore': scanScore,
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
        potDiameterCm: map['potDiameterCm'] is int
            ? map['potDiameterCm']
            : (map['potDiameterCm'] != null
                  ? int.tryParse(map['potDiameterCm'].toString())
                  : null),
        potMaterial: map['potMaterial']?.toString(),
        // `is bool` rather than `== true`: for these two, "no" and "never asked"
        // are different answers, and collapsing null into false would tell the
        // planner a pre-quiz plant has no drainage.
        hasDrainage: map['hasDrainage'] is bool
            ? map['hasDrainage'] as bool
            : null,
        placement: map['placement']?.toString(),
        nearHeatSource: map['nearHeatSource'] is bool
            ? map['nearHeatSource'] as bool
            : null,
        conditionsUpdatedAt: _parseTimestamp(map['conditionsUpdatedAt']),
        scanScore: map['scanScore'] is int
          ? map['scanScore']
          : (map['scanScore'] != null ? int.tryParse(map['scanScore'].toString()) : null),
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
    int? potDiameterCm,
    String? potMaterial,
    bool? hasDrainage,
    String? placement,
    bool? nearHeatSource,
    DateTime? conditionsUpdatedAt,
    int? scanScore,
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
      potDiameterCm: potDiameterCm ?? this.potDiameterCm,
      potMaterial: potMaterial ?? this.potMaterial,
      hasDrainage: hasDrainage ?? this.hasDrainage,
      placement: placement ?? this.placement,
      nearHeatSource: nearHeatSource ?? this.nearHeatSource,
      conditionsUpdatedAt: conditionsUpdatedAt ?? this.conditionsUpdatedAt,
      scanScore: scanScore ?? this.scanScore,
      idealSoilMoistureMin: idealSoilMoistureMin ?? this.idealSoilMoistureMin,
      idealSoilMoistureMax: idealSoilMoistureMax ?? this.idealSoilMoistureMax,
    );
  }
} 