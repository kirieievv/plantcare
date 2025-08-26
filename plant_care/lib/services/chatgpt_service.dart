import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with OpenAI's ChatGPT API
class ChatGPTService {
  // API configuration
  static String get _baseUrl => dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o';
  
  // API key from environment variables
  static String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY environment variable is not set');
    }
    return key;
  }
  
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
                  'text': r'Analyze this plant photo and provide detailed care recommendations. You MUST follow this EXACT format:\n\nPlant: [Identify the plant and provide the common name and scientific name if possible]\nDescription: [Provide a detailed description of the plant including its appearance, characteristics, and general information]\nCare Recommendations:\n   - Watering: [Specific watering instructions]\n   - Light Requirements: [Light needs]\n   - Temperature: [Temperature preferences]\n   - Soil: [Soil type and requirements]\n   - Fertilizing: [Fertilizer needs]\n   - Humidity: [Humidity requirements]\n   - Growth Rate / Size: [Growth characteristics]\n   - Blooming: [Flowering information if applicable]\nInteresting Facts: Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Format as simple sentences without any special characters, numbers, or bullet points.\n\nIMPORTANT: You MUST start with "Plant:" and "Description:" sections before the Care Recommendations. If you cannot identify the exact plant, provide a general description based on what you can see in the image.',
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
  
  /// Generates AI content for existing plants based on their basic information
  static Future<Map<String, dynamic>> generatePlantContent(String plantName, String species, {String? base64Image}) async {
    try {
      print('🔍 Generating AI content for existing plant: $plantName ($species)');
      
      // Unified prompt for both image and text analysis
      String prompt;
      if (base64Image != null) {
        prompt = 'Analyze this plant photo and provide detailed care recommendations. This is a $plantName. You MUST follow this EXACT format:\n\nPlant: [Identify the plant and provide the common name and scientific name if possible]\nDescription: [Provide a detailed description of the plant including its appearance, characteristics, and general information]\nCare Recommendations:\n   - Watering: [Specific watering instructions]\n   - Light Requirements: [Light needs]\n   - Temperature: [Temperature preferences]\n   - Soil: [Soil type and requirements]\n   - Fertilizing: [Fertilizer needs]\n   - Humidity: [Humidity requirements]\n   - Growth Rate / Size: [Growth characteristics]\n   - Blooming: [Flowering information if applicable]\nInteresting Facts: Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Format as simple sentences without any special characters, numbers, or bullet points.\n\nIMPORTANT: You MUST start with "Plant:" and "Description:" sections before the Care Recommendations. If you cannot identify the exact plant, provide a general description based on what you can see in the image.';
      } else {
        prompt = r'Provide detailed care recommendations for a $plantName. You MUST follow this EXACT format:\n\nPlant: [Identify the plant and provide the common name and scientific name if possible]\nDescription: [Provide a detailed description of the plant including its appearance, characteristics, and general information]\nCare Recommendations:\n   - Watering: [Specific watering instructions]\n   - Light Requirements: [Light needs]\n   - Temperature: [Temperature preferences]\n   - Soil: [Soil type and requirements]\n   - Fertilizing: [Fertilizer needs]\n   - Humidity: [Humidity requirements]\n   - Growth Rate / Size: [Growth characteristics]\n   - Blooming: [Flowering information if applicable]\nInteresting Facts: Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Format as simple sentences without any special characters, numbers, or bullet points.\n\nIMPORTANT: You MUST start with "Plant:" and "Description:" sections before the Care Recommendations. If you cannot identify the exact plant, provide a general description based on what you can see in the image.';
      }
      
      // Use GPT-4o for both image and text analysis
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model, // Always use GPT-4o
          'messages': [
            {
              'role': 'user',
              'content': base64Image != null 
                ? [
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
                  ]
                : prompt,
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final recommendations = _parseAIResponse(content);
        print('✅ Plant content generation successful using GPT-4o');
        return recommendations;
      } else {
        print('❌ GPT-4o API request failed with status: ${response.statusCode}');
        throw Exception('Failed to generate plant content: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Plant Content Generation Error: $e');
      throw Exception('Plant content generation failed: $e');
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
  
  /// Parses AI response to extract structured care recommendations
  static Map<String, dynamic> _parseAIResponse(String aiResponse) {
    try {
      // Try to parse as JSON first
      if (aiResponse.trim().startsWith('{')) {
        final jsonData = jsonDecode(aiResponse);
        return jsonData;
      }
      
      // Fallback: extract information from text
      final response = aiResponse.toLowerCase();
      
      // Extract plant name from Plant field
      String plantName = 'Plant';
      final lines = aiResponse.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.toLowerCase().startsWith('plant:')) {
          final parts = trimmedLine.split(':');
          if (parts.length >= 2) {
            plantName = parts[1].trim();
            break;
          }
        }
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

      // Extract structured care recommendations
      final careRecommendations = _extractStructuredCareRecommendations(aiResponse);

        return {
        'general_description': aiResponse,
        'name': plantName,
        'moisture_level': moistureLevel,
        'light': light,
        'watering_frequency': wateringFrequency,
        'watering_amount': 'Until soil is moist',
        'specific_issues': _extractIssues(aiResponse),
        'care_tips': careRecommendations,
        'interesting_facts': _extractInterestingFacts(aiResponse),
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
        'interesting_facts': ['Every plant is unique and has its own special characteristics', 'Plants grow and change throughout their lifecycle', 'Proper care helps plants thrive and stay healthy'],
      };
    }
  }

  /// Extracts structured care recommendations from AI response
  static String _extractStructuredCareRecommendations(String response) {
    final sections = <String>[];
    
    // Split response into lines and look for structured sections
    final lines = response.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      final lowerLine = trimmedLine.toLowerCase();
      
      // Check if we're entering the interesting facts section (end of care content)
      if (lowerLine.contains('interesting facts') || lowerLine.contains('fun facts')) {
        break;
      }
      
      // Extract any line with a colon (Plant:, Description:, Watering:, etc.)
      if (trimmedLine.contains(':')) {
        final parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          final title = parts[0].trim();
          final content = parts.sublist(1).join(':').trim();
          
          if (title.isNotEmpty && content.isNotEmpty) {
            // Clean up the title and content
            final cleanTitle = _cleanSectionTitle(title);
            final cleanContent = _cleanSectionContent(content);
            
            if (cleanTitle.isNotEmpty && cleanContent.isNotEmpty) {
              sections.add('$cleanTitle: $cleanContent');
            }
          }
        }
      }
    }
    
    // If no structured sections found, try to extract from the entire response
    if (sections.isEmpty) {
      sections.addAll(_extractCareSectionsFromText(response));
    }
    
    return sections.isEmpty ? 'Follow general plant care guidelines' : sections.join('\n');
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

  /// Extracts interesting facts from AI response
  static List<String> _extractInterestingFacts(String response) {
    final facts = <String>[];
    final lines = response.split('\n');
    bool inInterestingFactsSection = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      final lowerLine = trimmedLine.toLowerCase();
      
      // Check if we're entering the interesting facts section
      if (lowerLine.contains('interesting facts') || lowerLine.contains('fun facts') || lowerLine.contains('4. interesting facts') || lowerLine.contains('4. interesting facts:')) {
        inInterestingFactsSection = true;
        continue;
      }
      
      // Check if we're leaving the interesting facts section
      if (inInterestingFactsSection && (lowerLine.contains('care recommendations') || lowerLine.contains('plant identification') || lowerLine.contains('1.') || lowerLine.contains('2.') || lowerLine.contains('3.') || lowerLine.contains('5.'))) {
        break;
      }
      
      // If we're in the interesting facts section, extract facts
      if (inInterestingFactsSection) {
        // Skip lines that are clearly care instructions or section headers
        if (lowerLine.contains('watering') || 
            lowerLine.contains('light') || 
            lowerLine.contains('temperature') || 
            lowerLine.contains('soil') || 
            lowerLine.contains('fertilizer') || 
            lowerLine.contains('humidity') || 
            lowerLine.contains('growth') || 
            lowerLine.contains('bloom') ||
            lowerLine.contains('description') ||
            lowerLine.contains('care recommendations') ||
            lowerLine.contains('plant identification')) {
          continue;
        }
        
        // Skip empty lines and section markers
        if (trimmedLine.startsWith('-') || trimmedLine.startsWith('•') || trimmedLine.startsWith('*')) {
          // This is a bullet point, extract the content
          final content = trimmedLine.replaceAll(RegExp(r'^[-•*\s]+'), '').trim();
          if (content.isNotEmpty) {
            final cleanedFact = _cleanFactText(content);
            if (cleanedFact.isNotEmpty && !facts.contains(cleanedFact)) {
              facts.add(cleanedFact);
            }
          }
        } else if (trimmedLine.contains(':')) {
          // This might be a structured fact line
          final parts = trimmedLine.split(':');
          if (parts.length >= 2) {
            final content = parts.sublist(1).join(':').trim();
            if (content.isNotEmpty) {
              final cleanedFact = _cleanFactText(content);
              if (cleanedFact.isNotEmpty && !facts.contains(cleanedFact)) {
                facts.add(cleanedFact);
              }
            }
          }
        } else if (trimmedLine.length > 20) {
          // This might be a standalone fact
          final cleanedFact = _cleanFactText(trimmedLine);
          if (cleanedFact.isNotEmpty && !facts.contains(cleanedFact)) {
            facts.add(cleanedFact);
          }
        }
        
        // Limit to 4 facts
        if (facts.length >= 4) break;
      }
    }
    
    // If we still don't have enough facts, try to extract from the entire response
    if (facts.length < 4) {
      facts.addAll(_extractFactsFromResponse(response));
    }
    
    // If we still don't have enough facts, add some generic ones
    while (facts.length < 4) {
      if (facts.length == 0) {
        facts.add('Every plant is unique and has its own special characteristics');
      } else if (facts.length == 1) {
        facts.add('Plants grow and change throughout their lifecycle');
      } else if (facts.length == 2) {
        facts.add('Proper care helps plants thrive and stay healthy');
      } else if (facts.length == 3) {
        facts.add('Plants can communicate with each other through chemical signals');
      }
    }
    
      return facts.take(4).toList();
  }

  /// Cleans fact text by removing special characters and formatting
  static String _cleanFactText(String text) {
    return text
        // Remove markdown formatting
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'$1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Remove special characters
        .replaceAll('#', '')
        .replaceAll(r'$', '')
        .replaceAll('%', '')
        .replaceAll('^', '')
        .replaceAll('&', '')
        .replaceAll('*', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('|', '')
        .replaceAll('\\', '')
        .replaceAll(':', '')
        .replaceAll(';', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('?', '')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll('/', '')
        // Remove extra spaces and clean up
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Extracts general plant information for description
  static String _extractGeneralPlantInfo(String response) {
    final info = <String>[];
    
    // Extract plant type information
    if (response.toLowerCase().contains('tree')) {
      info.add('Tree plant');
    } else if (response.toLowerCase().contains('shrub')) {
      info.add('Shrub plant');
    } else if (response.toLowerCase().contains('herb')) {
      info.add('Herbaceous plant');
    } else if (response.toLowerCase().contains('succulent')) {
      info.add('Succulent plant');
    } else if (response.toLowerCase().contains('cactus')) {
      info.add('Cactus plant');
    } else {
      info.add('Plant');
    }
    
    // Extract basic characteristics
    if (response.toLowerCase().contains('evergreen')) {
      info.add('evergreen');
    }
    if (response.toLowerCase().contains('flowering')) {
      info.add('flowering');
    }
    if (response.toLowerCase().contains('fruiting')) {
      info.add('fruiting');
    }
    
    return info.join(' ');
  }

  /// Cleans section titles for consistent formatting
  static String _cleanSectionTitle(String title) {
    // Remove common prefixes and clean up
    String cleanTitle = title
        .replaceAll(RegExp(r'^[-*\s]+'), '') // Remove leading dashes, asterisks, spaces
        .replaceAll(RegExp(r'[-*\s]+$'), '') // Remove trailing dashes, asterisks, spaces
        .trim();
    
    // Capitalize first letter of each word
    final words = cleanTitle.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });
    
    return capitalizedWords.join(' ');
  }

  /// Cleans section content for better readability
  static String _cleanSectionContent(String content) {
    return content
        .replaceAll(RegExp(r'^[-*\s]+'), '') // Remove leading dashes, asterisks, spaces
        .replaceAll(RegExp(r'[-*\s]+$'), '') // Remove trailing dashes, asterisks, spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize multiple spaces
        .trim();
  }

  /// Fallback method to extract care sections from unstructured text
  static List<String> _extractCareSectionsFromText(String response) {
    final sections = <String>[];
    final lowerResponse = response.toLowerCase();
    
    // Look for specific care-related keywords and extract surrounding context
    if (lowerResponse.contains('water') || lowerResponse.contains('watering')) {
      sections.add('Watering: Monitor soil moisture regularly and water when the top inch feels dry');
    }
    
    if (lowerResponse.contains('light') || lowerResponse.contains('sun')) {
      sections.add('Light Requirements: Ensure proper light conditions for optimal growth');
    }
    
    if (lowerResponse.contains('temperature') || lowerResponse.contains('temp')) {
      sections.add('Temperature: Maintain stable temperature conditions');
    }
    
    if (lowerResponse.contains('soil') || lowerResponse.contains('potting')) {
      sections.add('Soil: Use well-draining potting mix appropriate for the plant type');
    }
    
    if (lowerResponse.contains('fertilizer') || lowerResponse.contains('fertilizing')) {
      sections.add('Fertilizing: Apply appropriate fertilizer during growing season');
    }
    
    if (lowerResponse.contains('humidity') || lowerResponse.contains('moisture')) {
      sections.add('Humidity: Consider humidity levels for optimal plant health');
    }
    
    if (lowerResponse.contains('growth') || lowerResponse.contains('size')) {
      sections.add('Growth Rate / Size: Monitor growth patterns and provide adequate space');
    }
    
    if (lowerResponse.contains('bloom') || lowerResponse.contains('flower')) {
      sections.add('Blooming: Provide proper care to encourage flowering when applicable');
    }
    
    return sections;
  }

  /// Extracts interesting facts from the entire response when section parsing fails
  static List<String> _extractFactsFromResponse(String response) {
    final facts = <String>[];
    final lowerResponse = response.toLowerCase();
    
    // Look for plant-specific interesting information
    if (lowerResponse.contains('native to') || lowerResponse.contains('origin')) {
      final match = RegExp(r'native to ([^.]+)', caseSensitive: false).firstMatch(response);
      if (match != null && match.group(1) != null) {
        facts.add('Native to ${match.group(1)!.trim()}');
      }
    }
    
    if (lowerResponse.contains('family') || lowerResponse.contains('genus')) {
      final match = RegExp(r'(?:family|genus)[:\s]+([^.]+)', caseSensitive: false).firstMatch(response);
      if (match != null && match.group(1) != null) {
        facts.add('Belongs to the ${match.group(1)!.trim()} family');
      }
    }
    
    if (lowerResponse.contains('fragrant') || lowerResponse.contains('scent')) {
      facts.add('Known for its pleasant fragrance and scent');
    }
    
    if (lowerResponse.contains('attracts') || lowerResponse.contains('pollinators')) {
      facts.add('Attracts beneficial pollinators and wildlife');
    }
    
    if (lowerResponse.contains('medicinal') || lowerResponse.contains('health benefits')) {
      facts.add('Has traditional medicinal uses and health benefits');
    }
    
    if (lowerResponse.contains('symbol') || lowerResponse.contains('meaning')) {
      facts.add('Holds cultural and symbolic significance');
    }
    
    if (lowerResponse.contains('variety') || lowerResponse.contains('cultivar')) {
      facts.add('Comes in many beautiful varieties and cultivars');
    }
    
    if (lowerResponse.contains('seasonal') || lowerResponse.contains('annual')) {
      facts.add('Shows seasonal changes and growth patterns');
    }
    
    return facts;
  }
}
