/// Add a plant — four steps (handoff v4 + the conditions quiz, SPEC §0).
///
/// Name and photos → species → conditions quiz → care plan. The backend is
/// unchanged: the same `analyzePlantPhoto` endpoint answers with either a list
/// of species candidates or a full set of recommendations, and which one comes
/// back is what moves the user between the first two steps.
///
/// The quiz sits between them because the things that matter most to a watering
/// plan — pot size, material, drainage, where the plant stands — cannot be read
/// off a photo. The analyzer gives the species baseline; the quiz bends it into
/// a plan for this particular plant, and the answers are stored on the plant so
/// every later AI call sees them.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/screens/plant_limit_screen.dart';
import 'package:plant_care/screens/subscription_locked_screen.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/services/image_upload_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/utils/care_sections.dart';
import 'package:plant_care/utils/cloud_functions.dart';
import 'package:plant_care/utils/image_source_picker.dart';
import 'package:plant_care/utils/plant_conditions.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// Glass base for a 200 ml glass — the same constant the plant screen uses.
const _kGlassMl = kGlassMl;

enum _Step { photo, species, conditions, plan }

/// How many questions the conditions quiz asks.
const _kQuestions = 4;

/// Breathing room between the pinned quiz button and the tab bar under it.
///
/// Only this — no tab-bar height. The shell runs `extendBody: true`, which
/// folds the bar into `MediaQuery.padding.bottom`, so adding it again is what
/// used to leave the button hanging in the middle of the card.
const double _kCtaGap = 8;

/// The pinned footer: its fade-out scrim plus the button under it (14 pt of
/// padding above and below a 15.5 pt line). Used to end the list above it.
const double _kCtaHeight = 30 + 14 * 2 + 22;

class AddPlantScreenV4 extends StatefulWidget {
  final VoidCallback? onPlantAdded;

  /// Switches the shell to the plant list — the "free up a slot" route out of
  /// the limit screen (SPEC 11, §2.3).
  final VoidCallback? onOpenPlants;

  const AddPlantScreenV4({super.key, this.onPlantAdded, this.onOpenPlants});

  @override
  State<AddPlantScreenV4> createState() => _AddPlantScreenV4State();
}

class _AddPlantScreenV4State extends State<AddPlantScreenV4> {
  final _name = TextEditingController();
  final _manual = TextEditingController();

  _Step _step = _Step.photo;

  /// The one scroll view of the flow — held so every step and every question
  /// can start at the top rather than where the previous one was left.
  final _scroll = ScrollController();

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

  // ── conditions quiz (SPEC §3) ─────────────────────────────────────────────

  /// Which of the four questions is on screen.
  int _q = 0;

  /// 16 cm counts as an answer from the start (SPEC 3.2): a disabled "Next"
  /// under a slider that already shows a value reads as a bug, not a rule.
  int _potCm = kPotDefaultCm;

  /// The user said they don't know the pot, so the analyzer measures it off the
  /// photo instead. Kept apart from [_potCm] because the slider always holds a
  /// number — "unknown" is a fact about where that number came from, not a
  /// value the slider could show.
  bool _potFromPhoto = false;

  /// Nothing else is pre-selected — a pre-ticked answer is an answer the user
  /// never gave, and these five feed straight into the plan.
  String? _material;
  bool? _drainage;
  String? _placement;
  bool? _nearHeat;

  /// Days since the last watering, or [kLastWateredUnknown]. Not a condition —
  /// it only anchors the first watering date (SPEC 1.2).
  int? _lastWateredDaysAgo;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Has the question at [index] been answered? "Next" waits on this.
  bool _questionReady(int index) => switch (index) {
    0 => true,
    1 => _material != null && _drainage != null,
    2 => _placement != null && _nearHeat != null,
    _ => _lastWateredDaysAgo != null,
  };

  /// One back button for the whole flow (SPEC §5). Null on the first step,
  /// where the slot stays reserved so the title does not jump sideways.
  VoidCallback? get _onBack => switch (_step) {
    _Step.photo => null,
    _Step.species => () => setState(() => _step = _Step.photo),
    _Step.conditions => () {
      setState(() {
        if (_q > 0) {
          _q--;
        } else {
          _step = _Step.species;
        }
      });
      _scrollToTop();
    },
    _Step.plan => () {
      setState(() {
        _step = _Step.conditions;
        _q = _kQuestions - 1;
      });
      _scrollToTop();
    },
  };

  void _nextQuestion() {
    if (!_questionReady(_q)) return;
    HapticFeedback.selectionClick();
    if (_q < _kQuestions - 1) {
      setState(() => _q++);
      _scrollToTop();
      return;
    }
    _finishQuiz();
  }

