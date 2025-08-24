import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/chatgpt_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
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
      
      setState(() {
        _aiGeneralDescription = recommendations['general_description'];
        _aiName = recommendations['name'];
        _aiMoistureLevel = recommendations['moisture_level'];
        _aiLight = recommendations['light'];
        _aiWateringFrequency = recommendations['watering_frequency']?.toString();
        _aiWateringAmount = recommendations['watering_amount'];
        _aiSpecificIssues = recommendations['specific_issues'];
        _aiCareTips = recommendations['care_tips'];
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
      final isAvailable = await ChatGPTService.isApiAvailable();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable 
                ? '✅ API is working! You have credits available.' 
                : '❌ API test failed. Check console for details.',
            ),
            backgroundColor: isAvailable ? Colors.green : Colors.red,
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
    
    final level = moistureLevel.toLowerCase();
    if (level.contains('low') || level.contains('dry')) return 25;
    if (level.contains('moderate') || level.contains('medium')) return 50;
    if (level.contains('high') || level.contains('wet') || level.contains('moist')) return 75;
    if (level.contains('very high') || level.contains('very wet')) return 90;
    
    return 50; // Default to moderate
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (moisturePercentage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: moisturePercentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Text(
              '$moisturePercentage%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Care Recommendations',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                // Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppTheme.accentGreen.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.accentGreen.withOpacity(0.3),
                      width: 1,
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
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Plant Description
            if (_aiGeneralDescription != null) ...[
              _buildInfoRow('Description', _aiGeneralDescription!),
              const SizedBox(height: 16),
            ],
            
            // Care Details Grid
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
                const SizedBox(width: 12),
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
            
            const SizedBox(height: 16),
            
            // Watering Schedule
            if (_aiWateringFrequency != null) ...[
              _buildInfoRow('Watering Frequency', _formatWateringFrequency(_aiWateringFrequency)),
              const SizedBox(height: 16),
            ],
            
            // Care Tips
            if (_aiCareTips != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentGreen,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiCareTips!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                        fontSize: 16,
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
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
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
                                    : _aiGeneralDescription == null
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.photo_camera,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Upload & Analyze Photo First',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Add Plant',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
} 