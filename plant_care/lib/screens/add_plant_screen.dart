import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/chatgpt_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
    
    // Show a fun message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Your plant is now called "$randomName"! 🌱',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
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
          content: Text('Error picking image: $e'),
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
      final recommendations = await ChatGPTService.analyzePlantPhoto(base64Image);
      
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
        _aiInterestingFacts = recommendations['interesting_facts'];
        
        // Extract plant size assessment data
        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'];
        
        // Extract plant size assessment data
        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'];
        
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI analysis completed! 🌱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: $e'),
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
            content: Text('❌ API test error: $e'),
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
      final recommendations = await ChatGPTService.analyzePlantPhoto(base64Image);
      
      setState(() {
        _aiGeneralDescription = recommendations['general_description'];
        _aiName = recommendations['name'];
        _aiMoistureLevel = recommendations['moisture_level'];
        _aiLight = recommendations['light'];
        _aiWateringFrequency = recommendations['watering_frequency']?.toString();
        _aiWateringAmount = recommendations['watering_amount'];
        _aiSpecificIssues = recommendations['specific_issues'];
        _aiCareTips = recommendations['care_tips'];
        _aiInterestingFacts = recommendations['interesting_facts'];
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI analysis refreshed! 🔄'),
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
            content: Text('AI analysis refresh failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
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
            'Upload Plant Photo',
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
  
  /// Convert moisture level text to percentage (0-100)
  int _getMoisturePercentage(String? moistureLevel) {
    if (moistureLevel == null) return 50;
    
    try {
      final level = moistureLevel.toLowerCase();
      int percentage;
      
      if (level.contains('low') || level.contains('dry')) {
        percentage = 25;
      } else if (level.contains('moderate') || level.contains('medium')) {
        percentage = 50;
      } else if (level.contains('high') || level.contains('wet') || level.contains('moist')) {
        percentage = 75;
      } else if (level.contains('very high') || level.contains('very wet')) {
        percentage = 90;
      } else {
        percentage = 50; // Default to moderate
      }
      
      // Return full moisture percentage range (0-100)
      return percentage;
    } catch (e) {
      print('Error parsing moisture level: $moistureLevel, error: $e');
      return 50; // Safe fallback
    }
  }
  
  /// Format watering frequency to human-readable text
  String _formatWateringFrequency(String? frequency) {
    if (frequency == null) return 'Once every 7 days';
    
    try {
      final days = int.parse(frequency);
      if (days == 1) return 'Once per day';
      if (days == 2) return 'Once every 2 days';
      if (days == 3) return 'Once every 3 days';
      if (days == 4) return 'Once every 4 days';
      if (days == 5) return 'Once every 5 days';
      if (days == 6) return 'Once every 6 days';
      if (days == 7) return 'Once per week';
      if (days <= 14) return 'Once every $days days';
      if (days <= 30) return 'Once every ${(days / 7).round()} weeks';
      return 'Once every $days days';
    } catch (e) {
      return 'Once every 7 days';
    }
  }
  
  /// Format moisture level to five gradations
  String _formatMoistureLevel(String? moistureLevel) {
    if (moistureLevel == null) return 'Medium';
    
    final level = moistureLevel.toLowerCase();
    if (level.contains('very low') || level.contains('extremely low') || level.contains('dry')) return 'Low';
    if (level.contains('low') || level.contains('slightly low')) return 'Medium-Low';
    if (level.contains('moderate') || level.contains('medium') || level.contains('average')) return 'Medium';
    if (level.contains('high') || level.contains('slightly high') || level.contains('moist')) return 'Medium-High';
    if (level.contains('very high') || level.contains('extremely high') || level.contains('wet') || level.contains('soggy')) return 'High';
    
    return 'Medium'; // Default
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
        throw Exception('User not authenticated');
      }

      // Handle image selection - only use custom uploaded image
      if (_selectedImageBytes == null) {
        throw Exception('Please upload a plant image');
      }
      
      // Require AI analysis before creating plant
      if (_aiGeneralDescription == null || _aiSpecificIssues == null) {
        throw Exception('Please wait for AI analysis to complete before adding the plant');
      }
      
      // Convert bytes to base64 data URL for storage
      final base64String = base64Encode(_selectedImageBytes!);
      final imageUrl = 'data:image/jpeg;base64,$base64String';
      
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
        aiSpecificIssues: _aiSpecificIssues,
        aiCareTips: _aiCareTips,
        interestingFacts: _aiInterestingFacts,
        aiPlantSize: _aiPlantSize,
        aiPotSize: _aiPotSize,
        aiGrowthStage: _aiGrowthStage,
        healthStatus: null, // No health status for new plants
        healthMessage: null, // No health message for new plants
        lastHealthCheck: null, // No health check for new plants
      );

      final plantId = await PlantService().addPlant(plant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant added successfully! 🌱'),
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
            content: Text('Error adding plant: $e'),
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
            if (label == 'Plant Name') ...[
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
                      tooltip: 'Generate random name',
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
                    _aiMoistureLevel ?? 'Not specified',
                    Icons.opacity,
                    AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCareCard(
                    'Light',
                    _aiLight ?? 'Not specified',
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
    // Transform title for display
    String displayTitle = title;
    if (title.toLowerCase().contains('1. plant identification') || title.toLowerCase().contains('plant identification')) {
              displayTitle = 'Plant';
    }
    
    // Split content into lines and clean each line
    final contentLines = content.split('\n')
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
      body: CustomScrollView(
        slivers: [
          // Header removed - clean interface
          
          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Plant Name Field
                    _buildInputCard(
                      'Plant Name',
                      'e.g., Monstera, Snake Plant',
                      Icons.local_florist,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a plant name';
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
                                  const Text(
                                    'Adding Plant...',
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
                                      const Text(
                                        'Analyzing Photo...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Add Plant',
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
        if (parts.length == 2) {
          final title = parts[0].trim();
          final value = parts[1].trim();
          
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