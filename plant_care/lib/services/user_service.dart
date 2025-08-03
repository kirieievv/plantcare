import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return UserModel.fromMap(data);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String name,
    String? bio,
    String? location,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (bio != null) updateData['bio'] = bio;
    if (location != null) updateData['location'] = location;

    await _firestore.collection('users').doc(user.uid).update(updateData);
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    final user = AuthService.currentUser;
    if (user == null) return {};

    try {
      final plantsSnapshot = await _firestore
          .collection('plants')
          .where('userId', isEqualTo: user.uid)
          .get();

      final totalPlants = plantsSnapshot.docs.length;
      final plantsNeedingWater = plantsSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final nextWatering = DateTime.parse(data['nextWatering']);
            return DateTime.now().isAfter(nextWatering);
          })
          .length;

      return {
        'totalPlants': totalPlants,
        'plantsNeedingWater': plantsNeedingWater,
        'healthyPlants': totalPlants - plantsNeedingWater,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }
} 