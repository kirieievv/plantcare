import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/smart_plant.dart';
import 'package:plant_care/models/user_model.dart';
import 'package:plant_care/screens/main_navigation_screen.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/health_check_service.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/services/cors_proxy_service.dart';
import 'package:plant_care/widgets/health_check_modal.dart';
import 'package:plant_care/widgets/plant_card.dart';
import 'package:plant_care/widgets/health_alert.dart';
import 'package:plant_care/widgets/health_gallery.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailsScreen({super.key, required this.plant});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late Plant _plant;
  late Stream<List<HealthCheckRecord>> _healthCheckStream;
  bool _isLoading = false;
  bool _isDetailsExpanded = true; // Add state for details expansion
  int _currentCarouselPage = 0;
  bool _isGeneratingAI = false; // Add state for AI content generation
  
  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _healthCheckStream = HealthCheckService().getHealthCheckHistory(_plant.id);
    
    // Save navigation state so user returns to this page after reload
    _saveNavigationState();
  }
  
  Future<void> _saveNavigationState() async {
    await NavigationService.savePlantDetailsState(_plant.id);
  }

  void _openHealthCheckModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HealthCheckModal(
        plantId: _plant.id,
        plantName: _plant.name,
        onHealthCheckComplete: _handleHealthCheckComplete,
      ),
    );
  }

  void _handleHealthCheckComplete(Map<String, dynamic> healthResult) async {
    try {
      // Update plant with health check results
      final updatedPlant = _plant.copyWith(
        healthStatus: healthResult['status'],
        healthMessage: healthResult['message'],
        lastHealthCheck: DateTime.now(),
      );

      // Save to database
      await PlantService().updatePlant(updatedPlant);
      
      // Update local state
      setState(() {
        _plant = updatedPlant;
      });

        // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  healthResult['status'] == 'ok' ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                  healthResult['status'] == 'ok' 
                      ? 'Plant Care Assistant has analyzed your plant! 🌱'
                      : 'Plant Care Assistant has some advice for you! 🌿',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    ),
                    // Allow text to wrap to multiple lines if needed
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
            backgroundColor: healthResult['status'] == 'ok' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
            // Ensure SnackBar doesn't overflow on mobile
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating plant with health check: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating plant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.delete_forever,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Plant',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${_plant.name}"? This action cannot be undone and will permanently remove the plant and all its health check history.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePlant();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlant() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Delete the plant
      await PlantService().deletePlant(_plant.id);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Plant "${_plant.name}" has been deleted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back to plant list
        final currentUser = FirebaseAuth.instance.currentUser;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(user: currentUser, initialIndex: 0),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error deleting plant: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting plant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generates AI content for the current plant
  Future<void> _generateAIContent() async {
    try {
      setState(() {
        _isGeneratingAI = true;
      });

      // Generate AI content using the plant service
      await PlantService().generateAIContent(_plant.id);
      
      // Refresh the plant data to get the new AI content
      await _refreshPlantData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI content generated successfully! 🌱',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error generating AI content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating AI content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }

  /// Refreshes the plant data from the database
  Future<void> _refreshPlantData() async {
    try {
      // Get the updated plant data from the database
      final updatedPlant = await PlantService().getPlantById(_plant.id);
      if (updatedPlant != null) {
        // Update the local plant state
        setState(() {
          _plant = updatedPlant;
        });
      }
    } catch (e) {
      print('❌ Error refreshing plant data: $e');
    }
  }

  Future<void> _waterPlant() async {
    try {
      final updatedPlant = _plant.copyWith(
        lastWatered: DateTime.now(),
        nextWatering: DateTime.now().add(Duration(days: _plant.wateringFrequency)),
      );

      await PlantService().updatePlant(updatedPlant);

    setState(() {
        _plant = updatedPlant;
    });
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_plant.name} has been watered! 💧',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Error watering plant: $e',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to see your plant here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds hero image with improved error handling
  Widget _buildHeroImage(String imageUrl) {
    // Validate image URL
    if (imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }
    
    // Try to get a CORS-free URL for web
    final processedUrl = CorsProxyService.getCorsFreeUrl(imageUrl);
    
    return imageUrl.startsWith('data:image')
        ? Image.memory(
            base64Decode(imageUrl.split(',')[1]),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Hero image memory error: $error');
              return _buildPlaceholderImage();
            },
          )
        : imageUrl.startsWith('http')
            ? Image.network(
                processedUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Hero image network error: $error');
                  // Try alternative URL if CORS fails
                  if (CorsProxyService.hasCorsIssues) {
                    return _buildPlaceholderImage();
                  }
                  return _buildPlaceholderImage();
                },
                // Add timeout to prevent hanging
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              )
            : _buildPlaceholderImage();
  }

  /// Formats health check date for display
  String _formatHealthCheckDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Calculate water amount based on plant type and size
  String _calculateWaterAmount() {
    if (_plant.aiName == null) {
      return '1-2 cups'; // Default for unknown plants
    }
    
    final plantName = _plant.aiName!.toLowerCase();
    final species = _plant.species.toLowerCase();
    
    // Large plants that need more water
    if (plantName.contains('monstera') || plantName.contains('fiddle leaf') || 
        plantName.contains('bird of paradise') || plantName.contains('elephant ear')) {
      return '3-4 cups';
    }
    
    // Medium plants with moderate water needs
    if (plantName.contains('calathea') || plantName.contains('prayer plant') ||
        plantName.contains('philodendron') || plantName.contains('pothos') ||
        plantName.contains('snake plant') || plantName.contains('zz plant')) {
      return '2-3 cups';
    }
    
    // Small plants or succulents
    if (plantName.contains('succulent') || plantName.contains('cactus') ||
        plantName.contains('aloe') || plantName.contains('jade')) {
      return '1/2-1 cup';
    }
    
    // Flowering plants
    if (plantName.contains('orchid') || plantName.contains('rose') ||
        plantName.contains('lily') || plantName.contains('daisy')) {
      return '2-3 cups';
    }
    
    // Herbs and small plants
    if (plantName.contains('herb') || plantName.contains('basil') ||
        plantName.contains('mint') || plantName.contains('rosemary')) {
      return '1-2 cups';
    }
    
    // Default based on species if available
    if (species.contains('tree') || species.contains('large')) {
      return '3-4 cups';
    } else if (species.contains('small') || species.contains('mini')) {
      return '1/2-1 cup';
    }
    
    return '2-3 cups'; // Default moderate amount
  }

  /// Get light type description
  String _getLightType() {
    if (_plant.aiLight == null || _plant.aiLight!.isEmpty) {
      return 'Bright indirect';
    }
    
    final lightRequirement = _plant.aiLight!.toLowerCase();
    
    if (lightRequirement.contains('full sun') || lightRequirement.contains('direct sun')) {
      return 'Direct sunlight';
    } else if (lightRequirement.contains('partial sun') || lightRequirement.contains('morning sun')) {
      return 'Partial sun';
    } else if (lightRequirement.contains('partial shade') || lightRequirement.contains('filtered light')) {
      return 'Partial shade';
    } else if (lightRequirement.contains('bright indirect') || lightRequirement.contains('bright light')) {
      return 'Bright indirect';
    } else if (lightRequirement.contains('low light') || lightRequirement.contains('shade')) {
      return 'Low light';
    } else if (lightRequirement.contains('medium light') || lightRequirement.contains('moderate light')) {
      return 'Medium light';
    } else if (lightRequirement.contains('very bright') || lightRequirement.contains('high light')) {
      return 'Very bright';
    }
    
    return 'Bright indirect'; // Default
  }

  // Key Metrics Cards
  Widget _buildNextWateringCard() {
    final daysUntilWatering = _plant.nextWatering.difference(DateTime.now()).inDays;
    final statusColor = daysUntilWatering < 0 ? Colors.red : daysUntilWatering <= 1 ? Colors.orange : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.water_drop,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Watering',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd').format(_plant.nextWatering),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'every ${_plant.wateringFrequency} days',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Water amount section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_dining,
                color: Colors.blue.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _calculateWaterAmount(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculate light hours per day based on AI light requirements
  String _calculateLightHours() {
    if (_plant.aiLight == null || _plant.aiLight!.isEmpty) {
      return 'Not specified';
    }
    
    final lightRequirement = _plant.aiLight!.toLowerCase();
    
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
    final species = _plant.aiName?.toLowerCase() ?? _plant.species.toLowerCase();
    
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

  Widget _buildLightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.wb_sunny,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Light',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_calculateLightHours()} hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'per day',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Light type section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              _getLightType(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureCard() {
    final moisturePercentage = _getMoisturePercentage(_plant.aiMoistureLevel);
    final moistureLevel = _formatMoistureLevel(_plant.aiMoistureLevel);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
      child: Column(
                                children: [
          Icon(
            Icons.opacity,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Moisture',
                                      style: TextStyle(
              fontSize: 12,
                                        fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
                                Text(
            '$moisturePercentage%',
                                  style: TextStyle(
                                    fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            moistureLevel,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
            height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
              widthFactor: (moisturePercentage / 100).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
          
          // Action Buttons
                        Row(
                          children: [
                            Expanded(
                child: ElevatedButton(
                  onPressed: _waterPlant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'I have watered',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
                            Expanded(
                child: ElevatedButton(
                  onPressed: _openHealthCheckModal,
                              style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        size: 14,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                    'Check plant',
                                style: TextStyle(
                      fontSize: 11,
                                  fontWeight: FontWeight.w600,
                    ),
                      ),
                    ],
                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
    );
  }

  // AI Care Card
  Widget _buildAiCareCard() {
    if (_plant.healthMessage == null) return const SizedBox.shrink();
    
    // Use the actual health status from the health check, not text parsing
    // This is the correct way to determine if the plant needs help
    final isBadAdvice = _plant.healthStatus?.toLowerCase() == 'issue' ||
                       _plant.healthStatus?.toLowerCase() == 'critical' ||
                       _plant.healthStatus?.toLowerCase() == 'needs attention';
    
    // Debug logging to verify the logic
    print('🌱 Plant Details: AI Care Card Logic:');
    print('🌱 Plant healthStatus: ${_plant.healthStatus}');
    print('🌱 Plant healthMessage length: ${_plant.healthMessage?.length}');
    print('🌱 isBadAdvice calculated: $isBadAdvice');
    print('🌱 Will show: ${isBadAdvice ? "Plant Needs Help!" : "Plant Care Assistant"}');
    
    return Container(
      width: double.infinity, // Full width for mobile
      margin: const EdgeInsets.symmetric(horizontal: 4), // Small margin to prevent edge overflow
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBadAdvice ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBadAdvice ? Colors.red.shade200 : Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Fixed layout to prevent overflow
          Row(
            children: [
              Icon(
                isBadAdvice ? Icons.warning : Icons.eco,
                color: isBadAdvice ? Colors.red.shade600 : Colors.green.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBadAdvice ? 'Plant Needs Help!' : 'Plant Care Assistant',
                style: TextStyle(
                    fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isBadAdvice ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  // Allow text to wrap to 2 lines if needed
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Content based on health status
          if (isBadAdvice) ...[
            // For unhealthy plants: Show full health message with care recommendations
            Container(
              width: double.infinity,
              child: Text(
                _plant.healthMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade800,
                  height: 1.4,
                ),
                maxLines: null,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.left,
              ),
            ),
          ] else ...[
            // For healthy plants: Show only essential information
            _buildHealthyPlantSummary(),
          ],
          
          // Add helpful tips for bad advice - more compact
          if (isBadAdvice) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.red.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                        'Quick Help Tips',
                        style: TextStyle(
                            fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    child: Text(
                    '• Check soil moisture - may need immediate watering\n'
                    '• Move to appropriate lighting conditions\n'
                    '• Remove any dead or yellowing leaves\n'
                    '• Take a new health check photo to track progress\n'
                    '• Consider repotting if roots are visible',
                    style: TextStyle(
                        fontSize: 10,
                      color: Colors.red.shade800,
                      height: 1.3,
                      ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 10),
          if (_plant.lastHealthCheck != null)
            Container(
              width: double.infinity,
              child: Text(
            'Last checked: ${DateFormat('MMM dd, h:mm a').format(_plant.lastHealthCheck!)}',
            style: TextStyle(
                  fontSize: 10,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Care Section Cards
  Widget _buildIssuesCard() {
    final issues = _plant.aiSpecificIssues;
    if (issues == null || issues == 'None detected') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.yellow.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Issues',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issues,
            style: TextStyle(
              fontSize: 13,
              color: Colors.yellow.shade800,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipsCard() {
    final tips = _plant.aiCareTips;
    if (tips == null || tips == 'No specific tips') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        children: [
          Icon(
                Icons.lightbulb,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
          Text(
                'Care Tips',
            style: TextStyle(
              fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
            Text(
            tips,
              style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    }
  
  // Healthy Plant Summary - Shows only essential info for healthy plants
  Widget _buildHealthyPlantSummary() {
    // Extract plant name and species from health message
    String plantName = 'Plant';
    String species = 'Species';
    
    if (_plant.healthMessage != null) {
      final lines = _plant.healthMessage!.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.toLowerCase().startsWith('plant name:')) {
          final parts = trimmedLine.split(':');
          if (parts.length >= 2) {
            plantName = parts[1].trim();
          }
        } else if (trimmedLine.toLowerCase().startsWith('species:')) {
          final parts = trimmedLine.split(':');
          if (parts.length >= 2) {
            species = parts[1].trim();
          }
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plant Name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            'Plant Name: $plantName',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Species
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            'Species: $species',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Health Assessment (friendly message)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            'Health Assessment: Your plant is looking great! Keep doing so good! 🌱✨',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }
  
  // Care Recommendations Accordion
  Widget _buildDetailsAccordion() {
    // Show details for all plants, even new ones without AI data
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen, width: 1),
      ),
      child: StreamBuilder<List<HealthCheckRecord>>(
        stream: _healthCheckStream,
        builder: (context, snapshot) {
          // Check if there are any health checks
          final hasHealthChecks = snapshot.hasData && 
              snapshot.data != null && 
              snapshot.data!.isNotEmpty;
          
          return Column(
          children: [
              // Custom header with better arrow control
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDetailsExpanded = !_isDetailsExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Increased padding
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.05), // Added subtle background
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Increased padding
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15), // Enhanced background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
              Icons.lightbulb_outline,
              color: AppTheme.accentGreen,
                          size: 18, // Increased size
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
              'Care Recommendations',
              style: TextStyle(
                            fontSize: 19, // Increased size
                            fontWeight: FontWeight.w800, // Made bolder
                color: AppTheme.accentGreen,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Icon(
                        _isDetailsExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.accentGreen,
                        size: 22, // Increased size
            ),
          ],
        ),
                ),
              ),
              
              // Content area
              if (_isDetailsExpanded) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // Species and Description are now shown in Care Recommendations section
                      
                      // Unified Care Recommendations content without inner border
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Care recommendations from GPT with structured sections (includes Description content)
                      if (_plant.aiCareTips != null && _plant.aiCareTips!.isNotEmpty && _plant.aiCareTips != 'No specific tips') ...[
                            // Display structured care sections from GPT directly
                            ..._buildStructuredCareSections(_plant.aiCareTips!),
                            const SizedBox(height: 16),
                          ] else ...[
                            // Show button to generate AI content if not available
                            Text(
                              'AI-generated care recommendations are not available for this plant yet.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isGeneratingAI ? null : _generateAIContent,
                                icon: _isGeneratingAI 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                      ),
                                    )
                                  : Icon(Icons.auto_awesome, color: Colors.white),
                                label: Text(
                                  _isGeneratingAI ? 'Generating...' : 'Generate AI Recommendations',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal:20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Interesting Facts section (4 facts: 3 interesting + 1 funny)
                          _buildInterestingFactsInDetails(),
                        ],
                      ),
              ],
            ),
          ),
        ],
            ],
          );
        },
      ),
    );
  }

  /// Build interesting facts section with stored facts from Plant model
  Widget _buildInterestingFacts() {
    // Use stored interesting facts from the plant model
    final facts = _plant.interestingFacts;
    
    if (facts == null || facts.isEmpty) {
      // Show button to generate AI content if facts are not available
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentGreen.withOpacity(0.3),
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
            Text(
              'AI-generated interesting facts are not available for this plant yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingAI ? null : _generateAIContent,
                icon: _isGeneratingAI 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                      ),
                    )
                  : Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGeneratingAI ? 'Generating...' : 'Generate AI Facts',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Display the same information as Description block (as requested by user)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.3),
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
          
          // Show the same content as Description block
          if (_plant.aiGeneralDescription != null && _plant.aiGeneralDescription!.isNotEmpty) ...[
                  Text(
              _cleanMarkdownContent(_plant.aiGeneralDescription!),
                    style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'No description available yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                    ),
                  ),
                ],
        ],
      ),
    );
  }
  


  Widget _buildDetailRow(String label, String value) {
    // Clean markdown formatting for AI-generated content
    String cleanedValue = value;
    if (label == 'Description' || label == 'AI Identified') {
      cleanedValue = _cleanMarkdownContent(value);
    }
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700, // Made bold
            color: AppTheme.accentGreen, // Changed to green for better hierarchy
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6), // Increased spacing
        Text(
          cleanedValue,
            style: TextStyle(
            fontSize: 14,
              color: Colors.grey.shade800,
            height: 1.5, // Increased line height for better readability
          ),
        ),
        const SizedBox(height: 12), // Reduced spacing between sections from 20 to 12
      ],
  );
}

  /// Builds an info row for the Care Recommendations section
  Widget _buildInfoRow(String label, String value) {
    // Clean markdown formatting for AI-generated content
    String cleanedValue = value;
    if (label == 'Description') {
      cleanedValue = _cleanMarkdownContent(value);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.accentGreen,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cleanedValue,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Builds interesting facts section within the Details block
  Widget _buildInterestingFactsInDetails() {
    final facts = _plant.interestingFacts;
    
    if (facts == null || facts.isEmpty) {
      // Show button to generate AI content if facts are not available
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
          Text(
            'AI-generated interesting facts are not available for this plant yet.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingAI ? null : _generateAIContent,
              icon: _isGeneratingAI 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                    ),
                  )
                : Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _isGeneratingAI ? 'Generating...' : 'Generate AI Facts',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Display 4 interesting facts (3 interesting + 1 funny)
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
        
        // Display facts with green borders
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
  
  /// Clean markdown formatting from AI-generated content
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
        .replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '')
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

  // Health History Gallery
  Widget _buildHealthHistoryGallery() {
  return Container(
      width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
              Icon(
                Icons.history,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Health Check History',
                style: TextStyle(
                    fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            GestureDetector(
                onTap: _openHealthCheckModal,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<HealthCheckRecord>>(
          stream: _healthCheckStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              print('❌ Error loading health check history: ${snapshot.error}');
              return Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading history: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              );
            }
            
            final healthChecks = snapshot.data ?? [];
            print('🌱 PlantDetailsScreen: Loaded ${healthChecks.length} health checks for plant: ${_plant.name}');
            
            if (healthChecks.isEmpty) {
              return _buildEmptyHealthHistory();
            }
            
            // Validate health check records before rendering
            final validHealthChecks = healthChecks.where((record) => 
              record != null && 
              record.id.isNotEmpty && 
              record.status.isNotEmpty
            ).toList();
            
            print('🌱 PlantDetailsScreen: Valid health checks: ${validHealthChecks.length}');
            
            // Debug each health check record
            for (int i = 0; i < validHealthChecks.length; i++) {
              final record = validHealthChecks[i];
              print('🌱 PlantDetailsScreen: Health check $i: ID=${record.id}, Status=${record.status}, ImageURL=${record.imageUrl?.isNotEmpty == true ? "Present" : "Missing"}, Timestamp=${record.timestamp}');
            }
            
            if (validHealthChecks.isEmpty) {
              return _buildEmptyHealthHistory();
            }
            
            return Column(
              children: [
                _buildHealthHistoryList(validHealthChecks),
                // Scroll indicator
                if (validHealthChecks.length > 3) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_left,
                        size: 16,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe to see more',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildEmptyHealthHistory() {
  return Container(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No health checks yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
            'Upload photos to track your plant\'s health',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

  Widget _buildHealthHistoryList(List<HealthCheckRecord> healthChecks) {
    // Validate health checks before processing
    if (healthChecks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final validHealthChecks = healthChecks.where((record) => 
      record != null && 
      record.id.isNotEmpty && 
      record.status.isNotEmpty
    ).toList();
    
    if (validHealthChecks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort by timestamp, most recent first
    final sortedHistory = List<HealthCheckRecord>.from(validHealthChecks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Limit to prevent overwhelming the UI
    final displayHistory = sortedHistory.take(10).toList();
  
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayHistory.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final record = displayHistory[index];
          if (record == null) {
            return const SizedBox.shrink();
          }
          
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < displayHistory.length - 1 ? 12 : 0),
            child: _buildHealthHistoryThumbnail(record),
          );
        },
      ),
    );
  }

  Widget _buildHealthHistoryThumbnail(HealthCheckRecord record) {
    // Add null safety check for record
    if (record == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.status == 'ok' ? Colors.green.shade200 : Colors.red.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: record.status == 'ok' ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  record.status == 'ok' ? Icons.check : Icons.warning,
                  color: record.status == 'ok' ? Colors.green.shade600 : Colors.red.shade600,
                  size: 12,
                ),
                const SizedBox(width: 2),
                                  Text(
                    record.status == 'ok' ? 'OK' : 'Issue',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: record.status == 'ok' ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // Image - Improved error handling and fallback
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 60,
                maxHeight: 80,
              ),
              child: record.imageUrl != null && record.imageUrl!.isNotEmpty
                  ? _buildHealthCheckImage(record.imageUrl!)
                  : _buildHealthCheckImagePlaceholder(),
            ),
          ),

          // Date
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _formatHealthCheckDate(record.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds health check image with improved error handling
  Widget _buildHealthCheckImage(String imageUrl) {
    // Validate image URL
    if (imageUrl.isEmpty) {
      return _buildHealthCheckImagePlaceholder();
    }
    
    // Try to get a CORS-free URL for web
    final processedUrl = CorsProxyService.getCorsFreeUrl(imageUrl);
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: imageUrl.startsWith('data:image')
          ? Image.memory(
              base64Decode(imageUrl.split(',')[1]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Health check image memory error: $error');
                return _buildHealthCheckImagePlaceholder();
              },
            )
          : Image.network(
              processedUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Health check image network error: $error');
                // Try alternative URL if CORS fails
                if (CorsProxyService.hasCorsIssues) {
                  return _buildHealthCheckImagePlaceholderWithRetry(imageUrl);
                }
                return _buildHealthCheckImagePlaceholder();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.blue.shade400,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              },
              // Add timeout to prevent hanging
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),
    );
  }

  /// Builds health check image placeholder
  Widget _buildHealthCheckImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }

  /// Builds health check image placeholder with retry button for web
  Widget _buildHealthCheckImagePlaceholderWithRetry(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image,
            size: 16,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 2),
          Text(
            'CORS',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Convert moisture level text to percentage (0-100) - consistent with AI recommendations
  int _getMoisturePercentage(String? moistureLevel) {
    if (moistureLevel == null) return 50;
    
    try {
      final lowerLevel = moistureLevel.toLowerCase();
      int percentage;
      
      if (lowerLevel.contains('very low') || lowerLevel.contains('extremely low')) {
        percentage = 10;
      } else if (lowerLevel.contains('low') || lowerLevel.contains('dry')) {
        percentage = 25;
      } else if (lowerLevel.contains('medium') || lowerLevel.contains('moderate')) {
        percentage = 50;
      } else if (lowerLevel.contains('high') || lowerLevel.contains('moist')) {
        percentage = 75;
      } else if (lowerLevel.contains('very high') || lowerLevel.contains('extremely high')) {
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
  
  /// Format moisture level to match AI recommendations format
  String _formatMoistureLevel(String? moistureLevel) {
    if (moistureLevel == null) return 'Medium';
    
    final lowerLevel = moistureLevel.toLowerCase();
    if (lowerLevel.contains('very low') || lowerLevel.contains('extremely low')) return 'Very Low';
    if (lowerLevel.contains('low') || lowerLevel.contains('dry')) return 'Low';
    if (lowerLevel.contains('medium') || lowerLevel.contains('moderate')) return 'Medium';
    if (lowerLevel.contains('high') || lowerLevel.contains('moist')) return 'High';
    if (lowerLevel.contains('very high') || lowerLevel.contains('extremely high')) return 'Very High';
    
    return 'Medium'; // Default
  }

  /// Helper method to check if text contains problem indicators
  bool _hasProblemsInText(String text) {
    print('🌱 _hasProblemsInText checking: "$text"');
    
    // First, check for clear positive health indicators
    // If the AI explicitly says the plant is healthy, trust that assessment
    if (text.contains('healthy') || 
        text.contains('thriving') || 
        text.contains('robust') ||
        text.contains('good condition') ||
        text.contains('no problems') ||
        text.contains('no issues') ||
        text.contains('appears healthy') ||
        text.contains('looks good') ||
        text.contains('doing well') ||
        text.contains('in good shape') ||
        text.contains('beautiful') ||
        text.contains('stunning') ||
        text.contains('great condition')) {
      print('🌱 _hasProblemsInText: Found positive indicators - returning FALSE (no problems)');
      return false;
    }
    
    // Only check for problems if no positive indicators were found
    // Check for specific problem indicators (these are more reliable)
    final hasProblems = text.contains('critical') || 
           text.contains('dying') || 
           text.contains('urgent') || 
           text.contains('emergency') || 
           text.contains('severe') || 
           text.contains('serious problem') ||
           text.contains('immediate attention') ||
           text.contains('declining') ||
           text.contains('unhealthy') ||
           text.contains('yellow') ||
           text.contains('brown') ||
           text.contains('wilting') ||
           text.contains('drooping') ||
           text.contains('overwatered') ||
           text.contains('underwatered') ||
           text.contains('root rot') ||
           text.contains('pest') ||
           text.contains('disease') ||
           text.contains('stress') ||
           text.contains('problem') ||
           text.contains('issue') ||
           _plant.healthStatus?.toLowerCase() == 'critical' ||
           _plant.healthStatus?.toLowerCase() == 'needs attention';
    
    print('🌱 _hasProblemsInText result: $hasProblems');
    return hasProblems;
  }

  /// Gets the unified health status based on the plant's health data
  /// This is the single source of truth for all health status displays
  String _getUnifiedHealthStatus() {
    print('🌱 Plant Details: Determining unified health status...');
    print('🌱 Plant healthStatus: ${_plant.healthStatus}');
    print('🌱 Plant healthMessage: ${_plant.healthMessage != null ? (_plant.healthMessage!.length > 100 ? _plant.healthMessage!.substring(0, 100) + "..." : _plant.healthMessage!) : "null"}');
    
    // PRIORITY 1: Use the plant's stored health status (from health checks)
    if (_plant.healthStatus != null && _plant.healthStatus!.isNotEmpty) {
      print('🌱 Using plant healthStatus: ${_plant.healthStatus}');
      
      if (_plant.healthStatus == 'issue') {
        print('🌱 Status: ISSUE (from healthStatus)');
        return 'Issue';
      } else if (_plant.healthStatus == 'ok') {
        print('🌱 Status: HEALTHY (from healthStatus)');
        return 'Healthy';
      }
    }
    
    // PRIORITY 2: Analyze health message if available
    if (_plant.healthMessage != null && _plant.healthMessage!.isNotEmpty) {
      print('🌱 Analyzing healthMessage for status...');
      
    final message = _plant.healthMessage!.toLowerCase();
      
      // Check for problem indicators
      final problemIndicators = [
        'wilted', 'drooping', 'yellow', 'brown', 'dry', 'distress',
        'unhealthy', 'dying', 'dead', 'critical', 'urgent', 'emergency',
        'severe', 'serious', 'turning yellow', 'brown spots',
        'not in the best health', 'needs help', 'poor health',
        'struggling', 'stress', 'fallen petals', 'drooping quite a bit',
        'not in the best health right now', 'problem', 'issue',
        'concern', 'damaged', 'sick', 'declining', 'overwatered',
        'underwatered', 'root rot', 'pest', 'disease'
      ];
      
      // Check if ANY problem indicator is present
      for (final indicator in problemIndicators) {
        if (message.contains(indicator)) {
          print('🌱 Found problem indicator: "$indicator"');
          print('🌱 Status: ISSUE (from healthMessage analysis)');
          return 'Issue';
        }
      }
      
      // Check for negative health statements
      final negativeStatements = [
        'not healthy', 'not thriving', 'not doing well',
        'not in good condition', 'not in good shape',
        'has problems', 'has issues', 'needs attention',
        'requires care', 'needs help', 'struggling'
      ];
      
      for (final statement in negativeStatements) {
        if (message.contains(statement)) {
          print('🌱 Found negative statement: "$statement"');
          print('🌱 Status: ISSUE (from healthMessage analysis)');
          return 'Issue';
        }
      }
      
      // Check for positive health indicators
      final positiveIndicators = [
        'healthy', 'thriving', 'robust', 'good condition',
        'no problems', 'no issues', 'appears healthy',
        'looks good', 'doing well', 'in good shape',
        'beautiful', 'stunning', 'great condition',
        'flourishing', 'lush', 'vibrant'
      ];
      
      for (final indicator in positiveIndicators) {
        if (message.contains(indicator)) {
          print('🌱 Found positive indicator: "$indicator"');
          print('🌱 Status: HEALTHY (from healthMessage analysis)');
          return 'Healthy';
        }
      }
    }
    
    // PRIORITY 3: Default for new plants or unclear status
    print('🌱 Status: NO STATUS (no health data available)');
    return 'No Status';
  }

  /// Gets the unified health status color based on the unified status
  Color _getUnifiedHealthStatusColor() {
    final status = _getUnifiedHealthStatus();
    
    switch (status) {
      case 'Issue':
        return Colors.red.shade600;
      case 'Healthy':
        return AppTheme.accentGreen;
      case 'No Status':
      default:
        return Colors.transparent;
    }
  }

  /// Gets the unified health status icon based on the unified status
  IconData _getUnifiedHealthStatusIcon() {
    final status = _getUnifiedHealthStatus();
    
    switch (status) {
      case 'Issue':
        return Icons.warning;
      case 'Healthy':
        return Icons.check_circle;
      case 'No Status':
      default:
        return Icons.info;
    }
  }

  /// Gets the unified health status text for health check history
  String _getHealthCheckHistoryStatus() {
    final status = _getUnifiedHealthStatus();
    
    switch (status) {
      case 'Issue':
        return 'Issue';
      case 'Healthy':
      return 'Healthy';
      case 'No Status':
      default:
        return 'No Status';
    }
  }

  Widget _buildHeroCarousel(List<HealthCheckRecord> healthChecks, {bool isLoading = false, bool hasError = false}) {
    // Prepare photos list: Health Check photos first, then default plant photo
    final List<Map<String, dynamic>> photos = [];
    
    // Add Health Check photos (most recent first)
    final sortedHealthChecks = List<HealthCheckRecord>.from(healthChecks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    for (final record in sortedHealthChecks) {
      if (record.imageUrl != null) {
        photos.add({
          'url': record.imageUrl!,
          'type': 'health_check',
          'record': record,
        });
      }
    }
    
    // Add default plant photo if it exists and no health check photos
    if (photos.isEmpty && _plant.imageUrl != null) {
      photos.add({
        'url': _plant.imageUrl!,
        'type': 'default',
        'record': null,
      });
    }
    
    // If no photos at all, show placeholder
    if (photos.isEmpty) {
      return _buildHeroPlaceholder();
    }
    
    return _HeroCarouselWidget(
      photos: photos,
      plantName: _plant.name,
      plantStatus: _plant.healthStatus!,
      onPageChanged: (currentPage) {
        setState(() {
          // Update the current page state
          _currentCarouselPage = currentPage;
        });
      },
    );
  }

  Widget _buildHeroPlaceholder() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: _getHeroImageHeight(context), // Use orientation-aware height
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: _plant.imageUrl != null && _plant.imageUrl!.startsWith('data:image')
              ? Image.memory(
                  base64Decode(_plant.imageUrl!.split(',')[1]),
                  fit: BoxFit.contain, // Better for vertical photos
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
              : _plant.imageUrl != null && _plant.imageUrl!.startsWith('http')
                  ? Image.network(
                      _plant.imageUrl!,
                      fit: BoxFit.contain, // Better for vertical photos
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
          ),
        ),
        
        // Back Button
        Positioned(
          top: 48,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                // Navigate to Home page (Dashboard) instead of going back
                final currentUser = FirebaseAuth.instance.currentUser;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => MainNavigationScreen(user: currentUser),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ),
        
        // Bottom Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plant.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getUnifiedHealthStatusColor().withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        _getUnifiedHealthStatusIcon(),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    Text(
                        _getUnifiedHealthStatus(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final screenSize = MediaQuery.of(context).size;
      print('🌱 PlantDetailsScreen: Building screen for plant: ${_plant.name}');
      print('🌱 PlantDetailsScreen: Plant ID: ${_plant.id}');
      print('🌱 PlantDetailsScreen: Plant species: ${_plant.species}');
      print('🌱 PlantDetailsScreen: Screen size: ${screenSize.width}x${screenSize.height}');
      print('🌱 PlantDetailsScreen: Is portrait: ${screenSize.height > screenSize.width}');
      
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // Allow content to extend behind system UI
      body: CustomScrollView(
        slivers: [
          // Hero Photo Section - Full width and to the top in portrait orientation
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Hero Image Section - Full width and height
                StreamBuilder<List<HealthCheckRecord>>(
                  stream: _healthCheckStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('❌ Error loading hero photos: ${snapshot.error}');
                      return _buildHeroPlaceholder();
                    }
                    
                    // Prepare photos list: Health Check photos first, then default plant photo
                    final List<Map<String, dynamic>> photos = [];
                    
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      // Add Health Check photos (most recent first)
                      final sortedHealthChecks = List<HealthCheckRecord>.from(snapshot.data!)
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      
                      print('🌱 PlantDetailsScreen: Processing ${sortedHealthChecks.length} health check photos');
                      
                      for (int i = 0; i < sortedHealthChecks.length; i++) {
                        final record = sortedHealthChecks[i];
                        if (record.imageUrl != null && record.imageUrl!.isNotEmpty) {
                          print('🌱 PlantDetailsScreen: Adding health check photo $i: URL=${record.imageUrl!.substring(0, record.imageUrl!.length > 50 ? 50 : record.imageUrl!.length)}...');
                          photos.add({
                            'url': record.imageUrl!,
                            'type': 'health_check',
                            'record': record,
                            'timestamp': record.timestamp,
                          });
                        } else {
                          print('🌱 PlantDetailsScreen: Skipping health check photo $i: No image URL');
                        }
                      }
                    }
                    
                    // Add default plant photo if it exists (first created plant photo)
                    if (_plant.imageUrl != null && _plant.imageUrl!.isNotEmpty) {
                      print('🌱 PlantDetailsScreen: Adding default plant photo: URL=${_plant.imageUrl!.substring(0, _plant.imageUrl!.length > 50 ? 50 : _plant.imageUrl!.length)}...');
                      photos.add({
                        'url': _plant.imageUrl!,
                        'type': 'default',
                        'record': null,
                        'timestamp': _plant.createdAt,
                      });
                    } else {
                      print('🌱 PlantDetailsScreen: No default plant photo available');
                    }
                    
                    print('🌱 PlantDetailsScreen: Total photos prepared: ${photos.length}');
                    
                    if (photos.isNotEmpty) {
                      // Convert photos to list of URLs for the new carousel
                      final List<String> imageUrls = photos.map((photo) => photo['url'] as String).toList();
                      
                      return PlantCarouselHeader(
                        images: imageUrls,
                        onBackPressed: () {
                          // Navigate to Home page (Dashboard) instead of going back
                          final currentUser = FirebaseAuth.instance.currentUser;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => MainNavigationScreen(user: currentUser, initialIndex: 0),
                            ),
                            (route) => false,
                          );
                        },
                      );
                    }
                    
                    // Fallback to default plant photo
                    return Container(
                      margin: const EdgeInsets.only(bottom: 52), // Match the 52px total spacing from other scenarios
                      child: _buildHeroPlaceholder(),
                    );
                  },
                ),
                

              ],
            ),
          ),
                  
                  // Key Metrics - 3 cards in a row (responsive) - REMOVED: Now integrated into unified block above image
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), // Removed top padding since spacing is now consistent above
                  //     child: LayoutBuilder(
                  //       builder: (context, constraints) {
                  //         // Responsive layout: stack on narrow screens
                  //         if (constraints.maxWidth < 600) {
                  //           return Column(
                  //             children: [
                  //               // First row: 2 cards
                  //               Row(
                  //                 children: [
                  //                   Expanded(child: _buildNextWateringCard()),
                  //               //     const SizedBox(width: 16),
                  //               //     Expanded(child: _buildLightCard()),
                  //               //   ],
                  //               // ),
                  //               // const SizedBox(height: 16),
                  //               // Second row: 1 card
                  //               _buildMoistureCard(),
                  //             ],
                  //           );
                  //         } else {
                  //           // Wide screen: 3 cards in a row
                  //           return Row(
                  //             children: [
                  //               Expanded(child: _buildNextWateringCard()),
                  //               const SizedBox(width: 16),
                  //               Expanded(child: _buildLightCard()),
                  //               const SizedBox(width: 16),
                  //               Expanded(child: _buildMoistureCard()),
                  //             ],
                  //           );
                  //         }
                  //       },
                  //     ),
                  //   ),
                  // ),
          
          // Unified Information Block - Plant name, health, and care info (NOW ABOVE THE IMAGE)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: _buildUnifiedInformationBlock(),
            ),
          ),
          
          // AI Care Assistant (green card) - More compact for mobile
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // Reduced bottom padding
              child: _buildAiCareCard(),
            ),
          ),
          
          // Care Section (Issues and Tips)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // Reduced bottom padding
              child: _buildDetailsAccordion(),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // Reduced bottom padding
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 500) {
                    // Stack vertically on narrow screens
                    return Column(
                      children: [
                        _buildIssuesCard(),
                        const SizedBox(height: 16),
                        _buildTipsCard(),
                      ],
                    );
                  } else {
                    // Side by side on wider screens
                    return Row(
                      children: [
                        Expanded(child: _buildIssuesCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTipsCard()),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          
          // Health Check History (horizontal gallery)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // Reduced bottom padding
              child: _buildHealthHistoryGallery(),
            ),
          ),
          
          // Delete Plant Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Center(
                child: SizedBox(
                  width: 80, // Further reduced to prevent overflow
                  height: 32, // Further reduced to prevent overflow
                  child: ElevatedButton(
                    onPressed: () => _showDeleteConfirmation(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600.withOpacity(0.6), // More transparent
                      foregroundColor: Colors.white.withOpacity(0.8), // More transparent text
                      elevation: 0, // No elevation for subtlety
                      padding: EdgeInsets.zero, // Remove default padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Adjusted for smaller size
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Ensure row doesn't expand
                      children: [
                        Icon(
                          Icons.delete_forever,
                          size: 14, // Further reduced icon size
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 3), // Minimal spacing
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11, // Further reduced font size
                            fontWeight: FontWeight.w400, // Lighter weight
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom padding - Increased for better mobile experience
          const SliverToBoxAdapter(
            child: SizedBox(height: 32), // Increased from 24 to 32
          ),
        ],
      ),
    );
    } catch (e) {
      print('❌ Error building PlantDetailsScreen: $e');
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('An error occurred while building the PlantDetailsScreen: $e'),
        ),
      );
    }
  }

  /// Check if device is in portrait orientation
  bool _isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Get hero image height based on orientation
  /// ⚠️ IMPORTANT: This method ensures the hero image is full width and to the top in portrait mode
  /// 
  /// Portrait mode: 60% of screen height for immersive experience
  /// Landscape mode: Fixed 400px height to maintain usability
  /// 
  /// This provides the optimal user experience for both orientations
  double _getHeroImageHeight(BuildContext context) {
    if (_isPortrait(context)) {
      return MediaQuery.of(context).size.height * 0.6; // 60% of screen height in portrait
    } else {
      return 400; // Fixed height in landscape
    }
  }

  // Unified Information Block - Plant name, health, and care info
  // Now positioned below the image as a separate section
  Widget _buildUnifiedInformationBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Name and Health Status Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Name
                    Text(
                      _plant.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Health Status - Only show if there's a health check
                    if (_plant.healthMessage != null && _plant.healthMessage!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getUnifiedHealthStatusColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getUnifiedHealthStatusIcon(),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getUnifiedHealthStatus(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Note: Page indicators are shown in the hero image section above
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Care Information Grid
          Row(
            children: [
              // Next Watering Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Watering',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd').format(_plant.nextWatering),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'every ${_plant.wateringFrequency} days',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Light Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Light',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateLightHours()} hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'per day',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Moisture Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.opacity,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Moisture',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getMoisturePercentage(_plant.aiMoistureLevel)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoistureLevel(_plant.aiMoistureLevel),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons Row
          Row(
            children: [
              // "I have watered" Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _waterPlant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: Icon(
                    Icons.water_drop,
                    size: 18,
                  ),
                  label: Text(
                    'I have watered',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // "Check plant" Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _openHealthCheckModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    elevation: 1,
                  ),
                  icon: Icon(
                    Icons.health_and_safety,
                    size: 18,
                  ),
                  label: Text(
                    'Check plant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build structured care recommendations with bold titles
  Widget _buildStructuredCareRecommendations(String aiCareTips) {
    // Clean the markdown first
    final cleanedTips = _cleanMarkdownContent(aiCareTips);
    
    // Parse the content into structured sections
    final sections = _parseCareContent(cleanedTips);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display each section (removed the main title)
        ...sections.map((section) => _buildCareSection(section['title']!, section['content']!)).toList(),
      ],
    );
  }
  
  /// Parse care content into structured sections
  List<Map<String, String>> _parseCareContent(String content) {
    final lines = content.split('\n');
    final sections = <Map<String, String>>[];
    String currentTitle = '';
    String currentContent = '';
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line is a section header (ends with colon and is relatively short)
      if (trimmedLine.endsWith(':') && trimmedLine.length < 50 && _isSectionHeader(trimmedLine)) {
        // Save previous section if exists
        if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
          sections.add({
            'title': currentTitle,
            'content': currentContent.trim(),
          });
        }
        
        // Start new section
        currentTitle = trimmedLine.substring(0, trimmedLine.length - 1); // Remove the colon
        currentContent = '';
      } else {
        // Add to current content
        if (currentContent.isNotEmpty) {
          currentContent += '\n';
        }
        currentContent += trimmedLine;
      }
    }
    
    // Add the last section
    if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
      sections.add({
        'title': currentTitle,
        'content': currentContent.trim(),
      });
    }
    
    return sections;
  }
  
  /// Check if a line is likely a section header
  bool _isSectionHeader(String line) {
    // Should start with capital letter, not be too long, and end with colon
    return line.isNotEmpty && 
           line[0] == line[0].toUpperCase() && 
           line.length < 50 && 
           line.endsWith(':') &&
           !line.contains('•') &&
           !line.contains('-') &&
           !line.contains('*');
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
    
    // If no structured sections found, return empty list (no fallback)
    
    return sections;
  }

  /// Builds a single care section with title and content
  Widget _buildCareSection(String title, String content) {
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
            title,
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
          // Section content
          Text(
            content,
            style: TextStyle(
            color: AppTheme.textSecondary,
              height: 1.4,
            fontSize: 14,
            ),
          ),
        ],
    );
  }

  /// Gets appropriate icon for care section
  IconData _getIconForSection(String title) {
    final lowerTitle = title.toLowerCase();
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

class _HeroCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final String plantName;
  final String plantStatus;
  final Function(int) onPageChanged;

  const _HeroCarouselWidget({
    required this.photos,
    required this.plantName,
    required this.plantStatus,
    required this.onPageChanged,
  });

  @override
  State<_HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
}

class _HeroCarouselWidgetState extends State<_HeroCarouselWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, // Cards peek behind each other
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        widget.onPageChanged(index);
      },
      itemCount: widget.photos.length,
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      pageSnapping: true,
      itemBuilder: (context, index) {
        final photo = widget.photos[index];
        
        return Stack(
          children: [
            // Photo - Full width and height
            Positioned.fill(
              child: _buildHeroImage(photo['url']),
            ),
          ],
        );
      },
    );
  }



  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to see your plant here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds hero image with improved error handling
  Widget _buildHeroImage(String imageUrl) {
    // Validate image URL
    if (imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }
    
    // Try to get a CORS-free URL for web
    final processedUrl = CorsProxyService.getCorsFreeUrl(imageUrl);
    
    return imageUrl.startsWith('data:image')
        ? Image.memory(
            base64Decode(imageUrl.split(',')[1]),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Hero image memory error: $error');
              return _buildPlaceholderImage();
            },
          )
        : imageUrl.startsWith('http')
            ? Image.network(
                processedUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Hero image network error: $error');
                  // Try alternative URL if CORS fails
                  if (CorsProxyService.hasCorsIssues) {
                    return _buildPlaceholderImage();
                  }
                  return _buildPlaceholderImage();
                },
                // Add timeout to prevent hanging
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              )
            : _buildPlaceholderImage();
  }
} 

