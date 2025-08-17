import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';

import 'package:plant_care/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailsScreen({Key? key, required this.plant}) : super(key: key);

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  bool _isLoading = false;
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  Future<void> _waterPlant() async {
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePlant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant'),
        content: Text('Are you sure you want to delete "${_plant.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await PlantService().deletePlant(_plant.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting plant: $e'),
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

  String _getWateringStatus() {
    final now = DateTime.now();
    final daysUntilWatering = _plant.nextWatering.difference(now).inDays;
    
    if (daysUntilWatering < 0) {
      return 'Overdue by ${daysUntilWatering.abs()} days';
    } else if (daysUntilWatering == 0) {
      return 'Water today!';
    } else if (daysUntilWatering == 1) {
      return 'Water tomorrow';
    } else {
      return 'Next watering in $daysUntilWatering days';
    }
  }

  Color _getWateringStatusColor() {
    final now = DateTime.now();
    final daysUntilWatering = _plant.nextWatering.difference(now).inDays;
    
    if (daysUntilWatering < 0) {
      return Colors.red;
    } else if (daysUntilWatering <= 1) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Plant Care Logo Bar
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.white,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppTheme.accentGreen,
                      size: 20,
                    ),
                  ),
                  // Logo and Title (centered)
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_florist,
                            color: AppTheme.accentGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PLANT CARE',
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Empty space to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          
          // Plant Name Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                _plant.name,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Centered Plant Image
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _plant.imageUrl != null && _plant.imageUrl!.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(_plant.imageUrl!.split(',')[1]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                          },
                        )
                        : _plant.imageUrl != null && _plant.imageUrl!.startsWith('http')
                            ? Image.network(
                                _plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              )
                            : _buildPlaceholderImage(),
                  ),
                ),
              ),
            ),
          ),
          
          // Plant details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Watering Status Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop,
                                color: _getWateringStatusColor(),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getWateringStatus(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getWateringStatusColor(),
                                      ),
                                    ),
                                    Text(
                                      'Last watered: ${DateFormat('MMM dd, yyyy').format(_plant.lastWatered)}',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _waterPlant,
                              icon: const Icon(Icons.water_drop),
                              label: const Text('I have watered'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Watering Schedule Block
                  if (_plant.aiMoistureLevel != null || _plant.wateringFrequency != null) ...[
                  const SizedBox(height: 16),
                  
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                              children: [
                                Icon(Icons.water_drop, color: Colors.blue.shade600),
                                const SizedBox(width: 12),
                          const Text(
                                  'Watering Schedule',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Watering Frequency
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatWateringFrequency(_plant.wateringFrequency.toString()),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Soil Moisture Level
                            Row(
                              children: [
                                Icon(Icons.opacity, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Soil Moisture Level:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatMoistureLevel(_plant.aiMoistureLevel),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Last Watering Date/Time
                            Row(
                              children: [
                                Icon(Icons.history, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Watered:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - HH:mm').format(_plant.lastWatered),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                          const SizedBox(height: 16),
                          
                            // Next Watering Date/Time
                            Row(
                              children: [
                                Icon(Icons.schedule_send, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Next Watering:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - HH:mm').format(_plant.nextWatering),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'AI Recommended Schedule',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // AI Care Recommendations
                  if (_plant.aiGeneralDescription != null) ...[
                    const SizedBox(height: 16),
                    
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: Colors.purple.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'AI Care Recommendations',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ),
                                // Status Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.green.shade100,
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AI Ready',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Plant Name and Description
                            if (_plant.aiName != null) ...[
                              _buildInfoRow('Plant Name', _plant.aiName!),
                              const SizedBox(height: 16),
                            ],
                            
                            if (_plant.aiGeneralDescription != null) ...[
                              _buildInfoRow('Description', _plant.aiGeneralDescription!),
                              const SizedBox(height: 16),
                            ],
                            
                            // Care Details Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCareCard(
                                    'Moisture',
                                    _plant.aiMoistureLevel ?? 'Not specified',
                                    Icons.opacity,
                                    Colors.green,
                                    moisturePercentage: _getMoisturePercentage(_plant.aiMoistureLevel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildCareCard(
                                    'Light',
                                    _plant.aiLight ?? 'Not specified',
                                    Icons.wb_sunny,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Specific Issues
                            if (_plant.aiSpecificIssues != null) ...[
                              _buildInfoRow('Specific Issues', _plant.aiSpecificIssues!),
                              const SizedBox(height: 16),
                            ],
                            
                            // Care Tips
                            if (_plant.aiCareTips != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Care Tips',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _plant.aiCareTips!,
                                      style: TextStyle(
                                        color: Colors.purple.shade600,
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
                    ),
                  ],
                  

                  
                  const SizedBox(height: 32),
                  
                  // Delete Plant Button
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _deletePlant,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                        label: Text(
                          'Delete Plant',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
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
  String _formatWateringFrequency(String frequency) {
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
} 