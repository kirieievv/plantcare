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
                Text(
                  healthResult['status'] == 'ok' 
                      ? 'Plant Care Assistant has analyzed your plant! 🌱'
                      : 'Plant Care Assistant has some advice for you! 🌿',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: healthResult['status'] == 'ok' ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
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
                Icons.warning,
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
            builder: (context) => MainNavigationScreen(user: currentUser),
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
      height: 400, // Increased height for vertical photos
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
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

  /// Builds image with CORS fallback handling
  Widget _buildImageWithFallback(String imageUrl) {
    // Validate image URL
    if (imageUrl.isEmpty) {
      return _buildImagePlaceholder();
    }
    
    // Try to get a CORS-free URL for web
    final processedUrl = CorsProxyService.getCorsFreeUrl(imageUrl);
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Image.network(
        processedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Image loading error: $error');
          // Try alternative URL if CORS fails
          if (CorsProxyService.hasCorsIssues) {
            return _buildImagePlaceholderWithRetry(imageUrl);
          }
          return _buildImagePlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder();
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
      ),
    );
  }

  /// Builds image placeholder with retry button for web
  Widget _buildImagePlaceholderWithRetry(String imageUrl) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
            Icons.broken_image,
                            size: 24,
            color: Colors.grey.shade400,
                          ),
          const SizedBox(height: 4),
                          Text(
            'CORS Error',
                            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          ElevatedButton(
            onPressed: () {
              // Force refresh the image
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 0),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds image placeholder when no image is available
  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
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
            'Next Watering',
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
              widthFactor: moisturePercentage / 100,
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
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                  child: Text(
                    'Check plant',
                                style: TextStyle(
                      fontSize: 11,
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

  // AI Care Card
  Widget _buildAiCareCard() {
    if (_plant.healthMessage == null) return const SizedBox.shrink();
    
    // Check if the advice indicates problems
    final advice = _plant.healthMessage!.toLowerCase();
    final isBadAdvice = advice.contains('critical') || 
                       advice.contains('dying') || 
                       advice.contains('urgent') || 
                       advice.contains('emergency') || 
                       advice.contains('severe') || 
                       advice.contains('serious problem') ||
                       advice.contains('immediate attention') ||
                       advice.contains('declining') ||
                       advice.contains('unhealthy') ||
                       advice.contains('yellow') ||
                       advice.contains('brown') ||
                       advice.contains('wilting') ||
                       advice.contains('drooping') ||
                       advice.contains('overwatered') ||
                       advice.contains('underwatered') ||
                       advice.contains('root rot') ||
                       advice.contains('pest') ||
                       advice.contains('disease') ||
                       advice.contains('stress') ||
                       advice.contains('problem') ||
                       advice.contains('issue') ||
                       _plant.healthStatus?.toLowerCase() == 'critical' ||
                       _plant.healthStatus?.toLowerCase() == 'needs attention';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                isBadAdvice ? Icons.warning : Icons.eco,
                color: isBadAdvice ? Colors.red.shade600 : Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBadAdvice ? 'Plant Needs Help!' : 'AI Care Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isBadAdvice ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _plant.healthMessage!,
            style: TextStyle(
              fontSize: 14,
              color: isBadAdvice ? Colors.red.shade800 : Colors.grey.shade800,
              height: 1.4,
            ),
            // Always show full text - no truncation
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
          
          // Add helpful tips for bad advice
          if (isBadAdvice) ...[
            const SizedBox(height: 16),
            Container(
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
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Quick Help Tips',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check soil moisture - may need immediate watering\n'
                    '• Move to appropriate lighting conditions\n'
                    '• Remove any dead or yellowing leaves\n'
                    '• Take a new health check photo to track progress\n'
                    '• Consider repotting if roots are visible',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          if (_plant.lastHealthCheck != null)
            Text(
              'Last checked: ${DateFormat('MMM dd, h:mm a').format(_plant.lastHealthCheck!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
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

  // Details Accordion
  Widget _buildDetailsAccordion() {
    // Show details for all plants, even new ones without AI data
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<List<HealthCheckRecord>>(
        stream: _healthCheckStream,
        builder: (context, snapshot) {
          // Check if there are any health checks
          final hasHealthChecks = snapshot.hasData && 
              snapshot.data != null && 
              snapshot.data!.isNotEmpty;
          
          return ExpansionTile(
            initiallyExpanded: !hasHealthChecks, // Open if no health checks, closed if there are
            title: Row(
              children: [
                Icon(
                  Icons.info,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always show basic plant information
                    _buildDetailRow('Name', _plant.name),
                    const SizedBox(height: 12),
                    _buildDetailRow('Species', _plant.species),
                    const SizedBox(height: 12),
                    
                    // Show AI-enhanced information if available
                    if (_plant.aiName != null && _plant.aiName != _plant.species) ...[
                      _buildDetailRow('AI Identified', _plant.aiName!),
                      const SizedBox(height: 12),
                    ],
                    if (_plant.aiGeneralDescription != null) ...[
                      _buildDetailRow('Description', _plant.aiGeneralDescription!),
                      const SizedBox(height: 12),
                    ],
                    
                    // Add interesting facts based on plant type
                    _buildInterestingFacts(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInterestingFacts() {
    // Use AI name if available, otherwise fall back to species
    // Prioritize species over custom name for more accurate facts
    final plantName = _plant.aiName?.toLowerCase() ?? _plant.species.toLowerCase();
    
    print('🌱 PlantDetailsScreen: Building interesting facts');
    print('🌱 PlantDetailsScreen: Custom name: ${_plant.name}');
    print('🌱 PlantDetailsScreen: AI name: ${_plant.aiName}');
    print('🌱 PlantDetailsScreen: Species: ${_plant.species}');
    print('🌱 PlantDetailsScreen: Using plantName for facts: $plantName');
    
    String facts = '';
    
    // Check for specific plant types in the species/aiName
    if (plantName.contains('tulip') || plantName.contains('tulipa')) {
      print('🌱 PlantDetailsScreen: Found tulip, setting tulip facts');
      facts = '🌷 **Tulip Family**: Part of the Liliaceae family, tulips are native to Central Asia and Turkey.\n\n'
          '🌸 **Spring Beauty**: One of the first flowers to bloom in spring, symbolizing new beginnings.\n\n'
          '🌱 **Bulb Plant**: Grows from bulbs that store energy for the next growing season.\n\n'
          '🌿 **Cut Flower Care**: For cut tulips, trim stems at an angle and change water daily to prolong freshness.';
    } else if (plantName.contains('calathea')) {
      facts = '🌿 **Calathea**: This plant is known for its beautiful, variegated leaves that can be quite large.\n\n'
          '💧 **Humidity Requirement**: Calatheas prefer high humidity, typically around 60-80%.\n\n'
          '🌱 **Watering**: Water thoroughly but infrequently, allowing the top layer of soil to dry out between waterings.\n\n'
          '🌿 **Fertilization**: Feed every 2-4 weeks during the growing season with a balanced fertilizer.\n\n'
          '🎨 **Unique Patterns**: Each leaf has unique, intricate patterns that make them highly prized as decorative plants.';
    } else if (plantName.contains('monstera')) {
      facts = '🕳️ **Swiss Cheese Plant**: The holes in Monstera leaves are called "fenestrations" and develop as the plant matures.\n\n'
          '🌿 **Climbing Nature**: In the wild, Monsteras climb trees using aerial roots and can grow up to 70 feet tall.\n\n'
          '🌱 **Fast Grower**: One of the fastest-growing houseplants, they can grow several feet per year.\n\n'
          '🌿 **Split Leaves**: Young leaves start solid, then develop splits and holes as they mature.';
    } else if (plantName.contains('ficus') || plantName.contains('fig')) {
      facts = '🌳 **Ficus Family**: Part of the fig family, these plants can grow into large trees in their native habitats.\n\n'
          '🌿 **Air Purifying**: Excellent at removing indoor air pollutants like formaldehyde and benzene.\n\n'
          '🌱 **Adaptable**: Can tolerate various light conditions, from bright indirect to low light.\n\n'
          '🌿 **Pruning Friendly**: Responds well to pruning and can be shaped into various forms.';
    } else if (plantName.contains('philodendron')) {
      facts = '🌿 **Tree Lover**: The name "Philodendron" means "tree lover" in Greek, as they naturally climb trees.\n\n'
          '🌱 **Easy Care**: One of the most forgiving houseplants, perfect for beginners.\n\n'
          '🌿 **Fast Growing**: Can grow several feet per year with proper care and conditions.\n\n'
          '🌱 **Propagation**: Easy to propagate from stem cuttings in water or soil.';
    } else if (plantName.contains('pothos') || plantName.contains('epipremnum')) {
      facts = '🌿 **Devil\'s Ivy**: Called "Devil\'s Ivy" because it\'s nearly impossible to kill, even in low light.\n\n'
          '🌱 **Air Purifying**: NASA study found it\'s excellent at removing indoor air pollutants.\n\n'
          '🌿 **Trailing Beauty**: Can grow vines up to 10 feet long, perfect for hanging baskets.\n\n'
          '🌱 **Low Maintenance**: Thrives on neglect and can survive with minimal watering.';
    } else if (plantName.contains('succulent') || plantName.contains('cactus')) {
      facts = '🌵 **Water Storage**: Succulents store water in their thick leaves, stems, or roots.\n\n'
          '🌱 **Drought Tolerant**: Can survive weeks or months without water.\n\n'
          '🌿 **Sun Lovers**: Most need bright, direct sunlight to maintain their compact shape.\n\n'
          '🌱 **Easy Propagation**: Many can be grown from single leaves or stem cuttings.';
    } else if (plantName.contains('lemon') || plantName.contains('citrus')) {
      facts = '🍋 **Citrus Family**: Part of the Rutaceae family, citrus trees are native to Southeast Asia.\n\n'
          '🌿 **Evergreen**: Unlike many fruit trees, citrus trees keep their leaves year-round.\n\n'
          '🌱 **Fragrant Flowers**: Citrus blossoms have a sweet, intoxicating fragrance that attracts pollinators.\n\n'
          '🍊 **Fruit Production**: Can take 3-5 years to produce fruit, but then provide harvests for decades.';
    } else if (plantName.contains('snake plant') || plantName.contains('sansevieria')) {
      facts = '🐍 **Snake Plant**: Named for its snake-like, upright leaves that can grow up to 8 feet tall.\n\n'
          '🌱 **Night Oxygen**: Unlike most plants, it releases oxygen at night, making it perfect for bedrooms.\n\n'
          '🌿 **Nearly Indestructible**: Can survive in almost any condition, including very low light.\n\n'
          '💧 **Water Efficient**: Stores water in its leaves and can go weeks without watering.';
    } else if (plantName.contains('zz plant') || plantName.contains('zamioculcas')) {
      facts = '🌿 **ZZ Plant**: Short for Zamioculcas zamiifolia, this plant is incredibly low maintenance.\n\n'
          '🌱 **Drought Tolerant**: Can survive months without water due to its thick rhizomes.\n\n'
          '🌿 **Low Light Champion**: Thrives in very low light conditions where other plants struggle.\n\n'
          '🌱 **Slow Grower**: Grows slowly but steadily, making it perfect for small spaces.';
    } else if (plantName.contains('fiddle leaf') || plantName.contains('ficus lyrata')) {
      facts = '🎻 **Fiddle Leaf Fig**: Named for its large, violin-shaped leaves that can grow up to 18 inches long.\n\n'
          '🌿 **Statement Plant**: One of the most popular statement plants due to its dramatic appearance.\n\n'
          '🌱 **Light Sensitive**: Prefers bright, indirect light and can be finicky about placement.\n\n'
          '🌿 **Growth Pattern**: Grows tall and tree-like, perfect for filling vertical spaces.';
    } else if (plantName.contains('aloe') || plantName.contains('aloe vera')) {
      facts = '🌵 **Succulent Family**: Part of the Asphodelaceae family, native to the Arabian Peninsula.\n\n'
          '💊 **Medicinal Properties**: Gel from leaves has been used for centuries to treat burns and skin conditions.\n\n'
          '🌱 **Easy Propagation**: Produces "pups" or offsets that can be separated to create new plants.\n\n'
          '🌿 **Drought Resistant**: Stores water in its thick, fleshy leaves for long periods.';
    } else if (plantName.contains('orchid') || plantName.contains('phalaenopsis')) {
      facts = '🦋 **Moth Orchid**: Phalaenopsis means "moth-like" due to the flower\'s resemblance to flying moths.\n\n'
          '🌿 **Epiphytic**: In nature, they grow on trees and rocks, not in soil.\n\n'
          '🌱 **Long Blooming**: Flowers can last 2-6 months, making them excellent value.\n\n'
          '💧 **Special Care**: Prefer bark-based potting mix and need careful watering to avoid root rot.';
    } else if (plantName.contains('peace lily') || plantName.contains('spathiphyllum')) {
      facts = '🕊️ **Peace Lily**: Named for its white, flag-like flowers that symbolize peace.\n\n'
          '🌿 **Air Purifying**: Excellent at removing indoor air pollutants like formaldehyde and benzene.\n\n'
          '🌱 **Drama Queen**: Leaves droop dramatically when thirsty, making it easy to know when to water.\n\n'
          '🌿 **Low Light Tolerant**: Can bloom in very low light conditions, unlike many flowering plants.';
    } else if (plantName.contains('jade') || plantName.contains('crassula')) {
      facts = '💎 **Jade Plant**: Also called "Money Tree" or "Friendship Tree" in many cultures.\n\n'
          '🌿 **Tree-like Growth**: Can be trained to grow like a miniature tree with proper pruning.\n\n'
          '🌱 **Long Lived**: Can live for decades and even centuries with proper care.\n\n'
          '🌿 **Symbolic**: In Feng Shui, it\'s believed to bring good luck and prosperity.';
    } else if (plantName.contains('geranium') || plantName.contains('pelargonium')) {
      facts = '🌸 **Geranium Family**: Part of the Pelargonium genus, native to South Africa.\n\n'
          '🌿 **Flowering Beauty**: Known for their vibrant, colorful blooms that can last throughout the growing season.\n\n'
          '🌱 **Easy Care**: Perfect for beginners, they\'re forgiving and adapt well to various conditions.\n\n'
          '🌿 **Versatile Uses**: Great for containers, hanging baskets, garden beds, and indoor decoration.';
    } else if (plantName.contains('rose')) {
      facts = '🌹 **Rose Family**: Part of the Rosaceae family, roses have been cultivated for thousands of years.\n\n'
          '🌿 **Symbolic Beauty**: Roses symbolize love, beauty, and passion across many cultures.\n\n'
          '🌱 **Fragrant Blooms**: Many varieties have intoxicating fragrances that fill the air.\n\n'
          '🌿 **Long History**: Roses have been grown since ancient times in China, Persia, and Egypt.';
    } else if (plantName.contains('lavender')) {
      facts = '💜 **Lavender Family**: Part of the Lamiaceae family, native to the Mediterranean region.\n\n'
          '🌿 **Aromatic Herb**: Known for its calming fragrance and beautiful purple flowers.\n\n'
          '🌱 **Drought Tolerant**: Thrives in dry, well-draining soil and full sun.\n\n'
          '🌿 **Multiple Uses**: Used in aromatherapy, cooking, and as a natural insect repellent.';
    } else if (plantName.contains('mint')) {
      facts = '🌿 **Mint Family**: Part of the Lamiaceae family, mints are fast-growing, aromatic herbs.\n\n'
          '🌱 **Invasive Nature**: Can spread quickly through underground runners, so best grown in containers.\n\n'
          '🌿 **Culinary Uses**: Popular in teas, cocktails, and various dishes.\n\n'
          '🌱 **Easy Propagation**: Can be grown from cuttings, seeds, or division.';
    } else if (plantName.contains('basil')) {
      facts = '🌿 **Basil Family**: Part of the Lamiaceae family, native to tropical regions of central Africa and Southeast Asia.\n\n'
          '🌱 **Annual Herb**: Grows quickly and produces abundant leaves throughout the growing season.\n\n'
          '🌿 **Culinary Star**: Essential herb in Mediterranean, Thai, and Italian cuisines.\n\n'
          '🌱 **Pinch to Grow**: Regular pinching of flower buds encourages bushier growth and more leaves.';
    } else if (plantName.contains('cannabis') || plantName.contains('marijuana') || plantName.contains('hemp')) {
      facts = '🌿 **Cannabis Family**: Part of the Cannabaceae family, one of the oldest cultivated plants in human history.\n\n'
          '🌱 **Ancient Plant**: Has been used for thousands of years for fiber, medicine, and other purposes.\n\n'
          '🌿 **Fast Growing**: Can grow several inches per day under optimal conditions.\n\n'
          '🌱 **Light Sensitive**: Requires specific light cycles for different growth stages.';
    } else {
      // More specific facts based on plant characteristics
      if (_plant.aiMoistureLevel != null) {
        final moisture = _plant.aiMoistureLevel!.toLowerCase();
        if (moisture.contains('high') || moisture.contains('moist')) {
          facts = '💧 **Moisture Loving**: This plant prefers consistently moist soil and high humidity.\n\n'
              '🌿 **Tropical Origin**: Likely native to tropical or subtropical regions with regular rainfall.\n\n'
              '🌱 **Water Sensitive**: May show signs of stress if allowed to dry out completely.\n\n'
              '🌿 **Humidity Appreciator**: Benefits from regular misting or a humidifier.';
        } else if (moisture.contains('low') || moisture.contains('dry')) {
          facts = '🌵 **Drought Tolerant**: This plant is adapted to survive with minimal water.\n\n'
              '🌿 **Water Storage**: Likely stores water in its leaves, stems, or roots.\n\n'
              '🌱 **Low Maintenance**: Perfect for busy people who might forget to water.\n\n'
              '🌿 **Native to Arid Regions**: Evolved in environments with infrequent rainfall.';
        }
      } else if (_plant.aiLight != null) {
        final light = _plant.aiLight!.toLowerCase();
        if (light.contains('bright') || light.contains('direct')) {
          facts = '☀️ **Sun Lover**: This plant thrives in bright, direct sunlight.\n\n'
              '🌿 **Native to Sunny Climates**: Evolved in regions with intense sunlight.\n\n'
              '🌱 **High Energy**: Produces lots of energy through photosynthesis.\n\n'
              '🌿 **Color Enhancement**: Bright light often intensifies leaf colors and patterns.';
        } else if (light.contains('low') || light.contains('shade')) {
          facts = '🌑 **Shade Tolerant**: This plant can survive and even thrive in low light conditions.\n\n'
              '🌿 **Forest Floor Native**: Likely evolved under the canopy of larger plants.\n\n'
              '🌱 **Energy Efficient**: Adapted to make the most of limited light.\n\n'
              '🌿 **Perfect for Dark Corners**: Ideal for spaces that don\'t get much natural light.';
        }
      } else {
        // Fallback to plant-specific facts based on species
        if (_plant.species.toLowerCase().contains('tree')) {
          facts = '🌳 **Tree Characteristics**: This plant has woody stems and can grow quite large over time.\n\n'
              '🌿 **Long Lived**: Trees can live for many years, even decades with proper care.\n\n'
              '🌱 **Seasonal Changes**: May show different growth patterns throughout the year.\n\n'
              '🌿 **Pruning Benefits**: Regular pruning helps maintain shape and promote healthy growth.';
        } else if (_plant.species.toLowerCase().contains('herb')) {
          facts = '🌿 **Herbaceous Plant**: This plant has soft, green stems that die back in winter.\n\n'
              '🌱 **Fast Growing**: Herbs typically grow quickly and can be harvested regularly.\n\n'
              '🌿 **Versatile Uses**: Many herbs have culinary, medicinal, or aromatic properties.\n\n'
              '🌱 **Easy Propagation**: Most herbs can be easily propagated from cuttings or seeds.';
        } else if (_plant.species.toLowerCase().contains('flower') || _plant.species.toLowerCase().contains('bloom')) {
          facts = '🌸 **Flowering Plant**: This plant produces beautiful blooms to attract pollinators.\n\n'
              '🌿 **Seasonal Beauty**: Flowers typically appear during specific seasons or growing periods.\n\n'
              '🌱 **Pollinator Friendly**: Attracts bees, butterflies, and other beneficial insects.\n\n'
              '🌿 **Colorful Display**: Adds vibrant colors and visual interest to your space.';
        } else {
          facts = '🌿 **Unique Plant**: This plant has its own special characteristics and care requirements.\n\n'
              '🌱 **Individual Needs**: Every plant is unique and may have specific preferences.\n\n'
              '🌿 **Growth Potential**: With proper care, this plant can thrive and grow beautifully.\n\n'
              '🌱 **Care Learning**: Paying attention to your plant\'s needs helps you become a better plant parent.';
        }
      }
    }
    
    print('🌱 PlantDetailsScreen: Final facts length: ${facts.length}');
    print('🌱 PlantDetailsScreen: Facts content: $facts');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interesting Facts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          facts,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
            style: TextStyle(
            fontSize: 14,
              color: Colors.grey.shade800,
            height: 1.4,
          ),
        ),
      ],
  );
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
            if (healthChecks.isEmpty) {
              return _buildEmptyHealthHistory();
            }
            
            // Validate health check records before rendering
            final validHealthChecks = healthChecks.where((record) => 
              record != null && 
              record.id.isNotEmpty && 
              record.status.isNotEmpty
            ).toList();
            
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
    
    final sortedHistory = List<HealthCheckRecord>.from(validHealthChecks)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedHistory.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          final record = sortedHistory[index];
          if (record == null) {
            return const SizedBox.shrink();
          }
          
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < sortedHistory.length - 1 ? 12 : 0),
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
          color: record.status == 'ok' ? Colors.green.shade200 : Colors.orange.shade200,
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
              color: record.status == 'ok' ? Colors.green.shade100 : Colors.orange.shade100,
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
                  color: record.status == 'ok' ? Colors.green.shade600 : Colors.orange.shade600,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  record.status == 'ok' ? 'OK' : 'Issue',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: record.status == 'ok' ? Colors.green.shade600 : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Image - Fixed to prevent rendering issues
          Flexible(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 60,
                maxHeight: 80,
              ),
              child: record.imageUrl != null && record.imageUrl!.isNotEmpty
                  ? _buildImageWithFallback(record.imageUrl!)
                  : _buildImagePlaceholder(),
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

  /// Convert moisture level text to percentage (0-100) - consistent with AI recommendations
  int _getMoisturePercentage(String? moistureLevel) {
    if (moistureLevel == null) return 50;
    
    final lowerLevel = moistureLevel.toLowerCase();
    if (lowerLevel.contains('very low') || lowerLevel.contains('extremely low')) return 10;
    if (lowerLevel.contains('low') || lowerLevel.contains('dry')) return 25;
    if (lowerLevel.contains('medium') || lowerLevel.contains('moderate')) return 50;
    if (lowerLevel.contains('high') || lowerLevel.contains('moist')) return 75;
    if (lowerLevel.contains('very high') || lowerLevel.contains('extremely high')) return 90;
    
    return 50; // Default to moderate
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

  Color _getStatusColor() {
    if (_plant.healthStatus == 'ok') {
      return Colors.green;
    } else if (_plant.healthStatus == 'warning') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (_plant.healthStatus == 'ok') {
      return Icons.check_circle;
    } else if (_plant.healthStatus == 'warning') {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  String _getStatusText() {
    if (_plant.healthStatus == 'ok') {
      return 'Healthy';
    } else if (_plant.healthStatus == 'warning') {
      return 'Needs Attention';
    } else {
      return 'Unhealthy';
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
    );
  }

  Widget _buildHeroPlaceholder() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 400, // Increased height for vertical photos
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
                    color: _getStatusColor().withOpacity(0.8),
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
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    Text(
                        _getStatusText(),
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
      print('🌱 PlantDetailsScreen: Building screen for plant: ${_plant.name}');
      print('🌱 PlantDetailsScreen: Plant ID: ${_plant.id}');
      print('🌱 PlantDetailsScreen: Plant species: ${_plant.species}');
      
      return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // Header with back button and plant name
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  children: [
                    // Header row with back button and name
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppTheme.textPrimary,
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
                        Expanded(
                          child: Text(
                            _plant.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                        ),
                      textAlign: TextAlign.center,
                    ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Hero Photo Section with margins and card effect
                  Container(
                    height: 400,
                    child: StreamBuilder<List<HealthCheckRecord>>(
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
                          
                          for (final record in sortedHealthChecks) {
                            if (record.imageUrl != null && record.imageUrl!.isNotEmpty) {
                              photos.add({
                                'url': record.imageUrl!,
                                'type': 'health_check',
                                'record': record,
                                'timestamp': record.timestamp,
                              });
                            }
                          }
                        }
                        
                        // Add default plant photo if it exists (first created plant photo)
                        if (_plant.imageUrl != null && _plant.imageUrl!.isNotEmpty) {
                          photos.add({
                            'url': _plant.imageUrl!,
                            'type': 'default',
                            'record': null,
                            'timestamp': _plant.createdAt,
                          });
                        }
                        
                        if (photos.isNotEmpty) {
                          return _HeroCarouselWidget(
                            photos: photos,
                            plantName: _plant.name,
                            plantStatus: _plant.healthStatus ?? 'unknown',
                          );
                        }
                        
                        // Fallback to default plant photo
                        return _buildHeroPlaceholder();
                      },
                    ),
                  ),
                  
                  // Subtle Page Indicator
                  StreamBuilder<List<HealthCheckRecord>>(
                    stream: _healthCheckStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('❌ Error loading page indicator: ${snapshot.error}');
                        return const SizedBox.shrink();
                      }
                      
                      // Calculate total photo count: health checks + plant photo
                      int photoCount = 0;
                      
                      if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                        photoCount += snapshot.data!
                            .where((record) => record != null && record.imageUrl != null && record.imageUrl!.isNotEmpty)
                            .length;
                      }
                      
                      // Add plant photo if it exists
                      if (_plant.imageUrl != null && _plant.imageUrl!.isNotEmpty) {
                        photoCount += 1;
                      }
                      
                      if (photoCount > 1) {
                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(photoCount, (index) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == 0 
                                      ? AppTheme.accentGreen 
                                      : Colors.grey.shade300,
                                ),
                              );
                            }),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ],
                ),
            ),
          ),
          
          // Key Metrics - 3 cards in a row (responsive)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout: stack on narrow screens
                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        // First row: 2 cards
                        Row(
                          children: [
                            Expanded(child: _buildNextWateringCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildLightCard()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Second row: 1 card
                        _buildMoistureCard(),
                      ],
                    );
                  } else {
                    // Wide screen: 3 cards in a row
                    return Row(
                      children: [
                        Expanded(child: _buildNextWateringCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLightCard()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMoistureCard()),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
          
          // AI Care Assistant (green card)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildAiCareCard(),
            ),
          ),
          
          // Care Section (Issues and Tips)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildDetailsAccordion(),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
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
}

class _HeroCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final String plantName;
  final String plantStatus;

  const _HeroCarouselWidget({
    required this.photos,
    required this.plantName,
    required this.plantStatus,
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
  return Container(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.photos.length,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        pageSnapping: true,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          final isActive = index == _currentPage;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(
              horizontal: isActive ? 0 : 8,
              vertical: isActive ? 0 : 4,
            ),
            child: Container(
    decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: isActive ? 20 : 8,
                    offset: Offset(0, isActive ? 8 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Photo
                    Container(
                      width: double.infinity,
                      height: 400,
                      child: photo['url'].startsWith('data:image')
                        ? Image.memory(
                            base64Decode(photo['url'].split(',')[1]),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : photo['url'].startsWith('http')
                            ? Image.network(
                                photo['url'],
                                fit: BoxFit.contain,
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
                    
                    // Plant Name Overlay with Gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.plantName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusText(),
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
                ),
              ),
            ),
          );
        },
    ),
  );
}

  Color _getStatusColor() {
    switch (widget.plantStatus.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'needs attention':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.plantStatus.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'needs attention':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }

  String _getStatusText() {
    switch (widget.plantStatus.toLowerCase()) {
      case 'healthy':
        return 'Healthy';
      case 'needs attention':
        return 'Needs Attention';
      case 'critical':
        return 'Critical';
      default:
        return 'Healthy';
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
} 