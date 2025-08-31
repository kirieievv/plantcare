import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/services/chatgpt_service.dart';
import 'package:plant_care/services/health_check_service.dart';

import 'package:plant_care/models/plant.dart';
import 'package:uuid/uuid.dart';

class HealthCheckModal extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Function(Map<String, dynamic>) onHealthCheckComplete;

  const HealthCheckModal({
    Key? key,
    required this.plantId,
    required this.plantName,
    required this.onHealthCheckComplete,
  }) : super(key: key);

  @override
  State<HealthCheckModal> createState() => _HealthCheckModalState();
}

class _HealthCheckModalState extends State<HealthCheckModal> {
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      setState(() {
        _errorMessage = null;
      });
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, // Reduced from 800
        maxHeight: 600, // Reduced from 800
        imageQuality: 70, // Reduced from 85 for smaller file size
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _analyzeHealth() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    
    // Add timeout to prevent infinite freezing
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isAnalyzing) {
        setState(() {
          _errorMessage = 'Analysis timed out. Please try again.';
          _isAnalyzing = false;
        });
      }
    });

    try {
      // Convert image to base64 for API call
      final base64Image = base64Encode(_selectedImageBytes!);
      
      // Use Firebase Function for unified AI analysis
      final aiResponse = await ChatGPTService.analyzePlantPhoto(base64Image, isHealthCheck: true);
      
      if (aiResponse != null) {
        // Extract the raw AI response and determine health status
        final rawResponse = aiResponse['rawResponse'] ?? aiResponse['general_description'] ?? '';
        final healthStatus = _analyzeTextForHealthStatus(rawResponse.toLowerCase());
        
        // Create a health check record
        final healthCheckRecord = HealthCheckRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          status: healthStatus,
          message: rawResponse,
          imageUrl: null, // Will be set by the service after upload
          imageBytes: _selectedImageBytes, // Pass the actual image bytes
          metadata: {
            'analysisTimestamp': DateTime.now().toIso8601String(),
          },
        );

        // Save the health check record to the plant
        try {
          print('🌱 Saving health check record...');
          
          // Show progress message to user
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
          
          await HealthCheckService().addHealthCheck(widget.plantId, healthCheckRecord);
          print('✅ Health check record saved successfully');
          
          // Check if widget is still mounted before proceeding
          if (!mounted) {
            print('⚠️ Widget no longer mounted, aborting health check completion');
            return;
          }
          
          // Add image bytes to the response for immediate display
          final responseWithImage = {
            'status': healthStatus,
            'message': rawResponse,
            'imageBytes': _selectedImageBytes,
          };
          
          print('🌱 Calling onHealthCheckComplete...');
          widget.onHealthCheckComplete(responseWithImage);
          print('✅ Health check completed, closing modal...');
          
          if (mounted) {
            Navigator.pop(context);
          }
        } catch (e) {
          print('❌ Error saving health check: $e');
          if (mounted) {
            setState(() {
              _errorMessage = 'Error saving health check: $e';
              _isAnalyzing = false; // Reset analyzing state on error
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to analyze image. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing image: $e';
      });
    } finally {
      timeoutTimer.cancel(); // Cancel timeout timer
      setState(() {
        _isAnalyzing = false;
      });
    }
  }



  /// Fallback method to analyze text for health status
  /// This is used only if the direct GPT health assessment fails
  String _analyzeTextForHealthStatus(String message) {
    print('🌱 Fallback: Analyzing text for health status...');
    
    // Check for problem indicators - but be more specific to avoid false positives
    final problemIndicators = [
      'wilted', 'drooping', 'yellow', 'brown', 'distress',
      'unhealthy', 'dying', 'dead', 'critical', 'urgent', 'emergency',
      'severe', 'serious', 'turning yellow', 'brown spots',
      'not in the best health', 'needs help', 'poor health',
      'struggling', 'stress', 'fallen petals', 'drooping quite a bit',
      'not in the best health right now', 'problem', 'issue',
      'concern', 'damaged', 'sick', 'declining', 'overwatered',
      'underwatered', 'root rot', 'pest'
      // Removed 'disease' as it can appear in educational content about healthy plants
    ];

    // Check for negative health statements
    final negativeStatements = [
      'not healthy', 'not thriving', 'not doing well',
      'not in good condition', 'not in good shape',
      'has problems', 'has issues', 'needs attention',
      'requires care', 'needs help', 'struggling'
    ];

    // Check for positive health indicators
    final positiveIndicators = [
      'healthy', 'thriving', 'robust', 'good condition',
      'no problems', 'no issues', 'appears healthy',
      'looks good', 'doing well', 'in good shape',
      'beautiful', 'stunning', 'great condition',
      'flourishing', 'lush', 'vibrant', 'excellent',
      'strong', 'vigorous', 'well-maintained', 'properly cared for',
      'showing good growth', 'developing well', 'progressing nicely',
      'maintaining good health', 'stable condition', 'steady growth',
      'good health', 'in good health', 'healthy appearance',
      'thriving plant', 'well-cared for', 'proper care',
      'optimal condition', 'prime condition', 'peak health'
    ];

    // First, check if the AI explicitly states the plant is healthy
    // If so, trust that assessment and don't look for problem indicators
    final explicitHealthStatements = [
      'appears healthy', 'looks healthy', 'is healthy', 'healthy and thriving',
      'no visible signs of damage', 'no visible signs of disease',
      'shows no visible signs', 'appears to be healthy', 'looks to be healthy',
      'healthy appearance', 'thriving condition', 'good health'
    ];
    
    bool hasExplicitHealthStatement = false;
    for (final statement in explicitHealthStatements) {
      if (message.contains(statement)) {
        print('🌱 Fallback: Found explicit health statement: "$statement"');
        hasExplicitHealthStatement = true;
        break;
      }
    }
    
    // If AI explicitly says plant is healthy, trust that assessment
    if (hasExplicitHealthStatement) {
      print('🌱 Fallback: Status = OK (AI explicitly states plant is healthy)');
      return 'ok';
    }
    
    // Check if ANY problem indicator is present (only if no explicit health statement)
    bool hasProblems = false;
    for (final indicator in problemIndicators) {
      if (message.contains(indicator)) {
        print('🌱 Fallback: Found problem indicator: "$indicator"');
        hasProblems = true;
        break;
      }
    }

    // Check for negative statements
    for (final statement in negativeStatements) {
      if (message.contains(statement)) {
        print('🌱 Fallback: Found negative statement: "$statement"');
        hasProblems = true;
        break;
      }
    }

    // Check for positive indicators (only if no problems found)
    bool hasPositiveIndicators = false;
    if (!hasProblems) {
      for (final indicator in positiveIndicators) {
        if (message.contains(indicator)) {
          print('🌱 Fallback: Found positive indicator: "$indicator"');
          hasPositiveIndicators = true;
          break;
        }
      }
    }

    // Determine final status
    if (hasProblems) {
      print('🌱 Fallback: Status = ISSUE (problems detected)');
      return 'issue';
    } else if (hasPositiveIndicators) {
      print('🌱 Fallback: Status = OK (positive indicators found)');
      return 'ok';
    } else {
      // If no clear problems or positive indicators, check if the plant looks generally healthy
      // Look for neutral or slightly positive indicators
      final neutralIndicators = [
        'appears', 'looks', 'seems', 'appearing', 'looking',
        'normal', 'typical', 'standard', 'regular', 'usual',
        'growing', 'developing', 'progressing', 'thriving'
      ];
      
      // Also check for general plant health indicators that suggest a healthy plant
      final generalHealthIndicators = [
        'flower', 'bloom', 'blooming', 'petals', 'leaves',
        'green', 'foliage', 'growth', 'plant', 'healthy',
        'good', 'fine', 'okay', 'alright', 'stable'
      ];
      
      bool hasNeutralIndicators = false;
      for (final indicator in neutralIndicators) {
        if (message.contains(indicator)) {
          print('🌱 Fallback: Found neutral indicator: "$indicator"');
          hasNeutralIndicators = true;
          break;
        }
      }
      
      // Check for general health indicators
      bool hasGeneralHealthIndicators = false;
      if (!hasNeutralIndicators) {
        for (final indicator in generalHealthIndicators) {
          if (message.contains(indicator)) {
            print('🌱 Fallback: Found general health indicator: "$indicator"');
            hasGeneralHealthIndicators = true;
            break;
          }
        }
      }
      
      if (hasNeutralIndicators || hasGeneralHealthIndicators) {
        print('🌱 Fallback: Status = OK (indicators suggest healthy plant)');
        return 'ok';
      } else {
        // Only default to issue if we truly can't determine health status
        // Check if the message is too short or unclear
        if (message.length < 20) {
          print('🌱 Fallback: Status = OK (short message, likely healthy)');
          return 'ok';
        } else {
          print('🌱 Fallback: Status = ISSUE (unclear status, defaulting to issue)');
          return 'issue';
        }
      }
    }
  }

  Widget _buildPlaceholderImage() {
    // Detect iPhone SE for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isIPhoneSE = screenWidth == 375 && screenHeight == 667;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: isIPhoneSE ? 32 : 48,
            color: AppTheme.accentGreen.withOpacity(0.6),
          ),
          if (!isIPhoneSE) ...[
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect iPhone SE and other small screens
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isIPhoneSE = screenWidth == 375 && screenHeight == 667;
    final isSmallScreen = screenHeight < 700;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: isIPhoneSE ? 88 : (isSmallScreen ? 48 : 32),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: isIPhoneSE 
              ? screenHeight * 0.85 
              : (isSmallScreen ? screenHeight * 0.8 : screenHeight * 0.85),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved design
            Container(
              padding: EdgeInsets.fromLTRB(
                20, 
                isIPhoneSE ? 12 : 20, 
                20, 
                isIPhoneSE ? 8 : 16
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header row with icon and title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.health_and_safety,
                          color: AppTheme.accentGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Health Check',
                          style: TextStyle(
                            fontSize: isIPhoneSE ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 18,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isIPhoneSE ? 8 : 16),
                  
                  // Instructions with improved styling
                  Container(
                    padding: EdgeInsets.all(isIPhoneSE ? 6 : 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.accentGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Upload a photo of ${widget.plantName} for AI health analysis',
                            style: TextStyle(
                              fontSize: isIPhoneSE ? 12 : 14,
                              color: AppTheme.accentGreen,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Flexible content area that adapts to content size
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Image Upload Area with improved design
                    Center(
                      child: Container(
                        width: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                        height: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                        margin: EdgeInsets.all(isIPhoneSE ? 2 : (isSmallScreen ? 8 : 16)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedImageBytes != null 
                                ? AppTheme.accentGreen.withOpacity(0.4)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _selectedImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      width: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                                      height: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                                          height: isIPhoneSE ? 60 : (isSmallScreen ? 120 : 180),
                                          color: AppTheme.accentGreen.withOpacity(0.1),
                                          child: Icon(
                                            Icons.image,
                                            size: isIPhoneSE ? 32 : 56,
                                            color: AppTheme.accentGreen,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Remove Button with improved styling
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade500,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedImageBytes = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _buildPlaceholderImage(),
                      ),
                    ),
                    
                    SizedBox(height: isIPhoneSE ? 2 : (isSmallScreen ? 8 : 16)),
                    
                    // Upload Button with improved styling
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          _selectedImageBytes != null ? Icons.refresh : Icons.upload,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          _selectedImageBytes != null ? 'Change Image' : 'Upload Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isIPhoneSE ? 12 : 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isIPhoneSE ? 16 : 24, 
                            vertical: isIPhoneSE ? 8 : 12
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: AppTheme.accentGreen.withOpacity(0.3),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isIPhoneSE ? 3 : (isSmallScreen ? 8 : 16)),
                    
                    if (_selectedImageBytes != null) ...[
                      SizedBox(height: isIPhoneSE ? 8 : (isSmallScreen ? 12 : 16)),
                      Container(
                        padding: EdgeInsets.all(isIPhoneSE ? 6 : 8),
                        margin: EdgeInsets.fromLTRB(16, 0, 16, isIPhoneSE ? 6 : 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Image uploaded successfully! Ready for health analysis.',
                                style: TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isIPhoneSE ? 11 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Analyze Button with improved styling
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedImageBytes != null && !_isAnalyzing ? _analyzeHealth : null,
                          icon: _isAnalyzing 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.health_and_safety,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: Text(
                            _isAnalyzing ? 'Analyzing...' : 'Analyze Health',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isIPhoneSE ? 13 : 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedImageBytes != null 
                                ? AppTheme.accentGreen 
                                : Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isIPhoneSE ? 8 : 16
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: _selectedImageBytes != null ? 3 : 0,
                            shadowColor: AppTheme.accentGreen.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    
                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Add bottom padding for mobile
                    SizedBox(height: isIPhoneSE ? 4 : (isSmallScreen ? 12 : 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 