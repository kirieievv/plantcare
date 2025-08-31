import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  try {
    // Get Firestore instance
    final firestore = FirebaseFirestore.instance;
    
    // Find Foxglove plant
    final querySnapshot = await firestore
        .collection('plants')
        .where('name', isEqualTo: 'Foxglove')
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      final plantDoc = querySnapshot.docs.first;
      final plantId = plantDoc.id;
      
      print('Found Foxglove plant with ID: $plantId');
      
      // Delete the plant
      await firestore.collection('plants').doc(plantId).delete();
      
      print('✅ Successfully deleted Foxglove plant!');
    } else {
      print('⚠️ Foxglove plant not found');
    }
  } catch (e) {
    print('❌ Error deleting Foxglove plant: $e');
  }
}
