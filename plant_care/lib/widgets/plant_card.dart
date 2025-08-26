import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        
        return GlassmorphicContainer(
          width: double.infinity,
          height: isCompact ? 120 : 100,
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
                    // Plant Image with enhanced styling - Show last health check image if available
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.shadowMedium,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _getPlantImage(),
                      ),
                    ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Plant Info - Expanded to prevent overflow
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Plant Name with animation - priority for space
                          Text(
                            widget.plant.name,
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(
                            duration: 400.ms,
                            delay: 100.ms,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Watering Status with enhanced indicator
                          if (isCompact) ...[
                            // Compact layout: status on next line
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
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _getWateringStatusText(daysUntilWatering),
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _getWateringStatusColor(),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Standard layout: status on same line
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
                                Flexible(
                                  child: Text(
                                    _getWateringStatusText(daysUntilWatering),
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: _getWateringStatusColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Fixed-size Water Button - pill shape with perfectly centered icon
                    if (widget.onWater != null) ...[
                      Container(
                        width: 56,
                        height: 48,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.accentGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isWatering ? null : _handleWater,
                            borderRadius: BorderRadius.circular(24),
                            child: Center(
                              child: _isWatering
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                                      ),
                                    )
                                  : Icon(
                                      Icons.water_drop,
                                      color: AppTheme.accentGreen,
                                      size: 24,
                                    ),
                            ),
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
      },
    );
  }

  Widget _getPlantImage() {
    // Priority 1: Last health check image (most current plant condition)
    if (widget.plant.lastHealthCheckImageUrl != null) {
      if (widget.plant.lastHealthCheckImageUrl!.startsWith('data:image')) {
        return Image.memory(
          base64Decode(widget.plant.lastHealthCheckImageUrl!.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _getFallbackImage();
          },
        );
      } else if (widget.plant.lastHealthCheckImageUrl!.startsWith('http')) {
        return Image.network(
          widget.plant.lastHealthCheckImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _getFallbackImage();
          },
        );
      }
    }
    
    // Priority 2: Fallback to plant's main image
    return _getFallbackImage();
  }
  
  Widget _getFallbackImage() {
    if (widget.plant.imageUrl != null && widget.plant.imageUrl!.startsWith('data:image')) {
      return Image.memory(
        base64Decode(widget.plant.imageUrl!.split(',')[1]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else if (widget.plant.imageUrl != null && widget.plant.imageUrl!.startsWith('http')) {
      return Image.network(
        widget.plant.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
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
      return 'Overdue ${days.abs()}d';
    } else if (days == 0) {
      return 'Watering today';
    } else if (days == 1) {
      return 'Watering tomorrow';
    } else {
      return 'Watering in ${days}d';
    }
  }
} 