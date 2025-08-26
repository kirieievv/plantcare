import 'package:cloud_firestore/cloud_firestore.dart';

class SmartPlant {
  final String id;
  final String plantId; // Reference to the Plant model
  final String blynkDeviceId;
  final String blynkAuthToken;
  final Map<String, dynamic> sensorData;
  final Map<String, dynamic> deviceStatus;
  final bool autoWateringEnabled;
  final double moistureThreshold;
  final int wateringDuration;
  final DateTime lastWatered;
  final DateTime createdAt;
  final DateTime updatedAt;

  SmartPlant({
    required this.id,
    required this.plantId,
    required this.blynkDeviceId,
    required this.blynkAuthToken,
    this.sensorData = const {},
    this.deviceStatus = const {},
    this.autoWateringEnabled = false,
    this.moistureThreshold = 30.0,
    this.wateringDuration = 5,
    required this.lastWatered,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'blynkDeviceId': blynkDeviceId,
      'blynkAuthToken': blynkAuthToken,
      'sensorData': sensorData,
      'deviceStatus': deviceStatus,
      'autoWateringEnabled': autoWateringEnabled,
      'moistureThreshold': moistureThreshold,
      'wateringDuration': wateringDuration,
      'lastWatered': lastWatered.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory SmartPlant.fromMap(Map<String, dynamic> map) {
    return SmartPlant(
      id: map['id'],
      plantId: map['plantId'],
      blynkDeviceId: map['blynkDeviceId'],
      blynkAuthToken: map['blynkAuthToken'],
      sensorData: Map<String, dynamic>.from(map['sensorData'] ?? {}),
      deviceStatus: Map<String, dynamic>.from(map['deviceStatus'] ?? {}),
      autoWateringEnabled: map['autoWateringEnabled'] ?? false,
      moistureThreshold: (map['moistureThreshold'] ?? 30.0).toDouble(),
      wateringDuration: map['wateringDuration'] ?? 5,
      lastWatered: _parseTimestamp(map['lastWatered']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  // Helper method to parse Firestore timestamps
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    return DateTime.now();
  }

  // Copy with method for updates
  SmartPlant copyWith({
    String? id,
    String? plantId,
    String? blynkDeviceId,
    String? blynkAuthToken,
    Map<String, dynamic>? sensorData,
    Map<String, dynamic>? deviceStatus,
    bool? autoWateringEnabled,
    double? moistureThreshold,
    int? wateringDuration,
    DateTime? lastWatered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartPlant(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      blynkDeviceId: blynkDeviceId ?? this.blynkDeviceId,
      blynkAuthToken: blynkAuthToken ?? this.blynkAuthToken,
      sensorData: sensorData ?? this.sensorData,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      autoWateringEnabled: autoWateringEnabled ?? this.autoWateringEnabled,
      moistureThreshold: moistureThreshold ?? this.moistureThreshold,
      wateringDuration: wateringDuration ?? this.wateringDuration,
      lastWatered: lastWatered ?? this.lastWatered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get current soil moisture
  double get currentMoisture => sensorData['soilMoisture'] ?? 0.0;
  
  // Get current temperature
  double get currentTemperature => sensorData['temperature'] ?? 0.0;
  
  // Get current humidity
  double get currentHumidity => sensorData['humidity'] ?? 0.0;
  
  // Get current light level
  double get currentLightLevel => sensorData['lightLevel'] ?? 0.0;
  
  // Check if device is connected
  bool get isDeviceConnected => deviceStatus['connected'] ?? false;
  
  // Check if plant needs watering
  bool get needsWatering => currentMoisture < moistureThreshold;
  
  // Get sensor data timestamp
  DateTime? get sensorDataTimestamp {
    final timestamp = sensorData['timestamp'];
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }
} 