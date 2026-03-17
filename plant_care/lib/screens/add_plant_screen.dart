import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/utils/responsive_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:plant_care/l10n/app_localizations.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plant_care/screens/plant_details_screen.dart';

/// ⚠️ IMPORTANT: AUTOMATIC NAVIGATION FEATURE ⚠️
/// 
/// This screen automatically redirects users to their newly created plant's details page
/// after successful plant creation. This is a key user experience feature that should
/// NOT be removed without careful consideration.
/// 
/// FEATURE DESCRIPTION:
/// - User creates a plant → Success message appears → Automatically redirected to PlantDetailsScreen
/// - Uses Navigator.pushReplacement to prevent accidental return to add plant form
/// - Provides fallback navigation if automatic navigation fails
/// 
/// WHY THIS FEATURE EXISTS:
/// - Better UX: Users see their new plant immediately after creation
/// - No confusion: No need to search for the new plant in a list
/// - Seamless flow: Direct transition from creation to management
/// 
/// IF YOU NEED TO MODIFY THIS BEHAVIOR:
/// 1. Test thoroughly to ensure the change improves user experience
/// 2. Consider adding a user preference option rather than removing the feature
/// 3. Update all related comments and documentation
/// 4. Ensure the change works from all entry points (Dashboard, Bottom Navigation)
/// 
/// RELATED FILES:
/// - dashboard_screen.dart: Simplified navigation logic (relies on this feature)
/// - plant_details_screen.dart: Destination screen for new plants
/// - plant_service.dart: Plant creation service
/// 
/// LAST UPDATED: [Current Date] - Automatic navigation implemented
/// 
class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({Key? key}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  

  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  // AI-generated care recommendations
  String? _aiGeneralDescription;
  String? _aiName;
  String? _aiMoistureLevel;
  String? _aiLight;
  String? _aiWateringFrequency;
  String? _aiWateringAmount;
  String? _aiSpecificIssues;
  String? _aiCareTips;
  List<String>? _aiInterestingFacts;
  
  // Plant size assessment fields
  String? _aiPlantSize;
  String? _aiPotSize;
  String? _aiGrowthStage;
  
  // Scientific watering calculation fields
  int? _wateringAmountMl;
  List<int>? _wateringRangeMl;
  int? _nextAfterWateringHours;
  int? _nextCheckHours;
  String? _wateringMode;
  int? _nextWateringInDays;
  bool _shouldWaterNow = false; // From AI watering_plan
  
  // Refresh status
  bool _isRefreshing = false;
  String? _refreshStatus = 'error'; // Start with error status since we know API is failing
  
  // Random plant names for name generator
  final List<String> _randomPlantNames = [
    'Fernando', 'Leafy', 'Buddy', 'Sprout', 'Greenie', 'Planty', 'Grower', 'Flora',
    'Verdant', 'Emerald', 'Jade', 'Sage', 'Olive', 'Mint', 'Basil', 'Rosemary',
    'Thyme', 'Lavender', 'Ivy', 'Willow', 'Maple', 'Oak', 'Pine', 'Cedar',
    'Bamboo', 'Palm', 'Cactus', 'Succulent', 'Herb', 'Spice', 'Blossom', 'Bloom',
    'Petunia', 'Daisy', 'Rose', 'Tulip', 'Lily', 'Orchid', 'Sunflower', 'Marigold',
    'Zinnia', 'Pansy', 'Violet', 'Iris', 'Peony', 'Chrysanthemum', 'Dahlia', 'Aster',
    'Cosmos', 'Snapdragon', 'Foxglove', 'Delphinium', 'Larkspur', 'Columbine',
    'Monstera', 'Philodendron', 'Pothos', 'Snake Plant', 'ZZ Plant', 'Fiddle Leaf',
    'Bird of Paradise', 'Elephant Ear', 'Calathea', 'Prayer Plant', 'Alocasia',
    'Anthurium', 'Peace Lily', 'Chinese Evergreen', 'Dracaena', 'Schefflera',
    'Ficus', 'Jade Plant', 'Aloe Vera', 'Haworthia', 'Echeveria', 'Sedum',
    'Crassula', 'Kalanchoe', 'Peperomia', 'Begonia', 'Impatiens', 'Geranium',
    'Coleus', 'Polka Dot Plant', 'Nerve Plant', 'Pilea', 'String of Pearls',
    'String of Hearts', 'Burro\'s Tail', 'Jade Necklace', 'Trailing Jade'
  ];

  AppLocalizations get l10n => AppLocalizations.of(context)!;



  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomPlantName() {
    final random = Random();
    final randomName = _randomPlantNames[random.nextInt(_randomPlantNames.length)];
    setState(() {
      _nameController.text = randomName;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200, // 3:4 portrait
        imageQuality: 90,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
        
        // Analyze the plant photo with ChatGPT
        _analyzePlantPhoto(bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorPickingImage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzePlantPhoto(Uint8List imageBytes) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final base64Image = base64Encode(imageBytes);
      
      // Call Firebase Function instead of OpenAI directly (CORS fix)
      final response = await http.post(
        Uri.parse('https://us-central1-plant-care-94574.cloudfunctions.net/analyzePlantPhoto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64Image': base64Image,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception(l10n.failedToAnalyzePlantPhoto(response.statusCode));
      }
      
      final result = jsonDecode(response.body);
      final recommendations = result['recommendations'] ?? {};
      
      print('🔍 AI Analysis Results:');
      print('🔍 general_description: ${recommendations['general_description']}');
      print('🔍 name: ${recommendations['name']}');
      print('🔍 moisture_level: ${recommendations['moisture_level']}');
      print('🔍 light: ${recommendations['light']}');
      print('🔍 watering_frequency: ${recommendations['watering_frequency']}');
      print('🔍 specific_issues: ${recommendations['specific_issues']}');
      print('🔍 care_tips: ${recommendations['care_tips']}');
      
      setState(() {
        _aiGeneralDescription = recommendations['general_description'];
        _aiName = recommendations['name'];
        _aiMoistureLevel = recommendations['moisture_level'];
        _aiLight = recommendations['light'];
        _aiWateringFrequency = recommendations['watering_frequency']?.toString();
        _aiWateringAmount = recommendations['watering_amount'];
        _aiSpecificIssues = recommendations['specific_issues'];
        _aiCareTips = recommendations['care_tips'];
        
        // Fix type casting for interesting_facts
        _aiInterestingFacts = (recommendations['interesting_facts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        
        // Extract plant size assessment data
        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'];
        
        // New: per-plant, days-based watering interval from AI (species-specific structure)
        final wateringPlan = recommendations['watering_plan'] as Map<String, dynamic>? ?? {};
        final nextDays = wateringPlan['next_watering_in_days'];
        _nextWateringInDays = nextDays != null ? int.tryParse(nextDays.toString()) : null;
        _shouldWaterNow = wateringPlan['should_water_now'] == true;
        
        // Extract amount_ml from watering_plan first (already clamped by backend), then fallback to legacy
        _wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        
        // Extract scientific watering calculation data (legacy support)
        _wateringRangeMl = recommendations['range_ml'] != null ? List<int>.from(recommendations['range_ml']) : null;
        _nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        _nextCheckHours = recommendations['next_check_in_hours'];
        _wateringMode = recommendations['mode'];
        
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisFailed(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    try {
      // Test Firebase Functions connectivity
      final response = await http.get(
        Uri.parse('https://us-central1-plant-care-94574.cloudfunctions.net/analyzePlantPhoto'),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 405 
                ? '✅ Firebase Functions are accessible! (Method not allowed is expected for GET)' 
                : '❌ Firebase Functions test failed. Status: ${response.statusCode}',
            ),
            backgroundColor: response.statusCode == 405 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.apiTestError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _refreshAnalysis() async {
    if (_selectedImageBytes == null) return;
    
    setState(() {
      _isRefreshing = true;
      _refreshStatus = null;
    });

    try {
      final base64Image = base64Encode(_selectedImageBytes!);
      
      // Call Firebase Function instead of OpenAI directly (CORS fix)
      final response = await http.post(
        Uri.parse('https://us-central1-plant-care-94574.cloudfunctions.net/analyzePlantPhoto'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64Image': base64Image,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception(l10n.failedToAnalyzePlantPhoto(response.statusCode));
      }
      
      final result = jsonDecode(response.body);
      final recommendations = result['recommendations'] ?? {};
      
      setState(() {
        _aiGeneralDescription = recommendations['general_description'];
        _aiName = recommendations['name'];
        _aiMoistureLevel = recommendations['moisture_level'];
        _aiLight = recommendations['light'];
        _aiWateringFrequency = recommendations['watering_frequency']?.toString();
        _aiWateringAmount = recommendations['watering_amount'];
        _aiSpecificIssues = recommendations['specific_issues'];
        _aiCareTips = recommendations['care_tips'];
        
        // Fix type casting for interesting_facts
        _aiInterestingFacts = (recommendations['interesting_facts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        
        // Extract plant size assessment data
        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'];
        
        // New: per-plant, days-based watering interval from AI (species-specific structure)
        final wateringPlan = recommendations['watering_plan'] as Map<String, dynamic>? ?? {};
        final nextDays = wateringPlan['next_watering_in_days'];
        _nextWateringInDays = nextDays != null ? int.tryParse(nextDays.toString()) : null;
        _shouldWaterNow = wateringPlan['should_water_now'] == true;
        
        // Extract amount_ml from watering_plan first (already clamped by backend), then fallback to legacy
        _wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        
        // Extract scientific watering calculation data (legacy support)
        _wateringRangeMl = recommendations['range_ml'] != null ? List<int>.from(recommendations['range_ml']) : null;
        _nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        _nextCheckHours = recommendations['next_check_in_hours'];
        _wateringMode = recommendations['mode'];
        
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisRefreshed),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _refreshStatus = 'error';
      });
      
      print('AI analysis refresh error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisRefreshFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.retry,
              onPressed: _refreshAnalysis,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL - 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 48,
            color: AppTheme.accentGreen.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.uploadPlantPhoto,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.accentGreen.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.purple.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Calculate light hours per day based on AI light requirements
  String _calculateLightHours() {
    if (_aiLight == null || _aiLight!.isEmpty) {
      return l10n.notSpecified;
    }
    
    final lightRequirement = _aiLight!.toLowerCase();
    
    // Extract hours if already specified as numbers
    final hourPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h\b)');
    final hourMatch = hourPattern.firstMatch(lightRequirement);
    if (hourMatch != null) {
      final hours = double.tryParse(hourMatch.group(1)!) ?? 0;
      return '${hours.toInt()}';
    }
    
    // Calculate based on light intensity descriptions
    if (lightRequirement.contains('full sun') || lightRequirement.contains('direct sun')) {
      return '6-8'; // Full sun plants need 6-8 hours of direct sunlight
    } else if (lightRequirement.contains('partial sun') || lightRequirement.contains('morning sun')) {
      return '4-6'; // Partial sun plants need 4-6 hours
    } else if (lightRequirement.contains('partial shade') || lightRequirement.contains('filtered light')) {
      return '2-4'; // Partial shade plants need 2-4 hours
    } else if (lightRequirement.contains('bright indirect') || lightRequirement.contains('bright light')) {
      return '8-12'; // Bright indirect light throughout the day
    } else if (lightRequirement.contains('low light') || lightRequirement.contains('shade')) {
      return '2-3'; // Low light plants need minimal direct light
    } else if (lightRequirement.contains('medium light') || lightRequirement.contains('moderate light')) {
      return '4-6'; // Medium light requirements
    } else if (lightRequirement.contains('very bright') || lightRequirement.contains('high light')) {
      return '10-12'; // Very bright light requirements
    }
    
    // Default calculation based on plant species if available
    final species = _aiName?.toLowerCase() ?? 'unknown';
    
    if (species.contains('succulent') || species.contains('cactus')) {
      return '6-8'; // Most succulents need full sun
    } else if (species.contains('pothos') || species.contains('philodendron')) {
      return '4-6'; // Popular houseplants with moderate light needs
    } else if (species.contains('snake plant') || species.contains('zz plant')) {
      return '2-4'; // Low light tolerant plants
    } else if (species.contains('fiddle leaf') || species.contains('monstera')) {
      return '6-8'; // Bright light loving houseplants
    } else if (species.contains('calathea') || species.contains('prayer plant')) {
      return '4-6'; // Prefer bright indirect light
    }
    
    // Default fallback
    return '4-6';
  }

  /// Convert moisture level text to percentage (0-100)
  int _getMoisturePercentage(String? moistureLevel) {
    if (moistureLevel == null) return 50;
    
    try {
      // First, check if it's already a percentage number
      final percentage = int.tryParse(moistureLevel);
      if (percentage != null && percentage >= 0 && percentage <= 100) {
        return percentage;
      }
      
      // Check if it's a range like "40-60%"
      final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(moistureLevel);
      if (rangeMatch != null) {
        final min = int.tryParse(rangeMatch.group(1) ?? '');
        final max = int.tryParse(rangeMatch.group(2) ?? '');
        if (min != null && max != null) {
          return (min + max) ~/ 2; // Return midpoint
        }
      }
      
      // Fallback to text-based conversion
      final level = moistureLevel.toLowerCase();
      int percentageResult;
      
      if (level.contains('low') || level.contains('dry')) {
        percentageResult = 25;
      } else if (level.contains('moderate') || level.contains('medium')) {
        percentageResult = 50;
      } else if (level.contains('high') || level.contains('wet') || level.contains('moist')) {
        percentageResult = 75;
      } else if (level.contains('very high') || level.contains('very wet')) {
        percentageResult = 90;
      } else {
        percentageResult = 50; // Default to moderate
      }
      
      return percentageResult;
    } catch (e) {
      print('Error parsing moisture level: $moistureLevel, error: $e');
      return 50; // Safe fallback
    }
  }
  
  /// Format watering frequency to human-readable text
  String _formatWateringFrequency(String? frequency) {
    if (frequency == null) return l10n.onceEvery7Days;
    
    try {
      final days = int.parse(frequency);
      if (days == 1) return l10n.oncePerDay;
      if (days == 7) return l10n.oncePerWeek;
      if (days <= 14) return l10n.onceEveryNDays(days);
      if (days <= 30) return l10n.onceEveryNWeeks((days / 7).round());
      return l10n.onceEveryNDays(days);
    } catch (e) {
      return l10n.onceEvery7Days;
    }
  }
  
  /// Format moisture level to five gradations
  String _formatMoistureLevel(String? moistureLevel) {
    if (moistureLevel == null) return l10n.medium;
    
    final level = moistureLevel.toLowerCase();
    if (level.contains('very low') || level.contains('extremely low') || level.contains('dry')) return l10n.low;
    if (level.contains('low') || level.contains('slightly low')) return l10n.mediumLow;
    if (level.contains('moderate') || level.contains('medium') || level.contains('average')) return l10n.medium;
    if (level.contains('high') || level.contains('slightly high') || level.contains('moist')) return l10n.mediumHigh;
    if (level.contains('very high') || level.contains('extremely high') || level.contains('wet') || level.contains('soggy')) return l10n.high;
    
    return l10n.medium; // Default
  }

  Widget _buildCareCard(String title, String value, IconData icon, Color color, {int? moisturePercentage}) {
    return Container(
      padding: const EdgeInsets.all(18), // Increased padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), // Reduced opacity for subtlety
        borderRadius: BorderRadius.circular(16), // Increased radius
        border: Border.all(
          color: color.withOpacity(0.25), // Reduced border opacity
          width: 1.5, // Increased border width
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12), // Increased spacing
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700, // Increased weight
              color: color,
              fontSize: 13, // Slightly increased
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6), // Increased spacing
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15, // Increased size
              fontWeight: FontWeight.w600, // Increased weight
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (moisturePercentage != null) ...[
            const SizedBox(height: 10), // Increased spacing
            Container(
              width: double.infinity,
              height: 8, // Increased height
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4), // Increased radius
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (moisturePercentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4), // Increased radius
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$moisturePercentage%',
              style: TextStyle(
                color: color,
                fontSize: 13, // Increased size
                fontWeight: FontWeight.w700, // Increased weight
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(l10n.userNotAuthenticated);
      }

      // Handle image selection - only use custom uploaded image
      if (_selectedImageBytes == null) {
        throw Exception(l10n.pleaseUploadPlantImage);
      }
      
      // Require AI analysis before creating plant
      if (_aiGeneralDescription == null || _aiSpecificIssues == null) {
        throw Exception(l10n.pleaseWaitForAiAnalysisBeforeAddingPlant);
      }

      // Upload image to Firebase Storage; store only the URL in Firestore (limit 1MB per field)
      final plantName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_aiName ?? l10n.plantLowercase);
      final imageUrl = await ImageUploadService().uploadPlantImageFromBytes(
        _selectedImageBytes!,
        plantName,
      );

      // Use AI-determined watering frequency or default to 7 days
      final wateringFreq = _aiWateringFrequency != null 
          ? int.tryParse(_aiWateringFrequency!) ?? 7 
          : 7;
      
      // NEW PLANTS: NO health status or health message until first manual health check
      // AI analysis is only used for care recommendations, not health status
      
      final plant = Plant(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        species: _aiName ?? 'Unknown Species', // Use AI name or default species
        imageUrl: imageUrl,
        lastWatered: DateTime.now(),
        nextWatering: DateTime.now().add(Duration(days: wateringFreq)),
        wateringFrequency: wateringFreq,
        notes: null, // No notes field in add plant screen
        createdAt: DateTime.now(),
        userId: user.uid,
        aiGeneralDescription: _aiGeneralDescription,
        aiName: _aiName,
        aiMoistureLevel: _aiMoistureLevel,
        aiLight: _aiLight,
        aiWateringAmount: _aiWateringAmount,
        aiSpecificIssues: _aiSpecificIssues,
        aiCareTips: _aiCareTips,
        interestingFacts: _aiInterestingFacts,
        aiPlantSize: _aiPlantSize,
        aiPotSize: _aiPotSize,
        aiGrowthStage: _aiGrowthStage,
        wateringAmountMl: _wateringAmountMl,
        wateringRangeMl: _wateringRangeMl,
        nextAfterWateringHours: _nextAfterWateringHours,
        nextCheckHours: _nextCheckHours,
        wateringMode: _wateringMode,
        wateringIntervalDays: _nextWateringInDays,
        shouldWaterNow: _shouldWaterNow, // From AI analysis
        healthStatus: null, // No health status for new plants
        healthMessage: null, // No health message for new plants
        lastHealthCheck: null, // No health check for new plants
      );

      final plantId = await PlantService().addPlant(plant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plantAddedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // ⚠️ IMPORTANT: DO NOT DELETE THIS AUTOMATIC NAVIGATION FUNCTIONALITY ⚠️
        // This feature automatically redirects users to their newly created plant's details page
        // instead of just going back to the previous screen. This provides a much better UX.
        // 
        // If you need to modify this behavior:
        // 1. Test thoroughly to ensure the change doesn't break user experience
        // 2. Consider adding a user preference option rather than removing the feature
        // 3. Update this comment to reflect any changes made
        // 
        // Current behavior: User creates plant → Automatically redirected to PlantDetailsScreen
        // Expected user flow: Add Plant → See Success Message → View New Plant Details
        
        // Navigate directly to the new plant's details page
        try {
          // Get the plant data from Firestore to pass to PlantDetailsScreen
          final plantDoc = await FirebaseFirestore.instance
              .collection('plants')
              .doc(plantId)
              .get();
          
          if (plantDoc.exists) {
            final plantData = plantDoc.data()!;
            plantData['id'] = plantId;
            final newPlant = Plant.fromMap(plantData);
            
            // Navigate to the new plant's details page using pushReplacement
            // This ensures the user can't accidentally go back to the add plant form
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PlantDetailsScreen(plant: newPlant),
              ),
            );
          } else {
            // Fallback: return to previous screen with plant ID
            // This should rarely happen but provides safety if Firestore query fails
            print('⚠️ AddPlantScreen: Plant not found in Firestore, using fallback navigation');
            Navigator.pop(context, {
              'success': true,
              'plantId': plantId,
            });
          }
        } catch (e) {
          print('❌ Error navigating to new plant: $e');
          // Fallback: return to previous screen with plant ID
          // This ensures the app doesn't crash if navigation fails
          Navigator.pop(context, {
            'success': true,
            'plantId': plantId,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAddingPlant(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputCard(String label, String hintText, IconData icon, {TextEditingController? controller, String? Function(String?)? validator, Color? iconColor}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Input field with random name button (only for Plant Name)
            if (label == l10n.plantName) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: AppTheme.inputDecoration(
                        labelText: '',
                        hintText: hintText,
                        prefixIcon: icon,
                        prefixIconColor: iconColor,
                      ),
                      style: AppTheme.bodyLarge,
                      validator: validator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Random name button
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      onPressed: _generateRandomPlantName,
                      icon: Icon(
                        Icons.shuffle,
                        color: AppTheme.accentGreen,
                        size: 24,
                      ),
                      tooltip: l10n.generateRandomName,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Regular input field for other fields
              TextFormField(
                controller: controller,
                decoration: AppTheme.inputDecoration(
                  labelText: '',
                  hintText: hintText,
                  prefixIcon: icon,
                  prefixIconColor: iconColor,
                ),
                style: AppTheme.bodyLarge,
                validator: validator,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Plant Image',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Image Display Area
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImageBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusL - 2),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            ),
                          ),
                          if (_isAnalyzing)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusL - 2),
                                color: Colors.black.withOpacity(0.6),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Analyzing...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Upload Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(
                  _selectedImageBytes != null ? Icons.refresh : Icons.upload,
                  color: Colors.white,
                ),
                label: Text(
                  _selectedImageBytes != null ? 'Change Image' : 'Upload Image',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            if (_selectedImageBytes != null && !_isAnalyzing) ...[
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image uploaded successfully! AI analysis complete.',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIResultsCard() {
    return Card(
      elevation: 2, // Reduced elevation for subtlety
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Increased radius for modern look
        side: BorderSide(
          color: AppTheme.accentGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header - Improved layout with smaller title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: AppTheme.accentGreen,
                    size: 20, // Reduced from 24 to 20
                  ),
                ),
                const SizedBox(width: 16), // Increased spacing
                Expanded(
                  child: Text(
                    'AI Care Recommendations',
                    style: TextStyle(
                      fontSize: 18, // Reduced from 20 to 18 for better UI balance
                      fontWeight: FontWeight.w600, // Reduced from bold to w600
                      color: AppTheme.textPrimary,
                      height: 1.2, // Better line height
                    ),
                  ),
                ),
                // Status Indicator - Improved design
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.accentGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700, // Increased weight
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24), // Increased spacing
            

            
            // Care Details Grid - Improved layout
            Row(
              children: [
                Expanded(
                  child: _buildCareCard(
                    'Moisture',
                    '${_getMoisturePercentage(_aiMoistureLevel)}%',
                    Icons.opacity,
                    AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCareCard(
                    'Light',
                    '${_calculateLightHours()} hours',
                    Icons.wb_sunny,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Watering Schedule - Improved styling
            if (_aiWateringFrequency != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watering Frequency',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatWateringFrequency(_aiWateringFrequency),
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Structured Care Recommendations - Unified design matching plant page
            if (_aiCareTips != null) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentGreen, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header matching plant page design
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: AppTheme.accentGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Care Recommendations',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentGreen,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content area
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildStructuredCareSections(_aiCareTips!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Interesting Facts - Design matching plant page
            if (_aiInterestingFacts != null && _aiInterestingFacts!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildInterestingFactsInDetails(_aiInterestingFacts!),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Cleans markdown formatting from AI content for better UI display
  String _cleanMarkdownContent(String content) {
    if (content.isEmpty) return content;
    
    return content
        // Remove markdown headers
        .replaceAll(RegExp(r'^###\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^##\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^#\s*', multiLine: true), '')
        // Remove bold formatting
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        // Remove italic formatting
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        // Remove underline formatting
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')
        // Remove strikethrough
        .replaceAll(RegExp(r'~~(.*?)~~'), r'$1')
        // Remove code formatting
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        // Remove blockquotes
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        // Remove horizontal rules
        .replaceAll(RegExp(r'^---$', multiLine: true), '')
        // Remove list markers
        .replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        // Remove AI artifacts like "$1:" that commonly appear in AI responses
        .replaceAll(RegExp(r'\$1:\s*'), '')
        .replaceAll(RegExp(r'\$\d+:\s*'), '')
        // Remove "$1" artifacts that appear at the beginning of lines
        .replaceAll(RegExp(r'^\$1\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\$\d+\s*', multiLine: true), '')
        // Clean up extra whitespace
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }



  /// Builds a structured care recommendations card from AI tips.
  Widget _buildStructuredCareRecommendations(String content) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Care Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._parseCareContent(content).map((section) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCareSection(section['title']!, section['content']!),
            ),
          ).toList(),
        ],
      ),
    );
  }

  /// Completely removes all markdown formatting from content.
  String _cleanAllMarkdown(String content) {
    return content
        // Remove all header markers
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        // Remove all bold formatting
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        // Remove all italic formatting
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        // Remove all underline formatting
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        // Remove all strikethrough formatting
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'$1')
        // Remove all code formatting
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Remove all blockquote markers
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        // Remove all horizontal rules
        .replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '')
        // Remove all list markers and convert to clean format
        .replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '• ')
        .replaceAll(RegExp(r'^[\s]*\d+\.\s*', multiLine: true), '• ')
        // Remove any remaining asterisks at start/end of lines
        .replaceAll(RegExp(r'^\*\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*\*$', multiLine: true), '')
        // Remove any remaining hash symbols
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        // Clean up multiple spaces and empty lines
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  /// Parses AI content into structured sections with complete markdown removal.
  List<Map<String, String>> _parseCareContent(String content) {
    // First, completely clean all markdown from the content
    final cleanedContent = _cleanAllMarkdown(content);
    
    final List<Map<String, String>> sections = [];
    final lines = cleanedContent.split('\n');
    
    String currentTitle = '';
    List<String> currentContent = [];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip empty lines
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line looks like a section header (starts with capital letter, no bullet points)
      if (_isSectionHeader(trimmedLine)) {
        // Save previous section if exists
        if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
          sections.add({
            'title': currentTitle,
            'content': currentContent.join('\n').trim(),
          });
        }
        
        // Start new section
        currentTitle = trimmedLine;
        currentContent = [];
      } else {
        // Add content line
        currentContent.add(trimmedLine);
      }
    }
    
    // Add last section
    if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
      sections.add({
        'title': currentTitle,
        'content': currentContent.join('\n').trim(),
      });
    }
    
    // If no sections were found, create a default one with cleaned content
    if (sections.isEmpty && cleanedContent.isNotEmpty) {
      sections.add({
        'title': 'Care Instructions',
        'content': cleanedContent,
      });
    }
    
    return sections;
  }

  /// Determines if a line is likely a section header.
  bool _isSectionHeader(String line) {
    // Section headers typically:
    // - Start with a capital letter
    // - Don't start with bullet points
    // - Are relatively short (not long paragraphs)
    // - Don't contain colons (which indicate key-value pairs)
    // - Don't end with punctuation like periods
    
    if (line.isEmpty) return false;
    if (line.startsWith('•')) return false;
    if (line.contains(':')) return false;
    if (line.endsWith('.')) return false;
    if (line.length > 50) return false; // Too long to be a header
    
    // Check if it starts with a capital letter and looks like a title
    return RegExp(r'^[A-Z]').hasMatch(line) && 
           !line.contains('  ') && // No double spaces
           line.split(' ').length <= 5; // Not too many words
  }

  /// Builds a single care section with title and content.
  Widget _buildCareSection(String title, String content) {
    // Override content for Moisture and Light with numeric values
    String displayContent = content;
    if (title.toLowerCase() == 'moisture' && _aiMoistureLevel != null) {
      // Use the same logic as the top card to get consistent moisture percentage
      displayContent = '${_getMoisturePercentage(_aiMoistureLevel)}%';
    } else if (title.toLowerCase() == 'light' && _aiLight != null) {
      // Use calculated light hours instead of descriptive text
      displayContent = '${_calculateLightHours()} hours per day';
    }
    
    // Transform title for display
    String displayTitle = title;
    if (title.toLowerCase().contains('1. plant identification') || title.toLowerCase().contains('plant identification')) {
              displayTitle = 'Plant';
    }
    
    // Split content into lines and clean each line
    final contentLines = displayContent.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForSection(title),
                color: AppTheme.accentGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Section content with proper formatting
        ...contentLines.map((line) {
          // Check if this line contains a key-value pair (like "Type: Rafflesia")
          if (line.contains(':')) {
            final parts = line.split(':');
            if (parts.length == 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              
              // Skip if key is empty or too short
              if (key.length < 2) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    line,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100, // Increased width for longer keys
                      child: Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
          
          // Check if this is a bullet point
          if (line.startsWith('•')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0, left: 16.0),
              child: Text(
                line,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            );
          }
          
          // Regular line content
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              line,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Returns appropriate icon for each care section.

  
  /// Builds interesting facts section matching plant page design
  Widget _buildInterestingFactsInDetails(List<String> facts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Interesting Facts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Display facts with green borders matching plant page
        ...facts.take(4).map((fact) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentGreen.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    _cleanMarkdownContent(fact),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
        slivers: [
          // Header removed - clean interface
          
          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.getContentPadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Plant Name Field
                    _buildInputCard(
                      l10n.plantName,
                      l10n.plantNameHint,
                      Icons.local_florist,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterPlantName;
                        }
                        return null;
                      },
                      iconColor: AppTheme.accentGreen,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Plant Image Section
                    _buildImageUploadCard(),
                    
                    const SizedBox(height: 24),
                    
                    // AI Analysis Results
                    if (_aiGeneralDescription != null) ...[
                      _buildAIResultsCard(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Add Plant Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isAnalyzing || _aiGeneralDescription == null) ? null : _addPlant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_isLoading || _isAnalyzing || _aiGeneralDescription == null) ? Colors.grey.shade400 : AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.addingPlant,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : _isAnalyzing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.analyzingPhoto,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    l10n.addPlant,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// Builds structured care sections from AI care tips
  List<Widget> _buildStructuredCareSections(String content) {
    final sections = <Widget>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line contains a care section (like "Watering: ...")
      if (trimmedLine.contains(':')) {
        final parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          final title = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          
          if (title.isNotEmpty && value.isNotEmpty) {
            // Add top padding only to the first section
            final isFirstSection = sections.isEmpty;
            sections.add(
              Padding(
                padding: EdgeInsets.only(
                  bottom: 16.0,
                  top: isFirstSection ? 16.0 : 0.0,
                ),
                child: _buildCareSection(title, value),
              ),
            );
          }
        }
      }
    }
    
    // If no structured sections found, create a default one
    if (sections.isEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
          child: _buildCareSection('Care Instructions', content),
        ),
      );
    }
    
    return sections;
  }

  /// Gets appropriate icon for care section
  IconData _getIconForSection(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('1. plant identification') || lowerTitle.contains('plant identification')) return Icons.local_florist;
    if (lowerTitle.contains('water')) return Icons.water_drop;
    if (lowerTitle.contains('light')) return Icons.wb_sunny;
    if (lowerTitle.contains('temperature')) return Icons.thermostat;
    if (lowerTitle.contains('soil')) return Icons.eco;
    if (lowerTitle.contains('fertiliz')) return Icons.grass;
    if (lowerTitle.contains('humidity')) return Icons.opacity;
    if (lowerTitle.contains('growth') || lowerTitle.contains('size')) return Icons.trending_up;
    if (lowerTitle.contains('bloom') || lowerTitle.contains('flower')) return Icons.local_florist;
    return Icons.info_outline;
  }
} 