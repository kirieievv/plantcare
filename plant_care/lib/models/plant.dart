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
    );
  }
} 