  /// Back to the top of the card whenever the content is replaced.
  ///
  /// Without it the next question opens at the scroll offset of the previous
  /// one — the user answers the bottom of question 2 and lands mid-way down
  /// question 3, with its title off-screen.
  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(0);
  }

  /// End of the quiz: the plan is written now, with the answers in hand.
  ///
  /// The loader is not decoration — the species request really does run here,
  /// and its third line is the one the user is waiting on.
  void _finishQuiz() {
    if (_selectedSpecies != null) {
      _buildPlan();
      return;
    }
    // The analyzer had already skipped identification and answered with a plan.
    if (_plan != null) setState(() => _step = _Step.plan);
  }

  bool get _canIdentify =>
      _slots[0] != null && _name.text.trim().isNotEmpty && !_busy;

  @override
  void dispose() {
    _name.dispose();
    _manual.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── photos ────────────────────────────────────────────────────────────────

  Future<void> _pick(int slot) async {
    if (_busy) return;
    try {
      final bytes = await pickImageBytes(
        context,
        maxWidth: 1200,
        maxHeight: 1600,
      );
      if (bytes != null && mounted) setState(() => _slots[slot] = bytes);
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
        // rare, but it means there is nothing to choose between. The quiz is
        // still asked: it is not optional, and the plan is worth less without
        // it than the species guess it came with.
        final plan = _coerceMap(result['recommendations']);
        if (plan != null) {
          setState(() {
            _plan = plan;
            _step = _Step.conditions;
            _q = 0;
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
      _scrollToTop();
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
      _scrollToTop();
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
      final interval = _plannedInterval(plan);
      final daysAgo = _lastWateredDaysAgo ?? kLastWateredUnknown;
      final firstIn = firstWateringInDays(
        intervalDays: interval,
        lastWateredDaysAgo: daysAgo,
      );
      // The cycle anchor, not "now": a plant watered three days ago is three
      // days into its cycle, and pretending otherwise pushes the first task a
      // full interval too late.
      final anchor = lastWateredAnchor(now, daysAgo);
      // The pot the user measured beats the pot the analyzer read off a photo —
      // that is the whole reason the question is asked. The photo only answers
      // when the user said they don't know.
      final potCm = _potDiameter(plan);
      final ml = wateringMlForPot(potCm);
      final problems = _problemTasks;

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
        lastWatered: anchor,
        nextWatering: now.add(Duration(days: firstIn)),
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
        wateringAmountMl: ml,
        wateringRangeMl: _intList(plan['range_ml']),
        nextAfterWateringHours: _int(plan['next_after_watering_in_hours']),
        nextCheckHours: _int(plan['next_check_in_hours']),
        wateringMode: _str(plan['mode']),
        wateringIntervalDays: interval,
        lastWateredAt: anchor,
        shouldWaterNow: firstIn == 0,
        // The quiz answers, stored for good: every later health check, chat
        // reply and plan recalculation reads them (SPEC 1.3).
        potDiameterCm: potCm,
        // Which of the three this number is. Without it every later prompt
        // states an assumed 16 cm as measured fact.
        potDiameterSource: !_potFromPhoto
            ? 'user'
            : (_int(plan['pot_diameter_cm']) != null ? 'photo' : 'assumed'),
        potMaterial: _material,
        hasDrainage: _drainage,
        placement: _placement,
        nearHeatSource: _nearHeat,
        conditionsUpdatedAt: now,
        // The starting score: SPEC 1.1 says a plant always has one, from the
        // moment it is added. SPEC 4.4 sets it from what the quiz uncovered —
        // a plant with no drainage next to a radiator does not start at full
        // health just because the photo looked fine.
        scanScore: startingScore(problems.length),
        healthStatus: null,
        healthMessage: null,
        lastHealthCheck: null,
      );

      final plantId = await PlantService().addPlant(plant);
      if (!mounted) return;

      // The problems the quiz uncovered become real tasks, not just rows in a
      // preview — the plan step promises "this is what you will get", and a
      // promised task the user then cannot find is worse than no promise.
      //
      // They are written once, here, rather than by the scheduler: fixing
      // drainage is a one-off job, and the scheduler would re-issue it every
      // six hours for as long as `hasDrainage` stays false.
      if (problems.isNotEmpty) {
        try {
          await TaskService().createFromAnalysis(
            plantId: plantId,
            tasks: [
              for (final task in problems)
                CareTask(
                  id: '',
                  plantId: plantId,
                  userId: user.uid,
                  title: switch (task) {
                    ConditionTask.light => l10n.addPlantAddLight,
                    ConditionTask.drainage => l10n.addPlantAddDrainage,
                    ConditionTask.heat => l10n.addPlantMoveFromHeat,
                  },
                  detail: switch (task) {
                    ConditionTask.light => l10n.addPlantAddLightDetail,
                    ConditionTask.drainage => l10n.addPlantAddDrainageDetail,
                    ConditionTask.heat => l10n.addPlantMoveFromHeatDetail,
                  },
                  category: switch (task) {
                    ConditionTask.light => TaskCategory.light,
                    ConditionTask.drainage => TaskCategory.soil,
                    ConditionTask.heat => TaskCategory.other,
                  },
                  source: TaskSource.analysis,
                  // Today, so a task the user has only just been handed is
                  // never shown as already overdue.
                  dueAt: now,
                ),
            ],
          );
        } catch (e) {
          // A plant without its starting chores is still a plant.
          debugPrint('⚠️ Could not create the starting tasks: $e');
        }
      }

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
      _q = 0;
      _potCm = kPotDefaultCm;
      _potFromPhoto = false;
      _material = null;
      _drainage = null;
      _placement = null;
      _nearHeat = null;
      _lastWateredDaysAgo = null;
    });
  }

  // ── the plan, as bent by the answers (SPEC §4) ────────────────────────────

  /// The species baseline from the analyzer, before the conditions touch it.
  /// The diameter the plan is built on.
  ///
  /// The slider's number unless the user handed the question to the photo, in
  /// which case it is what the analyzer measured — and the average only if the
  /// pot was not clearly in frame and the analyzer honestly said nothing.
  int _potDiameter(Map<String, dynamic>? plan) {
    if (!_potFromPhoto) return _potCm;
    return _int(plan?['pot_diameter_cm']) ?? kPotDefaultCm;
  }

  int _baseInterval(Map<String, dynamic> plan) =>
      _int(plan['next_watering_in_days']) ??
      _int(_coerceMap(plan['watering_plan'])?['next_watering_in_days']) ??
      7;

  int _plannedInterval(Map<String, dynamic> plan) =>
      conditionedWateringInterval(
        baseDays: _baseInterval(plan),
        material: _material,
        placement: _placement,
        nearHeatSource: _nearHeat,
        hasDrainage: _drainage,
      );

  List<ConditionTask> get _problemTasks => conditionTasks(
    placement: _placement,
    hasDrainage: _drainage,
    nearHeatSource: _nearHeat,
  );

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

            // Two different refusals, two different screens (SPEC 11, §2.1).
            //
            // No access at all — nothing can be generated, so the paywall.
            // Access but no room — the user can still fix this themselves by
            // removing a plant, so the slot screen with both ways out. Merging
            // them is what produced "plant limit reached" for someone whose
            // trial had ended with one plant in the garden.
            if (info != null && !info.hasAccess) {
              return SubscriptionLockedScreen(
                reason: info.lockedReason(plants)!,
                plantCount: plants,
                info: info,
              );
            }
            if (info != null && info.slotsExhausted(plants)) {
              return PlantLimitScreen(
                usedSlots: plants,
                info: info,
                onFreeUpSlot: () => widget.onOpenPlants?.call(),
              );
            }

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
                    child: SafeArea(bottom: false, child: _body()),
                  ),
                  // The quiz CTA is pinned above the tab bar in its own layer
                  // (SPEC 3.1). Inside the scroll it slides under the tab bar
                  // on the longer questions, and in the longer locales it does
                  // so on all of them.
                  if (_step == _Step.conditions)
                    Positioned(
                      left: 16,
                      right: 16,
                      // Just the breathing room, nothing more. The shell runs
                      // `extendBody: true`, so inside a tab `padding.bottom`
                      // already carries the tab bar's height — the 88 that used
                      // to be added here counted it a second time and pushed the
                      // button a finger's width up into the content.
                      bottom: _kCtaGap + MediaQuery.of(context).padding.bottom,
                      child: _QuizFooter(
                        label: _q == _kQuestions - 1
                            ? l10n.quizBuildPlan
                            : l10n.quizNext,
                        onTap: _questionReady(_q) ? _nextQuestion : null,
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

  Widget _body() {
    // The quiz footer floats over the list, so the list has to end above it:
    // the gap under the button, plus the button itself.
    final bottomInset = _step == _Step.conditions
        ? _kCtaGap * 2 + _kCtaHeight + MediaQuery.of(context).padding.bottom
        : 120.0;

    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
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
          _Step.conditions => _stepConditions(),
          _Step.plan => _stepPlan(),
        },
      ],
    );
  }

  Widget _header() {
    final index = _step.index;
    final onBack = _onBack;

    // Lead and accent for the step's title. Each locale decides where the green
    // word sits by placing the placeholder — German and French do not put it
    // where Russian does.
    final (String Function(String) template, String accent) = switch (_step) {
      _Step.photo => (l10n.addPlantHeaderPhoto, l10n.addPlantHeaderPhotoAccent),
      _Step.species => (
        l10n.addPlantHeaderSpecies,
        l10n.addPlantHeaderSpeciesAccent,
      ),
      _Step.conditions => (
        l10n.addPlantHeaderConditions,
        l10n.addPlantHeaderConditionsAccent,
      ),
      _Step.plan => (l10n.addPlantHeaderPlan, l10n.addPlantHeaderPlanAccent),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reserved, not removed, on the first step: dropping the button
              // shifts the whole title sideways the moment step two arrives.
              Opacity(
                opacity: onBack == null ? 0 : 1,
                child: IgnorePointer(
                  ignoring: onBack == null,
                  child: _BackButton(
                    label: l10n.addPlantBack,
                    onTap: onBack ?? () {},
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n
                          .addPlantStepOf(index + 1, _Step.values.length)
                          .toUpperCase(),
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
                        children: accentSpans(template, accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _Step.values.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: const Cubic(0.3, 0.7, 0.3, 1),
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
            label: l10n.quizNext,
            // Straight into the quiz, not into the plan: the plan is only
            // written once the conditions are known.
            onTap: _selectedSpecies == null
                ? null
                : () {
                    setState(() {
                      _step = _Step.conditions;
                      _q = 0;
                    });
                    _scrollToTop();
                  },
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

  // ── step 3 · the conditions quiz ──────────────────────────────────────────

  Widget _stepConditions() {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuizDots(
            index: _q,
            total: _kQuestions,
            label: l10n.quizQuestionOf(_q + 1, _kQuestions),
          ),
          const SizedBox(height: 14),
          // Keyed so the slide animation replays on every change of question —
          // without it Flutter reuses the subtree and nothing moves.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: const Cubic(0.22, 1, 0.36, 1),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            // The outgoing question fades under the incoming one instead of
            // reserving its own height, which would make the card jump.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previous.map(
                  (c) => Positioned(left: 0, right: 0, top: 0, child: c),
                ),
                if (current != null) current,
              ],
            ),
            child: KeyedSubtree(
              key: ValueKey(_q),
              child: switch (_q) {
                0 => _questionPot(),
                1 => _questionMaterial(),
                2 => _questionPlacement(),
                _ => _questionLastWatering(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionPot() {
    final ml = wateringMlForPot(_potCm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionHead(
          template: l10n.quizPotQuestion,
          accent: l10n.quizPotQuestionAccent,
          why: l10n.quizPotWhy,
        ),
        _PotView(diameterCm: _potCm),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 86,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: glassFont(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 30 * -0.04,
                    color: kGlassInk,
                  ),
                  children: [
                    TextSpan(text: '$_potCm'),
                    TextSpan(
                      text: ' ${l10n.unitCm}',
                      style: glassFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: kGlassAccent,
                  inactiveTrackColor: const Color(0x1F141E0F),
                  thumbColor: Colors.white,
                  overlayColor: kGlassAccent.withAlpha(28),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 15,
                    elevation: 3,
                  ),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _potCm.toDouble(),
                  min: kPotMinCm.toDouble(),
                  max: kPotMaxCm.toDouble(),
                  divisions: kPotMaxCm - kPotMinCm,
                  // Touching the slider is an answer, so it takes the
                  // question back from the photo.
                  onChanged: (v) => setState(() {
                    _potCm = v.round();
                    _potFromPhoto = false;
                  }),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$kPotMinCm ${l10n.unitCm}',
                style: glassFont(fontSize: 11.5, color: kGlassMut2),
              ),
              Text(
                '$kPotMaxCm ${l10n.unitCm}',
                style: glassFont(fontSize: 11.5, color: kGlassMut2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CalcCard(
          title: l10n.quizPotPerWatering(volumeLabel(l10n, ml)),
          subtitle: ml < kLitreThresholdMl ? glassesLabel(l10n, ml) : '',
        ),
        const SizedBox(height: 10),
        Text(
          l10n.quizPotHint,
          style: glassFont(fontSize: 12.5, height: 1.45, color: kGlassMut),
        ),
        const SizedBox(height: 4),
        // The way out for someone who has no tape measure to hand. Every other
        // question in the quiz offers one; this was the only slider, and a
        // slider has no "don't know" position.
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _potFromPhoto = true);
              _nextQuestion();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.quizPotUnknown,
                style: glassFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kGlassGreenText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionMaterial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionHead(
          template: l10n.quizMaterialQuestion,
          accent: l10n.quizMaterialQuestionAccent,
          why: l10n.quizMaterialWhy,
        ),
        _TileGrid(
          children: [
            _OptionTile(
              glyph: BotanlySvg.drop,
              title: l10n.quizMatPlastic,
              subtitle: l10n.quizMatPlasticDesc,
              selected: _material == PotMaterial.plastic,
              onTap: () => _pickMaterial(PotMaterial.plastic),
            ),
            _OptionTile(
              glyph: BotanlySvg.soil,
              title: l10n.quizMatCeramic,
              subtitle: l10n.quizMatCeramicDesc,
              selected: _material == PotMaterial.ceramic,
              onTap: () => _pickMaterial(PotMaterial.ceramic),
            ),
            _OptionTile(
              glyph: BotanlySvg.flower,
              title: l10n.quizMatTerracotta,
              subtitle: l10n.quizMatTerracottaDesc,
              selected: _material == PotMaterial.terracotta,
              onTap: () => _pickMaterial(PotMaterial.terracotta),
            ),
            _OptionTile(
              glyph: BotanlySvg.infoCircle,
              title: l10n.quizMatUnknown,
              subtitle: l10n.quizMatUnknownDesc,
              selected: _material == PotMaterial.unknown,
              onTap: () => _pickMaterial(PotMaterial.unknown),
            ),
          ],
        ),
        _SubLabel(l10n.quizDrainageLabel),
        _OptionRow(
          glyph: BotanlySvg.dropOutline,
          tint: kGlassWaterBg,
          color: kGlassWater,
          title: l10n.quizDrainageYes,
          subtitle: l10n.quizDrainageYesDesc,
          selected: _drainage == true,
          onTap: () => _pickDrainage(true),
        ),
        const SizedBox(height: 8),
        _OptionRow(
          glyph: BotanlySvg.close,
          tint: kGlassWarmBg,
          color: kGlassWarm,
          title: l10n.quizDrainageNo,
          subtitle: l10n.quizDrainageNoDesc,
          selected: _drainage == false,
          onTap: () => _pickDrainage(false),
        ),
      ],
    );
  }

  Widget _questionPlacement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionHead(
          template: l10n.quizPlaceQuestion,
          accent: l10n.quizPlaceQuestionAccent,
          why: l10n.quizPlaceWhy,
        ),
        _TileGrid(
          children: [
            _placeTile(
              Placement.south,
              BotanlySvg.sun,
              kGlassSunBg,
              kGlassSun,
              l10n.quizPlaceSouth,
              l10n.quizPlaceSouthDesc,
            ),
            _placeTile(
              Placement.east,
              BotanlySvg.speciesSun,
              kGlassSunBg,
              kGlassSun,
              l10n.quizPlaceEast,
              l10n.quizPlaceEastDesc,
            ),
            _placeTile(
              Placement.north,
              BotanlySvg.gallery,
              kGlassWaterBg,
              kGlassWater,
              l10n.quizPlaceNorth,
              l10n.quizPlaceNorthDesc,
            ),
            _placeTile(
              Placement.room,
              BotanlySvg.pin,
              const Color(0x12141E0F),
              kGlassMut,
              l10n.quizPlaceRoom,
              l10n.quizPlaceRoomDesc,
            ),
            _placeTile(
              Placement.balcony,
              BotanlySvg.leafPair,
              kGlassLeafBg,
              kGlassAccent,
              l10n.quizPlaceBalcony,
              l10n.quizPlaceBalconyDesc,
            ),
            _placeTile(
              Placement.bath,
              BotanlySvg.drop,
              kGlassWaterBg,
              kGlassWater,
              l10n.quizPlaceBath,
              l10n.quizPlaceBathDesc,
            ),
          ],
        ),
        _SubLabel(l10n.quizHeatLabel),
        _OptionRow(
          glyph: BotanlySvg.leaf,
          title: l10n.quizHeatNo,
          subtitle: l10n.quizHeatNoDesc,
          selected: _nearHeat == false,
          onTap: () => _pickHeat(false),
        ),
        const SizedBox(height: 8),
        _OptionRow(
          glyph: BotanlySvg.thermometer,
          tint: kGlassWarmBg,
          color: kGlassWarm,
          title: l10n.quizHeatYes,
          subtitle: l10n.quizHeatYesDesc,
          selected: _nearHeat == true,
          onTap: () => _pickHeat(true),
        ),
      ],
    );
  }

  Widget _placeTile(
    String key,
    String glyph,
    Color tint,
    Color color,
    String title,
    String subtitle,
  ) => _OptionTile(
    glyph: glyph,
    tint: tint,
    color: color,
    title: title,
    subtitle: subtitle,
    selected: _placement == key,
    onTap: () {
      HapticFeedback.selectionClick();
      setState(() => _placement = key);
    },
  );

  Widget _questionLastWatering() {
    Widget row(
      String glyph,
      Color tint,
      Color color,
      String title,
      String subtitle,
      int days,
    ) => _OptionRow(
      glyph: glyph,
      tint: tint,
      color: color,
      title: title,
      subtitle: subtitle,
      selected: _lastWateredDaysAgo == days,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _lastWateredDaysAgo = days);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuestionHead(
          template: l10n.quizWaterQuestion,
          accent: l10n.quizWaterQuestionAccent,
          why: l10n.quizWaterWhy,
        ),
        row(
          BotanlySvg.drop,
          kGlassWaterBg,
          kGlassWater,
          l10n.quizWaterToday,
          l10n.quizWaterTodayDesc,
          0,
        ),
        const SizedBox(height: 8),
        row(
          BotanlySvg.dropOutline,
          kGlassWaterBg,
          kGlassWater,
          l10n.quizWaterFewDays,
          l10n.quizWaterFewDaysDesc,
          3,
        ),
        const SizedBox(height: 8),
        row(
          BotanlySvg.clock,
          kGlassSunBg,
          kGlassSun,
          l10n.quizWaterWeek,
          l10n.quizWaterWeekDesc,
          7,
        ),
        const SizedBox(height: 8),
        row(
          BotanlySvg.infoCircle,
          const Color(0x12141E0F),
          kGlassMut,
          l10n.quizWaterUnknown,
          l10n.quizWaterUnknownDesc,
          kLastWateredUnknown,
        ),
      ],
    );
  }

  void _pickMaterial(String value) {
    HapticFeedback.selectionClick();
    setState(() => _material = value);
  }

  void _pickDrainage(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _drainage = value);
  }

  void _pickHeat(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _nearHeat = value);
  }

  // ── step 4 ────────────────────────────────────────────────────────────────

  Widget _stepPlan() {
    final plan = _plan!;
    final scientific = _str(plan['scientific_name']) ?? _selectedSpecies ?? '';
    final ml = wateringMlForPot(_potDiameter(plan));
    final interval = _plannedInterval(plan);
    final problems = _problemTasks;
    final score = startingScore(problems.length);
    final daysAgo = _lastWateredDaysAgo ?? kLastWateredUnknown;
    final firstIn = firstWateringInDays(
      intervalDays: interval,
      lastWateredDaysAgo: daysAgo,
    );

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
                    // The placement table, not the analyzer: the user told us
                    // which window this plant actually stands at.
                    value: _lightLabel() ?? _str(plan['light']) ?? '—',
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
                    value: _soilWords(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const BotanlyGlyph(
                BotanlySvg.check,
                size: 14,
                color: kGlassGreenText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.addPlantPlanTuned,
                  style: glassFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kGlassGreenText,
                  ),
                ),
              ),
            ],
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
                l10n.addPlantNTasks(3 + problems.length),
                style: glassFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kGlassMut2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Exactly what the scheduler will create, so the plan the user
          // accepts is the plan they get.
          _PlanRow(
            glyph: BotanlySvg.drop,
            tint: kGlassWaterBg,
            color: kGlassWater,
            title: l10n.addPlantFirstWatering,
            detail: firstWateringDetail(
              l10n,
              ml: ml,
              firstInDays: firstIn,
              unknownLastWatering: daysAgo < 0,
            ),
          ),
          // Where the dose came from, when it did not come from the user. The
          // volume is the one number on this card nobody can check by eye, so
          // it says whether the pot was measured off the photo or fell back to
          // an average.
          if (_potFromPhoto) ...[
            const SizedBox(height: 7),
            Text(
              _int(plan['pot_diameter_cm']) != null
                  ? l10n.addPlantPotFromPhoto(_potDiameter(plan))
                  : l10n.addPlantPotAverage(kPotDefaultCm),
              style: glassFont(fontSize: 12, height: 1.4, color: kGlassMut2),
            ),
          ],
          for (final task in problems) ...[
            const SizedBox(height: 9),
            _PlanRow(
              glyph: switch (task) {
                ConditionTask.light => BotanlySvg.sun,
                ConditionTask.drainage => BotanlySvg.dropOutline,
                ConditionTask.heat => BotanlySvg.thermometer,
              },
              tint: task == ConditionTask.light ? kGlassSunBg : kGlassWarmBg,
              color: task == ConditionTask.light ? kGlassSun : kGlassWarm,
              title: switch (task) {
                ConditionTask.light => l10n.addPlantAddLight,
                ConditionTask.drainage => l10n.addPlantAddDrainage,
                ConditionTask.heat => l10n.addPlantMoveFromHeat,
              },
              detail: switch (task) {
                ConditionTask.light => l10n.addPlantAddLightDetail,
                ConditionTask.drainage => l10n.addPlantAddDrainageDetail,
                ConditionTask.heat => l10n.addPlantMoveFromHeatDetail,
              },
            ),
          ],
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

  /// The light line for the answered placement, or null if it was skipped.
  String? _lightLabel() => switch (_placement) {
    Placement.south => l10n.placeLightSouth,
    Placement.east => l10n.placeLightEast,
    Placement.north => l10n.placeLightNorth,
    Placement.room => l10n.placeLightRoom,
    Placement.balcony => l10n.placeLightBalcony,
    Placement.bath => l10n.placeLightBath,
    _ => null,
  };

  String _soilWords() =>
      switch (soilFeel(placement: _placement, material: _material)) {
        SoilFeel.wet => l10n.moistureWet,
        SoilFeel.moderate => l10n.soilModerate,
        SoilFeel.slight => l10n.addPlantSoilSlightlyMoist,
      };
}

