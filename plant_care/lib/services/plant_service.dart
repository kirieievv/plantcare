import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';
import '../services/auth_service.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plants';
  
  /// Calculate next watering date with preferred time applied
  /// This is the single source of truth for calculating nextWateringAt
  static DateTime calculateNextWateringAt({
    required DateTime from,
    required int intervalDays,
    String preferredTime = '18:00',
  }) {
    // Parse preferred time (HH:mm format)
    final timeParts = preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    // Add interval days to base date
    var nextDue = from.add(Duration(days: intervalDays));
    
    // Apply preferred time (same day, just change hour/minute)
    return DateTime(
      nextDue.year,
      nextDue.month,
      nextDue.day,
      hour,
      minute,
      0, // seconds
      0, // milliseconds
      0, // microseconds
    );
  }

  // Get all plants for current user
  Stream<List<Plant>> getPlants() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            try {
              final validPlants = <Plant>[];
              
              for (final doc in snapshot.docs) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  
                  // Validate required fields before parsing
                  if (data['name'] == null || data['name'].toString().isEmpty) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing name');
                    continue;
                  }
                  if (data['species'] == null || data['species'].toString().isEmpty) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing species');
                    continue;
                  }
                  if (data['wateringFrequency'] == null) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing wateringFrequency');
                    continue;
                  }
                  
                  // Fetch the latest health check image URL for this plant
                  String? lastHealthCheckImageUrl;
                  try {
                    final healthCheckQuery = await _firestore
                        .collection('health_checks')
                        .where('plantId', isEqualTo: doc.id)
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .get();
                    
                    if (healthCheckQuery.docs.isNotEmpty) {
                      final latestHealthCheck = healthCheckQuery.docs.first.data();
                      lastHealthCheckImageUrl = latestHealthCheck['imageUrl']?.toString();
                      print('🌱 PlantService: Found latest health check image for ${data['name']}: ${lastHealthCheckImageUrl != null ? "Present" : "None"}');
                    }
                  } catch (e) {
                    print('⚠️ PlantService: Error fetching health check for ${data['name']}: $e');
                    // Continue without health check image
                  }
                  
                  // Add the health check image URL to the plant data
                  if (lastHealthCheckImageUrl != null) {
                    data['lastHealthCheckImageUrl'] = lastHealthCheckImageUrl;
                  }
                  
                  final plant = Plant.fromMap(data);
                  validPlants.add(plant);
                } catch (e) {
                  print('❌ PlantService: Error parsing plant ${doc.id}: $e');
                  print('❌ Plant data: ${doc.data()}');
                  // Continue with other plants instead of crashing
                  continue;
                }
              }
              
              print('✅ PlantService: Successfully loaded ${validPlants.length} valid plants');
              return validPlants;
            } catch (e) {
              print('❌ PlantService: Error processing plants snapshot: $e');
              return <Plant>[];
            }
          })
          .handleError((error) {
            print('❌ PlantService: Error getting plants: $error');
            return <Plant>[];
          });
    } catch (e) {
      print('❌ PlantService: Critical error in getPlants: $e');
      return Stream.value(<Plant>[]);
    }
  }

  // Add a new plant
  // ⚠️ IMPORTANT: This method is part of the automatic navigation feature ⚠️
  // After calling this method, the AddPlantScreen automatically navigates to the new plant's details
  // DO NOT modify this method's return value (plant ID) without updating the navigation logic
  // 
  // Expected behavior: Returns the new plant's ID for automatic navigation to PlantDetailsScreen
  // Related feature: Automatic redirect after plant creation for better user experience
  Future<String> addPlant(Plant plant) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final plantData = plant.toMap();
    plantData['userId'] = user.uid;
    
    // Initialize notification fields if not already set
    final now = DateTime.now();
    final preferredTime = plantData['preferredTime'] ?? '18:00';
    
    // Get watering interval from AI (preferred) or fallback to frequency
    int wateringIntervalDays = plantData['wateringIntervalDays'] ?? plantData['wateringFrequency'] ?? 7;
    
    // Get shouldWaterNow from plant (from AI analysis)
    final shouldWaterNow = plantData['shouldWaterNow'] ?? false;
    
    // IMPORTANT: Use shared helper to calculate nextWateringAt with preferred time
    // This ensures consistent calculation in AddPlant, HealthCheck, and WaterPlant flows
    final nextDue = calculateNextWateringAt(
      from: now,
      intervalDays: wateringIntervalDays,
      preferredTime: preferredTime,
    );
    
    print('🌱 PlantService.addPlant: intervalDays=$wateringIntervalDays, shouldWaterNow=$shouldWaterNow, preferredTime=$preferredTime, nextDue=$nextDue');
    
    // Set next notification to 1 hour before due time
    final nextNotification = nextDue.subtract(const Duration(hours: 1));
    
    plantData['lastWateredAt'] = plantData['lastWateredAt'] ?? now.toIso8601String();
    plantData['wateringIntervalDays'] = wateringIntervalDays;
    plantData['preferredTime'] = preferredTime;
    plantData['shouldWaterNow'] = shouldWaterNow;
    plantData['nextDueAt'] = nextDue.toIso8601String();
    plantData['nextNotificationAt'] = nextNotification.toIso8601String();
    plantData['notificationState'] = 'ok';
    plantData['muted'] = false;
    plantData['overdueStreak'] = 0;
    
    final docRef = await _firestore.collection(_collection).add(plantData);
    print('✅ PlantService: Added plant with notification scheduling');
    return docRef.id;
  }

  // Update a plant
  Future<void> updatePlant(Plant plant) async {
    await _firestore
        .collection(_collection)
        .doc(plant.id)
        .update(plant.toMap());
  }

  // Delete a plant
  Future<void> deletePlant(String plantId) async {
    await _firestore.collection(_collection).doc(plantId).delete();
  }

  // Delete plant by name (temporary function for debugging)
  Future<bool> deletePlantByName(String plantName) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: plantName)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final plantId = querySnapshot.docs.first.id;
        await _firestore.collection(_collection).doc(plantId).delete();
        print('✅ PlantService: Successfully deleted plant "$plantName" with ID: $plantId');
        return true;
      } else {
        print('⚠️ PlantService: Plant "$plantName" not found');
        return false;
      }
    } catch (e) {
      print('❌ PlantService: Error deleting plant by name: $e');
      return false;
    }
  }

  // Find plant by name (temporary function for debugging)
  Future<String?> findPlantIdByName(String plantName) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: plantName)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('❌ PlantService: Error finding plant by name: $e');
      return null;
    }
  }



  // Get a single plant by ID
  Future<Plant?> getPlantById(String plantId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(plantId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Plant.fromMap(data);
    } catch (e) {
      print('❌ PlantService: Error getting plant by ID: $e');
      return null;
    }
  }

  // Water a plant (update last watered date and record watering event)
  Future<void> waterPlant(String plantId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        print('⚠️ PlantService: Cannot water plant - user not authenticated');
        throw Exception('User not authenticated');
      }
      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc(plantId);

      await _firestore.runTransaction((transaction) async {
        try {
          final doc = await transaction.get(docRef);
          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = doc.id;

            // Validate required fields before parsing
            if (data['wateringFrequency'] == null) {
              print('⚠️ PlantService: Cannot water plant ${plantId} - missing wateringFrequency');
              return;
            }

            final plant = Plant.fromMap(data);
            // Use per-plant days interval (AI-derived where available)
            final wateringIntervalDays = plant.wateringIntervalDays ?? plant.wateringFrequency;
            final preferredTime = plant.preferredTime ?? '18:00';

            // Calculate next due date using shared helper with preferred time
            final nextDue = calculateNextWateringAt(
              from: now,
              intervalDays: wateringIntervalDays,
              preferredTime: preferredTime,
            );

            // Set next notification to 1 hour before due time
            final nextNotification = nextDue.subtract(const Duration(hours: 1));

            // Calculate nextWatering for backward compatibility
            final nextWatering = plant.wateringFrequency > 0
                ? now.add(Duration(days: plant.wateringFrequency))
                : nextDue;

            transaction.update(docRef, {
              'lastWatered': now.toIso8601String(),
              'nextWatering': nextWatering.toIso8601String(),
              'lastWateredAt': now.toIso8601String(),
              'nextDueAt': nextDue.toIso8601String(),
              'nextNotificationAt': nextNotification.toIso8601String(),
              'notificationState': 'ok',
              'overdueStreak': 0,
              'snoozedUntil': null,
              'shouldWaterNow': false, // Reset after watering - next interval starts
            });

            // Record watering event for history (plantId, userId, timestamp, amountMl)
            final eventRef = _firestore.collection('watering_events').doc();
            transaction.set(eventRef, {
              'plantId': plantId,
              'userId': user.uid,
              'timestamp': now.toIso8601String(),
              'amountMl': plant.wateringAmountMl,
            });

            print('✅ PlantService: Successfully watered plant ${plantId}');
            print('   Next due: $nextDue');
            print('   Next notification: $nextNotification');
          } else {
            print('⚠️ PlantService: Plant ${plantId} not found');
          }
        } catch (e) {
          print('❌ PlantService: Error in waterPlant transaction: $e');
          rethrow;
        }
      });
    } catch (e) {
      print('❌ PlantService: Critical error in waterPlant: $e');
      rethrow;
    }
  }

  // Get plants that need watering for current user
  Stream<List<Plant>> getPlantsNeedingWater() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    try {
      final now = DateTime.now();
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('nextWatering', isLessThanOrEqualTo: now.toIso8601String())
          .snapshots()
          .map((snapshot) {
            try {
              final validPlants = <Plant>[];
              
              for (final doc in snapshot.docs) {
                try {
                  final data = doc.data();
                  data['id'] = doc.id;
                  
                  // Validate required fields before parsing
                  if (data['name'] == null || data['name'].toString().isEmpty) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing name');
                    continue;
                  }
                  if (data['species'] == null || data['species'].toString().isEmpty) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing species');
                    continue;
                  }
                  if (data['wateringFrequency'] == null) {
                    print('⚠️ PlantService: Skipping plant ${doc.id} - missing wateringFrequency');
                    continue;
                  }
                  
                  final plant = Plant.fromMap(data);
                  validPlants.add(plant);
                } catch (e) {
                  print('❌ PlantService: Error parsing plant ${doc.id}: $e');
                  print('❌ Plant data: ${doc.data()}');
                  // Continue with other plants instead of crashing
                  continue;
                }
              }
              
              print('✅ PlantService: Successfully loaded ${validPlants.length} plants needing water');
              return validPlants;
            } catch (e) {
              print('❌ PlantService: Error processing plants needing water snapshot: $e');
              return <Plant>[];
            }
          })
          .handleError((error) {
            print('❌ PlantService: Error getting plants needing water: $error');
            return <Plant>[];
          });
    } catch (e) {
      print('❌ PlantService: Critical error in getPlantsNeedingWater: $e');
      return Stream.value(<Plant>[]);
    }
  }

  // Utility method to identify corrupted plants
  Future<List<Map<String, dynamic>>> getCorruptedPlants() async {
    final user = AuthService.currentUser;
    if (user == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final corruptedPlants = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final issues = <String>[];
        
        if (data['name'] == null || data['name'].toString().isEmpty) {
          issues.add('Missing name');
        }
        if (data['species'] == null || data['species'].toString().isEmpty) {
          issues.add('Missing species');
        }
        if (data['wateringFrequency'] == null) {
          issues.add('Missing wateringFrequency');
        }
        
        if (issues.isNotEmpty) {
          corruptedPlants.add({
            'id': doc.id,
            'data': data,
            'issues': issues,
          });
        }
      }
      
      print('⚠️ PlantService: Found ${corruptedPlants.length} corrupted plants');
      return corruptedPlants;
    } catch (e) {
      print('❌ PlantService: Error getting corrupted plants: $e');
      return [];
    }
  }

  // Utility method to fix corrupted plant data
  Future<void> fixCorruptedPlant(String plantId, Map<String, dynamic> fixes) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(plantId)
          .update(fixes);
      
      print('✅ PlantService: Successfully fixed plant $plantId');
    } catch (e) {
      print('❌ PlantService: Error fixing plant $plantId: $e');
      rethrow;
    }
  }

  // Utility method to remove completely corrupted plants
  Future<void> removeCorruptedPlant(String plantId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(plantId)
          .delete();
      
      print('✅ PlantService: Successfully removed corrupted plant $plantId');
    } catch (e) {
      print('❌ PlantService: Error removing corrupted plant $plantId: $e');
      rethrow;
    }
  }

  // Utility method to clean up all corrupted plants
  Future<void> cleanupCorruptedPlants() async {
    try {
      final corruptedPlants = await getCorruptedPlants();
      
      if (corruptedPlants.isEmpty) {
        print('✅ PlantService: No corrupted plants found');
        return;
      }
      
      print('🧹 PlantService: Starting cleanup of ${corruptedPlants.length} corrupted plants');
      
      for (final corruptedPlant in corruptedPlants) {
        final plantId = corruptedPlant['id'] as String;
        final issues = corruptedPlant['issues'] as List<String>;
        final data = corruptedPlant['data'] as Map<String, dynamic>;
        
        // Try to fix plants with missing species or wateringFrequency
        if (issues.contains('Missing species') || issues.contains('Missing wateringFrequency')) {
          final fixes = <String, dynamic>{};
          
          if (issues.contains('Missing species')) {
            fixes['species'] = data['aiName'] ?? 'Unknown Species';
            print('🔧 PlantService: Fixing missing species for plant $plantId');
          }
          
          if (issues.contains('Missing wateringFrequency')) {
            fixes['wateringFrequency'] = 7; // Default to 7 days
            print('🔧 PlantService: Fixing missing wateringFrequency for plant $plantId');
          }
          
          await fixCorruptedPlant(plantId, fixes);
        } else {
          // Remove plants that are completely corrupted (missing name)
          print('🗑️ PlantService: Removing completely corrupted plant $plantId');
          await removeCorruptedPlant(plantId);
        }
      }
      
      print('✅ PlantService: Cleanup completed');
    } catch (e) {
      print('❌ PlantService: Error during cleanup: $e');
      rethrow;
    }
  }

} 