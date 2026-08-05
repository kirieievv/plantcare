import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:async';
import '../models/plant.dart';
import '../services/auth_service.dart';

class HealthCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'health_checks';

  // Add a new health check record (supports up to 3 photos)
  Future<void> addHealthCheck(String plantId, HealthCheckRecord healthCheck) async {
    print('🌱 HealthCheckService: Starting health check save...');
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Upload all provided image bytes, collecting resulting URLs
    final uploadedUrls = <String?>[];
    final bytesToUpload = healthCheck.imageBytesList.isNotEmpty
        ? healthCheck.imageBytesList
        : (healthCheck.imageBytes != null ? [healthCheck.imageBytes] : <Uint8List?>[]);

    for (int i = 0; i < bytesToUpload.length; i++) {
      final bytes = bytesToUpload[i];
      if (bytes == null) {
        uploadedUrls.add(null);
        continue;
      }
      String? uploadedUrl;
      try {
        print('🌱 HealthCheckService: Uploading photo ${i + 1}/${bytesToUpload.length}...');
        final suffix = i == 0 ? '' : '_$i';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('health_checks')
            .child(user.uid)
            .child(plantId)
            .child('${healthCheck.id}$suffix.jpg');

        int retryCount = 0;
        const maxRetries = 3;
        while (retryCount < maxRetries) {
          try {
            final snapshot = await storageRef.putData(bytes).timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw TimeoutException('Upload timeout after 60 seconds'),
            );
            uploadedUrl = await snapshot.ref.getDownloadURL();
            print('✅ HealthCheckService: Photo ${i + 1} uploaded: $uploadedUrl');
            break;
          } catch (e) {
            retryCount++;
            if (retryCount >= maxRetries) break;
            await Future.delayed(Duration(seconds: retryCount * 3));
          }
        }
      } catch (e) {
        print('❌ HealthCheckService: Error uploading photo ${i + 1}: $e');
      }
      uploadedUrls.add(uploadedUrl);
    }

    final primaryUrl = uploadedUrls.isNotEmpty ? uploadedUrls.first : null;

    final healthCheckData = {
      'id': healthCheck.id,
      'plantId': plantId,
      'userId': user.uid,
      'timestamp': healthCheck.timestamp.toIso8601String(),
      'status': healthCheck.status,
      'message': healthCheck.message,
      'imageUrl': primaryUrl,
      'imageUrls': uploadedUrls,
      'metadata': healthCheck.metadata,
      'score': healthCheck.score,
      'findings': healthCheck.findings.map((f) => f.toMap()).toList(),
      'recommendations': healthCheck.recommendations.map((r) => r.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    print('🌱 HealthCheckService: Saving to health_checks collection...');
    await _firestore.collection(_collection).doc(healthCheck.id).set(healthCheckData);
    print('✅ HealthCheckService: Health check document saved');

    // `healthMessage`, not `message`: Plant.fromMap reads the former, and writing
    // the latter here left the plant showing the previous check's text whenever
    // the caller's own update didn't land.
    await _firestore.collection('plants').doc(plantId).update({
      'healthStatus': healthCheck.status,
      'healthMessage': healthCheck.message,
      'lastHealthCheck': healthCheck.timestamp.toIso8601String(),
      'lastHealthCheckImageUrl': primaryUrl,
    });
    print('✅ HealthCheckService: Plant document updated');
    print('✅ HealthCheckService: Health check save completed successfully');
  }

  // Get health check history for a specific plant
  Stream<List<HealthCheckRecord>> getHealthCheckHistory(String plantId) {
    print('🌱 HealthCheckService: Getting health check history for plant: $plantId');
    final user = AuthService.currentUser;
    if (user == null) {
      print('❌ HealthCheckService: User not authenticated');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection(_collection)
          .where('plantId', isEqualTo: plantId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              print('🌱 HealthCheckService: Firestore returned ${snapshot.docs.length} documents');
              final records = snapshot.docs.map((doc) {
                try {
                  final data = doc.data();
                  print('🌱 HealthCheckService: Document data: ${data['id']} - ${data['status']} - ${data['timestamp']}');
                  return HealthCheckRecord.fromMap(data);
                } catch (e) {
                  print('❌ HealthCheckService: Error parsing document ${doc.id}: $e');
                  return null;
                }
              }).where((record) => record != null).cast<HealthCheckRecord>().toList();
              
              final dropped = snapshot.docs.length - records.length;
              if (dropped > 0) {
                print('⚠️ HealthCheckService: $dropped of ${snapshot.docs.length} '
                    'records failed to parse and are missing from History');
              }
              print('✅ HealthCheckService: Returning ${records.length} health check records');
              return records;
            } catch (e) {
              print('❌ HealthCheckService: Error processing snapshot: $e');
              return <HealthCheckRecord>[];
            }
          })
          // Deliberately not swallowed: an empty History and a failed query look
          // identical to the user, and the returned value of a handleError
          // callback is discarded anyway — so the stream used to just stop.
          .handleError((Object error, StackTrace stack) {
            print('❌ HealthCheckService: health check history query failed: $error');
            Error.throwWithStackTrace(error, stack);
          });
    } catch (e) {
      print('❌ HealthCheckService: Critical error in getHealthCheckHistory: $e');
      return Stream.value(<HealthCheckRecord>[]);
    }
  }

  // Get all health checks across all plants for current user
  Stream<List<HealthCheckRecord>> getAllHealthChecks() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value([]);
    
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs.map((doc) {
                try {
                  final data = doc.data();
                  return HealthCheckRecord.fromMap(data);
                } catch (e) {
                  print('❌ HealthCheckService: Error parsing document ${doc.id}: $e');
                  return null;
                }
              }).where((record) => record != null).cast<HealthCheckRecord>().toList();
            } catch (e) {
              print('❌ HealthCheckService: Error processing getAllHealthChecks snapshot: $e');
              return <HealthCheckRecord>[];
            }
          })
          .handleError((error) {
            print('❌ HealthCheckService: Error getting all health checks: $error');
            return <HealthCheckRecord>[];
          });
    } catch (e) {
      print('❌ HealthCheckService: Critical error in getAllHealthChecks: $e');
      return Stream.value(<HealthCheckRecord>[]);
    }
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
    
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs.map((doc) {
                try {
                  final data = doc.data();
                  return HealthCheckRecord.fromMap(data);
                } catch (e) {
                  print('❌ HealthCheckService: Error parsing document ${doc.id}: $e');
                  return null;
                }
              }).where((record) => record != null).cast<HealthCheckRecord>().toList();
            } catch (e) {
              print('❌ HealthCheckService: Error processing date range snapshot: $e');
              return <HealthCheckRecord>[];
            }
          })
          .handleError((error) {
            print('❌ HealthCheckService: Error getting health checks by date range: $error');
            return <HealthCheckRecord>[];
          });
    } catch (e) {
      print('❌ HealthCheckService: Critical error in getHealthChecksByDateRange: $e');
      return Stream.value(<HealthCheckRecord>[]);
    }
  }
} 