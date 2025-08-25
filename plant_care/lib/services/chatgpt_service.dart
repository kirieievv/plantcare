import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with OpenAI's ChatGPT API
class ChatGPTService {
  // API configuration
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o';
  
  // API key - in production, this should be stored securely
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  
  /// Analyzes a plant photo using OpenAI's GPT-4 Vision API
  static Future<Map<String, dynamic>> analyzePlantPhoto(String base64Image) async {
    try {
      print('🔍 Starting plant photo analysis with model: $_model');
      print('🔍 API Key length: ${_apiKey.length}');
      print('🔍 Base64 image length: ${base64Image.length}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this plant photo and provide detailed care recommendations. Identify the plant type, assess its health, and provide specific care tips including watering frequency, light requirements, and any issues you notice.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );
      
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Headers: ${response.headers}');
      print('🔍 API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Parse the AI response to extract structured information
        final recommendations = _parseAIResponse(content);
        
        print('✅ Plant analysis successful');
        print('✅ Extracted recommendations: $recommendations');
        
        return recommendations;
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
  
  /// Analyzes plant health using OpenAI's GPT-4 Vision API
  static Future<Map<String, dynamic>> analyzePlantHealth(String base64Image, String prompt) async {
    try {
      print('🔍 Starting plant health analysis with model: $_model');
      print('🔍 API Key length: ${_apiKey.length}');
      print('🔍 Base64 image length: ${base64Image.length}');
      print('🔍 Prompt: $prompt');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );
      
      print('🔍 API Response Status: ${response.statusCode}');
      print('🔍 API Response Headers: ${response.headers}');
      print('🔍 API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        return {
          'message': content,
          'status': 'success',
        };
      }
      
      throw Exception('Failed to analyze plant health: ${response.statusCode}');
    } catch (e) {
      print('❌ Plant Health Analysis Error: $e');
      throw Exception('Plant health analysis failed: $e');
    }
  }
  
  /// Checks if the ChatGPT API is available
  static Future<bool> isApiAvailable() async {
    try {
      print('🔍 Checking API availability...');
      print('🔍 API Key length: ${_apiKey.length}');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );
      
      print('🔍 API Check Response Status: ${response.statusCode}');
      print('🔍 API Check Response Headers: ${response.headers}');
      print('🔍 API Check Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List;
        final availableModels = models.map((m) => m['id']).toList();
        
        print('✅ API is available');
        print('✅ Available models: $availableModels');
        
        return availableModels.contains(_model);
      }
      
      print('❌ API check failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ API availability check failed: $e');
      return false;
    }
  }
  
  /// Gets available models for debugging
  static Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List;
        return models.map((m) => m['id'] as String).toList();
      }
      
      return <String>[];
    } catch (e) {
      print('❌ Failed to get available models: $e');
      return <String>[];
    }
  }
  
  /// Parses the AI response to extract structured information
  static Map<String, dynamic> _parseAIResponse(String aiResponse) {
    try {
      // Try to parse as JSON first
      if (aiResponse.trim().startsWith('{') && aiResponse.trim().endsWith('}')) {
        final jsonData = jsonDecode(aiResponse);
        return jsonData;
      }
      
      // Fallback: extract information from text
      final response = aiResponse.toLowerCase();
      
      // Extract plant name
      String plantName = 'Plant';
      if (response.contains('peace lily') || response.contains('peace lily')) {
        plantName = 'Peace Lily';
      } else if (response.contains('orchid')) {
        plantName = 'Orchid';
      } else if (response.contains('monstera')) {
        plantName = 'Monstera';
      } else if (response.contains('ficus')) {
        plantName = 'Ficus';
      } else if (response.contains('pothos')) {
        plantName = 'Pothos';
      }
      
      // Extract moisture level
      String moistureLevel = 'Moderate';
      if (response.contains('dry') || response.contains('underwatered')) {
        moistureLevel = 'Low';
      } else if (response.contains('wet') || response.contains('overwatered')) {
        moistureLevel = 'High';
      }
      
      // Extract light requirements
      String light = 'Bright indirect light';
      if (response.contains('low light') || response.contains('shade')) {
        light = 'Low light';
      } else if (response.contains('direct sun') || response.contains('full sun')) {
        light = 'Direct sunlight';
      }
      
      // Extract watering frequency
      int wateringFrequency = 7;
      if (response.contains('every 3 days') || response.contains('3 days')) {
        wateringFrequency = 3;
      } else if (response.contains('every 5 days') || response.contains('5 days')) {
        wateringFrequency = 5;
      } else if (response.contains('every 10 days') || response.contains('10 days')) {
        wateringFrequency = 10;
      } else if (response.contains('every 14 days') || response.contains('14 days')) {
        wateringFrequency = 14;
      }
      
      return {
        'general_description': aiResponse,
        'name': plantName,
        'moisture_level': moistureLevel,
        'light': light,
        'watering_frequency': wateringFrequency,
        'watering_amount': 'Until soil is moist',
        'specific_issues': _extractIssues(aiResponse),
        'care_tips': _extractCareTips(aiResponse),
      };
    } catch (e) {
      print('❌ Failed to parse AI response: $e');
      return {
        'general_description': aiResponse,
        'name': 'Plant',
        'moisture_level': 'Moderate',
        'light': 'Bright indirect light',
        'watering_frequency': 7,
        'watering_amount': 'Until soil is moist',
        'specific_issues': 'Please check plant care manually',
        'care_tips': 'Monitor soil moisture and light conditions',
      };
    }
  }
  
  /// Extracts specific issues from AI response
  static String _extractIssues(String response) {
    final issues = <String>[];
    
    if (response.toLowerCase().contains('yellow') || response.toLowerCase().contains('yellowing')) {
      issues.add('Yellowing leaves');
    }
    if (response.toLowerCase().contains('brown') || response.toLowerCase().contains('browning')) {
      issues.add('Brown spots or edges');
    }
    if (response.toLowerCase().contains('wilted') || response.toLowerCase().contains('wilting')) {
      issues.add('Wilting or drooping');
    }
    if (response.toLowerCase().contains('dry') || response.toLowerCase().contains('underwatered')) {
      issues.add('Underwatering');
    }
    if (response.toLowerCase().contains('wet') || response.toLowerCase().contains('overwatered')) {
      issues.add('Overwatering');
    }
    if (response.toLowerCase().contains('root rot')) {
      issues.add('Root rot');
    }
    
    return issues.isEmpty ? 'No specific issues detected' : issues.join(', ');
  }
  
  /// Extracts care tips from AI response
  static String _extractCareTips(String response) {
    final tips = <String>[];
    
    if (response.toLowerCase().contains('water')) {
      tips.add('Monitor soil moisture regularly');
    }
    if (response.toLowerCase().contains('light')) {
      tips.add('Ensure proper light conditions');
    }
    if (response.toLowerCase().contains('temperature')) {
      tips.add('Maintain stable temperature');
    }
    if (response.toLowerCase().contains('humidity')) {
      tips.add('Consider humidity levels');
    }
    if (response.toLowerCase().contains('fertilizer')) {
      tips.add('Use appropriate fertilizer');
    }
    
    return tips.isEmpty ? 'Follow general plant care guidelines' : tips.join('. ') + '.';
  }
}
