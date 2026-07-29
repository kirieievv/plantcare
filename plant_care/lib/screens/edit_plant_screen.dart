import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_cabinet_kit.dart';

/// Edit plant — UI from `Botanly /screens/edit_plant_screen.html`. Logic
/// preserved from the production version: name/species/notes/frequency
/// editing, image picking with web base64 support, save via PlantService.
class EditPlantScreen extends StatefulWidget {
  final Plant plant;

  const EditPlantScreen({super.key, required this.plant});

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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
      setState(() => _isImageLoading = true);

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          setState(() {
            _imagePath = 'data:image/jpeg;base64,$base64String';
            _imageFile = null;
          });
        } else {
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
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: BotanlyColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImageLoading = false);
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _plant.imageUrl;
      if (_imagePath != null &&
          _imagePath!.startsWith('data:image') &&
          _imagePath != _plant.imageUrl) {
        imageUrl = _imagePath;
      }

      final updatedPlant = _plant.copyWith(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        wateringFrequency: _wateringFrequency,
        imageUrl: imageUrl,
      );

      await PlantService().updatePlant(updatedPlant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plantUpdatedSuccessfully),
            backgroundColor: BotanlyColors.sage,
          ),
        );
        Navigator.pop(context, updatedPlant);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorUpdatingPlant(e.toString())),
            backgroundColor: BotanlyColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────── Build ───────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    _buildImageBlock(),
                    const SizedBox(height: 18),
                    _buildField(
                      label: l10n.plantName,
                      required: true,
                      icon: Icons.local_florist_outlined,
                      child: TextFormField(
                        controller: _nameController,
                        style: _inputStyle(),
                        cursorColor: BotanlyColors.sage,
                        decoration: _inputDecoration(l10n.plantName),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.pleaseEnterPlantName;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      label: l10n.species,
                      icon: Icons.hub_outlined,
                      child: TextFormField(
                        controller: _speciesController,
                        style: _inputStyle(),
                        cursorColor: BotanlyColors.sage,
                        decoration: _inputDecoration('e.g. Iris germanica'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      label: l10n.wateringFrequency,
                      required: true,
                      icon: Icons.water_drop_outlined,
                      child: _buildFrequencyDropdown(),
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      label: l10n.notes,
                      icon: Icons.description_outlined,
                      area: true,
                      child: TextFormField(
                        controller: _notesController,
                        style: _inputStyle(),
                        cursorColor: BotanlyColors.sage,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _inputDecoration(l10n.notes),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── App bar ───────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EBE1))),
      ),
      child: Row(
        children: [
          _appBarButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_florist_outlined,
                      size: 20, color: BotanlyColors.sage),
                  const SizedBox(width: 8),
                  Text(
                    'BOTANLY',
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: BotanlyColors.sage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _appBarButton(
            Icons.save_outlined,
            _isLoading ? null : _savePlant,
            loading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _appBarButton(IconData icon, VoidCallback? onTap,
      {bool loading = false}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(BotanlyColors.sage),
                    ),
                  )
                : Icon(icon, size: 20, color: BotanlyColors.sage),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Image block ───────────────────────

  Widget _buildImageBlock() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: BotanlyColors.sagePale, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFBCD4B5), Color(0xFF5E7B58)],
              ),
            ),
            child: _isImageLoading
                ? Container(
                    color: const Color(0xFFEBEBEB),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(BotanlyColors.sage),
                    ),
                  )
                : _buildImageDisplay(),
          ),
          const SizedBox(height: 14),
          _buildChangeImageButton(),
        ],
      ),
    );
  }

  Widget _buildChangeImageButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: BotanlyColors.sage,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D5FA346),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isImageLoading ? null : _pickImage,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.changeImage,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      if (_imagePath!.startsWith('data:image')) {
        try {
          final parts = _imagePath!.split(',');
          if (parts.length > 1) {
            final bytes = base64Decode(parts[1]);
            return Image.memory(bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildPlaceholderImage());
          }
        } catch (_) {}
      } else if (_imagePath!.startsWith('http')) {
        return Image.network(_imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage());
      } else if (_imageFile != null && !kIsWeb) {
        try {
          return Image.file(_imageFile!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderImage());
        } catch (_) {
          return _buildPlaceholderImage();
        }
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(Icons.add_a_photo_outlined,
          size: 56, color: Colors.white),
    );
  }

  // ─────────────────────── Field ───────────────────────

  Widget _buildField({
    required String label,
    required IconData icon,
    required Widget child,
    bool required = false,
    bool area = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text.rich(
            TextSpan(
              text: label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: BotanlyColors.inkMute,
              ),
              children: required
                  ? [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BotanlyColors.red,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 14, vertical: area ? 14 : 0),
          constraints: BoxConstraints(minHeight: area ? 0 : 52),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: const Color(0xFFE4EBE1), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment:
                area ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: area ? 2 : 0, right: 10),
                child: Icon(icon, size: 18, color: BotanlyColors.sage),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    final defaults = [1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 30];
    final allValues = {_wateringFrequency, ...defaults}.toList()..sort();
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        isExpanded: true,
        value: allValues.contains(_wateringFrequency)
            ? _wateringFrequency
            : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 20, color: BotanlyColors.inkMute),
        style: _inputStyle(),
        dropdownColor: Colors.white,
        items: allValues
            .map(
              (d) => DropdownMenuItem(
                value: d,
                child: Text(l10n.everyNDays(d)),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _wateringFrequency = v);
        },
      ),
    );
  }

  TextStyle _inputStyle() => GoogleFonts.dmSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1B2A18),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        isCollapsed: true,
        filled: false,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w300,
          color: BotanlyColors.inkMute,
        ),
      );

  // ─────────────────────── Save button ───────────────────────

  Widget _buildSaveButton() {
    return BotanlyPrimaryButton(
      label: _isLoading ? l10n.saving : l10n.saveChanges,
      icon: _isLoading ? null : Icons.save_outlined,
      loading: _isLoading,
      onPressed: _isLoading ? null : _savePlant,
      height: 54,
      radius: 14,
    );
  }
}
