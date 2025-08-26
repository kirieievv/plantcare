import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import 'dart:io';
import 'dart:convert';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;

  const EditPlantScreen({Key? key, required this.plant}) : super(key: key);

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _notesController = TextEditingController();
  
  late int _wateringFrequency;
  late Plant _plant;
  bool _isLoading = false;
  bool _isImageLoading = false;
  String? _imagePath;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _nameController.text = _plant.name;
    _speciesController.text = _plant.species;
    _notesController.text = _plant.notes ?? '';
    _wateringFrequency = _plant.wateringFrequency;
    _imagePath = _plant.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // For web, we need to handle this differently
        if (kIsWeb) {
          // Convert to base64 immediately for web
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          print('Image picked, converted to base64, length: ${base64String.length}');
          setState(() {
            _imagePath = 'data:image/jpeg;base64,$base64String';
            _imageFile = null; // Don't store file on web
          });
        } else {
          // For mobile, use file
          setState(() {
            _imageFile = File(image.path);
            _imagePath = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _plant.imageUrl;
      
      // If a new image was picked, use the base64 string we already created
      if (_imagePath != null && _imagePath!.startsWith('data:image') && _imagePath != _plant.imageUrl) {
        imageUrl = _imagePath;
      }

      final updatedPlant = _plant.copyWith(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        wateringFrequency: _wateringFrequency,
        imageUrl: imageUrl,
      );

      await PlantService().updatePlant(updatedPlant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant updated successfully! 🌱'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedPlant);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating plant: $e'),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.accentGreen,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _savePlant,
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant Image
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _isImageLoading 
                        ? _buildLoadingImage()
                        : _buildSimpleImageDisplay(),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_rounded, size: 20),
                  label: const Text(
                    'Change Image',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Plant Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_florist),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plant name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Species
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Watering Frequency
              DropdownButtonFormField<int>(
                value: _wateringFrequency,
                decoration: const InputDecoration(
                  labelText: 'Watering Frequency *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop),
                ),
                items: List.generate(30, (index) => index + 1)
                    .map((days) => DropdownMenuItem(
                          value: days,
                          child: Text('Every $days day${days == 1 ? '' : 's'}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _wateringFrequency = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value < 1) {
                    return 'Please select watering frequency';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _savePlant,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildSimpleImageDisplay() {
    // Show image based on _imagePath (which now contains base64 for web)
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      if (_imagePath!.startsWith('data:image')) {
        // Base64 image (works on both web and mobile)
        try {
          final parts = _imagePath!.split(',');
          if (parts.length > 1) {
            final bytes = base64Decode(parts[1]);
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            );
          }
        } catch (e) {
          // Fall through to placeholder
        }
      } else if (_imagePath!.startsWith('http')) {
        // Network image
        return Image.network(
          _imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else if (_imageFile != null && !kIsWeb) {
        // File image (mobile only)
        try {
          return Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }
    }
    
    return _buildPlaceholderImage();
  }

  



  Widget _buildLoadingImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading image...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.add_a_photo,
        size: 60,
        color: Colors.grey,
      ),
    );
  }
} 