/// Detail line under "First watering" in the care plan.
///
/// The date comes from the same arithmetic the plant is saved with (SPEC 4.2),
/// so the plan the user accepts is the plan they get. "Don't know" gets its own
/// wording: promising a date we did not compute is worse than saying we will
/// look at the soil.
String firstWateringDetail(
  AppLocalizations l10n, {
  required int ml,
  required int firstInDays,
  required bool unknownLastWatering,
}) {
  // "today" is already lowercase; "In 10 days" is a sentence opener elsewhere
  // and has to be folded down before it can sit after a middot.
  final when = unknownLastWatering
      ? l10n.addPlantCheckToday
      : (firstInDays <= 0
            ? l10n.addPlantToday
            : l10n.whenInNDays(firstInDays).toLowerCase());
  if (ml <= 0) return when;
  final volume = volumeLabel(l10n, ml);
  // Glasses only while they still mean something — see [kLitreThresholdMl].
  if (ml >= kLitreThresholdMl) return '$volume · $when';
  return '$volume · ${glassesLabel(l10n, ml)} · $when';
}

/// A watering volume in the unit that suits its size (SPEC 3.2).
String volumeLabel(AppLocalizations l10n, int ml) {
  if (ml < kLitreThresholdMl) return l10n.volumeMl('$ml');
  final litres = (ml / 100).round() / 10;
  // The locale of the strings around it, not the process default: `intl` falls
  // back to en_US on its own and would print "2.6 л" in Russian.
  final text = NumberFormat.decimalPattern(l10n.localeName).format(litres);
  return l10n.volumeLitres(text);
}