// Reusable header widget for edge-to-edge carousel
class PlantCarouselHeader extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onBackPressed;
  
  const PlantCarouselHeader({
    super.key, 
    required this.images,
    this.onBackPressed,
  });

  @override
  State<PlantCarouselHeader> createState() => _PlantCarouselHeaderState();
}

class _PlantCarouselHeaderState extends State<PlantCarouselHeader> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    
    // In portrait mode: 60% of screen height, in landscape: fixed 400px
    final headerH = isPortrait ? size.height * 0.60 : 400.0;
    final clampedH = headerH.clamp(260.0, 600.0); // Increased max height for portrait
    
    print('🌱 PlantCarouselHeader: Screen size: ${size.width}x${size.height}');
    print('🌱 PlantCarouselHeader: Is portrait: $isPortrait');
    print('🌱 PlantCarouselHeader: Calculated height: $headerH, clamped: $clampedH');
    print('🌱 PlantCarouselHeader: Device width: ${MediaQuery.of(context).size.width}');

    return Container(
      width: MediaQuery.of(context).size.width, // Explicit full device width
      height: clampedH,
      margin: EdgeInsets.zero, // No margins
      padding: EdgeInsets.zero, // No padding
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Edge-to-edge PageView - Full width
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            padEnds: false,
            itemCount: widget.images.length,
            itemBuilder: (_, i) {
              return Container(
                width: MediaQuery.of(context).size.width, // Explicit full width
                height: clampedH,
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.cover, // fill width, crop height
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width, // Force full width
                  height: clampedH, // Force full height
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      height: clampedH,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Back button overlay (SafeArea)
          Positioned(
            left: 8,
            top: 8,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: widget.onBackPressed ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          // Green dots indicators (padding above white card)
          if (widget.images.length > 1)
            Positioned(
              bottom: 24, // keep 16–24px above the card overlap
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 10 : 8, 
                    height: active ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFF2E7D32)       // green active
                          : const Color(0x662E7D32),      // green with opacity
                      border: active 
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: active 
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}