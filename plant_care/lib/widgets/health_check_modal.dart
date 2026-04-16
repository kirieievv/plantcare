import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/services/health_check_service.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:http/http.dart' as http;

import 'package:plant_care/models/plant.dart';
import 'package:uuid/uuid.dart';

enum HealthCheckAnalysisMode { aiCare, aiAgent }

class HealthCheckModal extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Function(Map<String, dynamic>) onHealthCheckComplete;
  final HealthCheckAnalysisMode analysisMode;

  const HealthCheckModal({
    Key? key,
    required this.plantId,
    required this.plantName,
    required this.onHealthCheckComplete,
    this.analysisMode = HealthCheckAnalysisMode.aiAgent,
  }) : super(key: key);

  @override
  State<HealthCheckModal> createState() => _HealthCheckModalState();
}

class _HealthCheckModalState extends State<HealthCheckModal> {
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  String get _analysisModeLabel {
    return widget.analysisMode == HealthCheckAnalysisMode.aiCare ? 'AI Care' : 'AI Agent';
  }

  String get _analysisModeKey {
    return widget.analysisMode == HealthCheckAnalysisMode.aiCare ? 'ai_care' : 'ai_agent';
  }

  /// Shows a centered dialog to choose image source (gallery/camera), so the choice UI is not at the top.
  void _showImageSourceDialog() {
    setState(() {
      _errorMessage = null;
    });
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.choosePhoto,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppTheme.accentGreen),
                  title: Text(AppLocalizations.of(context)!.gallery),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppTheme.accentGreen),
                  title: Text(AppLocalizations.of(context)!.camera),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error picking image: $e';
        });
      }
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
    timeoutTimer = Timer(const Duration(seconds: 60), () {
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
      
      // Call Firebase Function for analysis (uses unified prompt)
      final response = await _callChatGPT(base64Image);
      
      if (response != null) {
        // Create a health check record (include watering recommendation in metadata for history)
        final metadata = <String, dynamic>{
          'analysisTimestamp': DateTime.now().toIso8601String(),
          'analysisMode': response['analysisMode'] ?? _analysisModeKey,
        };
        if (response['agent'] is Map) {
          final agent = Map<String, dynamic>.from(response['agent'] as Map);
          metadata['retryCount'] = agent['attemptsUsed'];
          metadata['tierUsed'] = agent['tierUsed'];
          metadata['imagesUsed'] = agent['imagesUsed'];
          metadata['escalationReason'] = agent['escalationReason'];
          metadata['agentAccepted'] = agent['accepted'];
          metadata['agentAttemptTrace'] = agent['attemptTrace'];
          metadata['decisionTraceV2'] = agent['decisionTraceV2'];
          metadata['agentContext'] = agent['context'];
        }
        if (response['amount_ml'] != null) {
          metadata['recommendedAmountMl'] = response['amount_ml'];
        }
        if (response['watering_amount'] != null) {
          metadata['watering_amount'] = response['watering_amount'];
        }
        final healthCheckRecord = HealthCheckRecord(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          status: response['status'],
          message: response['message'],
          imageUrl: null, // Will be set by the service after upload
          imageBytes: _selectedImageBytes, // Pass the actual image bytes
          metadata: metadata,
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
          final responseWithImage = Map<String, dynamic>.from(response);
          responseWithImage['imageBytes'] = _selectedImageBytes;
          
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

  Future<Map<String, dynamic>?> _callChatGPT(String base64Image) async {
    try {
      // Call Firebase Function for analysis (uses unified prompt)
      print('🌱 Health Check Modal: Calling Firebase Functions for AI analysis...');
      print('🌱 Health Check Modal: Selected mode: $_analysisModeLabel ($_analysisModeKey)');

      final bool isAgentMode = widget.analysisMode == HealthCheckAnalysisMode.aiAgent;
      final String endpointUrl = isAgentMode ? analyzeHealthCheckAgentUrl : analyzePlantPhotoUrl;
      print('🌱 Health Check Modal: Endpoint: $endpointUrl');
      
      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64Image': base64Image,
          // Agent mode uses context fields; AI Care endpoint ignores extra fields safely.
          if (isAgentMode) ...{
            'plantId': widget.plantId,
            'plantName': widget.plantName,
            'userId': FirebaseAuth.instance.currentUser?.uid,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Firebase Function response received');
        print('🔍 Response keys: ${result.keys.toList()}');
        final agentInfo = result['agent'];
        
        // Extract recommendations from the response (shared with AddPlant flow)
        // Convert to proper Map<String, dynamic> to avoid type errors
        final recommendationsRaw = result['recommendations'];
        final recommendations = recommendationsRaw is Map 
            ? Map<String, dynamic>.from(recommendationsRaw as Map) 
            : <String, dynamic>{};
        print('🔍 Recommendations keys: ${recommendations.keys.toList()}');
        
        // Extract plant size data from the AI response
        final plantSize = recommendations['plant_size'] ?? result['plant_size'];
        final potSize = recommendations['pot_size'] ?? result['pot_size'];
        final growthStage = recommendations['growth_stage'] ?? result['growth_stage'];
        
        // Moisture / light and care recommendations (same structure as AddPlant)
        final moistureLevel = recommendations['moisture_level'] ?? result['moisture_level'];
        final light = recommendations['light'] ?? result['light'];
        final careTips = recommendations['care_tips'];
        final interestingFacts = recommendations['interesting_facts'];
        
        // Per-plant, days-based watering interval from AI (new species-specific structure)
        // Fix: Properly convert LinkedMap to Map<String, dynamic>
        final wateringPlanRaw = recommendations['watering_plan'];
        final wateringPlan = wateringPlanRaw is Map 
            ? Map<String, dynamic>.from(wateringPlanRaw as Map) 
            : <String, dynamic>{};
        // Extract from new watering_plan structure
        final wateringIntervalDays = wateringPlan['next_watering_in_days'];
        final shouldWaterNow = wateringPlan['should_water_now'] as bool?;
        final reasonShort = wateringPlan['reason_short'] as String?;
        
        // Extract amount_ml from watering_plan first (already clamped by backend), then fallback to legacy
        final wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        
        // Scientific watering calculation data (legacy support)
        final wateringRangeMl = recommendations['range_ml'];
        final nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        final nextCheckHours = recommendations['next_check_in_hours'];
        final wateringMode = recommendations['mode'];
        final wateringAmountText = recommendations['watering_amount'];
        final rawResponse = result['rawResponse'] ?? result['message'] ?? '';
        
        print('🌱 ========== HEALTH CHECK WATERING DATA ==========');
        print('🌱 Health Check: watering_plan exists: ${wateringPlan.isNotEmpty}');
        print('🌱 Health Check: watering_plan keys: ${wateringPlan.keys.toList()}');
        print('🌱 Health Check: Extracted watering_plan=$wateringPlan');
        print('🌱 Health Check: Per-plant watering_interval_days=$wateringIntervalDays (type: ${wateringIntervalDays.runtimeType})');
        print('🌱 Health Check: next_after_watering_in_hours=$nextAfterWateringHours');
        print('🌱 Health Check: mode=$wateringMode');
        print('🌱 ================================================');
        
        // Determine health status from the AI response content
        String status = 'ok'; // Default to healthy
        
        print('🌱 Health Check Modal: Analyzing AI response for health status...');
        print('🌱 AI Message: ${rawResponse.substring(0, rawResponse.length > 200 ? 200 : rawResponse.length)}...');
        print('🌱 Plant Size: $plantSize, Pot Size: $potSize, Growth Stage: $growthStage');
        
        // Improved health status determination - prioritize positive indicators
        // Look for strong positive indicators first
        final lowerResponse = rawResponse.toLowerCase();
        print('🌱 Lower response: ${lowerResponse.substring(0, lowerResponse.length > 200 ? 200 : lowerResponse.length)}...');
        
        // Debug: Check for specific phrases
        print('🌱 Contains "appears healthy": ${lowerResponse.contains('appears healthy')}');
        print('🌱 Contains "no signs of": ${lowerResponse.contains('no signs of')}');
        print('🌱 Contains "disease": ${lowerResponse.contains('disease')}');
        print('🌱 Contains "no signs of disease": ${lowerResponse.contains('no signs of disease')}');
        
        // Count positive vs negative indicators
        final positiveIndicators = [
          'healthy', 'thriving', 'good condition', 'no problems', 
          'doing well', 'looking great', 'vibrant', 'robust'
        ];
        
        final negativeIndicators = [
          'unhealthy', 'dying', 'wilting', 'wilted', 'drooping',
          'needs help', 'needs attention', 'struggling', 'stress',
          'health issues', 'brown patches', 'brown spots', 'rot',
          'disease', 'trauma', 'damage', 'problems', 'issues',
          'declining', 'critical', 'urgent', 'emergency', 'severe'
        ];
        
        // Check for strong positive indicators first (they override negative ones)
        if (lowerResponse.contains('appears healthy') ||
            lowerResponse.contains('shows healthy') || 
            lowerResponse.contains('looking healthy') ||
            lowerResponse.contains('is healthy') ||
            lowerResponse.contains('thriving') ||
            lowerResponse.contains('doing well') ||
            lowerResponse.contains('no signs of') ||
            lowerResponse.contains('no visible problems') ||
            lowerResponse.contains('no issues')) {
          print('🌱 Found strong positive indicator - setting status to ok');
          status = 'ok';
        }
        // Check for strong negative indicators (only if no positive indicators found)
        else if (lowerResponse.contains('appears to have some health issues') ||
            lowerResponse.contains('has some health issues') ||
            lowerResponse.contains('health issues') ||
            lowerResponse.contains('brown patches') ||
            lowerResponse.contains('brown spots') ||
            lowerResponse.contains('rot') ||
            lowerResponse.contains('disease') ||
            lowerResponse.contains('trauma') ||
            lowerResponse.contains('damage')) {
          print('🌱 Found strong negative indicator - setting status to issue');
          status = 'issue';
        } else {
          // Count positive and negative indicators
          int positiveCount = positiveIndicators.where((word) => lowerResponse.contains(word)).length;
          int negativeCount = negativeIndicators.where((word) => lowerResponse.contains(word)).length;
          
          print('🌱 Positive indicators found: $positiveCount');
          print('🌱 Negative indicators found: $negativeCount');
          
          // Debug: Show which specific indicators were found
          final foundPositive = positiveIndicators.where((word) => lowerResponse.contains(word)).toList();
          final foundNegative = negativeIndicators.where((word) => lowerResponse.contains(word)).toList();
          print('🌱 Found positive indicators: $foundPositive');
          print('🌱 Found negative indicators: $foundNegative');
          
          // If more positive than negative, plant is healthy
          if (positiveCount > negativeCount) {
            print('🌱 More positive than negative - setting status to ok');
            status = 'ok';
          } else if (negativeCount > 0) {
            print('🌱 Found negative indicators - setting status to issue');
          status = 'issue';
          } else {
            print('🌱 No clear indicators - defaulting to ok');
            status = 'ok'; // Default to healthy if unclear
          }
        }
        
        // Plant Assistant: use AI block if present, else keep heuristic status
        final plantAssistantRaw = recommendations['plant_assistant'];
        final Map<String, dynamic>? plantAssistant = plantAssistantRaw is Map
            ? Map<String, dynamic>.from(plantAssistantRaw as Map)
            : null;
        if (plantAssistant != null && plantAssistant['status'] != null) {
          final paStatus = plantAssistant['status'].toString().toLowerCase();
          if (paStatus == 'issue_detected') status = 'issue';
          else if (paStatus == 'healthy') status = 'ok';
        }
        print('🌱 Health Check Modal: Final status determined: $status');
        print('🌱 Health Check Modal: plant_assistant present: ${plantAssistant != null}');

        // Store structured Plant Assistant JSON for card (no raw API dump)
        final String messageForStorage = plantAssistant != null
            ? jsonEncode(plantAssistant)
            : rawResponse;

        return {
          "status": status,
          "message": messageForStorage,
          "analysisMode": _analysisModeKey,
          "plant_assistant": plantAssistant,
          "plant_size": plantSize,
          "pot_size": potSize,
          "growth_stage": growthStage,
          "moisture_level": moistureLevel,
          "light": light,
          "care_tips": careTips,
          "interesting_facts": interestingFacts,
          "amount_ml": wateringAmountMl,
          "range_ml": wateringRangeMl,
          "next_after_watering_in_hours": nextAfterWateringHours,
          "next_check_in_hours": nextCheckHours,
          "mode": wateringMode,
          "watering_amount": wateringAmountText,
          "watering_interval_days": wateringIntervalDays,
          "should_water_now": shouldWaterNow,
          "reason_short": reasonShort,
          "agent": agentInfo,
        };
      } else {
        throw Exception('Firebase Function failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Firebase Function call failed: $e');
      // Fallback to mock response if API fails
      return {
        "status": "issue",
        "analysisMode": _analysisModeKey,
        "message": "Something went wrong. Please try analyzing the plant's health again."
      };
    }
  }

  /// Fallback method to analyze text for health status
  /// This is used only if the direct GPT health assessment fails
  String _analyzeTextForHealthStatus(String message) {
    print('🌱 Fallback: Analyzing text for health status...');
    
    final lowerMessage = message.toLowerCase();
    
    // Strong positive indicators (about actual plant condition)
    final strongPositiveIndicators = [
      'shows healthy', 'looking healthy', 'appears healthy', 'is healthy',
      'plant is thriving', 'plant looks great', 'doing well', 'in great shape',
      'robust growth', 'vibrant and healthy', 'healthy growth'
    ];
    
    // Check for strong positive indicators first
    for (final indicator in strongPositiveIndicators) {
      if (lowerMessage.contains(indicator)) {
        print('🌱 Fallback: Found strong positive indicator: "$indicator"');
        return 'ok';
      }
    }
    
    // Moderate positive indicators
    final positiveIndicators = [
      'healthy', 'thriving', 'robust', 'good condition',
      'no problems', 'appears healthy', 'looks good',
      'beautiful', 'flourishing', 'lush', 'vibrant'
    ];

    // Actual problem indicators (about plant condition, not general care advice)
    final problemIndicators = [
      'unhealthy', 'dying', 'dead', 'wilted', 'wilting', 'drooping',
      'not in the best health', 'poor health', 'struggling', 'distressed',
      'falling petals', 'not healthy', 'not thriving', 'not doing well',
      'needs help', 'needs attention', 'requires immediate'
    ];

    // Count indicators
    int positiveCount = 0;
    int problemCount = 0;
    
      for (final indicator in positiveIndicators) {
      if (lowerMessage.contains(indicator)) {
        positiveCount++;
          print('🌱 Fallback: Found positive indicator: "$indicator"');
      }
    }
    
    for (final indicator in problemIndicators) {
      if (lowerMessage.contains(indicator)) {
        problemCount++;
        print('🌱 Fallback: Found problem indicator: "$indicator"');
      }
    }

    // Determine final status based on counts
    if (positiveCount > problemCount) {
      print('🌱 Fallback: Status = OK (positive: $positiveCount, problems: $problemCount)');
      return 'ok';
    } else if (problemCount > 0) {
      print('🌱 Fallback: Status = ISSUE (positive: $positiveCount, problems: $problemCount)');
      return 'issue';
    } else {
      print('🌱 Fallback: Status = OK (default - no strong indicators found)');
      return 'ok'; // Default to ok if unclear
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
              AppLocalizations.of(context)!.uploadPlantPhoto,
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
    final l10n = AppLocalizations.of(context)!;
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
                          l10n.healthCheckTitle,
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
                            l10n.healthCheckUploadHint(widget.plantName),
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
                        onPressed: _showImageSourceDialog,
                        icon: Icon(
                          _selectedImageBytes != null ? Icons.refresh : Icons.upload,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          _selectedImageBytes != null ? l10n.changeImage : l10n.uploadPlantPhoto,
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
                                l10n.imageReadyForAnalysis,
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
                            _isAnalyzing ? l10n.analyzing : l10n.analyzeHealth,
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