/// A localised title split around its highlighted word.
///
/// The ARB entry carries the placeholder rather than a fixed lead/accent pair,
/// because German puts the green word first and French puts it last. Passing a
/// control character in and splitting on it is what lets each translation place
/// the accent wherever its grammar needs it.
List<InlineSpan> accentSpans(String Function(String) template, String accent) {
  const mark = '\u0000';
  final parts = template(mark).split(mark);
  return [
    TextSpan(text: parts.first),
    TextSpan(
      text: accent,
      style: const TextStyle(color: kGlassAccent),
    ),
    if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
  ];
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

// ─────────────────────────────────────────────────────────────────────────────
//  Quiz pieces (SPEC §3)
// ─────────────────────────────────────────────────────────────────────────────

/// The round back button in the header — one for the whole flow (SPEC §5).
class _BackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BackButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: BotanlyPress(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xB3FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: kGlassBorder, width: 0.5),
          ),
          child: const BotanlyGlyph(
            BotanlySvg.chevronLeft,
            size: 17,
            color: kGlassInk2,
          ),
        ),
      ),
    );
  }
}

/// Progress inside the quiz: four dots on the left, the counter centred.
///
/// A three-column grid rather than a row, so the counter sits in the middle of
/// the card whatever the dots or the translated string are worth in pixels.
class _QuizDots extends StatelessWidget {
  final int index;
  final int total;
  final String label;

