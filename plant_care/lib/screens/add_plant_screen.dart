import 'package:flutter/material.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/chatgpt_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

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



  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Add Photo',
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
      
      // Convert bytes to base64 data URL for storage
      final base64String = base64Encode(_selectedImageBytes!);
      final imageUrl = 'data:image/jpeg;base64,$base64String';
      
      // Use AI-determined watering frequency or default to 7 days
      final wateringFreq = _aiWateringFrequency != null 
          ? int.tryParse(_aiWateringFrequency!) ?? 7 
          : 7;
      
      final plant = Plant(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        species: '', // Remove species field
        imageUrl: imageUrl,
        lastWatered: DateTime.now(),
        nextWatering: DateTime.now().add(Duration(days: wateringFreq)),
        wateringFrequency: wateringFreq,
        notes: '', // Remove notes field
        createdAt: DateTime.now(),
        userId: user.uid,
        aiGeneralDescription: _aiGeneralDescription,
        aiName: _aiName,
        aiMoistureLevel: _aiMoistureLevel,
        aiLight: _aiLight,
        aiSpecificIssues: _aiSpecificIssues,
        aiCareTips: _aiCareTips,
      );

      await PlantService().addPlant(plant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant added successfully! 🌱'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Plant', style: AppTheme.headingMedium.copyWith(color: AppTheme.white)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryGreen, AppTheme.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Plant Name - Moved above photo upload
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: AppTheme.inputDecoration(
                      labelText: 'Plant Name *',
                      hintText: 'e.g., Monstera, Snake Plant',
                      prefixIcon: Icons.local_florist,
                    ),
                    style: AppTheme.bodyLarge,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a plant name';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Plant Image Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    children: [
                      // Section Title
                      Text(
                        'Plant Image',
                        style: AppTheme.headingSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Image Display Area
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: AppTheme.lightGreen,
                            width: 2,
                          ),
                          color: AppTheme.lightGrey,
                        ),
                        child: _selectedImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholderImage();
                                      },
                                    ),
                                  ),
                                  if (_isAnalyzing)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              strokeWidth: 3,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Analyzing...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
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
                      
                      const SizedBox(height: 20),
                      
                      // Upload Button - Centered
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_rounded, size: 20),
                          label: Text(
                            'Upload Photo',
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                          ),
                          style: AppTheme.primaryButtonStyle,
                        ),
                      ),
                      
                      // Remove Button (only show when image is uploaded)
                      if (_selectedImageBytes != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImageBytes = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(
                              'Remove Photo',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.red.shade600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                      

                    ],
                  ),
                ),
              ),
              
                            // AI-Determined Watering Schedule
              if (_aiWateringFrequency != null) ...[
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
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
                                _formatWateringFrequency(_aiWateringFrequency),
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
                        
                        // Watering Amount
                        Row(
                          children: [
                            Icon(Icons.opacity, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aiWateringAmount ?? 'Until soil is moist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Soil Moisture Level
                        Row(
                          children: [
                            Icon(Icons.water_drop, color: Colors.blue.shade600, size: 20),
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
                                    _formatMoistureLevel(_aiMoistureLevel),
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
              ] else ...[
                // Default Watering Info (when AI hasn't analyzed yet)
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.water_drop, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Text(
                              'Watering Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          'Upload a plant photo to get AI-recommended watering schedule',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              

              
              // AI Recommendations Section
                                      if (_aiGeneralDescription != null || _isAnalyzing) ...[
                const SizedBox(height: 24),
                
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                color: _refreshStatus == 'success' 
                                    ? Colors.green.shade100 
                                    : _refreshStatus == 'error' 
                                        ? Colors.orange.shade100 
                                        : Colors.grey.shade100,
                                border: Border.all(
                                  color: _refreshStatus == 'success' 
                                      ? Colors.green.shade300 
                                      : _refreshStatus == 'error' 
                                          ? Colors.orange.shade300 
                                          : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                                                        Icon(
                                        _refreshStatus == 'success' 
                                            ? Icons.check_circle
                                            : _refreshStatus == 'error' 
                                                ? Icons.info
                                                : Icons.info,
                                        color: _refreshStatus == 'success' 
                                            ? Colors.green.shade600 
                                            : _refreshStatus == 'error' 
                                                ? Colors.orange.shade600 
                                                : Colors.grey.shade600,
                                        size: 16,
                                      ),
                                  const SizedBox(width: 6),
                                                                        Text(
                                        _refreshStatus == 'success' 
                                            ? 'AI Ready'
                                            : _refreshStatus == 'error' 
                                                ? 'Using Fallback'
                                                : 'No AI Available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _refreshStatus == 'success' 
                                              ? Colors.green.shade600 
                                              : _refreshStatus == 'error' 
                                                  ? Colors.orange.shade600 
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Test API Button
                            IconButton(
                              onPressed: _testApiConnection,
                              icon: const Icon(Icons.bug_report),
                              tooltip: 'Test API Connection',
                              color: Colors.blue.shade600,
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Refresh Button
                            IconButton(
                              onPressed: _isRefreshing ? null : _refreshAnalysis,
                              icon: _isRefreshing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              tooltip: 'Refresh AI Analysis',
                              color: Colors.purple.shade600,
                            ),
                          ],
                        ),
                        
                        if (_isAnalyzing) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Analyzing your plant...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_aiGeneralDescription != null) ...[
                          const SizedBox(height: 20),
                          
                          // Plant Name and Description
                          if (_aiName != null) ...[
                            _buildRecommendationRow('Plant Name', _aiName!),
                            const SizedBox(height: 16),
                          ],
                          
                          _buildRecommendationRow('Description', _aiGeneralDescription!),
                          
                          const SizedBox(height: 16),
                          
                                                          // Care Details Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCareCard(
                                        'Moisture',
                                        _aiMoistureLevel ?? 'Not specified',
                                        Icons.opacity,
                                        Colors.green,
                                        moisturePercentage: _getMoisturePercentage(_aiMoistureLevel),
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
                          
                          // Specific Issues
                          if (_aiSpecificIssues != null) ...[
                            _buildRecommendationRow('Specific Issues', _aiSpecificIssues!),
                            const SizedBox(height: 16),
                          ],
                          
                          if (_aiCareTips != null) ...[
                            const SizedBox(height: 20),
                            
                            // Check if this is a fallback response (analysis failed)
                            if (_aiName == 'Upload New Photo' || _aiName == 'Photo Quality Issue' || _aiGeneralDescription!.contains('parsing issue') || _aiGeneralDescription!.contains('temporarily unavailable') || _aiGeneralDescription!.contains('Photo quality issue')) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                        const SizedBox(width: 8),
                                                                        Text(
                                  _aiName == 'Photo Quality Issue' ? 'Photo Quality Issue Detected' : 'Analysis Issue Detected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _aiName == 'Photo Quality Issue' 
                                    ? 'The photo is unclear or poorly lit for AI analysis. Please upload a new, clearer photo with better lighting and focus.'
                                    : 'The AI analysis encountered an issue. Please upload a new, clearer plant photo for better results.',
                                      style: TextStyle(
                                        color: Colors.orange.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Clear current image and prompt for new upload
                                          setState(() {
                                            _selectedImageBytes = null;
                                            _aiGeneralDescription = null;
                                            _aiName = null;
                                            _aiMoistureLevel = null;
                                            _aiLight = null;
                                            _aiSpecificIssues = null;
                                            _aiCareTips = null;
                                            _aiWateringFrequency = null;
                                            _aiWateringAmount = null;
                                          });
                                        },
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('Upload New Photo'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
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
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _aiCareTips!,
                                    style: TextStyle(
                                      color: Colors.purple.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Add Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addPlant,
                  style: AppTheme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                          ),
                        )
                      : Text(
                          'Add Plant',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 