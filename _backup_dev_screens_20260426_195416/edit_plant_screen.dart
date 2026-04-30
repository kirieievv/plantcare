import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/botanly_theme.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/image_upload_service.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;
  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _notes;
  late int _frequency;
  bool _saving = false;
  Uint8List? _newImageBytes;
  bool _uploadingImage = false;

  static const _options = [1, 2, 3, 4, 5, 6, 7, 10, 14, 21, 30];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.plant.name);
    _species = TextEditingController(text: widget.plant.species);
    _notes = TextEditingController(text: widget.plant.notes ?? '');
    _frequency =
        widget.plant.wateringIntervalDays ?? widget.plant.wateringFrequency;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _newImageBytes = bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: BotanlyColors.red));
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = widget.plant.imageUrl;

      if (_newImageBytes != null) {
        setState(() => _uploadingImage = true);
        imageUrl = await ImageUploadService()
            .uploadPlantImageFromBytes(_newImageBytes!, _name.text.trim());
        setState(() => _uploadingImage = false);
      }

      final updated = widget.plant.copyWith(
        name: _name.text.trim(),
        species: _species.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        wateringFrequency: _frequency,
        wateringIntervalDays: _frequency,
        imageUrl: imageUrl,
      );
      await PlantService().updatePlant(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Changes saved',
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss));
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: BotanlyColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, color: BotanlyColors.sage, size: 20),
            const SizedBox(width: 8),
            Text('Edit plant',
                style: GoogleFonts.fraunces(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5,
                  color: BotanlyColors.sage,
                )),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BotanlyColors.sage),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, color: BotanlyColors.sage),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BotanlyColors.sagePale, width: 2),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImage(),
                ),
                if (_uploadingImage)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xB31B2A18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.upload, size: 16),
              label: Text('Change image',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: BotanlyColors.sage,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 4,
                shadowColor: BotanlyColors.sage.withOpacity(.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Field(
            label: 'Plant name',
            required: true,
            child: TextField(
              controller: _name,
              decoration:
                  _inputDecoration('Plant name', Icons.eco_outlined),
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: BotanlyColors.ink),
            ),
          ),
          const SizedBox(height: 18),
          _Field(
            label: 'Species',
            child: TextField(
              controller: _species,
              decoration: _inputDecoration(
                  'e.g. Iris germanica', Icons.category_outlined),
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: BotanlyColors.ink),
            ),
          ),
          const SizedBox(height: 18),
          _Field(
            label: 'Watering frequency',
            required: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: BotanlyColors.line, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.water_drop_outlined,
                      color: BotanlyColors.sage, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _options.contains(_frequency)
                          ? _frequency
                          : _options.first,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: GoogleFonts.dmSans(
                          fontSize: 14.5, color: BotanlyColors.ink),
                      onChanged: (v) =>
                          setState(() => _frequency = v ?? _frequency),
                      items: _options
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                    'Every $d ${d == 1 ? 'day' : 'days'}'),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Field(
            label: 'Notes',
            child: TextField(
              controller: _notes,
              maxLines: 3,
              decoration:
                  _inputDecoration('Notes', Icons.note_outlined, alignTop: true),
              style: GoogleFonts.dmSans(
                  fontSize: 14.5, color: BotanlyColors.ink),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Saving…' : 'Save changes',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _saving ? const Color(0xFFCDD5CB) : BotanlyColors.sage,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: _saving ? 0 : 4,
                shadowColor: BotanlyColors.sage.withOpacity(.32),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_newImageBytes != null) {
      return Image.memory(_newImageBytes!, fit: BoxFit.cover,
          width: 200, height: 200);
    }
    if (widget.plant.imageUrl != null) {
      return Image.network(widget.plant.imageUrl!, fit: BoxFit.cover,
          width: 200, height: 200,
          errorBuilder: (_, __, ___) => _gradientPlaceholder());
    }
    return _gradientPlaceholder();
  }

  Widget _gradientPlaceholder() => Container(
        width: 200,
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFBCD4B5), Color(0xFF5E7B58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon,
      {bool alignTop = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        color: BotanlyColors.inkMute,
        fontWeight: FontWeight.w300,
      ),
      prefixIcon: Padding(
        padding: EdgeInsets.only(top: alignTop ? 14 : 0, left: 4, right: 0),
        child: Icon(icon, color: BotanlyColors.sage, size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BotanlyColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BotanlyColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BotanlyColors.sage, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _Field(
      {required this.label, this.required = false, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Text(label.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                    color: BotanlyColors.inkMute,
                  )),
              if (required)
                Text(' *',
                    style: GoogleFonts.dmSans(
                      color: BotanlyColors.red,
                      fontWeight: FontWeight.w700,
                    )),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
