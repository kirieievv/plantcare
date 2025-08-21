import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';
import '../services/auth_service.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plants';

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
  Future<String> addPlant(Plant plant) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final plantData = plant.toMap();
    plantData['userId'] = user.uid;
    
    final docRef = await _firestore.collection(_collection).add(plantData);
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

  // Water a plant (update last watered date)
  Future<void> waterPlant(String plantId) async {
    try {
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
            final nextWatering = now.add(Duration(days: plant.wateringFrequency));
            
            transaction.update(docRef, {
              'lastWatered': now.toIso8601String(),
              'nextWatering': nextWatering.toIso8601String(),
            });
            
            print('✅ PlantService: Successfully watered plant ${plantId}');
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