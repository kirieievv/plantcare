import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:async';
import '../models/plant.dart';
import '../services/auth_service.dart';

class HealthCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'health_checks';

  // Add a new health check record
  Future<void> addHealthCheck(String plantId, HealthCheckRecord healthCheck) async {
    print('🌱 HealthCheckService: Starting health check save...');
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    String? imageUrl;
    
    // Upload image to Firebase Storage if we have image bytes
    if (healthCheck.imageBytes != null) {
      try {
        print('🌱 HealthCheckService: Uploading image to Firebase Storage...');
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('health_checks')
            .child(user.uid)
            .child(plantId)
            .child('${healthCheck.id}.jpg');
        
        // Add retry logic with exponential backoff
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries) {
          try {
            print('🌱 HealthCheckService: Upload attempt ${retryCount + 1} starting...');
            
            final uploadTask = storageRef.putData(healthCheck.imageBytes!);
            
            // Increase timeout to 60 seconds for slow networks
            final snapshot = await uploadTask.timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw TimeoutException('Upload timeout after 60 seconds'),
            );
            
            imageUrl = await snapshot.ref.getDownloadURL();
            print('✅ HealthCheckService: Image uploaded successfully: $imageUrl');
            break; // Success, exit retry loop
            
          } catch (e) {
            retryCount++;
            print('❌ HealthCheckService: Upload attempt $retryCount failed: $e');
            
            if (retryCount >= maxRetries) {
              print('❌ HealthCheckService: Max retries reached, continuing without image');
              break;
            }
            
            // Wait before retry with exponential backoff
            final delay = Duration(seconds: retryCount * 3); // Increased delay
            print('🌱 HealthCheckService: Retrying in ${delay.inSeconds} seconds...');
            await Future.delayed(delay);
          }
        }
      } catch (e) {
        print('❌ HealthCheckService: Error uploading image: $e');
        // Continue without image if upload fails
      }
    } else {
      print('🌱 HealthCheckService: No image to upload');
    }
    
    // Create the health check document
    final healthCheckData = {
      'id': healthCheck.id,
      'plantId': plantId,
      'userId': user.uid,
      'timestamp': healthCheck.timestamp.toIso8601String(),
      'status': healthCheck.status,
      'message': healthCheck.message,
      'imageUrl': imageUrl,
      'metadata': healthCheck.metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    print('🌱 HealthCheckService: Saving to health_checks collection...');
    // Save to health_checks collection
    await _firestore.collection(_collection).doc(healthCheck.id).set(healthCheckData);
    print('✅ HealthCheckService: Health check document saved');
    
    print('🌱 HealthCheckService: Updating plant document...');
    // Also update the plant's last health check info (but not the full history)
    await _firestore.collection('plants').doc(plantId).update({
      'healthStatus': healthCheck.status,
      'message': healthCheck.message,
      'lastHealthCheck': healthCheck.timestamp.toIso8601String(),
    });
    print('✅ HealthCheckService: Plant document updated');
    print('✅ HealthCheckService: Health check save completed successfully');
    
    // If image upload failed but we have image bytes, store them locally for immediate display
    if (imageUrl == null && healthCheck.imageBytes != null) {
      print('🌱 HealthCheckService: Image upload failed, but health check saved successfully');
      print('💡 Tip: The health check was saved without the image. You can retry the image upload later.');
      print('🌱 HealthCheckService: Health check data saved: Status=${healthCheck.status}, Message=${healthCheck.message.substring(0, 50)}...');
    }
  }

  // Get health check history for a specific plant
  Stream<List<HealthCheckRecord>> getHealthCheckHistory(String plantId) {
    print('🌱 HealthCheckService: Getting health check history for plant: $plantId');
    final user = AuthService.currentUser;
    if (user == null) {
      print('❌ HealthCheckService: User not authenticated');
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('plantId', isEqualTo: plantId)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('🌱 HealthCheckService: Firestore returned ${snapshot.docs.length} documents');
          final records = snapshot.docs.map((doc) {
            final data = doc.data();
            print('🌱 HealthCheckService: Document data: ${data['id']} - ${data['status']} - ${data['timestamp']}');
            return HealthCheckRecord.fromMap(data);
          }).toList();
          print('✅ HealthCheckService: Returning ${records.length} health check records');
          return records;
        })
        .handleError((error) {
          print('❌ HealthCheckService: Error getting health check history: $error');
          return <HealthCheckRecord>[];
        });
  }

  // Get all health checks across all plants for current user
  Stream<List<HealthCheckRecord>> getAllHealthChecks() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HealthCheckRecord.fromMap(data);
      }).toList();
    });
  }

  // Delete a health check record
  Future<void> deleteHealthCheck(String healthCheckId) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await _firestore.collection(_collection).doc(healthCheckId).delete();
  }

  // Get health checks for a specific date range
  Stream<List<HealthCheckRecord>> getHealthChecksByDateRange(
    DateTime startDate, 
    DateTime endDate
  ) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HealthCheckRecord.fromMap(data);
      }).toList();
    });
  }
} 