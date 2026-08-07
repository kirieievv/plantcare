/// Add a plant — three steps (handoff v4, ORDER stage 3).
///
/// Name and photos → species → care plan. The backend is unchanged: the same
/// `analyzePlantPhoto` endpoint answers with either a list of species candidates
/// or a full set of recommendations, and which one comes back is what moves the
/// user between steps.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/utils/care_sections.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:plant_care/utils/web_file_picker.dart';
import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/widgets/subscription_banner.dart';

/// Glass base for a 200 ml glass — the same constant the plant screen uses.
const _kGlassMl = 200;

enum _Step { photo, species, plan }

class AddPlantScreenV4 extends StatefulWidget {
  final VoidCallback? onPlantAdded;

  const AddPlantScreenV4({super.key, this.onPlantAdded});

  @override
  State<AddPlantScreenV4> createState() => _AddPlantScreenV4State();
}

class _AddPlantScreenV4State extends State<AddPlantScreenV4> {
  final _name = TextEditingController();
  final _manual = TextEditingController();
  final _picker = ImagePicker();

  _Step _step = _Step.photo;

  /// Slot 0 is required ("the whole plant"), slot 1 optional ("close-up").
  final List<Uint8List?> _slots = [null, null];

  bool _busy = false;

  /// Phase 1 stops after "identifying"; phase 2 only starts once a species is
  /// chosen, because the care plan cannot be written before then (ORDER 3.3).
  bool _planPhase = false;

  String? _error;

  List<Map<String, dynamic>> _candidates = const [];
  String? _selectedSpecies;

  /// Identification answers, keyed by the search text ('' for the photo pass).
  /// SPEC asks for the same query to give the same list — this is what keeps
  /// it from reshuffling when the user goes back and forth.
  final Map<String, List<Map<String, dynamic>>> _candidateCache = {};

  Map<String, dynamic>? _plan;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get _canIdentify =>
      _slots[0] != null && _name.text.trim().isNotEmpty && !_busy;

  @override
  void dispose() {
    _name.dispose();
    _manual.dispose();
    super.dispose();
  }

  // ── photos ────────────────────────────────────────────────────────────────

