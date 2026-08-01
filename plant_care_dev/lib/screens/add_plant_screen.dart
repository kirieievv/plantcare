import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/utils/app_theme.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/utils/responsive_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:plant_care/l10n/app_localizations.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plant_care/screens/paywall_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/services/plant_service.dart' show PlantService;
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/widgets/subscription_banner.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/widgets/botanly_shimmer.dart';
import 'package:plant_care/utils/web_file_picker.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:plant_care/utils/care_sections.dart';

Map<String, dynamic>? _asStringKeyedMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

String? _safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.trim().isEmpty ? null : v.trim();
  if (v is Map || v is List) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String? _firstNonEmptyString(Iterable<dynamic?> values) {
  for (final v in values) {
    if (v == null) continue;
    if (v is Map || v is List) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

/// Builds the care_tips blob from nested `care_recommendations` (mirrors
/// `transformNewJsonToLegacy` in Cloud Functions when the client receives
/// nested JSON without a flat `care_tips` field).
String? _composeCareTipsFromCareMap(Map<String, dynamic>? care) {
  if (care == null) return null;
  const sourceKeys = <String, String>{
    CareSection.cultivar: 'name',
    CareSection.generalDescription: 'general_description',
    CareSection.soil: 'soil',
    CareSection.soilMoisture: 'moisture',
    CareSection.moistureCheck: 'moisture_check_tip',
    CareSection.water: 'water',
    CareSection.light: 'light',
    CareSection.temperature: 'temperature',
    CareSection.fertilizer: 'fertilizer',
    CareSection.growthRate: 'growth_rate',
    CareSection.toxicity: 'toxicity',
    CareSection.placement: 'placement',
    CareSection.personality: 'personality',
  };
  final sections = sourceKeys.map(
    (section, key) => MapEntry(section, care[key]?.toString().trim()),
  );
  return composeCareTips(
    sections,
    LanguageService.localeNotifier.value.languageCode,
  );
}

/// Flattens `analyzePlantPhoto` payloads so the UI always reads the same keys
/// whether the backend sent legacy flat fields or nested `care_recommendations`.
Map<String, dynamic> _coerceAnalyzeRecommendationsMap(dynamic raw) {
  if (raw == null || raw is! Map) return <String, dynamic>{};
  final rec = Map<String, dynamic>.from(raw as Map);
  final care = _asStringKeyedMap(rec['care_recommendations']);
  final soil = _asStringKeyedMap(rec['soil']) ?? _asStringKeyedMap(rec['soil_data']);
  final wp = _asStringKeyedMap(rec['watering_plan']);
  final species = _asStringKeyedMap(rec['species']);

  void setIfEmpty(String key, List<dynamic?> candidates) {
    final cur = rec[key];
    final empty = cur == null || cur.toString().trim().isEmpty;
    if (!empty) return;
    final v = _firstNonEmptyString(candidates);
    if (v != null) rec[key] = v;
  }

  if (care != null) {
    setIfEmpty('general_description', [
      rec['general_description'],
      care['general_description'],
    ]);
    setIfEmpty('name', [
      rec['name'],
      care['name'],
      species?['ai_species_guess'],
    ]);
    setIfEmpty('moisture_level', [rec['moisture_level'], care['moisture']]);
    setIfEmpty('light', [rec['light'], care['light']]);
    setIfEmpty('watering_amount', [rec['watering_amount'], care['water']]);

    // Lift moisture range from care_recommendations to top level
    if (rec['ideal_soil_moisture_min'] == null && care['ideal_soil_moisture_min'] != null) {
      rec['ideal_soil_moisture_min'] = care['ideal_soil_moisture_min'];
    }
    if (rec['ideal_soil_moisture_max'] == null && care['ideal_soil_moisture_max'] != null) {
      rec['ideal_soil_moisture_max'] = care['ideal_soil_moisture_max'];
    }

    // Always rebuild care_tips from structured JSON so labels use the user's language.
    // This overwrites any flat English string the Cloud Function may have sent.
    final built = _composeCareTipsFromCareMap(care);
    if (built != null) rec['care_tips'] = built;

    final details = extractCareDetails(care);
    if (details != null) rec['care_details'] = details;
  } else if (species != null) {
    setIfEmpty('name', [rec['name'], species['ai_species_guess']]);
  }

  setIfEmpty('general_description', [
    rec['general_description'],
    rec['health_assessment'],
  ]);

  final pa = _asStringKeyedMap(rec['plant_assistant']);
  if (pa != null) {
    setIfEmpty('general_description', [
      rec['general_description'],
      pa['health_summary'],
      pa['problem_description'],
      pa['praise_phrase'],
    ]);
    final steps = pa['action_steps'];
    if (steps is List && steps.isNotEmpty) {
      final existingTips = rec['care_tips']?.toString().trim();
      if (existingTips == null || existingTips.isEmpty) {
        final joined = steps
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .join('\n');
        if (joined.isNotEmpty) rec['care_tips'] = joined;
      }
    }
  }

  setIfEmpty('moisture_level', [
    rec['moisture_level'],
    soil != null && soil['moisture_current_pct'] != null
        ? '${soil['moisture_current_pct']}%'
        : null,
  ]);

  if (wp != null && wp['next_watering_in_days'] != null) {
    final cur = rec['watering_frequency'];
    final empty = cur == null || cur.toString().trim().isEmpty;
    if (empty) {
      rec['watering_frequency'] = wp['next_watering_in_days'].toString();
    }
  }

  final issues = rec['specific_issues'];
  if (issues is List) {
    final joined = issues
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .join('\n');
    rec['specific_issues'] =
        joined.isEmpty ? 'No specific issues detected' : joined;
  } else if (issues == null ||
      (issues is String && issues.toString().trim().isEmpty)) {
    rec['specific_issues'] = 'No specific issues detected';
  }

  return rec;
}

/// ⚠️ IMPORTANT: AUTOMATIC NAVIGATION FEATURE ⚠️
/// 
/// This screen automatically redirects users to their newly created plant's details page
/// after successful plant creation. This is a key user experience feature that should
/// NOT be removed without careful consideration.
/// 
/// FEATURE DESCRIPTION:
/// - User creates a plant → Success message appears → Automatically redirected to PlantDetailsScreen
/// - Uses Navigator.pushReplacement to prevent accidental return to add plant form
/// - Provides fallback navigation if automatic navigation fails
/// 
/// WHY THIS FEATURE EXISTS:
/// - Better UX: Users see their new plant immediately after creation
/// - No confusion: No need to search for the new plant in a list
/// - Seamless flow: Direct transition from creation to management
/// 
/// IF YOU NEED TO MODIFY THIS BEHAVIOR:
/// 1. Test thoroughly to ensure the change improves user experience
/// 2. Consider adding a user preference option rather than removing the feature
/// 3. Update all related comments and documentation
/// 4. Ensure the change works from all entry points (Dashboard, Bottom Navigation)
/// 
/// RELATED FILES:
/// - dashboard_screen.dart: Simplified navigation logic (relies on this feature)
/// - plant_details_screen.dart: Destination screen for new plants
/// - plant_service.dart: Plant creation service
/// 
/// LAST UPDATED: [Current Date] - Automatic navigation implemented
/// 
class AddPlantScreen extends StatefulWidget {
  /// Called after a plant is successfully added, before navigating to its details.
  /// Use this to switch the parent tab to Home/My Plants so pressing Back
  /// from PlantDetailsScreen returns there instead of to AddPlantScreen.
  final VoidCallback? onPlantAdded;

  const AddPlantScreen({Key? key, this.onPlantAdded}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  bool _nameError = false;
  

  // Slot 0 = whole plant (required), slot 1 = close-up (optional)
  Uint8List? _selectedImageBytes; // kept for legacy compat (= slot 0)
  Uint8List? _slot1ImageBytes;    // close-up photo
  bool _showAnalysisLoader = false; // fullscreen step-loader
  int _loaderInitialStep = 1;       // 1 = normal flow, 2 = from species confirmation
  bool _loaderShowProfileButton = true;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  // Species identification flow
  List<Map<String, dynamic>> _speciesCandidates = [];
  bool _showSpeciesSelection = false;
  bool _showManualInput = false;
  final _manualSpeciesController = TextEditingController();
  String? _confirmedSpecies;
  bool _isFetchingFullAnalysis = false;

  // AI-generated care recommendations
  String? _aiGeneralDescription;
  String? _aiName;
  String? _aiMoistureLevel;
  int? _aiMoistureMin;
  int? _aiMoistureMax;
  String? _aiLight;
  String? _aiWateringFrequency;
  String? _aiWateringAmount;
  String? _aiSpecificIssues;
  String? _aiCareTips;
  Map<String, String>? _careDetails;
  List<String>? _aiInterestingFacts;
  
  // Plant size assessment fields
  String? _aiPlantSize;
  String? _aiPotSize;
  String? _aiGrowthStage;
  
  // Scientific watering calculation fields
  int? _wateringAmountMl;
  List<int>? _wateringRangeMl;
  int? _nextAfterWateringHours;
  int? _nextCheckHours;
  String? _wateringMode;
  int? _nextWateringInDays;
  bool _shouldWaterNow = false; // From AI watering_plan
  
  // Refresh status
  bool _isRefreshing = false;
  String? _refreshStatus = 'error'; // Start with error status since we know API is failing
  
  // Random plant names for name generator
  final List<String> _randomPlantNames = [
    'Fernando', 'Leafy', 'Buddy', 'Sprout', 'Greenie', 'Planty', 'Grower', 'Flora',
    'Verdant', 'Emerald', 'Jade', 'Sage', 'Olive', 'Mint', 'Basil', 'Rosemary',
    'Thyme', 'Lavender', 'Ivy', 'Willow', 'Maple', 'Oak', 'Pine', 'Cedar',
    'Bamboo', 'Palm', 'Cactus', 'Succulent', 'Herb', 'Spice', 'Blossom', 'Bloom',
    'Petunia', 'Daisy', 'Rose', 'Tulip', 'Lily', 'Orchid', 'Sunflower', 'Marigold',
    'Zinnia', 'Pansy', 'Violet', 'Iris', 'Peony', 'Chrysanthemum', 'Dahlia', 'Aster',
    'Cosmos', 'Snapdragon', 'Foxglove', 'Delphinium', 'Larkspur', 'Columbine',
    'Monstera', 'Philodendron', 'Pothos', 'Snake Plant', 'ZZ Plant', 'Fiddle Leaf',
    'Bird of Paradise', 'Elephant Ear', 'Calathea', 'Prayer Plant', 'Alocasia',
    'Anthurium', 'Peace Lily', 'Chinese Evergreen', 'Dracaena', 'Schefflera',
    'Ficus', 'Jade Plant', 'Aloe Vera', 'Haworthia', 'Echeveria', 'Sedum',
    'Crassula', 'Kalanchoe', 'Peperomia', 'Begonia', 'Impatiens', 'Geranium',
    'Coleus', 'Polka Dot Plant', 'Nerve Plant', 'Pilea', 'String of Pearls',
    'String of Hearts', 'Burro\'s Tail', 'Jade Necklace', 'Trailing Jade'
  ];

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// True when the backend returned enough AI fields to render the results card.
  /// Do not require [general_description] alone — the API may send [care_tips],
  /// name, moisture/light, etc. without that key.
  bool get _hasAiResultsToDisplay {
    if (_selectedImageBytes == null) return false;
    final desc = _aiGeneralDescription?.trim();
    if (desc != null && desc.isNotEmpty) return true;
    final tips = _aiCareTips?.trim();
    if (tips != null && tips.isNotEmpty) return true;
    final name = _aiName?.trim();
    if (name != null && name.isNotEmpty) return true;
    if (_aiInterestingFacts != null && _aiInterestingFacts!.isNotEmpty) {
      return true;
    }
    final m = _aiMoistureLevel?.trim();
    if (m != null && m.isNotEmpty) return true;
    final l = _aiLight?.trim();
    if (l != null && l.isNotEmpty) return true;
    final w = _aiWateringFrequency?.trim();
    if (w != null && w.isNotEmpty) return true;
    final days = _nextWateringInDays;
    if (days != null && days > 0) return true;
    final issues = _aiSpecificIssues?.trim();
    if (issues != null && issues.isNotEmpty) return true;
    return false;
  }

  /// Clears AI fields when the user starts a new photo analysis so we never
  /// show recommendations from a previous image/species.
  void _clearAiAnalysisPayload() {
    _showAnalysisLoader = false;
    _aiGeneralDescription = null;
    _aiName = null;
    _aiMoistureLevel = null;
    _aiMoistureMin = null;
    _aiMoistureMax = null;
    _aiLight = null;
    _aiWateringFrequency = null;
    _aiWateringAmount = null;
    _aiSpecificIssues = null;
    _aiCareTips = null;
    _careDetails = null;
    _aiInterestingFacts = null;
    _aiPlantSize = null;
    _aiPotSize = null;
    _aiGrowthStage = null;
    _nextWateringInDays = null;
    _shouldWaterNow = false;
    _wateringAmountMl = null;
    _wateringRangeMl = null;
    _nextAfterWateringHours = null;
    _nextCheckHours = null;
    _wateringMode = null;
    _refreshStatus = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manualSpeciesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateRandomPlantName() {
    final random = Random();
    final randomName = _randomPlantNames[random.nextInt(_randomPlantNames.length)];
    setState(() {
      _nameController.text = randomName;
    });
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  /// Pick image for a specific slot (0 = whole plant, 1 = close-up).
  /// Does NOT auto-start analysis — user taps Analyze Plant button.
  Future<void> _pickImageForSlot(int slot) async {
    if (_isMobile) {
      await _showImageSourceSheetForSlot(slot);
    } else {
      final bytes = await pickCenteredImageFromWeb();
      if (bytes != null && mounted) {
        setState(() {
          if (slot == 0) _selectedImageBytes = bytes;
          else _slot1ImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _showImageSourceSheetForSlot(int slot) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImageFromSourceForSlot(ImageSource.camera, slot);
            },
            child: Text(l10n.camera),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImageFromSourceForSlot(ImageSource.gallery, slot);
            },
            child: Text(l10n.gallery),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Future<void> _pickImageFromSourceForSlot(ImageSource source, int slot) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            if (slot == 0) _selectedImageBytes = bytes;
            else _slot1ImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Legacy single-slot entry point — kept for internal callers that
  /// re-analyse after species confirmation (always slot 0).
  Future<void> _pickImage() async {
    await _pickImageForSlot(0);
  }

  Future<void> _analyzePlantPhoto(Uint8List imageBytes, {String? userHint}) async {
    setState(() {
      _clearAiAnalysisPayload();
      _isAnalyzing = true;
      _showAnalysisLoader = true;
      _loaderInitialStep = 1;
      _loaderShowProfileButton = true;
      _showSpeciesSelection = false;
      _speciesCandidates = [];
      _confirmedSpecies = null;
      _showManualInput = false;
    });

    try {
      // Build list: slot0 first, slot1 if available
      final images = <Uint8List>[imageBytes];
      if (_slot1ImageBytes != null) images.add(_slot1ImageBytes!);

      final base64Images = images.map(base64Encode).toList();

      final body = <String, dynamic>{
        'base64Image': base64Images.first,   // legacy compat
        'base64Images': base64Images,
        'language': LanguageService.localeNotifier.value.languageCode,
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };
      if (userHint != null) body['userHint'] = userHint;

      final response = await http.post(
        Uri.parse(analyzePlantPhotoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode != 200) {
        throw Exception(l10n.failedToAnalyzePlantPhoto(response.statusCode));
      }
      
      final result = jsonDecode(response.body);

      if (result['step'] == 'identification') {
        final candidates = (result['speciesCandidates'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _speciesCandidates = candidates;
          _showSpeciesSelection = true;
          _isAnalyzing = false;
          _showAnalysisLoader = false;
        });
        return;
      }

      final recommendations =
          _coerceAnalyzeRecommendationsMap(result['recommendations']);

      print('🔍 AI Analysis Results (coerced):');
      print('🔍 general_description: ${recommendations['general_description']}');
      print('🔍 name: ${recommendations['name']}');
      print('🔍 moisture_level: ${recommendations['moisture_level']}');
      print('🔍 light: ${recommendations['light']}');
      print('🔍 watering_frequency: ${recommendations['watering_frequency']}');
      print('🔍 specific_issues: ${recommendations['specific_issues']}');
      print('🔍 care_tips: ${recommendations['care_tips']}');

      setState(() {
        _aiGeneralDescription = _safeString(recommendations['general_description']);
        _aiName = _safeString(recommendations['name']);
        _aiMoistureLevel = _safeString(recommendations['moisture_level']);
        _aiMoistureMin = recommendations['ideal_soil_moisture_min'] is int
            ? recommendations['ideal_soil_moisture_min']
            : int.tryParse(recommendations['ideal_soil_moisture_min']?.toString() ?? '');
        _aiMoistureMax = recommendations['ideal_soil_moisture_max'] is int
            ? recommendations['ideal_soil_moisture_max']
            : int.tryParse(recommendations['ideal_soil_moisture_max']?.toString() ?? '');
        _aiLight = _safeString(recommendations['light']);
        _aiWateringAmount = _safeString(recommendations['watering_amount']);
        _aiSpecificIssues = _safeString(recommendations['specific_issues']);
        _aiCareTips = _safeString(recommendations['care_tips']);
        _careDetails = recommendations['care_details'] as Map<String, String>?;

        _aiInterestingFacts = (recommendations['interesting_facts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();

        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'];

        final wateringPlan = recommendations['watering_plan'] as Map<String, dynamic>? ?? {};
        final nextDays = wateringPlan['next_watering_in_days'];
        _nextWateringInDays = nextDays != null ? int.tryParse(nextDays.toString()) : null;
        _shouldWaterNow = wateringPlan['should_water_now'] == true;
        _aiWateringFrequency = _nextWateringInDays?.toString() ??
            _safeString(recommendations['watering_frequency']);
        
        _wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        
        // Extract scientific watering calculation data (legacy support)
        _wateringRangeMl = recommendations['range_ml'] != null ? List<int>.from(recommendations['range_ml']) : null;
        _nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        _nextCheckHours = recommendations['next_check_in_hours'];
        _wateringMode = recommendations['mode'];
        
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisFailed(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
        _showAnalysisLoader = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    try {
      // Test Firebase Functions connectivity
      final response = await http.get(
        Uri.parse(analyzePlantPhotoUrl),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 405 
                ? '✅ Firebase Functions are accessible! (Method not allowed is expected for GET)' 
                : '❌ Firebase Functions test failed. Status: ${response.statusCode}',
            ),
            backgroundColor: response.statusCode == 405 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.apiTestError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _confirmSpecies(String scientificName) async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _confirmedSpecies = scientificName;
      _showSpeciesSelection = false;
      _isFetchingFullAnalysis = true;
      _isAnalyzing = true;
      _showAnalysisLoader = true;
      _loaderInitialStep = 2;
      _loaderShowProfileButton = false;
    });

    try {
      final base64Image = base64Encode(_selectedImageBytes!);

      final response = await http.post(
        Uri.parse(analyzePlantPhotoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64Image': base64Image,
          'confirmedSpecies': scientificName,
          'language': LanguageService.localeNotifier.value.languageCode,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }

      final result = jsonDecode(response.body);
      final recommendations =
          _coerceAnalyzeRecommendationsMap(result['recommendations']);

      setState(() {
        _aiGeneralDescription = _safeString(recommendations['general_description']);
        _aiName = _safeString(recommendations['name']) ?? scientificName;
        _aiMoistureLevel = _safeString(recommendations['moisture_level']);
        _aiMoistureMin = recommendations['ideal_soil_moisture_min'] is int
            ? recommendations['ideal_soil_moisture_min']
            : int.tryParse(recommendations['ideal_soil_moisture_min']?.toString() ?? '');
        _aiMoistureMax = recommendations['ideal_soil_moisture_max'] is int
            ? recommendations['ideal_soil_moisture_max']
            : int.tryParse(recommendations['ideal_soil_moisture_max']?.toString() ?? '');
        _aiLight = _safeString(recommendations['light']);

        final wateringPlan =
            recommendations['watering_plan'] as Map<String, dynamic>? ?? {};
        final nextDays = wateringPlan['next_watering_in_days'];
        _nextWateringInDays = nextDays != null ? int.tryParse(nextDays.toString()) : null;
        _aiWateringFrequency = _nextWateringInDays?.toString() ??
            _safeString(recommendations['watering_frequency']);
        _aiWateringAmount = _safeString(recommendations['watering_amount']);
        _wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        _shouldWaterNow = wateringPlan['should_water_now'] == true;

        _aiSpecificIssues = _safeString(recommendations['specific_issues']);
        _aiCareTips = _safeString(recommendations['care_tips']);
        _careDetails = recommendations['care_details'] as Map<String, String>?;
        _aiInterestingFacts = (recommendations['interesting_facts'] is List)
            ? List<String>.from(recommendations['interesting_facts'])
            : null;

        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'] ?? recommendations['other_care']?['growth_stage'];

        _wateringRangeMl = recommendations['range_ml'] != null ? List<int>.from(recommendations['range_ml']) : null;
        _nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        _nextCheckHours = recommendations['next_check_in_hours'];
        _wateringMode = recommendations['mode'];

        _refreshStatus = 'success';
        _isFetchingFullAnalysis = false;
        _isAnalyzing = false;
        // Auto-populate name from AI result so _addPlant() validation passes
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = _aiName ?? scientificName;
        }
      });
      // Immediately save the plant and navigate — no manual button press needed
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addPlant();
      });
    } catch (e) {
      setState(() {
        _isFetchingFullAnalysis = false;
        _isAnalyzing = false;
        _refreshStatus = 'error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _retryWithManualInput() {
    final query = _manualSpeciesController.text.trim();
    if (query.isEmpty || _selectedImageBytes == null) return;
    _analyzePlantPhoto(_selectedImageBytes!, userHint: query);
  }

  Future<void> _refreshAnalysis() async {
    if (_selectedImageBytes == null) return;
    
    setState(() {
      _isRefreshing = true;
      _refreshStatus = null;
    });

    try {
      final base64Image = base64Encode(_selectedImageBytes!);
      
      final body = <String, dynamic>{
        'base64Image': base64Image,
        'language': LanguageService.localeNotifier.value.languageCode,
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };
      if (_confirmedSpecies != null) body['confirmedSpecies'] = _confirmedSpecies;

      final response = await http.post(
        Uri.parse(analyzePlantPhotoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode != 200) {
        throw Exception(l10n.failedToAnalyzePlantPhoto(response.statusCode));
      }
      
      final result = jsonDecode(response.body);

      if (result['step'] == 'identification') {
        final candidates = (result['speciesCandidates'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _speciesCandidates = candidates;
          _showSpeciesSelection = true;
          _isRefreshing = false;
          _refreshStatus = 'success';
        });
        return;
      }

      final recommendations =
          _coerceAnalyzeRecommendationsMap(result['recommendations']);

      setState(() {
        _aiGeneralDescription = _safeString(recommendations['general_description']);
        _aiName = _safeString(recommendations['name']);
        _aiMoistureLevel = _safeString(recommendations['moisture_level']);
        _aiMoistureMin = recommendations['ideal_soil_moisture_min'] is int
            ? recommendations['ideal_soil_moisture_min']
            : int.tryParse(recommendations['ideal_soil_moisture_min']?.toString() ?? '');
        _aiMoistureMax = recommendations['ideal_soil_moisture_max'] is int
            ? recommendations['ideal_soil_moisture_max']
            : int.tryParse(recommendations['ideal_soil_moisture_max']?.toString() ?? '');
        _aiLight = _safeString(recommendations['light']);
        _aiWateringFrequency =
            _safeString(recommendations['watering_frequency']) ??
                _safeString(recommendations['watering_plan']?['next_watering_in_days']);
        _aiWateringAmount = _safeString(recommendations['watering_amount']);
        _aiSpecificIssues = _safeString(recommendations['specific_issues']);
        _aiCareTips = _safeString(recommendations['care_tips']);
        _careDetails = recommendations['care_details'] as Map<String, String>?;
        
        _aiInterestingFacts = (recommendations['interesting_facts'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        _aiPlantSize = recommendations['plant_size'];
        _aiPotSize = recommendations['pot_size'];
        _aiGrowthStage = recommendations['growth_stage'] ?? recommendations['other_care']?['growth_stage'];
        
        final wateringPlan = recommendations['watering_plan'] as Map<String, dynamic>? ?? {};
        final nextDays = wateringPlan['next_watering_in_days'];
        _nextWateringInDays = nextDays != null ? int.tryParse(nextDays.toString()) : null;
        _shouldWaterNow = wateringPlan['should_water_now'] == true;
        _wateringAmountMl = wateringPlan['amount_ml'] ?? recommendations['amount_ml'];
        
        _wateringRangeMl = recommendations['range_ml'] != null ? List<int>.from(recommendations['range_ml']) : null;
        _nextAfterWateringHours = recommendations['next_after_watering_in_hours'];
        _nextCheckHours = recommendations['next_check_in_hours'];
        _wateringMode = recommendations['mode'];
        
        _refreshStatus = 'success';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiAnalysisRefreshed),
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
            content: Text(l10n.aiAnalysisRefreshFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.retry,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F1D6), Color(0xFFF1F8EB)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_a_photo_outlined,
            size: 42,
            color: Color(0xFF5FA346),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.uploadPlantPhoto,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: Color(0xFF7A8676),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
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
  
  /// Calculate light hours per day based on AI light requirements
  String _calculateLightHours() {
    if (_aiLight == null || _aiLight!.isEmpty) {
      return l10n.notSpecified;
    }
    
    final lightRequirement = _aiLight!.toLowerCase();
    
    // Extract hours if already specified as numbers
    final hourPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|h\b)');
    final hourMatch = hourPattern.firstMatch(lightRequirement);
    if (hourMatch != null) {
      final hours = double.tryParse(hourMatch.group(1)!) ?? 0;
      return '${hours.toInt()}';
    }
    
    // Calculate based on light intensity descriptions
    if (lightRequirement.contains('full sun') || lightRequirement.contains('direct sun')) {
      return '6-8'; // Full sun plants need 6-8 hours of direct sunlight
    } else if (lightRequirement.contains('partial sun') || lightRequirement.contains('morning sun')) {
      return '4-6'; // Partial sun plants need 4-6 hours
    } else if (lightRequirement.contains('partial shade') || lightRequirement.contains('filtered light')) {
      return '2-4'; // Partial shade plants need 2-4 hours
    } else if (lightRequirement.contains('bright indirect') || lightRequirement.contains('bright light')) {
      return '8-12'; // Bright indirect light throughout the day
    } else if (lightRequirement.contains('low light') || lightRequirement.contains('shade')) {
      return '2-3'; // Low light plants need minimal direct light
    } else if (lightRequirement.contains('medium light') || lightRequirement.contains('moderate light')) {
      return '4-6'; // Medium light requirements
    } else if (lightRequirement.contains('very bright') || lightRequirement.contains('high light')) {
      return '10-12'; // Very bright light requirements
    }
    
    // Default calculation based on plant species if available
    final species = _aiName?.toLowerCase() ?? 'unknown';
    
    if (species.contains('succulent') || species.contains('cactus')) {
      return '6-8'; // Most succulents need full sun
    } else if (species.contains('pothos') || species.contains('philodendron')) {
      return '4-6'; // Popular houseplants with moderate light needs
    } else if (species.contains('snake plant') || species.contains('zz plant')) {
      return '2-4'; // Low light tolerant plants
    } else if (species.contains('fiddle leaf') || species.contains('monstera')) {
      return '6-8'; // Bright light loving houseplants
    } else if (species.contains('calathea') || species.contains('prayer plant')) {
      return '4-6'; // Prefer bright indirect light
    }
    
    // Default fallback
    return '4-6';
  }

  /// Convert moisture level text to percentage (0-100)
  int _getMoisturePercentage(String? moistureLevel) {
    if (moistureLevel == null) return 50;
    
    try {
      // First, check if it's already a percentage number
      final percentage = int.tryParse(moistureLevel);
      if (percentage != null && percentage >= 0 && percentage <= 100) {
        return percentage;
      }
      
      // Check if it's a range like "40-60%"
      final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(moistureLevel);
      if (rangeMatch != null) {
        final min = int.tryParse(rangeMatch.group(1) ?? '');
        final max = int.tryParse(rangeMatch.group(2) ?? '');
        if (min != null && max != null) {
          return (min + max) ~/ 2; // Return midpoint
        }
      }
      
      // Fallback to text-based conversion
      final level = moistureLevel.toLowerCase();
      int percentageResult;
      
      if (level.contains('low') || level.contains('dry')) {
        percentageResult = 25;
      } else if (level.contains('moderate') || level.contains('medium')) {
        percentageResult = 50;
      } else if (level.contains('high') || level.contains('wet') || level.contains('moist')) {
        percentageResult = 75;
      } else if (level.contains('very high') || level.contains('very wet')) {
        percentageResult = 90;
      } else {
        percentageResult = 50; // Default to moderate
      }
      
      return percentageResult;
    } catch (e) {
      print('Error parsing moisture level: $moistureLevel, error: $e');
      return 50; // Safe fallback
    }
  }
  
  /// Format watering frequency to human-readable text
  String _formatWateringFrequency(String? frequency) {
    if (frequency == null) return l10n.onceEvery7Days;
    
    try {
      final days = int.parse(frequency);
      if (days == 1) return l10n.oncePerDay;
      if (days == 7) return l10n.oncePerWeek;
      if (days <= 14) return l10n.onceEveryNDays(days);
      if (days <= 30) return l10n.onceEveryNWeeks((days / 7).round());
      return l10n.onceEveryNDays(days);
    } catch (e) {
      return l10n.onceEvery7Days;
    }
  }
  
  /// Format moisture level to five gradations
  String _formatMoistureLevel(String? moistureLevel) {
    if (moistureLevel == null) return l10n.medium;
    
    final level = moistureLevel.toLowerCase();
    if (level.contains('very low') || level.contains('extremely low') || level.contains('dry')) return l10n.low;
    if (level.contains('low') || level.contains('slightly low')) return l10n.mediumLow;
    if (level.contains('moderate') || level.contains('medium') || level.contains('average')) return l10n.medium;
    if (level.contains('high') || level.contains('slightly high') || level.contains('moist')) return l10n.mediumHigh;
    if (level.contains('very high') || level.contains('extremely high') || level.contains('wet') || level.contains('soggy')) return l10n.high;
    
    return l10n.medium; // Default
  }

  Widget _buildCareCard(String title, String value, IconData icon, Color color, {int? moisturePercentage}) {
    return Container(
      padding: const EdgeInsets.all(18), // Increased padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), // Reduced opacity for subtlety
        borderRadius: BorderRadius.circular(16), // Increased radius
        border: Border.all(
          color: color.withOpacity(0.25), // Reduced border opacity
          width: 1.5, // Increased border width
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon with background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12), // Increased spacing
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700, // Increased weight
              color: color,
              fontSize: 13, // Slightly increased
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6), // Increased spacing
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15, // Increased size
              fontWeight: FontWeight.w600, // Increased weight
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (moisturePercentage != null) ...[
            const SizedBox(height: 10), // Increased spacing
            Container(
              width: double.infinity,
              height: 8, // Increased height
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4), // Increased radius
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (moisturePercentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4), // Increased radius
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$moisturePercentage%',
              style: TextStyle(
                color: color,
                fontSize: 13, // Increased size
                fontWeight: FontWeight.w700, // Increased weight
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addPlant() async {
    final nameEmpty = _nameController.text.trim().isEmpty;
    if (nameEmpty) {
      setState(() => _nameError = true);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(l10n.userNotAuthenticated);
      }

      // Handle image selection - only use custom uploaded image
      if (_selectedImageBytes == null) {
        throw Exception(l10n.pleaseUploadPlantImage);
      }
      
      // Require AI analysis before creating plant (API may omit general_description)
      if (!_hasAiResultsToDisplay) {
        throw Exception(l10n.pleaseWaitForAiAnalysisBeforeAddingPlant);
      }

      // Upload image to Firebase Storage; store only the URL in Firestore (limit 1MB per field)
      final plantName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_aiName ?? l10n.plantLowercase);
      final imageUrl = await ImageUploadService().uploadPlantImageFromBytes(
        _selectedImageBytes!,
        plantName,
      );

      // Use AI-determined watering frequency or default to 7 days
      final wateringFreq = _aiWateringFrequency != null 
          ? int.tryParse(_aiWateringFrequency!) ?? 7 
          : 7;
      
      // NEW PLANTS: NO health status or health message until first manual health check
      // AI analysis is only used for care recommendations, not health status
      
      final plant = Plant(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        species: _aiName ?? 'Unknown Species', // Use AI name or default species
        imageUrl: imageUrl,
        lastWatered: DateTime.now(),
        nextWatering: DateTime.now().add(Duration(days: wateringFreq)),
        wateringFrequency: wateringFreq,
        notes: null, // No notes field in add plant screen
        createdAt: DateTime.now(),
        userId: user.uid,
        aiGeneralDescription: _aiGeneralDescription,
        aiName: _aiName,
        aiMoistureLevel: _aiMoistureLevel,
        idealSoilMoistureMin: _aiMoistureMin,
        idealSoilMoistureMax: _aiMoistureMax,
        aiLight: _aiLight,
        aiWateringAmount: _aiWateringAmount,
        aiSpecificIssues: _aiSpecificIssues,
        aiCareTips: _aiCareTips,
        careDetails: _careDetails,
        interestingFacts: _aiInterestingFacts,
        aiPlantSize: _aiPlantSize,
        aiPotSize: _aiPotSize,
        aiGrowthStage: _aiGrowthStage,
        wateringAmountMl: _wateringAmountMl,
        wateringRangeMl: _wateringRangeMl,
        nextAfterWateringHours: _nextAfterWateringHours,
        nextCheckHours: _nextCheckHours,
        wateringMode: _wateringMode,
        wateringIntervalDays: _nextWateringInDays,
        shouldWaterNow: _shouldWaterNow, // From AI analysis
        healthStatus: null, // No health status for new plants
        healthMessage: null, // No health message for new plants
        lastHealthCheck: null, // No health check for new plants
      );

      final plantId = await PlantService().addPlant(plant);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.plantAddedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Defer navigation to next frame so the SnackBar animation doesn't
        // conflict with Navigator operations (avoids !_debugLocked assertion).
        SchedulerBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          // Resolve the navigator up front. onPlantAdded() switches the tab, and
          // main navigation renders `_screens[_currentIndex]`, so that call
          // detaches this screen from the tree — any ancestor lookup on this
          // context afterwards throws "deactivated widget's ancestor".
          final navigator = Navigator.of(context, rootNavigator: true);
          var navigated = false;

          try {
            final plantDoc = await FirebaseFirestore.instance
                .collection('plants')
                .doc(plantId)
                .get();

            if (!mounted) return;

            if (!plantDoc.exists) {
              debugPrint('⚠️ Plant $plantId not found right after creation; '
                  'staying on the tab (creation already succeeded).');
              return;
            }

            final plantData = plantDoc.data()!;
            plantData['id'] = plantId;
            // Parsed before the tab switch so a malformed document leaves the
            // user on a consistent screen.
            final newPlant = Plant.fromMap(plantData);

            // Switch the underlying tab to "My Plants" (index 1) BEFORE pushing,
            // so pressing Back from PlantDetailsScreen returns to the plant list
            // instead of to AddPlantScreen.
            widget.onPlantAdded?.call();
            navigated = true;

            navigator.push(
              MaterialPageRoute(
                builder: (_) => PlantDetailsScreen(plant: newPlant),
              ),
            );
          } catch (e, stack) {
            debugPrint('❌ Error navigating to new plant: $e\n$stack');
          } finally {
            // Must run on every path: the loader covers the whole screen, so
            // leaving it up on a failure strands the user with no way forward.
            if (!navigated && mounted) {
              setState(() => _showAnalysisLoader = false);
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e is SubscriptionLimitException) {
        // Show paywall instead of error snackbar
        final subscribed = await showPaywall(context);
        if (subscribed == true && mounted) {
          // Let the user try again now that they subscribed
          _addPlant();
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAddingPlant(e.toString())),
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

  Widget _buildInputCard(String label, String hintText, IconData icon,
      {TextEditingController? controller,
      String? Function(String?)? validator,
      bool showNameError = false,
      ValueChanged<String>? onNameChanged,
      Color? iconColor}) {
    final isPlantName = label == l10n.plantName;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFCCE8B8),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.local_florist_outlined,
                        size: 17, color: Color(0xFF5FA346)),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                  color: Color(0xFF2D3D2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BotanlyAddInputShell(
                    icon: icon,
                    child: TextFormField(
                      controller: controller,
                      onChanged: onNameChanged,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1B2A18),
                      ),
                      cursorColor: const Color(0xFF5FA346),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        hoverColor: Colors.transparent,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF7A8676),
                        ),
                      ),
                      validator: validator,
                    ),
                  ),
                ),
                if (isPlantName) ...[
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFFF1F8EB),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _generateRandomPlantName,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8EB),
                          border: Border.all(color: const Color(0xFFE4EBE1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shuffle_rounded,
                            size: 18, color: Color(0xFF5FA346)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showNameError) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: const Color(0xFFFFCDD2)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: Color(0xFFE05252)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.pleaseEnterPlantName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE05252),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({bool limitReached = false, bool subLoading = false, bool subReady = true}) {
    final bool canTap = subReady && !limitReached && !_isAnalyzing;
    final bool hasPhoto = _selectedImageBytes != null;
    final bool canAnalyze = canTap && hasPhoto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0D2D3D2A), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8EB),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.photo_camera_outlined, size: 14, color: Color(0xFF4A8C33)),
              ),
              const SizedBox(width: 10),
              Builder(builder: (context) {
                final words = l10n.plantPhoto.split(' ');
                final plain = '${words.sublist(0, words.length - 1).join(' ')} ';
                final italic = words.last;
                return RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Fraunces', fontSize: 16, fontWeight: FontWeight.w500,
                        letterSpacing: -0.3, color: Color(0xFF2D3D2A)),
                    children: [
                      TextSpan(text: plain),
                      TextSpan(text: italic, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF5FA346))),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // ── Dual tile grid ──
          Row(
            children: [
              Expanded(child: _buildPhotoTile(
                slot: 0,
                bytes: _selectedImageBytes,
                title: l10n.addPlantWholePlantTitle,
                desc: l10n.addPlantWholePlantDesc,
                tag: l10n.addPlantWholePlantTag,
                isRequired: true,
                canTap: canTap,
                icon: Icons.photo_camera_outlined,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildPhotoTile(
                slot: 1,
                bytes: _slot1ImageBytes,
                title: l10n.addPlantCloseUpTitle,
                desc: l10n.addPlantCloseUpDesc,
                tag: l10n.addPlantCloseUpTag,
                isRequired: false,
                canTap: canTap,
                icon: Icons.eco_outlined,
              )),
            ],
          ),

          // ── Hint ──
          const SizedBox(height: 10),
          Text(
            l10n.addPlantDualHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans', fontSize: 13,
              color: Color(0xFF8B9486),
              height: 1.4,
            ),
          ),

          // ── Tips pills (only when no photo yet) ──
          if (!hasPhoto) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _buildTipPill(Icons.wb_sunny_outlined, l10n.tipGoodLight),
                  _buildTipPill(Icons.eco_outlined, l10n.tipShowLeaves),
                  _buildTipPill(Icons.check_rounded, l10n.tipSinglePlant),
                ],
              ),
            ),
          ],

          // ── Analyze button (hidden once species candidates are shown) ──
          if (!_showSpeciesSelection) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canAnalyze
                  ? () => _analyzePlantPhoto(_selectedImageBytes!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAnalyze ? const Color(0xFF5FA346) : const Color(0xFFDFE6D7),
                foregroundColor: canAnalyze ? Colors.white : const Color(0xFFA7B29C),
                elevation: canAnalyze ? 4 : 0,
                shadowColor: const Color(0xFF56A93B).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: canAnalyze ? Colors.white : const Color(0xFFA7B29C),
              ),
              label: Text(
                l10n.addPlantAnalyzeButton,
                style: const TextStyle(
                  fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ], // end if (!_showSpeciesSelection)
        ],
      ),
    );
  }

  Widget _buildPhotoTile({
    required int slot,
    required Uint8List? bytes,
    required String title,
    required String desc,
    required String tag,
    required bool isRequired,
    required bool canTap,
    required IconData icon,
  }) {
    final bool filled = bytes != null;
    return GestureDetector(
      onTap: canTap ? () => _pickImageForSlot(slot) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: filled
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEF7E6), Color(0xFFE3F1D6)],
                ),
          border: Border.all(
            color: filled ? const Color(0xFF5FA346) : const Color(0xFFCFE6BB),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview image
            if (filled)
              Image.memory(bytes!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),

            // Overlay content (hidden when filled)
            if (!filled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Color(0x1A223A18), blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      child: Icon(icon, size: 22, color: const Color(0xFF4F9A32)),
                    ),
                    const SizedBox(height: 10),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF20271E))),
                    const SizedBox(height: 3),
                    Text(desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11.5, color: Color(0xFF90A085), height: 1.3)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRequired ? const Color(0xFFD9EBC6) : const Color(0xFFE6EDF9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 0.04,
                          color: isRequired ? const Color(0xFF3F8127) : const Color(0xFF5878B0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Green check badge (top-right)
            if (filled)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5FA346),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
              ),

            // Remove button (top-left)
            if (filled && canTap)
              Positioned(
                top: 8, left: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (slot == 0) _selectedImageBytes = null;
                      else _slot1ImageBytes = null;
                    });
                  },
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 5)],
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF8A9580)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoStage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.3),
          radius: 1.0,
          colors: [Color(0x2E5FA346), Colors.transparent],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1F8EB), Color(0xFFE3F1D6), Color(0xFFF7FAF5)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Leaf decoration top-right
            Positioned(
              top: -20,
              right: -14,
              child: Opacity(
                opacity: 0.18,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(painter: _AddPlantLeafPainter()),
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF5FA346).withValues(alpha: 0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5FA346).withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.photo_camera_outlined, size: 24, color: Color(0xFF4A8C33)),
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    final words = l10n.snapYourSprout.split(' ');
                    final plain = '${words.sublist(0, words.length - 1).join(' ')} ';
                    final italic = words.last;
                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w500,
                            letterSpacing: -0.3, color: Color(0xFF2D3D2A)),
                        children: [
                          TextSpan(text: plain),
                          TextSpan(text: italic, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF5FA346))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Text(
                    l10n.snapDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      color: Color(0xFF7A8676),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: _AnalyzingOverlay(),
    );
  }

  Widget _buildTipPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5FA346).withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF5FA346)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5C46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultsCard() {
    const Color cSage = Color(0xFF5FA346);
    const Color cSageDark = Color(0xFF4A8C33);
    const Color cMoss = Color(0xFF2D3D2A);
    const Color cSagePale = Color(0xFFCCE8B8);
    const Color cSagePale2 = Color(0xFFE3F1D6);
    const Color cSageSoft = Color(0xFFF1F8EB);
    const Color cAmber = Color(0xFFB8893A);
    const Color cAmberPale = Color(0xFFF7ECD8);
    const Color cAmberBorder = Color(0xFFEBD9B8);
    const Color cBlue = Color(0xFF4A91C8);
    const Color cBluePale = Color(0xFFE4EFF8);
    const Color cBlueBorder = Color(0xFFCADFEE);
    const Color cInkMute = Color(0xFF7A8676);
    const Color cInkSoft = Color(0xFF4A5C46);

    final commonName = _aiName ?? _nameController.text.trim();
    final latinName = (_confirmedSpecies != null &&
            _confirmedSpecies!.toLowerCase() !=
                commonName.toLowerCase())
        ? _confirmedSpecies!
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cSagePale, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: icon plate + title + AI Ready badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cSagePale2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 17, color: cSage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.aiCareRecommendationsHeader,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                    height: 1.2,
                    color: cMoss,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: cSagePale2,
                  border: Border.all(color: cSagePale, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 13, color: cSage),
                    const SizedBox(width: 5),
                    Text(
                      l10n.aiReady,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cSageDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Plant common name (Fraunces 22) ──
          if (commonName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              commonName,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 22,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
                color: cMoss,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (latinName != null) ...[
            const SizedBox(height: 4),
            Text(
              latinName,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: cInkMute,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Description ──
          if (_aiGeneralDescription != null &&
              _aiGeneralDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _cleanMarkdownContent(_aiGeneralDescription!),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: cInkSoft,
                height: 1.5,
              ),
            ),
          ],

          // ── 2 stat cards: Moisture / Light ──
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _AiStatBox(
                    bg: cSageSoft,
                    borderColor: cSagePale,
                    iconColor: cSage,
                    valueColor: cSageDark,
                    icon: Icons.opacity_rounded,
                    value: _buildMoistureDisplayValue(),
                    label: l10n.soilMoisture,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AiStatBox(
                    bg: cAmberPale,
                    borderColor: cAmberBorder,
                    iconColor: cAmber,
                    valueColor: cAmber,
                    icon: Icons.wb_sunny_outlined,
                    value: '${_calculateLightHours()} ${l10n.hoursLabel}',
                    label: '${l10n.lightLabel} / ${l10n.perDay}',
                  ),
                ),
              ],
            ),
          ),

          // ── Watering frequency strip ──
          if (_aiWateringFrequency != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cBluePale,
                border: Border.all(color: cBlueBorder, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        size: 16, color: cBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.wateringFrequency,
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            color: cBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatWateringFrequency(_aiWateringFrequency),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: cBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Care Recommendations acc-block ──
          if (_aiCareTips != null && _aiCareTips!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cSagePale, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                      color: cSageSoft,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: cSagePale,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb_outline,
                              size: 16, color: cSage),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.careRecommendationsTitle,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 19,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.3,
                              height: 1.1,
                              color: cSage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildStructuredCareSections(_aiCareTips!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Interesting Facts ──
          if (_aiInterestingFacts != null &&
              _aiInterestingFacts!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInterestingFactsInDetails(_aiInterestingFacts!),
          ],
        ],
      ),
    );
  }

  String _getMoistureLabelInline() {
    final pct = (_aiMoistureMin != null && _aiMoistureMax != null)
        ? (_aiMoistureMin! + _aiMoistureMax!) ~/ 2
        : _getMoisturePercentage(_aiMoistureLevel);
    if (pct <= 15) return 'Very dry';
    if (pct <= 35) return 'Dry';
    if (pct <= 54) return 'Slightly moist';
    if (pct <= 74) return 'Moist';
    return 'Very moist';
  }

  String _buildMoistureDisplayValue() {
    final label = _getMoistureLabelInline();
    if (_aiMoistureMin != null && _aiMoistureMax != null) {
      return '$label · $_aiMoistureMin–$_aiMoistureMax%';
    }
    return label;
  }

  /// Cleans markdown formatting from AI content for better UI display
  String _cleanMarkdownContent(String content) {
    if (content.isEmpty) return content;
    
    return content
        // Remove markdown headers
        .replaceAll(RegExp(r'^###\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^##\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^#\s*', multiLine: true), '')
        // Remove bold formatting
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        // Remove italic formatting
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        // Remove underline formatting
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')
        // Remove strikethrough
        .replaceAll(RegExp(r'~~(.*?)~~'), r'$1')
        // Remove code formatting
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        // Remove blockquotes
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        // Remove horizontal rules
        .replaceAll(RegExp(r'^---$', multiLine: true), '')
        // Remove list markers
        .replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        // Remove AI artifacts like "$1:" that commonly appear in AI responses
        .replaceAll(RegExp(r'\$1:\s*'), '')
        .replaceAll(RegExp(r'\$\d+:\s*'), '')
        // Remove "$1" artifacts that appear at the beginning of lines
        .replaceAll(RegExp(r'^\$1\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\$\d+\s*', multiLine: true), '')
        // Clean up extra whitespace
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }



  /// Builds a structured care recommendations card from AI tips.
  Widget _buildStructuredCareRecommendations(String content) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentGreen.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.careRecommendationsTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._parseCareContent(content).map((section) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCareSection(section['title']!, section['content']!),
            ),
          ).toList(),
        ],
      ),
    );
  }

  /// Completely removes all markdown formatting from content.
  String _cleanAllMarkdown(String content) {
    return content
        // Remove all header markers
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        // Remove all bold formatting
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        // Remove all italic formatting
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        // Remove all underline formatting
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        // Remove all strikethrough formatting
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'$1')
        // Remove all code formatting
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Remove all blockquote markers
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        // Remove all horizontal rules
        .replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '')
        // Remove all list markers and convert to clean format
        .replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '• ')
        .replaceAll(RegExp(r'^[\s]*\d+\.\s*', multiLine: true), '• ')
        // Remove any remaining asterisks at start/end of lines
        .replaceAll(RegExp(r'^\*\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*\*$', multiLine: true), '')
        // Remove any remaining hash symbols
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        // Clean up multiple spaces and empty lines
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
  }

  /// Parses AI content into structured sections with complete markdown removal.
  List<Map<String, String>> _parseCareContent(String content) {
    // First, completely clean all markdown from the content
    final cleanedContent = _cleanAllMarkdown(content);
    
    final List<Map<String, String>> sections = [];
    final lines = cleanedContent.split('\n');
    
    String currentTitle = '';
    List<String> currentContent = [];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // Skip empty lines
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line looks like a section header (starts with capital letter, no bullet points)
      if (_isSectionHeader(trimmedLine)) {
        // Save previous section if exists
        if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
          sections.add({
            'title': currentTitle,
            'content': currentContent.join('\n').trim(),
          });
        }
        
        // Start new section
        currentTitle = trimmedLine;
        currentContent = [];
      } else {
        // Add content line
        currentContent.add(trimmedLine);
      }
    }
    
    // Add last section
    if (currentTitle.isNotEmpty && currentContent.isNotEmpty) {
      sections.add({
        'title': currentTitle,
        'content': currentContent.join('\n').trim(),
      });
    }
    
    // If no sections were found, create a default one with cleaned content
    if (sections.isEmpty && cleanedContent.isNotEmpty) {
      sections.add({
        'title': 'Care Instructions',
        'content': cleanedContent,
      });
    }
    
    return sections;
  }

  /// Determines if a line is likely a section header.
  bool _isSectionHeader(String line) {
    // Section headers typically:
    // - Start with a capital letter
    // - Don't start with bullet points
    // - Are relatively short (not long paragraphs)
    // - Don't contain colons (which indicate key-value pairs)
    // - Don't end with punctuation like periods
    
    if (line.isEmpty) return false;
    if (line.startsWith('•')) return false;
    if (line.contains(':')) return false;
    if (line.endsWith('.')) return false;
    if (line.length > 50) return false; // Too long to be a header
    
    // Check if it starts with a capital letter and looks like a title
    return RegExp(r'^[A-Z]').hasMatch(line) && 
           !line.contains('  ') && // No double spaces
           line.split(' ').length <= 5; // Not too many words
  }

  /// Builds a single care section with title and content.
  Widget _buildCareSection(String title, String content) {
    // Override content for Moisture and Light with numeric values
    String displayContent = content;
    if (title.toLowerCase() == 'light' && _aiLight != null) {
      // Use calculated light hours instead of descriptive text
      displayContent = '${_calculateLightHours()} hours per day';
    }
    
    // Transform title for display
    String displayTitle = title;
    if (title.toLowerCase().contains('1. plant identification') || title.toLowerCase().contains('plant identification')) {
              displayTitle = 'Plant';
    }
    
    // Split content into lines and clean each line
    final contentLines = displayContent.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForSection(displayTitle),
                color: AppTheme.accentGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Section content with proper formatting
        ...contentLines.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            line,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        )).toList(),
      ],
    );
  }

  /// Returns appropriate icon for each care section.

  
  /// Builds interesting facts section matching plant page design
  Widget _buildInterestingFactsInDetails(List<String> facts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppTheme.accentGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.interestingFactsTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Display facts with green borders matching plant page
        ...facts.take(4).map((fact) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentGreen.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    _cleanMarkdownContent(fact),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }


  Widget _buildSpeciesSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppTheme.accentGreen, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.isThisYourPlant,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.speciesPickSubtitle,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._speciesCandidates.asMap().entries.map((entry) {
            final idx = entry.key;
            final sp = entry.value;
            final confidence = ((sp['confidence'] ?? 0) * 100).round();
            final imageUrl = sp['image_url'] as String?;
            return Padding(
              padding: EdgeInsets.only(bottom: idx < _speciesCandidates.length - 1 ? 12 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _confirmSpecies(sp['scientific_name'] ?? sp['common_name'] ?? 'Unknown'),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.accentGreen.withOpacity(0.04),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.eco, color: AppTheme.accentGreen, size: 32),
                                  ),
                                )
                              : Container(
                                  width: 72, height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.eco, color: AppTheme.accentGreen, size: 32),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sp['common_name'] ?? sp['scientific_name'] ?? '?',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sp['scientific_name'] ?? '',
                                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sp['visual_hint'] ?? '',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$confidence%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (!_showManualInput)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showManualInput = true),
                icon: Icon(Icons.edit, size: 18),
                label: Text(l10n.noneOfThese),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_showManualInput) ...[
            const SizedBox(height: 4),
            Text(
              l10n.typePlantNameRetry,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualSpeciesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Monstera deliciosa',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hoverColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.accentGreen, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _retryWithManualInput(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _retryWithManualInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.search, size: 22),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullAnalysisLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Analyzing ${_confirmedSpecies ?? "plant"}...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.gettingCareRecommendations,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          BotanlyShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLine(width: 160, height: 14),
                const SizedBox(height: 12),
                const ShimmerLine(height: 11),
                const SizedBox(height: 8),
                const ShimmerLine(width: 240, height: 11),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    ShimmerCircle(size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(width: 100, height: 12),
                          SizedBox(height: 6),
                          ShimmerLine(width: 160, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    ShimmerCircle(size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(width: 80, height: 12),
                          SizedBox(height: 6),
                          ShimmerLine(width: 200, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    ShimmerCircle(size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(width: 120, height: 12),
                          SizedBox(height: 6),
                          ShimmerLine(width: 180, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionInfo>(
      stream: SubscriptionService().stream,
      initialData: SubscriptionService().currentInfo,
      builder: (context, subSnap) {
        return StreamBuilder<List<dynamic>>(
          stream: PlantService().getPlants(),
          builder: (context, plantSnap) {
            final subInfo = subSnap.data;
            final plantCount = plantSnap.data?.length ?? 0;
            // subReady: true once we have actual subscription data (cached or fresh)
            final subReady = subInfo != null;
            final limitReached = subReady &&
                plantCount >= subInfo!.plantLimit &&
                !subInfo.isActive;

            final disableAdd = limitReached ||
                _isLoading ||
                _isAnalyzing ||
                _isFetchingFullAnalysis ||
                _showSpeciesSelection ||
                !_hasAiResultsToDisplay;

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                                20, 16, 20, limitReached ? 108 : 32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildInputCard(
                                    l10n.plantName,
                                    l10n.plantNameHint,
                                    Icons.local_florist,
                                    controller: _nameController,
                                    showNameError: _nameError,
                                    onNameChanged: (_) {
                                      if (_nameError) setState(() => _nameError = false);
                                    },
                                    iconColor: AppTheme.accentGreen,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildImageUploadCard(
                                      limitReached: limitReached,
                                      subReady: subReady),
                                  const SizedBox(height: 20),
                                  if (_showSpeciesSelection) ...[
                                    _buildSpeciesSelectionCard(),
                                    const SizedBox(height: 20),
                                  ],
                                  if (_isFetchingFullAnalysis) ...[
                                    _buildFullAnalysisLoadingCard(),
                                    const SizedBox(height: 20),
                                  ],
                                  if (_hasAiResultsToDisplay &&
                                      !_showSpeciesSelection &&
                                      !_isFetchingFullAnalysis) ...[
                                    _buildAIResultsCard(),
                                    const SizedBox(height: 20),
                                  ],
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Limit banner floats at the bottom
                    if (limitReached && subInfo != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: PlantLimitBanner(info: subInfo),
                      ),

                    // Fullscreen analysis loader
                    if (_showAnalysisLoader)
                      Positioned.fill(
                        child: _AddPlantAnalysisLoader(
                          photoBytes: _selectedImageBytes,
                          isAnalyzing: _isAnalyzing,
                          onSeeProfile: () {
                            setState(() => _showAnalysisLoader = false);
                          },
                          l10n: l10n,
                          initialStep: _loaderInitialStep,
                          showProfileButton: _loaderShowProfileButton,
                          advanceSteps: _loaderInitialStep >= 2,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds structured care sections from AI care tips.
  /// Titles in [content] are already in the user's language (built by
  /// [_composeCareTipsFromCareMap]). We use the canonical-key map for icon
  /// selection so icons work regardless of the display language.
  List<Widget> _buildStructuredCareSections(String content) {
    final sections = <Widget>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      if (trimmedLine.contains(':')) {
        final parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          final rawTitle = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          
          if (rawTitle.isNotEmpty && value.isNotEmpty) {
            final isFirstSection = sections.isEmpty;
            sections.add(
              Padding(
                padding: EdgeInsets.only(
                  bottom: 16.0,
                  top: isFirstSection ? 16.0 : 0.0,
                ),
                child: _buildCareSection(rawTitle, value),
              ),
            );
          }
        }
      }
    }
    
    if (sections.isEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
          child: _buildCareSection('Care Instructions', content),
        ),
      );
    }
    
    return sections;
  }

  /// Gets appropriate icon for a care section.
  /// [title] is the raw (possibly localized) label — we resolve the canonical key
  /// so icons work regardless of the app language.
  IconData _getIconForSection(String title) {
    final canonical = careLabelToKey(title);
    switch (canonical) {
      case CareSection.water: return Icons.water_drop;
      case CareSection.light: return Icons.wb_sunny;
      case CareSection.temperature: return Icons.thermostat;
      case CareSection.soil:
      case CareSection.soilMoisture:
      case CareSection.moistureCheck: return Icons.eco;
      case CareSection.fertilizer: return Icons.grass;
      case CareSection.growthRate: return Icons.trending_up;
      case 'cultivar':
      case 'generalDescription': return Icons.local_florist;
      case 'toxicity': return Icons.warning_amber_outlined;
      case 'placement': return Icons.place_outlined;
      case 'personality': return Icons.psychology_outlined;
      default: return Icons.info_outline;
    }
  }
}

class _BotanlyAddInputShell extends StatelessWidget {
  final IconData icon;
  final Widget child;
  const _BotanlyAddInputShell({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4EBE1), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(icon, size: 18, color: const Color(0xFF5FA346)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BotanlyAddPlantHeader extends StatelessWidget {
  final String title;
  const _BotanlyAddPlantHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE4EBE1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Color(0xFF2D3D2A)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: const Color(0xFF2D3D2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotanlyAddBigButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback? onTap;
  final bool isUpload;
  const _BotanlyAddBigButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
    this.isUpload = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = disabled
        ? const Color(0xFFCDD5CB)
        : BotanlyColors.sage;
    final textColor = disabled
        ? const Color(0xFFCDD5CB)
        : BotanlyColors.sage;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: BotanlyColors.sagePale,
            highlightColor: BotanlyColors.sagePale.withValues(alpha: 0.5),
            onTap: onTap,
            child: Center(
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation(textColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  : isUpload
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 17, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: textColor,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: textColor,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact stat tile used inside the AI Care Recommendations card.
/// Mirrors `.ai-results .stat` from add_plant_screen.html.
class _AiStatBox extends StatelessWidget {
  final Color bg;
  final Color borderColor;
  final Color iconColor;
  final Color valueColor;
  final IconData icon;
  final String value;
  final String label;

  const _AiStatBox({
    required this.bg,
    required this.borderColor,
    required this.iconColor,
    required this.valueColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A8676),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Analyzing overlay widget ───────────────

class _AnalyzingOverlay extends StatefulWidget {
  const _AnalyzingOverlay();

  @override
  State<_AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<_AnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark blur overlay
        Positioned.fill(
          child: Container(color: const Color(0xFF2D3D2A).withValues(alpha: 0.45)),
        ),
        // Center content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinning conic ring
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) => Transform.rotate(
                  angle: _spin.value * 2 * pi,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [Color(0xFFA8D784), Color(0xFFCDEE9B), Color(0xFF5FA346), Color(0xFFA8D784)],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xD92D3D2A),
                      ),
                      child: const Center(
                        child: Icon(Icons.eco_outlined, size: 24, color: Color(0xFFCDEE9B)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Fraunces', fontSize: 19,
                        fontWeight: FontWeight.w500, letterSpacing: -0.3, color: Colors.white),
                    children: [
                      TextSpan(text: l10n.identifyingPlantPrefix),
                      TextSpan(text: l10n.identifyingPlantWord, style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFFCDEE9B))),
                      const TextSpan(text: '…'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Builder(builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return Text(
                  l10n.identifyingSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11.5,
                      color: Color(0xBFFFFFFF), height: 1.4),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _Sparkle extends StatefulWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double delay;

  const _Sparkle({this.top, this.bottom, this.left, this.right, required this.delay});

  @override
  State<_Sparkle> createState() => _SparkleState();
}

class _SparkleState extends State<_Sparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final dx = (widget.left != null ? widget.left! * w : null) ??
              (w - widget.right! * w - 14);
          final dy = (widget.top != null ? widget.top! * h : null) ??
              (h - widget.bottom! * h - 14);
          return AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final t = (_ctrl.value + widget.delay / 2.2) % 1.0;
              final pulse = 0.5 - 0.5 * cos(t * 2 * pi);
              return Positioned(
                left: dx,
                top: dy,
                child: Opacity(
                  opacity: (0.2 + 0.8 * pulse).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + 0.3 * pulse,
                    child: const Icon(Icons.lens_blur_rounded, size: 14, color: Color(0xFFCDEE9B)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────── Painters & utilities ───────────────

class _AddPlantLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCDEE9B), Color(0xFF5FA346)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final sx = size.width / 100;
    final sy = size.height / 100;
    final path = Path()
      ..moveTo(55 * sx, 90 * sy)
      ..quadraticBezierTo(20 * sx, 65 * sy, 50 * sx, 30 * sy)
      ..cubicTo(70 * sx, 25 * sy, 80 * sx, 22 * sy, 90 * sx, 10 * sy)
      ..relativeCubicTo(2 * sx, 22 * sy, 4 * sx, 38 * sy, -4 * sx, 52 * sy)
      ..relativeCubicTo(-7 * sx, 14 * sy, -22 * sx, 22 * sy, -31 * sx, 25 * sy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AddPlantLeafPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen step-loader shown during plant analysis
// ─────────────────────────────────────────────────────────────────────────────
class _AddPlantAnalysisLoader extends StatefulWidget {
  final Uint8List? photoBytes;
  final bool isAnalyzing;
  final VoidCallback onSeeProfile;
  final AppLocalizations l10n;
  final int initialStep;
  final bool showProfileButton;
  /// When false the step counter stays frozen at [initialStep] — no timer fires.
  /// Use for the first (identification-only) analysis where step 3 is irrelevant.
  final bool advanceSteps;

  const _AddPlantAnalysisLoader({
    required this.photoBytes,
    required this.isAnalyzing,
    required this.onSeeProfile,
    required this.l10n,
    this.initialStep = 1,
    this.showProfileButton = true,
    this.advanceSteps = true,
  });

  @override
  State<_AddPlantAnalysisLoader> createState() => _AddPlantAnalysisLoaderState();
}

class _AddPlantAnalysisLoaderState extends State<_AddPlantAnalysisLoader>
    with SingleTickerProviderStateMixin {
  // 0 = Photos received (done from start)
  // 1 = Identifying species
  // 2 = Tailoring care plan
  int _currentStep = 1;
  bool _complete = false;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialStep >= 2) {
      // Steps 1 & 2 already done (species was confirmed manually) — jump straight to step 2
      _currentStep = 2;
    } else if (!widget.advanceSteps) {
      // Identification-only: start at 0 (Photos pulsing), advance to 1 after 1.5s, then freeze
      _currentStep = 0;
      _stepTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _currentStep = 1);
      });
    } else {
      // Full analysis flow: start at 1, advance to 2 after 1.6 s
      _currentStep = 1;
      _stepTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _currentStep = 2);
      });
    }
  }

  @override
  void didUpdateWidget(_AddPlantAnalysisLoader old) {
    super.didUpdateWidget(old);
    if (old.isAnalyzing && !widget.isAnalyzing && !_complete) {
      // Analysis finished — mark complete
      setState(() {
        _currentStep = 3;
        _complete = true;
      });
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Container(
      color: const Color(0xFFF4F6F2),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Pulsing ring + disc ──
            SizedBox(
              width: 210, height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Three pulse rings
                  ...List.generate(3, (i) => _PulseRing(delay: i * 800)),
                  // Photo disc
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEEF7E6), Color(0xFFD9EEC7)],
                      ),
                      border: Border.all(color: const Color(0xFFCFE6BB)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x264F9A32), blurRadius: 24, offset: Offset(0, 10)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.photoBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(widget.photoBytes!, fit: BoxFit.cover),
                              if (!_complete) const _ScanLine(),
                            ],
                          )
                        : const Icon(Icons.eco_rounded, size: 64, color: Color(0xFF4F9A32)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 34),

            // ── Title ──
            Text(
              l10n.addPlantAnalyzingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Fraunces', fontSize: 24, fontWeight: FontWeight.w700,
                letterSpacing: -0.3, color: Color(0xFF20271E),
              ),
            ),

            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _complete ? l10n.addPlantAnalysisComplete : l10n.addPlantAnalyzingSubtitle,
                key: ValueKey(_complete),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 15,
                  color: _complete ? const Color(0xFF4A9632) : const Color(0xFF8B9486),
                  fontWeight: _complete ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Steps ──
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  _StepRow(
                      label: l10n.addPlantStepPhotosReceived,
                      state: _currentStep > 0
                          ? _AddPlantStepState.done
                          : _AddPlantStepState.now),
                  const SizedBox(height: 13),
                  _StepRow(label: l10n.addPlantStepIdentifying,
                      state: _currentStep > 1
                          ? _AddPlantStepState.done
                          : (_currentStep == 1 ? _AddPlantStepState.now : _AddPlantStepState.pending)),
                  const SizedBox(height: 13),
                  _StepRow(label: l10n.addPlantStepCarePlan,
                      state: _currentStep > 2
                          ? _AddPlantStepState.done
                          : (_currentStep == 2 ? _AddPlantStepState.now : _AddPlantStepState.pending)),
                ],
              ),
            ),

            // ── CTA ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: (_complete && widget.showProfileButton)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: SizedBox(
                        width: 280,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: widget.onSeeProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5FA346),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF56A93B).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.eco_rounded, size: 18),
                          label: Text(l10n.addPlantSeePlantProfile,
                              style: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AddPlantStepState { pending, now, done }

class _StepRow extends StatelessWidget {
  final String label;
  final _AddPlantStepState state;
  const _StepRow({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _AddPlantStepState.done;
    final isNow = state == _AddPlantStepState.now;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? const Color(0xFF5FA346) : Colors.transparent,
            border: Border.all(
              color: isDone ? const Color(0xFF5FA346)
                  : isNow ? const Color(0xFF5FA346)
                  : const Color(0xFFD4DDC9),
              width: 2.5,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : isNow
                  ? const _BlinkingDot()
                  : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w600,
            color: (isDone || isNow) ? const Color(0xFF46503F) : const Color(0xFFAAB3A3),
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.25).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _anim,
        child: Container(
          width: 9, height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF5FA346),
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  final int delay;
  const _PulseRing({required this.delay});
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _scale = Tween<double>(begin: 0.55, end: 1.15).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 80),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 210, height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFE0A0), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pos = Tween<double>(begin: -36, end: 150).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pos,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            top: _pos.value,
            left: 0, right: 0,
            child: Container(
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0056A93B),
                    Color(0x6656A93B),
                    Color(0x0056A93B),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
