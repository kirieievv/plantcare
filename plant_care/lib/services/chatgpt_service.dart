import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'watering_calculator_service.dart';

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
  
  /// Generates AI content with image analysis
  static Future<Map<String, dynamic>> generatePlantContent(String plantName, String species, {String? base64Image}) async {
    try {
      print('🔍 Generating AI content for: $plantName ($species)');
      
      if (base64Image == null) {
        throw Exception('Image is required for analysis');
      }
      
      // Same unified prompt as Firebase Function
      final prompt = 'Analyze this image to assess plant health and calculate scientific watering recommendations.\n\nCRITICAL: Provide precise measurements for watering calculations.\n\nName: [Plant name]\nSpecies: [Species if identifiable]\nDescription: [Visual description]\n\nWatering Calculation Data (REQUIRED):\n   - Pot Present: [yes/no - Is there a visible pot/container?]\n   - Pot Diameter: [X cm or inches - Measure the top inner diameter of the pot]\n   - Pot Height: [X cm or inches - Measure the visible pot height]\n   - Plant Height: [X cm or inches - Total height from soil to top]\n   - Canopy Diameter: [X cm or inches - Widest horizontal spread]\n   - Visual Soil State: [wet/moist/slightly_dry/dry/very_dry/not_visible - Assess soil moisture]\n   - Plant Profile: [succulent/succulent_large/tropical_broadleaf/herbaceous/woody_potted/large_palm_indoor - Classify the plant type]\n\nOther Care:\n   - Light: [Hours per day and intensity]\n   - Growth Stage: [Seedling/Young/Mature/Established]\n\nInteresting Facts: [4 facts]\n\nHEALTH ASSESSMENT: [Is it healthy? Any problems?]';
      
      return await _generatePlantContentWithRetry(base64Image, prompt);
    } catch (e) {
      print('❌ Plant Content Generation Error: $e');
      throw Exception('Plant content generation failed: $e');
    }
  }
  
  /// Generates AI content with retry mechanism for measurement extraction
  static Future<Map<String, dynamic>> _generatePlantContentWithRetry(String base64Image, String initialPrompt, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      print('🔄 Attempt ${attempt + 1} of ${maxRetries + 1}');
      
      try {
        String promptToUse = initialPrompt;
        
        // Use a more aggressive prompt on retry
        if (attempt > 0) {
          promptToUse = '''CRITICAL: You MUST provide ALL required measurements EXACTLY in this format:

Pot Present: yes
Pot Diameter: [NUMBER] cm
Pot Height: [NUMBER] cm
Plant Height: [NUMBER] cm
Canopy Diameter: [NUMBER] cm
Visual Soil State: dry
Plant Profile: succulent

If you cannot see a pot, use:
Pot Present: no
Plant Height: [NUMBER] cm
Canopy Diameter: [NUMBER] cm
Visual Soil State: dry
Plant Profile: succulent

Provide your analysis in this format:

Name: [Plant name]
Species: [Species if identifiable]
Description: [Visual description]

Watering Calculation Data (REQUIRED):
   - Pot Present: [yes/no]
   - Pot Diameter: [X] cm
   - Pot Height: [X] cm
   - Plant Height: [X] cm
   - Canopy Diameter: [X] cm
   - Visual Soil State: [wet/moist/slightly_dry/dry/very_dry/not_visible]
   - Plant Profile: [succulent/succulent_large/tropical_broadleaf/herbaceous/woody_potted/large_palm_indoor]

Other Care:
   - Light: [Hours per day and intensity]
   - Growth Stage: [Seedling/Young/Mature/Established]

Interesting Facts: [4 facts]

HEALTH ASSESSMENT: [Is it healthy? Any problems?]''';
        }
        
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
                    'text': promptToUse,
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
          'max_tokens': 3000,
            'temperature': attempt == 0 ? 1.0 : 0.3, // Lower temperature on retry for more consistent formatting
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final recommendations = _parseAIResponse(content);
          
          // Check if scientific calculation succeeded
          if (recommendations.containsKey('amount_ml') && recommendations['amount_ml'] != null) {
            print('✅ Plant content generation successful with measurements on attempt ${attempt + 1}');
        return recommendations;
          } else {
            print('⚠️ Attempt ${attempt + 1} failed: Scientific calculation returned null');
            if (attempt < maxRetries) {
              print('🔄 Retrying with more specific prompt...');
              await Future.delayed(Duration(milliseconds: 500)); // Small delay before retry
              continue;
            } else {
              throw Exception('Failed to extract required measurements after $maxRetries retries. Please try again or provide more detailed plant information.');
            }
          }
      } else {
        print('❌ gpt-4o API request failed with status: ${response.statusCode}');
        throw Exception('Failed to generate plant content: ${response.statusCode}');
      }
    } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        print('⚠️ Attempt ${attempt + 1} failed: $e');
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    
    throw Exception('Failed to generate plant content after $maxRetries retries');
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
          'max_tokens': 3000,
          'temperature': 1.0,
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
      
      // Extract name from Name or Plant field
      String plantName = 'Plant';
      final lines = aiResponse.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        final lowerLine = trimmedLine.toLowerCase();
        if (lowerLine.startsWith('name:') || lowerLine.startsWith('plant:')) {
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
      
      // Extract watering frequency - more comprehensive detection
      int wateringFrequency = 7; // Default fallback
      
      // Try to extract frequency pattern like "every X days" or "X days"
      final frequencyPattern = RegExp(r'every\s*(\d+)\s*days?|(\d+)\s*days?', caseSensitive: false);
      final frequencyMatch = frequencyPattern.firstMatch(response);
      
      if (frequencyMatch != null) {
        // Check group 1 (every X days) or group 2 (X days)
        final days = frequencyMatch.group(1) ?? frequencyMatch.group(2);
        if (days != null) {
          wateringFrequency = int.tryParse(days) ?? 7;
        }
      }
      
      // Also check for common patterns
      if (response.contains('daily') || response.contains('every day') || response.contains('1 day')) {
        wateringFrequency = 1;
      } else if (response.contains('every 2 days') || response.contains('2 days')) {
        wateringFrequency = 2;
      } else if (response.contains('every 3 days') || response.contains('3 days')) {
        wateringFrequency = 3;
      } else if (response.contains('every 4 days') || response.contains('4 days')) {
        wateringFrequency = 4;
      } else if (response.contains('every 5 days') || response.contains('5 days')) {
        wateringFrequency = 5;
      } else if (response.contains('every 6 days') || response.contains('6 days')) {
        wateringFrequency = 6;
      } else if (response.contains('every 7 days') || response.contains('7 days') || response.contains('weekly')) {
        wateringFrequency = 7;
      } else if (response.contains('every 10 days') || response.contains('10 days')) {
        wateringFrequency = 10;
      } else if (response.contains('every 14 days') || response.contains('14 days') || response.contains('biweekly')) {
        wateringFrequency = 14;
      } else if (response.contains('every 21 days') || response.contains('21 days') || response.contains('3 weeks')) {
        wateringFrequency = 21;
      } else if (response.contains('monthly') || response.contains('every month') || response.contains('30 days')) {
        wateringFrequency = 30;
      }
      
      print('🌱 Extracted watering frequency: $wateringFrequency days');
      
      // Extract watering amount in milliliters
      String wateringAmount = '200-400 ml'; // Default fallback
      final mlPattern = RegExp(r'amount:\s*(\d+\s*-\s*\d+\s*ml)', caseSensitive: false);
      final mlMatch = mlPattern.firstMatch(aiResponse);
      if (mlMatch != null) {
        wateringAmount = mlMatch.group(1)?.trim() ?? '200-400 ml';
        print('🌱 Extracted watering amount: $wateringAmount');
      } else {
        // Try alternative patterns
        final mlPattern2 = RegExp(r'(\d+)\s*-\s*(\d+)\s*ml', caseSensitive: false);
        final mlMatch2 = mlPattern2.firstMatch(aiResponse);
        if (mlMatch2 != null) {
          wateringAmount = '${mlMatch2.group(1)}-${mlMatch2.group(2)} ml';
          print('🌱 Extracted watering amount: $wateringAmount');
        }
        }

      // Extract structured care recommendations
      final careRecommendations = _extractStructuredCareRecommendations(aiResponse);

      // Extract fields for scientific watering calculation
      final scientificWatering = _calculateScientificWatering(aiResponse, plantName);
      
      // Scientific watering calculation is REQUIRED - no fallback
      if (scientificWatering != null) {
        print('✅ Scientific watering calculated: ${scientificWatering['amount_ml']} ml, mode: ${scientificWatering['mode']}');
      } else {
        print('❌ Scientific watering calculation returned null');
        // Return null so retry mechanism can trigger
        return {
          'general_description': aiResponse,
          'name': plantName,
          'moisture_level': moistureLevel,
          'light': light,
          'watering_frequency': wateringFrequency,
          'watering_amount': null, // Signal failure
          'specific_issues': _extractIssues(aiResponse),
          'care_tips': careRecommendations,
          'interesting_facts': _extractInterestingFacts(aiResponse),
        };
      }

        return {
        'general_description': aiResponse,
        'name': plantName,
        'moisture_level': moistureLevel,
        'light': light,
        'watering_frequency': wateringFrequency,
        'watering_amount': wateringAmount,
        'specific_issues': _extractIssues(aiResponse),
        'care_tips': careRecommendations,
        'interesting_facts': _extractInterestingFacts(aiResponse),
        // Scientific watering calculation results
        ...scientificWatering,
      };
    } catch (e) {
      print('❌ Failed to parse AI response: $e');
      // Re-throw to trigger retry mechanism
      rethrow;
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
      
      // Extract any line with a colon (Name:, Description:, Watering:, etc.)
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
  
  /// Calculate scientific watering based on extracted AI data
  static Map<String, dynamic>? _calculateScientificWatering(String aiResponse, String plantName) {
    try {
      print('🔍 Starting scientific watering calculation...');
      
      // Extract pot presence
      final potPresentMatch = RegExp(r'Pot\s*Present:\s*(yes|no)', caseSensitive: false).firstMatch(aiResponse);
      final hasPot = potPresentMatch?.group(1)?.toLowerCase() == 'yes';
      print('🔍 Pot present: $hasPot');
      
      // Extract pot dimensions
      double? potDiameter;
      double? potHeight;
      if (hasPot) {
        final diameterMatch = RegExp(r'Pot\s*Diameter:\s*(\d+(?:\.\d+)?)\s*(cm|in)', caseSensitive: false).firstMatch(aiResponse);
        if (diameterMatch != null) {
          potDiameter = double.tryParse(diameterMatch.group(1)!);
          final unit = diameterMatch.group(2)?.toLowerCase();
          if (unit == 'in' && potDiameter != null) {
            potDiameter = potDiameter! * 2.54; // Convert inches to cm
          }
        }
        
        final heightMatch = RegExp(r'Pot\s*Height:\s*(\d+(?:\.\d+)?)\s*(cm|in)', caseSensitive: false).firstMatch(aiResponse);
        if (heightMatch != null) {
          potHeight = double.tryParse(heightMatch.group(1)!);
          final unit = heightMatch.group(2)?.toLowerCase();
          if (unit == 'in' && potHeight != null) {
            potHeight = potHeight! * 2.54; // Convert inches to cm
          }
        }
        print('🔍 Pot dimensions: diameter=$potDiameter cm, height=$potHeight cm');
      }
      
      // Extract plant dimensions
      final plantHeightMatch = RegExp(r'Plant\s*Height:\s*(\d+(?:\.\d+)?)\s*(cm|in)', caseSensitive: false).firstMatch(aiResponse);
      double? plantHeight;
      if (plantHeightMatch != null) {
        plantHeight = double.tryParse(plantHeightMatch.group(1)!);
        final unit = plantHeightMatch.group(2)?.toLowerCase();
        if (unit == 'in' && plantHeight != null) {
          plantHeight = plantHeight! * 2.54;
        }
      }
      
      final canopyMatch = RegExp(r'Canopy\s*Diameter:\s*(\d+(?:\.\d+)?)\s*(cm|in)', caseSensitive: false).firstMatch(aiResponse);
      double? canopyDiameter;
      if (canopyMatch != null) {
        canopyDiameter = double.tryParse(canopyMatch.group(1)!);
        final unit = canopyMatch.group(2)?.toLowerCase();
        if (unit == 'in' && canopyDiameter != null) {
          canopyDiameter = canopyDiameter! * 2.54;
        }
      }
      print('🔍 Plant dimensions: height=$plantHeight cm, canopy=$canopyDiameter cm');
      
      // Extract soil state
      final soilStateMatch = RegExp(r'Visual\s*Soil\s*State:\s*(wet|moist|slightly_dry|dry|very_dry|not_visible)', caseSensitive: false).firstMatch(aiResponse);
      final soilStateText = soilStateMatch?.group(1)?.toLowerCase();
      print('🔍 Soil state: $soilStateText');
      
      // Extract profile
      final profileMatch = RegExp(r'Plant\s*Profile:\s*(succulent|succulent_large|tropical_broadleaf|herbaceous|woody_potted|large_palm_indoor)', caseSensitive: false).firstMatch(aiResponse);
      final profileText = profileMatch?.group(1)?.toLowerCase();
      print('🔍 Plant profile: $profileText');
      
      // If we don't have enough data, return null
      if (!hasPot && (plantHeight == null || canopyDiameter == null)) {
        print('⚠️ Insufficient data for scientific watering calculation - no pot and missing plant dimensions');
        return null;
      }
      
      if (hasPot && (potDiameter == null || potHeight == null)) {
        print('⚠️ Insufficient data for scientific watering calculation - has pot but missing pot dimensions');
        return null;
      }
      
      // Calculate effective volume
      double effectiveVolumeMl;
      if (hasPot && potDiameter != null && potHeight != null) {
        final container = ContainerDimensions(
          potDiameterCm: potDiameter!,
          potHeightCm: potHeight!,
        );
        effectiveVolumeMl = WateringCalculatorService.calculatePotVolume(container);
      } else if (plantHeight != null && canopyDiameter != null) {
        final plantDims = PlantDimensions(
          plantHeightCm: plantHeight!,
          plantCanopyDiameterCm: canopyDiameter!,
        );
        effectiveVolumeMl = WateringCalculatorService.calculateEquivalentRootVolume(plantDims);
      } else {
        print('⚠️ Cannot calculate volume without dimensions');
        return null;
      }
      
      // Parse soil state
      VisualSoilState soilState = VisualSoilState.notVisible;
      if (soilStateText != null) {
        switch (soilStateText) {
          case 'wet':
            soilState = VisualSoilState.wet;
            break;
          case 'moist':
            soilState = VisualSoilState.moist;
            break;
          case 'slightly_dry':
            soilState = VisualSoilState.slightlyDry;
            break;
          case 'dry':
            soilState = VisualSoilState.dry;
            break;
          case 'very_dry':
            soilState = VisualSoilState.veryDry;
            break;
          default:
            soilState = VisualSoilState.notVisible;
        }
      }
      
      // Parse profile
      PlantProfile profile = WateringCalculatorService.parsePlantProfile(plantName, null);
      if (profileText != null) {
        switch (profileText) {
          case 'succulent':
            profile = PlantProfile.succulent;
            break;
          case 'succulent_large':
            profile = PlantProfile.succulentLarge;
            break;
          case 'tropical_broadleaf':
            profile = PlantProfile.tropicalBroadleaf;
            break;
          case 'herbaceous':
            profile = PlantProfile.herbaceous;
            break;
          case 'woody_potted':
            profile = PlantProfile.woodyPotted;
            break;
          case 'large_palm_indoor':
            profile = PlantProfile.largePalmIndoor;
            break;
        }
      }
      
      // Calculate watering
      final result = WateringCalculatorService.calculateWatering(
        profile: profile,
        soilState: soilState,
        effectiveVolumeMl: effectiveVolumeMl,
        hasPot: hasPot,
      );
      
      return result.toMap();
    } catch (e) {
      print('❌ Error in scientific watering calculation: $e');
      return null;
    }
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
