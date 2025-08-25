import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class PlantCard extends StatefulWidget {
  final Plant plant;
  final VoidCallback? onWater;
  final VoidCallback? onTap;

  const PlantCard({
    Key? key,
    required this.plant,
    this.onWater,
    this.onTap,
  }) : super(key: key);

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard> {
  bool _isWatering = false;

  Future<void> _handleWater() async {
    if (_isWatering || widget.onWater == null) return;

    setState(() {
      _isWatering = true;
    });

    try {
      // Call the onWater callback
      widget.onWater!();
      
      // Show success message
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
                  '${widget.plant.name} has been watered! 💧',
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
      // Show error message
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
          _isWatering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilWatering = widget.plant.nextWatering.difference(DateTime.now()).inDays;
    final wateringPercentage = _calculateWateringPercentage();
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 140,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Plant Image with enhanced styling
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.shadowMedium,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.plant.imageUrl != null && widget.plant.imageUrl!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(widget.plant.imageUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : widget.plant.imageUrl != null && widget.plant.imageUrl!.startsWith('http')
                            ? Image.network(
                                widget.plant.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              )
                            : _buildPlaceholderImage(),
                  ),
                ).animate().scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                ),
                
                const SizedBox(width: 16),
                
                // Plant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Plant Name with animation
                      Text(
                        widget.plant.name,
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(
                        duration: 400.ms,
                        delay: 100.ms,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Watering Status with enhanced indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getWateringStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.water_drop,
                              color: _getWateringStatusColor(),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getWateringStatusText(daysUntilWatering),
                            style: AppTheme.bodyMedium.copyWith(
                              color: _getWateringStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ).animate().slideX(
                        begin: 0.3,
                        duration: 500.ms,
                        delay: 200.ms,
                      ),
                    ],
                  ),
                ),
                
                // Watering Progress Indicator
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 6.0,
                    percent: wateringPercentage,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${daysUntilWatering.abs()}',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getWateringStatusColor(),
                          ),
                        ),
                        Text(
                          'days',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    progressColor: _getWateringStatusColor(),
                    backgroundColor: AppTheme.lightGrey,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ).animate().rotate(
                  duration: 600.ms,
                  delay: 300.ms,
                ),
                
                // Water Button
                if (widget.onWater != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGreen,
                          AppTheme.accentGreen.withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isWatering ? null : _handleWater,
                      icon: _isWatering
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                              size: 24,
                            ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ).animate().scale(
                    duration: 400.ms,
                    delay: 400.ms,
                    curve: Curves.elasticOut,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.local_florist,
        size: 40,
        color: AppTheme.mediumGrey,
      ),
    );
  }

  Color _getWateringStatusColor() {
    if (widget.plant.nextWatering.isBefore(DateTime.now())) {
      return Colors.red; // Overdue
    } else if (widget.plant.nextWatering.difference(DateTime.now()).inDays <= 1) {
      return Colors.orange; // Water soon
    } else {
      return AppTheme.accentGreen; // Healthy
    }
  }

  String _getWateringStatusText(int days) {
    if (days < 0) {
      return 'Overdue by ${days.abs()} days';
    } else if (days == 0) {
      return 'Water today!';
    } else if (days == 1) {
      return 'Water tomorrow';
    } else {
      return 'Next watering in $days days';
    }
  }

  double _calculateWateringPercentage() {
    final totalDays = widget.plant.wateringFrequency;
    final daysLeft = widget.plant.nextWatering.difference(DateTime.now()).inDays;
    
    if (daysLeft <= 0) return 1.0; // Overdue
    if (daysLeft >= totalDays) return 0.0; // Just watered
    
    return 1.0 - (daysLeft / totalDays);
  }
} 