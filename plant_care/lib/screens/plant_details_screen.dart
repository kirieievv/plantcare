import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/smart_plant.dart';
import 'package:plant_care/models/user_model.dart';
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
  
  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    
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
            backgroundColor: healthResult['status'] == 'ok' 
                ? Colors.green 
                : Colors.orange,
            duration: const Duration(seconds: 4),
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
                  'Error saving health check: $e',
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
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
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
                        ],
                      ),
    );
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
            _plant.aiLight != null ? '${_plant.aiLight} hours' : 'Not specified',
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
                        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
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
                color: Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Issues',
                          style: TextStyle(
                            fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issues,
              style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade800,
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
    if (_plant.aiName == null && _plant.aiGeneralDescription == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
                  color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
                ),
              ],
            ),
      child: ExpansionTile(
        title: Row(
              children: [
                Icon(
              Icons.info,
              color: Colors.grey.shade600,
                  size: 20,
                ),
            const SizedBox(width: 8),
                Text(
              'Details',
              style: TextStyle(
                    fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
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
                if (_plant.aiName != null) ...[
                  _buildDetailRow('Species', _plant.aiName!),
                  const SizedBox(height: 12),
                ],
                if (_plant.aiGeneralDescription != null) ...[
                  _buildDetailRow('Description', _plant.aiGeneralDescription!),
                ],
              ],
            ),
          ),
        ],
      ),
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
            stream: HealthCheckService().getHealthCheckHistory(_plant.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error loading history: ${snapshot.error}');
              }
              
              final healthChecks = snapshot.data ?? [];
              if (healthChecks.isEmpty) {
                return _buildEmptyHealthHistory();
              }
              
              return _buildHealthHistoryList(healthChecks);
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
    final sortedHistory = List<HealthCheckRecord>.from(healthChecks)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sortedHistory.length,
    itemBuilder: (context, index) {
          final record = sortedHistory[index];
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

          // Image
                    Expanded(
                      child: record.imageUrl != null
                          ? _buildImageWithFallback(record.imageUrl!)
                          : _buildImagePlaceholder(),
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
              onPressed: () => Navigator.of(context).pop(),
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
    return Scaffold(
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
                        onPressed: () => Navigator.of(context).pop(),
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
                      stream: HealthCheckService().getHealthCheckHistory(_plant.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          // Use health check photos
                          final healthCheckPhotos = snapshot.data!
                              .where((record) => record.imageUrl != null)
                              .map((record) => {
                                    'url': record.imageUrl!,
                                    'timestamp': record.timestamp,
                                  })
                              .toList();
                          
                          if (healthCheckPhotos.isNotEmpty) {
                            return _HeroCarouselWidget(
                              photos: healthCheckPhotos,
                              plantName: _plant.name,
                              plantStatus: _plant.healthStatus!,
                            );
                          }
                        }
                        
                        // Fallback to default plant photo
                        return _buildHeroPlaceholder();
                      },
                    ),
                  ),
                  
                  // Subtle Page Indicator
                  StreamBuilder<List<HealthCheckRecord>>(
                    stream: HealthCheckService().getHealthCheckHistory(_plant.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final photoCount = snapshot.data!
                            .where((record) => record.imageUrl != null)
                            .length;
                        
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
          
          // Care Section - two cards side-by-side
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
          
          // Details (collapsible/accordion)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildDetailsAccordion(),
            ),
          ),
          
          // Health Check History (horizontal gallery)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildHealthHistoryGallery(),
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
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