  Future<void> _pick(int slot) async {
    if (_busy) return;
    try {
      if (_isMobile) {
        final image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1600,
          imageQuality: 90,
        );
        if (image == null) return;
        final bytes = await image.readAsBytes();
        if (mounted) setState(() => _slots[slot] = bytes);
      } else {
        final bytes = await pickCenteredImageFromWeb();
        if (bytes != null && mounted) setState(() => _slots[slot] = bytes);
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = l10n.errorPickingImage(e.toString()));
    }
  }

  void _clearSlot(int slot) => setState(() => _slots[slot] = null);

  // ── AI ────────────────────────────────────────────────────────────────────

  /// Asks the analyzer to identify the plant. [hint] is the manual search text;
  /// empty means "go by the photos".
  Future<void> _identify({String hint = ''}) async {
    final cached = _candidateCache[hint];
    if (cached != null) {
      setState(() {
        _candidates = cached;
        _selectedSpecies = null;
        _step = _Step.species;
      });
      return;
    }

    setState(() {
      _busy = true;
      _planPhase = false;
      _error = null;
    });

    try {
      final result = await _post({if (hint.isNotEmpty) 'userHint': hint});

      final candidates =
          (result['speciesCandidates'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];

      if (candidates.isEmpty) {
        // The analyzer skipped identification and went straight to a plan —
        // rare, but it means there is nothing to choose between.
        final plan = _coerceMap(result['recommendations']);
        if (plan != null) {
          setState(() {
            _plan = plan;
            _step = _Step.plan;
          });
          return;
        }
        throw Exception(l10n.addPlantNoSpeciesFound);
      }

      _candidateCache[hint] = candidates;
      setState(() {
        _candidates = candidates;
        _selectedSpecies = null;
        _step = _Step.species;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Second phase: the care plan for the chosen species.
  Future<void> _buildPlan() async {
    final species = _selectedSpecies;
    if (species == null || _busy) return;

    setState(() {
      _busy = true;
      _planPhase = true;
      _error = null;
    });

    try {
      final result = await _post({'confirmedSpecies': species});
      final plan = _coerceMap(result['recommendations']);
      if (plan == null) throw Exception(l10n.addPlantNoPlan);

      setState(() {
        _plan = plan;
        _step = _Step.plan;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> extra) async {
    final images = [
      for (final slot in _slots)
        if (slot != null) base64Encode(slot),
    ];

    final response = await http.post(
      Uri.parse(analyzePlantPhotoUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'base64Image': images.first, // legacy field, still read by the function
        'base64Images': images,
        'language': LanguageService.localeNotifier.value.languageCode,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        ...extra,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(l10n.failedToAnalyzePlantPhoto(response.statusCode));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _readableError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  // ── saving ────────────────────────────────────────────────────────────────

  Future<void> _addToGarden() async {
    final plan = _plan;
    final user = FirebaseAuth.instance.currentUser;
    if (plan == null || user == null || _busy) return;

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final interval =
          _int(plan['next_watering_in_days']) ??
          _int(_coerceMap(plan['watering_plan'])?['next_watering_in_days']) ??
          7;
      final waterNow = _waterNow(plan);

      // The photo lives in Storage, not in Firestore: the document has a 1 MB
      // field limit, and the plant screen wears this picture as its background.
      // Skipping this was why a freshly added plant came up with a placeholder.
      String? imageUrl;
      try {
        imageUrl = await ImageUploadService().uploadPlantImageFromBytes(
          _slots[0]!,
          _name.text.trim(),
        );
      } catch (e) {
        // A plant without its photo is still a plant — better than losing the
        // whole flow at the last step.
        debugPrint('⚠️ Could not upload the plant photo: $e');
      }

      final plant = Plant(
        id: '',
        name: _name.text.trim(),
        species: _str(plan['name']) ?? _selectedSpecies ?? 'Unknown Species',
        imageUrl: imageUrl,
        lastWatered: now,
        // Due today when the analyzer says the soil is already dry, otherwise a
        // full interval out. `lastWatered` stays at the creation time either
        // way — it is the cycle anchor, and the watering-reminder cron reads it
        // to decide the first cycle is already handled.
        nextWatering: waterNow ? now : now.add(Duration(days: interval)),
        wateringFrequency: interval,
        createdAt: now,
        userId: user.uid,
        aiGeneralDescription: _str(plan['general_description']),
        aiName: _str(plan['name']) ?? _selectedSpecies,
        aiMoistureLevel: _str(plan['moisture_level']),
        idealSoilMoistureMin: _int(plan['ideal_soil_moisture_min']),
        idealSoilMoistureMax: _int(plan['ideal_soil_moisture_max']),
        aiLight: _str(plan['light']),
        aiWateringAmount: _str(plan['watering_amount']),
        aiSpecificIssues: _str(plan['specific_issues']),
        aiCareTips: _str(plan['care_tips']),
        careDetails: extractCareDetails(plan['care_recommendations']),
        aiPlantSize: _str(plan['plant_size']),
        aiPotSize: _str(plan['pot_size']),
        aiGrowthStage: _str(plan['growth_stage']),
        wateringAmountMl: _int(plan['amount_ml']),
        wateringRangeMl: _intList(plan['range_ml']),
        nextAfterWateringHours: _int(plan['next_after_watering_in_hours']),
        nextCheckHours: _int(plan['next_check_in_hours']),
        wateringMode: _str(plan['mode']),
        wateringIntervalDays: interval,
        shouldWaterNow: waterNow,
        // The starting score: SPEC 1.1 says a plant always has one, from the
        // moment it is added.
        scanScore: _score(plan['health_score']),
        healthStatus: null,
        healthMessage: null,
        lastHealthCheck: null,
      );

      final plantId = await PlantService().addPlant(plant);
      if (!mounted) return;

      final saved = await PlantService().getPlantById(plantId);
      if (!mounted) return;

      widget.onPlantAdded?.call();
      // Straight to the plant, no "added!" screen in between (ORDER 3.5).
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlantDetailsScreen(plant: saved ?? plant),
        ),
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.errorAddingPlant(_readableError(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.photo;
      _slots[0] = null;
      _slots[1] = null;
      _name.clear();
      _manual.clear();
      _candidates = const [];
      _candidateCache.clear();
      _selectedSpecies = null;
      _plan = null;
      _error = null;
    });
  }

  // ── parsing helpers ───────────────────────────────────────────────────────

  static Map<String, dynamic>? _coerceMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  String? _str(dynamic v) {
    if (v == null || v is Map || v is List) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  int? _int(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// A usable starting score, or null.
  ///
  /// The plan step does not always carry `health_score`, and a literal 0 is not
  /// "no data" — it would brand a brand-new plant as dying and drag the garden
  /// ring down with it. Zero and nothing both mean "we do not know yet", and the
  /// health model has its own default for that.
  int? _score(dynamic v) {
    final n = _int(v)?.clamp(0, 100);
    return (n == null || n == 0) ? null : n;
  }

  List<int>? _intList(dynamic v) {
    if (v is! List) return null;
    return [
      for (final item in v)
        if (_int(item) != null) _int(item)!,
    ];
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionInfo>(
      stream: SubscriptionService().stream,
      initialData: SubscriptionService().currentInfo,
      builder: (context, subSnap) {
        return StreamBuilder<List<Plant>>(
          stream: PlantService().getPlants(),
          builder: (context, plantSnap) {
            final info = subSnap.data;
            final plants = plantSnap.data?.length ?? 0;
            // The free plan's cap, unchanged from production.
            final limitReached =
                info != null && plants >= info.plantLimit && !info.isActive;

            return Scaffold(
              backgroundColor: const Color(0xFFEDF0EC),
              resizeToAvoidBottomInset: true,
              body: Stack(
                children: [
                  const Positioned.fill(child: BotanlyBackground()),
                  // The chosen photo becomes the screen's own background, the
                  // way the plant screen wears its plant.
                  if (_slots[0] != null)
                    Positioned.fill(child: _PhotoBackdrop(bytes: _slots[0]!)),
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: _body(limitReached, info),
                    ),
                  ),
                  if (_busy)
                    Positioned.fill(
                      child: _AnalysisOverlay(
                        photo: _slots[0],
                        planPhase: _planPhase,
                        l10n: l10n,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _body(bool limitReached, SubscriptionInfo? info) {
    if (limitReached && info != null) {
      return Column(
        children: [
          Expanded(child: Center(child: _header())),
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: PlantLimitBanner(info: info),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _header(),
        const SizedBox(height: 16),
        if (_error != null) ...[
          _ErrorNote(text: _error!),
          const SizedBox(height: 12),
        ],
        switch (_step) {
          _Step.photo => _stepPhoto(),
          _Step.species => _stepSpecies(),
          _Step.plan => _stepPlan(),
        },
      ],
    );
  }

  Widget _header() {
    final index = _step.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addPlantStepOf(index + 1, 3).toUpperCase(),
            style: glassFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 11.5 * 0.09,
              color: kGlassMut,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              style: glassFont(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                letterSpacing: 27 * -0.035,
                color: kGlassInk,
              ),
              children: [
                TextSpan(text: '${l10n.addPlantTitleLead} '),
                TextSpan(
                  text: l10n.addPlantTitleAccent,
                  style: const TextStyle(color: kGlassAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= index
                          ? kGlassAccent
                          : const Color(0x1C141E0F),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── step 1 ────────────────────────────────────────────────────────────────

  Widget _stepPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BotanlyField(
                      controller: _name,
                      hint: l10n.plantNameHint,
                      glyph: BotanlySvg.leaf,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 9),
                  _DiceButton(onTap: _rollName),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                l10n.addPlantNameHint,
                style: glassFont(
                  fontSize: 12.5,
                  height: 1.45,
                  color: kGlassMut,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kGlassLeafBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const BotanlyGlyph(
                      BotanlySvg.gallery,
                      size: 16,
                      color: kGlassAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.addPlantPhotosTitle,
                    style: glassFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.02,
                      color: kGlassInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSlot(
                      bytes: _slots[0],
                      title: l10n.addPlantWholePlant,
                      subtitle: l10n.addPlantWholePlantHint,
                      tag: l10n.addPlantRequired,
                      required: true,
                      onTap: () => _pick(0),
                      onClear: () => _clearSlot(0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhotoSlot(
                      bytes: _slots[1],
                      title: l10n.addPlantCloseUpTitle,
                      subtitle: l10n.addPlantCloseUpDesc,
                      tag: l10n.addPlantCloseUpTag,
                      required: false,
                      onTap: () => _pick(1),
                      onClear: () => _clearSlot(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                l10n.addPlantTwoAnglesHint,
                style: glassFont(
                  fontSize: 12.5,
                  height: 1.45,
                  color: kGlassMut,
                ),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _Tip(BotanlySvg.sun, l10n.addPlantTipLight),
                  _Tip(BotanlySvg.leaf, l10n.addPlantTipLeaves),
                  _Tip(BotanlySvg.check, l10n.addPlantTipSingle),
                ],
              ),
              const SizedBox(height: 14),
              BotanlyButton(
                label: l10n.addPlantIdentifyCta,
                glyph: BotanlySvg.sparkle,
                onTap: _canIdentify ? () => _identify() : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A name so the field is never the thing standing between a user and their
  /// plant. Deliberately silly — the copy under the field promises as much.
  void _rollName() {
    final names = l10n.addPlantRandomNames.split('|');
    final taken = _name.text.trim();
    final pool = names.where((n) => n != taken).toList();
    if (pool.isEmpty) return;
    final next = pool[math.Random().nextInt(pool.length)];
    setState(() => _name.text = next);
    HapticFeedback.selectionClick();
  }

  // ── step 2 ────────────────────────────────────────────────────────────────

  Widget _stepSpecies() {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGlassLeafBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const BotanlyGlyph(
                  BotanlySvg.scan,
                  size: 16,
                  color: kGlassAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.addPlantIsThisYourPlant,
                  style: glassFont(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 15.5 * -0.02,
                    color: kGlassInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            l10n.addPlantPickSpeciesHint,
            style: glassFont(fontSize: 12.5, height: 1.45, color: kGlassMut),
          ),
          const SizedBox(height: 13),
          for (final candidate in _candidates) ...[
            _SpeciesRow(
              data: candidate,
              selected: _selectedSpecies == _speciesKey(candidate),
              onTap: () =>
                  setState(() => _selectedSpecies = _speciesKey(candidate)),
            ),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 3),
          _GhostButton(
            label: l10n.addPlantNoneMatch,
            glyph: BotanlySvg.edit,
            onTap: () => setState(() => _manualOpen = !_manualOpen),
          ),
          if (_manualOpen) ...[
            const SizedBox(height: 12),
            Text(
              l10n.addPlantManualHint,
              style: glassFont(fontSize: 12.5, height: 1.45, color: kGlassMut),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: BotanlyField(
                    controller: _manual,
                    hint: l10n.addPlantManualPlaceholder,
                    glyph: BotanlySvg.scan,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => _searchManual(v),
                  ),
                ),
                const SizedBox(width: 9),
                _DiceButton(
                  glyph: BotanlySvg.scan,
                  onTap: () => _searchManual(_manual.text),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          BotanlyButton(
            label: l10n.addPlantBuildPlanCta,
            onTap: _selectedSpecies == null ? null : _buildPlan,
          ),
        ],
      ),
    );
  }

  bool _manualOpen = false;

  void _searchManual(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    _identify(hint: query);
  }

  String _speciesKey(Map<String, dynamic> candidate) =>
      _str(candidate['scientific_name']) ??
      _str(candidate['common_name']) ??
      '';

  // ── step 3 ────────────────────────────────────────────────────────────────

  Widget _stepPlan() {
    final plan = _plan!;
    final scientific = _str(plan['scientific_name']) ?? _selectedSpecies ?? '';
    final ml = _int(plan['amount_ml']);
    final interval =
        _int(plan['next_watering_in_days']) ??
        _int(_coerceMap(plan['watering_plan'])?['next_watering_in_days']) ??
        7;
    final score = _score(plan['health_score']);

    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PlanAvatar(bytes: _slots[0]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glassFont(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 19 * -0.03,
                        color: kGlassInk,
                      ),
                    ),
                    if (scientific.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        scientific,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: glassFont(
                          fontSize: 13,
                          letterSpacing: 0,
                          color: kGlassMut,
                        ),
                      ),
                    ],
                    if (score != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: kGlassAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.addPlantStartingScore(score),
                            style: glassFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: kGlassGreenText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // IntrinsicHeight, потому что `stretch` в Row внутри скролла просит
          // бесконечную высоту: раскладка падала, и всё ниже — плитки, план и
          // кнопка «Добавить в сад» — просто не рисовалось.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PlanTile(
                    glyph: BotanlySvg.drop,
                    tint: kGlassWaterBg,
                    color: kGlassWater,
                    label: l10n.addPlantPlanWatering,
                    value: l10n.addPlantEveryNDays(interval),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanTile(
                    glyph: BotanlySvg.sun,
                    tint: kGlassSunBg,
                    color: kGlassSun,
                    label: l10n.addPlantPlanLight,
                    value: _str(plan['light']) ?? '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PlanTile(
                    glyph: BotanlySvg.soil,
                    tint: kGlassLeafBg,
                    color: kGlassAccent,
                    // Words, not percentages: the numbers stay in the care card
                    // on the plant screen (CHANGELOG v4).
                    label: l10n.addPlantPlanSoil,
                    value: _moistureWords(plan),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.addPlantCarePlan.toUpperCase(),
                  style: glassFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 11.5 * 0.09,
                    color: kGlassMut,
                  ),
                ),
              ),
              Text(
                l10n.addPlantNTasks(3),
                style: glassFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kGlassMut2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // These three are exactly what the scheduler will create, so the plan
          // the user accepts is the plan they get.
          _PlanRow(
            glyph: BotanlySvg.drop,
            tint: kGlassWaterBg,
            color: kGlassWater,
            title: l10n.addPlantFirstWatering,
            detail: firstWateringDetail(
              l10n,
              ml: ml,
              waterNow: _waterNow(plan),
              intervalDays: interval,
            ),
          ),
          const SizedBox(height: 9),
          _PlanRow(
            glyph: BotanlySvg.fertilizer,
            tint: kGlassLeafBg,
            color: kGlassAccent,
            title: l10n.addPlantFertilising,
            detail: l10n.addPlantFertilisingDetail,
          ),
          const SizedBox(height: 9),
          _PlanRow(
            glyph: BotanlySvg.scan,
            tint: kGlassSunBg,
            color: kGlassSun,
            title: l10n.addPlantHealthCheck,
            detail: l10n.addPlantHealthCheckDetail,
          ),
          const SizedBox(height: 16),
          BotanlyButton(
            label: l10n.addPlantAddToGarden,
            glyph: BotanlySvg.plus,
            onTap: _busy ? null : _addToGarden,
          ),
        ],
      ),
    );
  }

  String _moistureWords(Map<String, dynamic> plan) {
    final raw = _str(plan['moisture_level'])?.toLowerCase() ?? '';
    if (raw.contains('dry') || raw.contains('сух')) return l10n.moistureDry;
    if (raw.contains('wet') || raw.contains('влажн')) return l10n.moistureWet;
    return l10n.addPlantSoilSlightlyMoist;
  }

  /// Does the analyzer want this plant watered right away?
  ///
  /// Read through the same two shapes as the interval: some responses carry the
  /// watering plan flattened onto the root, others keep it nested.
  static bool _waterNow(Map<String, dynamic> plan) =>
      plan['should_water_now'] == true ||
      _coerceMap(plan['watering_plan'])?['should_water_now'] == true;
}

/// Detail line under "First watering" in the care plan.
///
/// The mockup hard-coded "today" here and taking it literally meant the row
/// announced a watering due now even when the analyzer had scheduled the first
/// one ten days out — contradicting the watering tile two rows above it. The
/// date now comes from the same `should_water_now` the plant is saved with, so
/// the plan the user accepts is the plan they get.
String firstWateringDetail(
  AppLocalizations l10n, {
  required int? ml,
  required bool waterNow,
  required int intervalDays,
}) {
  // "today" is already lowercase; "In 10 days" is a sentence opener elsewhere
  // and has to be folded down before it can sit after a middot.
  final when = waterNow ? l10n.addPlantToday : l10n.whenInNDays(intervalDays);
  if (ml == null || ml <= 0) {
    return waterNow ? l10n.addPlantWaterToday : when;
  }
  return '$ml ${l10n.millilitersShort} · ${glassesLabel(l10n, ml)} · '
      '${when.toLowerCase()}';
}

/// Millilitres as glasses — the unit people actually pour with.
String glassesLabel(AppLocalizations l10n, int ml) {
  final quarters = (ml * 4 / _kGlassMl).round().clamp(1, 1 << 20);
  if (quarters == 4) return l10n.glassesOne;
  final whole = quarters ~/ 4;
  const marks = ['', '¼', '½', '¾'];
  final fraction = marks[quarters % 4];
  final value = whole == 0
      ? fraction
      : (fraction.isEmpty ? '$whole' : '$whole $fraction');
  return l10n.glassesAmount(value);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pieces
// ─────────────────────────────────────────────────────────────────────────────

/// The chosen photo, blurred behind the glass — the same trick the plant screen
/// uses, so adding a plant already feels like the plant's own screen.
class _PhotoBackdrop extends StatelessWidget {
  final Uint8List bytes;

  const _PhotoBackdrop({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.5, child: Image.memory(bytes, fit: BoxFit.cover)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFEDF0EC).withAlpha(200),
                const Color(0xFFEDF0EC).withAlpha(245),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final Uint8List? bytes;
  final String title;
  final String subtitle;
  final String tag;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PhotoSlot({
    required this.bytes,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.required,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filled = bytes != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 190),
      child: AspectRatio(
        aspectRatio: 1,
        child: BotanlyPress(
          scale: 0.98,
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: filled ? null : const Color(0x99FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: filled
                          ? const Color(0xE6FFFFFF)
                          : kGlassAccent.withAlpha(92),
                      width: 1.5,
                    ),
                  ),
                  child: filled
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Image.memory(bytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BotanlyGlyph(
                              required ? BotanlySvg.gallery : BotanlySvg.leaf,
                              size: 24,
                              color: kGlassAccent.withAlpha(140),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: glassFont(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: kGlassInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: glassFont(
                                  fontSize: 11.5,
                                  color: kGlassMut,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: required
                                    ? kGlassLeafBg
                                    : const Color(0x12141E0F),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag.toUpperCase(),
                                style: glassFont(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 11 * 0.03,
                                  color: required
                                      ? kGlassGreenText
                                      : kGlassMut2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (filled)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    // 28 px visual inside a 44 px target.
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xCC12180E),
                            shape: BoxShape.circle,
                          ),
                          child: const BotanlyGlyph(
                            BotanlySvg.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
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

class _Tip extends StatelessWidget {
  final String glyph;
  final String label;

  const _Tip(this.glyph, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: kGlassAccent.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kGlassAccent.withAlpha(56), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotanlyGlyph(glyph, size: 13, color: kGlassGreenText),
          const SizedBox(width: 6),
          Text(
            label,
            style: glassFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: kGlassGreenText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  final VoidCallback onTap;
  final String glyph;

  const _DiceButton({required this.onTap, this.glyph = BotanlySvg.sparkle});

  @override
  Widget build(BuildContext context) {
    return BotanlyPress(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kGlassAccent.withAlpha(28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kGlassAccent.withAlpha(61), width: 0.5),
        ),
        child: BotanlyGlyph(glyph, size: 19, color: kGlassGreenText),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final String glyph;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BotanlyPress(
      scale: 0.985,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xB3FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BotanlyGlyph(glyph, size: 16, color: kGlassInk2),
            const SizedBox(width: 8),
            Text(
              label,
              style: glassFont(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kGlassInk2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A candidate species: reference photo of the *species* (not the user's shot),
/// common name, latin name and how sure the analyzer is.
class _SpeciesRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool selected;
  final VoidCallback onTap;

  const _SpeciesRow({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final common = (data['common_name'] ?? '').toString().trim();
    final scientific = (data['scientific_name'] ?? '').toString().trim();
    final imageUrl = (data['image_url'] ?? '').toString().trim();
    final confidence = data['confidence'];
    final percent = confidence is num
        ? (confidence <= 1 ? (confidence * 100).round() : confidence.round())
        : null;

    return BotanlyPress(
      scale: 0.985,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? kGlassAccent.withAlpha(26)
              : const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kGlassAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imageUrl.isEmpty
                    ? const ColoredBox(
                        color: kGlassLeafBg,
                        child: Center(
                          child: BotanlyGlyph(
                            BotanlySvg.leaf,
                            size: 22,
                            color: kGlassAccent,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: kGlassLeafBg,
                          child: Center(
                            child: BotanlyGlyph(
                              BotanlySvg.leaf,
                              size: 22,
                              color: kGlassAccent,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    common.isEmpty ? scientific : common,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glassFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15 * -0.015,
                      color: kGlassInk,
                    ),
                  ),
                  if (scientific.isNotEmpty && common.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      scientific,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glassFont(
                        fontSize: 12.5,
                        letterSpacing: 0,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (percent != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kGlassLeafBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent%',
                  style: glassFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kGlassGreenText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanAvatar extends StatelessWidget {
  final Uint8List? bytes;

  const _PlanAvatar({this.bytes});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 62,
        height: 62,
        child: bytes == null
            ? const ColoredBox(
                color: kGlassLeafBg,
                child: Center(
                  child: BotanlyGlyph(
                    BotanlySvg.leaf,
                    size: 26,
                    color: kGlassAccent,
                  ),
                ),
              )
            : Image.memory(bytes!, fit: BoxFit.cover),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String label;
  final String value;

  const _PlanTile({
    required this.glyph,
    required this.tint,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: BotanlyGlyph(glyph, size: 15, color: color),
          ),
          const SizedBox(height: 7),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: glassFont(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 10 * 0.06,
              color: kGlassMut,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: glassFont(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 14 * -0.015,
              color: kGlassInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String title;
  final String detail;

  const _PlanRow({
    required this.glyph,
    required this.tint,
    required this.color,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: BotanlyGlyph(glyph, size: 17, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: glassFont(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 14.5 * -0.015,
                    color: kGlassInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 12.5,
                    height: 1.35,
                    color: kGlassMut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  final String text;

  const _ErrorNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGlassWarm.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlassWarm.withAlpha(66), width: 0.5),
      ),
      child: Row(
        children: [
          const BotanlyGlyph(
            BotanlySvg.warningTriangle,
            size: 17,
            color: kGlassWarm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: glassFont(fontSize: 13, height: 1.4, color: kGlassAlert),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen loader with the two phases from ORDER 3.3: identification stops
/// at "working out the species"; the plan line only lights up once a species has
/// been chosen and the second request is on the wire.
class _AnalysisOverlay extends StatefulWidget {
  final Uint8List? photo;
  final bool planPhase;
  final AppLocalizations l10n;

  const _AnalysisOverlay({
    required this.photo,
    required this.planPhase,
    required this.l10n,
  });

  @override
  State<_AnalysisOverlay> createState() => _AnalysisOverlayState();
}

class _AnalysisOverlayState extends State<_AnalysisOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scan;
  late final AnimationController _halo;
  late final AnimationController _blink;
  int _row = 0;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    // `blink 1.2s infinite` from the handoff: the dot of the current step
    // breathes so the screen never looks stuck while the request is in flight.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _advance();
  }

  Future<void> _advance() async {
    // The checklist is cosmetic: it walks forward on a timer while the real
    // request runs, and stops one short so it never claims to be finished.
    while (mounted && _row < 1) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _row++);
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    _halo.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <String>[
      widget.l10n.addPlantLoaderPhotos,
      widget.l10n.addPlantLoaderIdentify,
      if (widget.planPhase) widget.l10n.addPlantLoaderPlan,
    ];
    // How many steps are finished. The one right after them is the step being
    // worked on: it gets a blinking dot, not a tick, because nothing about it is
    // done yet (the handoff's `.st.now`).
    final done = widget.planPhase ? rows.length - 1 : _row;

    return ColoredBox(
      color: const Color(0xF2EDF0EC),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _halo,
                    builder: (_, __) {
                      final t = _halo.value;
                      return Opacity(
                        opacity: t >= 0.7 ? 0 : 0.5 * (1 - t / 0.7),
                        child: Transform.scale(
                          scale: 0.98 + 0.3 * t,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kGlassAccent.withAlpha(71),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.photo != null)
                            Image.memory(widget.photo!, fit: BoxFit.cover)
                          else
                            const ColoredBox(color: kGlassLeafBg),
                          AnimatedBuilder(
                            animation: _scan,
                            builder: (_, __) => Align(
                              alignment: Alignment(0, _scan.value * 2 - 1),
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kGlassAccent.withAlpha(0),
                                      kGlassAccent,
                                      kGlassAccent.withAlpha(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepDot(
                      state: i < done
                          ? _StepState.done
                          : (i == done ? _StepState.now : _StepState.idle),
                      blink: _blink,
                    ),
                    const SizedBox(width: 10),
                    Opacity(
                      opacity: i > done ? 0.4 : 1,
                      child: Text(
                        rows[i],
                        style: glassFont(
                          fontSize: 14,
                          fontWeight: i == done
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: i <= done ? kGlassInk : kGlassMut,
                        ),
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
}

/// One step of the loader checklist.
///
/// Three states, straight from the handoff: finished carries a tick, the step in
/// progress shows a blinking dot inside a green ring, and anything further out
/// is a dim outline.
enum _StepState { done, now, idle }

class _StepDot extends StatelessWidget {
  final _StepState state;
  final Animation<double> blink;

  const _StepDot({required this.state, required this.blink});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == _StepState.done ? kGlassAccent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: state == _StepState.idle
              ? const Color(0x24141E0F)
              : kGlassAccent,
          width: 2,
        ),
      ),
      child: switch (state) {
        _StepState.done => const BotanlyGlyph(
          BotanlySvg.check,
          size: 11,
          color: Colors.white,
        ),
        _StepState.now => FadeTransition(
          // 1 → .25 → 1, the CSS keyframes as a reversing tween.
          opacity: Tween<double>(begin: 1, end: 0.25).animate(blink),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: kGlassAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _StepState.idle => const SizedBox.shrink(),
      },
    );
  }
}
