import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/botanly_theme.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';
import '../services/image_upload_service.dart';
import 'plant_details_screen.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _name = TextEditingController(text: '');
  Uint8List? _imageBytes;
  bool _analyzing = false;
  bool _showSpecies = false;
  bool _loadingPlan = false;
  bool _showResults = false;
  bool _saving = false;

  List<Map<String, dynamic>> _candidates = [];
  String _commonName = '';
  String _latinName = '';

  // AI care data
  String? _aiGeneralDescription;
  String? _aiName;
  String? _aiMoistureLevel;
  String? _aiLight;
  String? _aiCareTips;
  String? _aiSpecificIssues;
  String? _aiWateringAmount;
  int? _wateringAmountMl;
  List<int>? _wateringRangeMl;
  int? _nextAfterWateringHours;
  int? _nextCheckHours;
  String? _wateringMode;
  int? _nextWateringInDays;
  bool _shouldWaterNow = false;
  List<String>? _interestingFacts;
  String? _aiPlantSize;
  String? _aiPotSize;
  String? _aiGrowthStage;

  static const _pool = [
    'Iris', 'Verdi', 'Sprout', 'Mossy', 'Fern', 'Pip', 'Petal', 'Clover',
    'Sage', 'Olive', 'Mint', 'Basil', 'Rosemary', 'Thyme', 'Lavender', 'Ivy',
    'Willow', 'Maple', 'Jade', 'Bamboo', 'Palm', 'Bloom', 'Flora', 'Buddy',
  ];

  static const _cloudFnUrl =
      'https://us-central1-plant-care-dev-0001.cloudfunctions.net/analyzePlantPhoto';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _randomName() {
    final r = Random();
    String pick;
    do {
      pick = _pool[r.nextInt(_pool.length)];
    } while (pick == _name.text);
    _name.text = pick;
  }

  Future<void> _uploadPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _analyzing = true;
        _showSpecies = false;
        _showResults = false;
        _candidates = [];
      });
      await _analyze(bytes);
    } catch (e) {
      if (!mounted) return;
      _showError('Could not pick image: $e');
    }
  }

  Future<void> _analyze(Uint8List bytes, {String? hint}) async {
    setState(() => _analyzing = true);
    try {
      final body = <String, dynamic>{
        'base64Image': base64Encode(bytes),
      };
      if (hint != null) body['userHint'] = hint;

      final response = await http.post(
        Uri.parse(_cloudFnUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('API error ${response.statusCode}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['step'] == 'identification') {
        final candidates =
            (result['speciesCandidates'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        setState(() {
          _candidates = candidates;
          _showSpecies = true;
          _analyzing = false;
        });
        return;
      }

      _applyRecommendations(result['recommendations'] ?? {});
    } catch (e) {
      if (!mounted) return;
      _showError('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _applyRecommendations(Map<String, dynamic> r) {
    final wateringPlan = r['watering_plan'] as Map<String, dynamic>? ?? {};
    final nextDays = wateringPlan['next_watering_in_days'];

    setState(() {
      _aiGeneralDescription = r['general_description'];
      _aiName = r['name'];
      _aiMoistureLevel = r['moisture_level'];
      _aiLight = r['light'];
      _aiCareTips = r['care_tips'];
      _aiSpecificIssues = r['specific_issues'];
      _aiWateringAmount = r['watering_amount'];
      _interestingFacts = (r['interesting_facts'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      _aiPlantSize = r['plant_size'];
      _aiPotSize = r['pot_size'];
      _aiGrowthStage = r['growth_stage'];
      _wateringAmountMl =
          wateringPlan['amount_ml'] ?? r['amount_ml'];
      _wateringRangeMl = r['range_ml'] != null
          ? List<int>.from(r['range_ml'])
          : null;
      _nextAfterWateringHours = r['next_after_watering_in_hours'];
      _nextCheckHours = r['next_check_in_hours'];
      _wateringMode = r['mode'];
      _nextWateringInDays =
          nextDays != null ? int.tryParse(nextDays.toString()) : null;
      _shouldWaterNow = wateringPlan['should_water_now'] == true;
      _showResults = true;
    });
  }

  Future<void> _pickSpecies(String common, String latin) async {
    setState(() {
      _commonName = common;
      _latinName = latin;
      _showSpecies = false;
      _loadingPlan = true;
    });

    try {
      if (_imageBytes != null) {
        await _analyze(_imageBytes!, hint: common);
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _addPlant() async {
    if (!_showResults || _imageBytes == null) return;
    if (_name.text.trim().isEmpty) {
      _showError('Please enter a name for your plant');
      return;
    }
    setState(() => _saving = true);
    try {
      // Upload image to Firebase Storage
      final imageUrl = await ImageUploadService()
          .uploadPlantImageFromBytes(_imageBytes!, _name.text.trim());

      final now = DateTime.now();
      final frequency = _nextWateringInDays ?? 7;
      final nextWatering = now.add(Duration(days: frequency));

      final plant = Plant(
        id: '',
        name: _name.text.trim(),
        species: _latinName.isNotEmpty ? _latinName : (_aiName ?? 'Unknown'),
        imageUrl: imageUrl,
        lastWatered: now,
        nextWatering: nextWatering,
        wateringFrequency: frequency,
        createdAt: now,
        aiGeneralDescription: _aiGeneralDescription,
        aiName: _aiName,
        aiMoistureLevel: _aiMoistureLevel,
        aiLight: _aiLight,
        aiCareTips: _aiCareTips,
        aiSpecificIssues: _aiSpecificIssues,
        aiWateringAmount: _aiWateringAmount,
        interestingFacts: _interestingFacts,
        aiPlantSize: _aiPlantSize,
        aiPotSize: _aiPotSize,
        aiGrowthStage: _aiGrowthStage,
        wateringAmountMl: _wateringAmountMl,
        wateringRangeMl: _wateringRangeMl,
        nextAfterWateringHours: _nextAfterWateringHours,
        nextCheckHours: _nextCheckHours,
        wateringMode: _wateringMode,
        wateringIntervalDays: frequency,
        shouldWaterNow: _shouldWaterNow,
        notificationState: 'ok',
      );

      final newId = await PlantService().addPlant(plant);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_name.text.trim()} added to your garden!',
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss));

      // Navigate to new plant's details
      final newPlant = plant.copyWith(id: newId, imageUrl: imageUrl);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlantDetailsScreen(plant: newPlant),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to add plant: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: BotanlyColors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _nameCard(),
            const SizedBox(height: 20),
            _imageCard(),
            const SizedBox(height: 20),
            if (_showSpecies) ...[
              _speciesCard(),
              const SizedBox(height: 20),
            ],
            if (_loadingPlan) ...[
              _loadingCard(),
              const SizedBox(height: 20),
            ],
            if (_showResults) ...[
              _aiResultsCard(),
              const SizedBox(height: 20),
            ],
            _addButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ───────── Name card ─────────

  Widget _nameCard() {
    return _Card(
      icon: Icons.eco_outlined,
      title: 'Plant name',
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: BotanlyColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined,
                        color: BotanlyColors.sage, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          color: BotanlyColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Give your plant a name',
                          hintStyle: GoogleFonts.dmSans(
                            color: BotanlyColors.inkMute,
                            fontWeight: FontWeight.w300,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _randomName,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BotanlyColors.sageSoft,
                  border: Border.all(color: BotanlyColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shuffle, color: BotanlyColors.sage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── Image card ─────────

  Widget _imageCard() {
    return _Card(
      icon: Icons.photo_camera_outlined,
      title: 'Plant image',
      child: Column(
        children: [
          const SizedBox(height: 14),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: BotanlyColors.line, width: 1.5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!,
                          fit: BoxFit.cover, width: 200, height: 200)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                BotanlyColors.sagePale2,
                                BotanlyColors.sageSoft,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_camera_outlined,
                                    color: BotanlyColors.sage, size: 42),
                                const SizedBox(height: 6),
                                Text('Add a photo of your plant',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: BotanlyColors.inkMute,
                                    )),
                              ],
                            ),
                          ),
                        ),
                ),
                if (_analyzing)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xB31B2A18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Analyzing…',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _analyzing ? null : _uploadPhoto,
            icon: const Icon(Icons.upload, size: 17),
            label: Text(
              _imageBytes != null ? 'Change photo' : 'Upload plant photo',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BotanlyColors.sage,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 4,
              shadowColor: BotanlyColors.sage.withOpacity(.3),
            ),
          ),
          if (_imageBytes != null && !_analyzing) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: BotanlyColors.sageSoft,
                border: Border.all(color: BotanlyColors.sagePale),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: BotanlyColors.sage),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Photo uploaded — analysis complete',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BotanlyColors.sageDark,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────── Species card ─────────

  Widget _speciesCard() {
    return _Card(
      icon: Icons.search,
      title: 'Is this your plant?',
      subtitle: 'We found ${_candidates.length} likely matches — pick the closest one.',
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          children: [
            ..._candidates.asMap().entries.map((e) {
              final c = e.value;
              final name = c['commonName'] ?? c['name'] ?? 'Unknown';
              final latin = c['latinName'] ?? c['species'] ?? '';
              final hint = c['description'] ?? c['hint'] ?? '';
              final pct =
                  c['confidence'] != null ? '${c['confidence']}%' : '—';
              return Padding(
                padding: EdgeInsets.only(
                    bottom: e.key < _candidates.length - 1 ? 10 : 0),
                child: _speciesRow(name, latin, hint, pct),
              );
            }),
            if (_candidates.isEmpty)
              TextButton(
                onPressed: () => _pickSpecies('Unknown plant', ''),
                child: Text('Continue anyway',
                    style: GoogleFonts.dmSans(
                      color: BotanlyColors.sage,
                      fontWeight: FontWeight.w600,
                    )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _speciesRow(
      String common, String latin, String hint, String pct) {
    return InkWell(
      onTap: () => _pickSpecies(common, latin),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BotanlyColors.sagePale.withOpacity(.18),
          border: Border.all(color: BotanlyColors.sagePale, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA7C59E), Color(0xFF5E7B58)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(common,
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: BotanlyColors.moss,
                      )),
                  if (latin.isNotEmpty)
                    Text(latin,
                        style:
                            BotanlyText.latin().copyWith(fontSize: 12)),
                  if (hint.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(hint,
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w300,
                          color: BotanlyColors.inkMute,
                          height: 1.35,
                        )),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pct,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BotanlyColors.sage,
                    )),
                Text('MATCH',
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      letterSpacing: .4,
                      color: BotanlyColors.inkMute,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────── Loading card ─────────

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BotanlyShadows.card,
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: BotanlyColors.sage,
            ),
          ),
          const SizedBox(height: 12),
          Text('Building your care plan…',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.moss,
              )),
          const SizedBox(height: 4),
          Text(
              'Pulling watering, light, soil and temperature recommendations',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w300,
                color: BotanlyColors.inkMute,
              )),
        ],
      ),
    );
  }

  // ───────── AI results card ─────────

  Widget _aiResultsCard() {
    final waterDays = _nextWateringInDays ?? 7;
    final mlText = _wateringAmountMl != null ? '~$_wateringAmountMl ml' : '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BotanlyColors.sagePale),
        borderRadius: BorderRadius.circular(20),
        boxShadow: BotanlyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: BotanlyColors.sagePale2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: BotanlyColors.sage, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('AI Care Recommendations',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.moss,
                      letterSpacing: -.3,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: BotanlyColors.sagePale2,
                  border: Border.all(
                      color: BotanlyColors.sagePale, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check,
                        size: 13, color: BotanlyColors.sage),
                    const SizedBox(width: 5),
                    Text('AI Ready',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: BotanlyColors.sageDark,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_commonName.isNotEmpty)
            Text(_commonName,
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: BotanlyColors.moss,
                  letterSpacing: -.4,
                )),
          if (_latinName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_latinName, style: BotanlyText.latin()),
          ],
          if (_aiGeneralDescription != null) ...[
            const SizedBox(height: 12),
            Text(_aiGeneralDescription!, style: BotanlyText.body()),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _statTile(
                _aiMoistureLevel ?? 'Moist',
                'Soil moisture',
                Icons.opacity,
                BotanlyColors.sage,
                BotanlyColors.sageSoft,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(
                _aiLight ?? '—',
                'Light / day',
                Icons.wb_sunny_outlined,
                BotanlyColors.amber,
                BotanlyColors.amberPale,
              )),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BotanlyColors.bluePale,
              border: Border.all(color: const Color(0xFFCADFEE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Text('Watering frequency',
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: BotanlyColors.blue,
                        letterSpacing: -.2,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    'Every $waterDays day${waterDays == 1 ? '' : 's'}${mlText.isNotEmpty ? ' · $mlText' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: BotanlyColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
      String value, String label, IconData icon, Color iconColor, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bg.withOpacity(.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                letterSpacing: .3,
                color: BotanlyColors.inkMute,
              )),
        ],
      ),
    );
  }

  // ───────── Add button ─────────

  Widget _addButton() {
    final enabled = _showResults && !_saving;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? _addPlant : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? BotanlyColors.sage : const Color(0xFFCDD5CB),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: enabled ? 4 : 0,
          shadowColor: BotanlyColors.sage.withOpacity(.4),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text('Add plant',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: .2,
                )),
      ),
    );
  }
}

// ────────────────────── Reusable card shell ──────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BotanlyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: BotanlyColors.sagePale,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: BotanlyColors.sage, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: BotanlyColors.moss,
                      letterSpacing: -.3,
                    )),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  color: BotanlyColors.inkMute,
                )),
          ],
          child,
        ],
      ),
    );
  }
}