  const _QuizDots({
    required this.index,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == index ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? kGlassAccent
                  : (i < index
                        ? kGlassAccent.withAlpha(115)
                        : const Color(0x24141E0F)),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ],
    );

    return Row(
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: dots),
        ),
        Text(
          label.toUpperCase(),
          style: glassFont(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 11.5 * 0.06,
            color: kGlassMut2,
          ),
        ),
        // Mirrors the dots column so the counter stays optically centred.
        const Expanded(child: SizedBox()),
      ],
    );
  }
}

/// Question title plus the "why we ask" line.
///
/// The explanation is mandatory on every question (SPEC 3.1): a form that does
/// not say what it does with an answer reads as data collection.
class _QuestionHead extends StatelessWidget {
  final String Function(String) template;
  final String accent;
  final String why;

  const _QuestionHead({
    required this.template,
    required this.accent,
    required this.why,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: glassFont(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: 20 * -0.03,
              color: kGlassInk,
            ),
            children: accentSpans(template, accent),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: BotanlyGlyph(
                BotanlySvg.infoCircle,
                size: 15,
                color: kGlassAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                why,
                style: glassFont(fontSize: 12.5, height: 1.4, color: kGlassMut),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// The pot, growing with the slider (SPEC 3.2).
///
/// Not decoration: 8 cm and 40 cm are hard to picture as numbers, and the point
/// of the question is that the user recognises their own pot.
class _PotView extends StatelessWidget {
  final int diameterCm;

  const _PotView({required this.diameterCm});

  @override
  Widget build(BuildContext context) {
    final width = 44 + (diameterCm - kPotMinCm) * 2.4;
    final height = width * 0.86;

    return SizedBox(
      height: 150,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Body first, rim and soil over it — the order the mockup paints.
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFD9B79C),
                        Color(0xFFC89777),
                        Color(0xFFB0805F),
                      ],
                      stops: [0, 0.46, 1],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(6),
                      bottom: Radius.elliptical(width * 0.46, height * 0.22),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -width * 0.04,
                right: -width * 0.04,
                top: 0,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE3C4AC), Color(0xFFC79A79)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.06,
                right: width * 0.06,
                top: 2,
                height: 12,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6B5442), Color(0xFF4E3E31)],
                    ),
                    borderRadius: BorderRadius.all(Radius.elliptical(60, 6)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: height * 0.7,
                child: const Center(
                  child: BotanlyGlyph(
                    BotanlySvg.leaf,
                    size: 40,
                    color: kGlassAccent,
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

/// The live volume under the pot slider — the answer to "why does this matter".
class _CalcCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CalcCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: kGlassWater.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGlassWater.withAlpha(51), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kGlassWater.withAlpha(41),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const BotanlyGlyph(
              BotanlySvg.drop,
              size: 17,
              color: kGlassWater,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: glassFont(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: kGlassBlueText,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: glassFont(fontSize: 12.5, color: kGlassMut),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid of option tiles, rows sized to their tallest cell.
class _TileGrid extends StatelessWidget {
  final List<Widget> children;

  const _TileGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 9),
              Expanded(child: right ?? const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          rows[i],
        ],
      ],
    );
  }
}

/// A tile in the 2×N answer grid: icon on the left, title and gloss beside it.
class _OptionTile extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.tint = kGlassLeafBg,
    this.color = kGlassAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: BotanlyPress(
        scale: 0.98,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? kGlassAccent.withAlpha(28)
                    : const Color(0xD1FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kGlassAccent : const Color(0xF2FFFFFF),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: glassFont(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 13.5 * -0.015,
                            color: kGlassInk,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: glassFont(
                            fontSize: 11,
                            height: 1.25,
                            color: kGlassMut,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The tick's gutter, kept whether or not the tile is picked.
                  const SizedBox(width: 15),
                ],
              ),
            ),
            // Floated, not part of the row: laying the tick out inline made the
            // text reflow the moment a tile was picked, so the tile grew a line
            // taller under the finger that had just tapped it.
            if (selected)
              const Positioned(top: 8, right: 8, child: _Tick(size: 17)),
          ],
        ),
      ),
    );
  }
}

