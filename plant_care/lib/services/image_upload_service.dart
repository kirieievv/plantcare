import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload plant image from bytes (e.g. from picker). Returns download URL.
  /// Use this when adding a new plant to avoid storing base64 in Firestore.
  Future<String> uploadPlantImageFromBytes(List<int> imageBytes, String plantName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final safeName = plantName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final baseName = safeName.isEmpty ? 'plant' : safeName.split(RegExp(r'\s+')).first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'plants/${user.uid}/${baseName}_$timestamp.jpg';

    final storageRef = _storage.ref().child(fileName);
    final uploadTask = storageRef.putData(
      imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload a plant image to Firebase Storage
  Future<String> uploadPlantImage(File imageFile, String plantName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'plants/${user.uid}/${plantName}_$timestamp.jpg';
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child(fileName);
      
      // Upload the file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'plantName': plantName,
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete a plant image from Firebase Storage
  Future<void> deletePlantImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3) {
        // Firebase Storage URLs have a specific structure
        // We need to extract the actual file path
        final filePath = pathSegments.sublist(2).join('/');
        final storageRef = _storage.ref().child(filePath);
        
        await storageRef.delete();
      }
    } catch (e) {
      // Don't throw error for deletion failures as the image might not exist
      print('Failed to delete image: $e');
    }
  }
} 