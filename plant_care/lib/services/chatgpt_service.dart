import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with Firebase Functions for AI plant analysis
class ChatGPTService {
  // Firebase Functions URLs
  static const String _analyzePhotoUrl = 'https://us-central1-plant-care-94574.cloudfunctions.net/analyzePlantPhoto';
  static const String _generateContentUrl = 'https://us-central1-plant-care-94574.cloudfunctions.net/generatePlantContent';
  
  /// Analyzes a plant photo using Firebase Functions
  static Future<Map<String, dynamic>> analyzePlantPhoto(String base64Image) async {
    try {
      print('🔍 Starting plant photo analysis via Firebase Functions');
      print('🔍 Base64 image length: ${base64Image.length}');
      
      final response = await http.post(
        Uri.parse(_analyzePhotoUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64Image': base64Image,
        }),
      );
      
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Plant analysis successful');
          return data['recommendations'];
        } else {
          throw Exception('AI analysis failed: ${data['error']}');
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to analyze plant photo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Plant Photo Analysis Error: $e');
      throw Exception('Plant photo analysis failed: $e');
    }
  }
  
  /// Generates AI content for existing plants based on their basic information
  static Future<Map<String, dynamic>> generatePlantContent(String plantName, String species, {String? base64Image}) async {
    try {
      print('🔍 Generating AI content for existing plant: $plantName ($species)');
      
      final response = await http.post(
        Uri.parse(_generateContentUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plantName': plantName,
          'species': species,
        }),
      );
      
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Plant content generation successful');
          return data['recommendations'];
        } else {
          throw Exception('AI content generation failed: ${data['error']}');
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to generate plant content: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Plant Content Generation Error: $e');
      throw Exception('Plant content generation failed: $e');
    }
  }
}