/// A full-width answer row — the control drainage, heat and last watering share.
class _OptionRow extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.tint = kGlassLeafBg,
    this.color = kGlassAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: BotanlyPress(
        scale: 0.99,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? kGlassAccent.withAlpha(28)
                : const Color(0xD1FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? kGlassAccent : const Color(0xF2FFFFFF),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: BotanlyGlyph(glyph, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: glassFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 15 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: glassFont(fontSize: 12.5, color: kGlassMut),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  final double size;

  const _Tick({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: kGlassAccent,
        shape: BoxShape.circle,
      ),
      child: BotanlyGlyph(
        BotanlySvg.check,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;

  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? kGlassAccent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? kGlassAccent : const Color(0x33141E0F),
          width: 1.5,
        ),
      ),
      child: selected
          ? const BotanlyGlyph(BotanlySvg.check, size: 11, color: Colors.white)
          : null,
    );
  }
}

/// The uppercase label over the second group inside a question.
class _SubLabel extends StatelessWidget {
  final String text;

  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(
        text.toUpperCase(),
        style: glassFont(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 11.5 * 0.09,
          color: kGlassMut,
        ),
      ),
    );
  }
}

/// The pinned "Next" layer, with the scrim that keeps the card readable as it
/// scrolls underneath.
class _QuizFooter extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuizFooter({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kGlassBase.withAlpha(0), kGlassBase.withAlpha(240)],
            ),
          ),
        ),
        ColoredBox(
          color: kGlassBase.withAlpha(240),
          // No glyph: the kit draws it before the label, and a left-pointing
          // slot in front of "Next" reads as "back".
          child: BotanlyButton(label: label, onTap: onTap),
        ),
      ],
    );
  }
}

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
