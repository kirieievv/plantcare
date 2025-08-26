import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:plant_care/utils/app_theme.dart';

class HealthImage {
  final String id;
  final Uint8List imageBytes;
  final DateTime timestamp;
  final Map<String, dynamic> healthResult;

  HealthImage({
    required this.id,
    required this.imageBytes,
    required this.timestamp,
    required this.healthResult,
  });
}

class HealthGallery extends StatelessWidget {
  final List<HealthImage> images;
  final VoidCallback? onAddImage;

  const HealthGallery({
    Key? key,
    required this.images,
    this.onAddImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: AppTheme.accentGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Health Check History',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (onAddImage != null)
              IconButton(
                onPressed: onAddImage,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                tooltip: 'Add Health Check',
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
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
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload photos to track your plant\'s health over time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return _buildHealthImageCard(context, image);
            },
          ),
      ],
    );
  }

  Widget _buildHealthImageCard(BuildContext context, HealthImage image) {
    final isHealthy = image.healthResult['status'] == 'ok';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  // Actual Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: image.imageBytes.isNotEmpty
                        ? Image.memory(
                            image.imageBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: AppTheme.accentGreen.withOpacity(0.1),
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: AppTheme.accentGreen,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: AppTheme.accentGreen.withOpacity(0.1),
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                  ),
                  // Health Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHealthy ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHealthy ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHealthy ? 'OK' : 'Issue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
          
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(image.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isHealthy && image.healthResult['problem'] != null)
                  Text(
                    image.healthResult['problem'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 