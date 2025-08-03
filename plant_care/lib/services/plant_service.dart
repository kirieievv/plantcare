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
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Plant.fromMap(data);
      }).toList();
    });
  }

  // Add a new plant
  Future<void> addPlant(Plant plant) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final plantData = plant.toMap();
    plantData['userId'] = user.uid;
    
    await _firestore.collection(_collection).add(plantData);
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
    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc(plantId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        final plant = Plant.fromMap({...doc.data()!, 'id': doc.id});
        final nextWatering = now.add(Duration(days: plant.wateringFrequency));
        
        transaction.update(docRef, {
          'lastWatered': now.toIso8601String(),
          'nextWatering': nextWatering.toIso8601String(),
        });
      }
    });
  }

  // Get plants that need watering for current user
  Stream<List<Plant>> getPlantsNeedingWater() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('nextWatering', isLessThanOrEqualTo: now.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Plant.fromMap(data);
      }).toList();
    });
  }
} 