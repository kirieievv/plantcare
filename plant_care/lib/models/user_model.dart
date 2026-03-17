import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? bio;
  final String? location;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;
  
  // Notification settings
  final String? timezone; // IANA timezone (e.g., "America/New_York")
  final Map<String, String>? quietHours; // {start: "22:00", end: "08:00"}
  final List<String> fcmTokens; // Array of FCM device tokens
  final int maxPushesPerDay; // Default 3

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.bio,
    this.location,
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.timezone,
    this.quietHours,
    List<String>? fcmTokens,
    int? maxPushesPerDay,
  })  : fcmTokens = fcmTokens ?? [],
        maxPushesPerDay = maxPushesPerDay ?? 3;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'bio': bio,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'timezone': timezone,
      'quietHours': quietHours,
      'fcmTokens': fcmTokens,
      'maxPushesPerDay': maxPushesPerDay,
    };
  }

  // Create from Map (from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'],
      location: map['location'],
      createdAt: _parseTimestamp(map['createdAt']),
      lastLogin: _parseTimestamp(map['lastLogin']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      timezone: map['timezone'],
      quietHours: map['quietHours'] != null 
          ? Map<String, String>.from(map['quietHours'])
          : null,
      fcmTokens: map['fcmTokens'] != null
          ? List<String>.from(map['fcmTokens'])
          : null,
      maxPushesPerDay: map['maxPushesPerDay'],
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
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? bio,
    String? location,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    String? timezone,
    Map<String, String>? quietHours,
    List<String>? fcmTokens,
    int? maxPushesPerDay,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      timezone: timezone ?? this.timezone,
      quietHours: quietHours ?? this.quietHours,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      maxPushesPerDay: maxPushesPerDay ?? this.maxPushesPerDay,
    );
  }
} 