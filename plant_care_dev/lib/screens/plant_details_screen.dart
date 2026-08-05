import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/plant_health.dart';
import 'package:plant_care/screens/edit_plant_screen.dart';
import 'package:plant_care/screens/plant_chat_screen.dart';
import 'package:plant_care/services/health_check_service.dart';
import 'package:plant_care/services/navigation_service.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/widgets/health_check_modal.dart';
import 'package:plant_care/utils/care_sections.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/screens/main_navigation_screen.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/widgets/subscription_gate.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/utils/chat_topics.dart';
import 'package:plant_care/widgets/botanly_sheet.dart';
import 'package:plant_care/widgets/health_result_view.dart';
import 'package:plant_care/widgets/task_sheet.dart';
import 'package:plant_care/widgets/todo_block.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens — Botanly Plant Screen v8 (Liquid Glass)
//  Defined in theme/botanly_glass.dart and aliased here so the rest of this file
//  keeps its short local names. The health check sheet reads the same tokens.
// ─────────────────────────────────────────────────────────────────────────────

const _kInk = kGlassInk;
const _kInk2 = kGlassInk2;
const _kMut = kGlassMut;
const _kMut2 = kGlassMut2;
const _kChev = kGlassChevron;

const _kAccent = kGlassAccent;
const _kWater = kGlassWater;
const _kSun = kGlassSun;
const _kWarm = kGlassWarm;

const _kBase = kGlassBase;
const _kGlassFill = kGlassFill;
const _kGlassBorder = kGlassBorder;
const _kGlassSpecular = kGlassSpecular;
const _kKnob = kGlassKnob;

const _kIssuesFill = kGlassIssuesFill;
const _kHistoryFill = kGlassHistoryFill;
const _kIssuesText = kGlassIssuesText;

// Category tints — background / foreground
const _kLeafBg = kGlassLeafBg;
const _kWaterBg = kGlassWaterBg;
const _kSunBg = kGlassSunBg;
const _kWarmBg = kGlassWarmBg;

// Elevation — shadow tint is rgba(20,30,15,α) = #141E0F
const _kCardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x2E141E0F),
    blurRadius: 30,
    spreadRadius: -8,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x19141E0F),
    blurRadius: 8,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
];

// Motion
const _kKnobCurve = Cubic(0.32, 0.72, 0.25, 1.0); //  340 ms knob slide
const _kProgressCurve = Cubic(0.3, 0.7, 0.3, 1.0); //  800 ms progress fill
const _kSheetCurve = Cubic(0.22, 1.0, 0.36, 1.0); //  420 ms sheet rise

// ─────────────────────────────────────────────────────────────────────────────
//  Typography
//
//  The prototype uses `-apple-system, BlinkMacSystemFont, "SF Pro Text", …`,
//  i.e. the platform font, with a global `letter-spacing: -.01em` on <body>.
//  Set [kUseSystemFont] to false to fall back to the Botanly brand face used
//  by the rest of the app (DM Sans via botanly_theme.dart) — the screen then
//  matches the app instead of the prototype.
// ─────────────────────────────────────────────────────────────────────────────

/// Typography helper, shared with the health check sheet.
const _font = glassFont;

// ─────────────────────────────────────────────────────────────────────────────
//  Backdrop filters
//
//  Every glass surface in the prototype is `blur(Npx) saturate(180%)`; the recipe
//  itself lives in `glassFrost` so this screen and the home screen cannot drift
//  apart. Called directly rather than through a local alias: aliasing a function
//  as a top-level field turns a procedure into a getter, and hot reload refuses
//  to swap one for the other.
// ─────────────────────────────────────────────────────────────────────────────

final _kGlassFilter = glassFrost(26); //  .g
final _kNavFilter = glassFrost(18); //  .gbtn
final _kSheetFilter = glassFrost(40); //  .bs

// ─────────────────────────────────────────────────────────────────────────────
//  Glyphs — verbatim SVG from the prototype, so stroke weights and silhouettes
//  match rather than approximating with Material icons.
// ─────────────────────────────────────────────────────────────────────────────

/// The shared glass icon set and its renderer, aliased to the short local
/// names this file already uses.
typedef _Svg = BotanlySvg;
typedef _Glyph = BotanlyGlyph;

// ─────────────────────────────────────────────────────────────────────────────

class PlantDetailsScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailsScreen({super.key, required this.plant});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen>
    with TickerProviderStateMixin {
  late Plant _plant;
  late Stream<List<HealthCheckRecord>> _healthCheckStream;

  /// This plant's open tasks. One subscription feeds both the health score and
  /// the "what to do" block — they are two readings of the same list, and a
  /// second stream would let them disagree.
  StreamSubscription<List<CareTask>>? _tasksSub;
  List<CareTask> _tasks = const [];

  /// Tasks ticked off in this session, kept by value.
  ///
  /// The stream carries open tasks only, so a completed one disappears the
  /// instant it is written. Holding it here is what lets the row cross itself
  /// out instead of vanishing, and what lets the block reach "all done" —
  /// otherwise closing the last task would just hide the block (SPEC 3.3).
  Map<String, CareTask> _justCompletedTasks = const {};
  bool _isLoading = false;
  int _activeTab = 0; // 0 = Care, 1 = About, 2 = History
  bool _wateredJustNow = false;
  int _dropletBurst = 0;

  Timer? _wateringCountdownTimer;
  int? _wateringCountdownDays;
  final HealthCheckAnalysisMode _healthCheckMode =
      HealthCheckAnalysisMode.aiAgent;
  int _checksInCurrentCycle = 0;
  static const _maxChecksPerCycle = 2;

  late final AnimationController _pulseCtrl;

  ScaffoldMessengerState? _messenger;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Every `DateFormat` on this screen needs this — without it `intl` falls
  /// back to en_US and prints "Aug 3" no matter what language the app is in.
  String get _localeTag => Localizations.localeOf(context).toLanguageTag();

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _healthCheckStream = HealthCheckService().getHealthCheckHistory(_plant.id);
    _tasksSub = TaskService().watchPlantTasks(_plant.id).listen((tasks) {
      if (mounted) setState(() => _tasks = tasks);
    });
    _saveNavigationState();
    _startWateringCountdownTimer();
    _loadHealthCheckCount();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _wateringCountdownTimer?.cancel();
    _tasksSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _saveNavigationState() =>
      NavigationService.savePlantDetailsState(_plant.id);

  Future<void> _loadHealthCheckCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final since = _plant.lastWateredAt ?? _plant.lastWatered;
      final snap = await FirebaseFirestore.instance
          .collection('health_checks')
          .where('plantId', isEqualTo: _plant.id)
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: since.toIso8601String())
          .get();
      if (!mounted) return;
      setState(() => _checksInCurrentCycle = snap.docs.length);
    } catch (_) {
      // A failed count only gates the "add check" button; keep the last value.
    }
  }

  bool _canDoHealthCheck() =>
      !_canWaterPlant() && _checksInCurrentCycle < _maxChecksPerCycle;

  /// Whether the paid doors on this screen are shut right now.
  ///
  /// Read from the live subscription stream rather than fetched per tap, so the
  /// padlocks appear and disappear the moment the user's document changes —
  /// paying should not require restarting the app (SPEC 5.3).
  bool get _paidLocked =>
      !(SubscriptionService().currentInfo?.hasAccess ?? true);

  /// Gate for the paid features reachable from this screen (SPEC 10, §4).
  ///
  /// Shows the shared "needs a subscription" sheet, not the full paywall: at
  /// this point the user tapped one control, and the first thing they need is
  /// reassurance that the plant in front of them is not going anywhere. The
  /// paywall itself is one more tap, from the sheet's CTA.
  ///
  /// Returns true when the caller may proceed.
  Future<bool> _requirePaidAccess(GateAction action) async {
    final info =
        SubscriptionService().currentInfo ??
        await SubscriptionService().fetchInfo();
    if (info.hasAccess) return true;
    if (!mounted) return false;

    await showSubscriptionGate(context, action: action, onResume: _openPaywall);
    return false;
  }

  /// Sends the user to the paywall — the real one, in the "Add" tab.
  ///
  /// Not a second sheet stacked on the first. That version rebuilt the locked
  /// screen inside a 94%-height sheet, where its pinned footer and its scroll
  /// had to be re-tuned for a container they were never laid out for. The tab
  /// already holds this screen, correctly sized, so the CTA goes there instead
  /// of cloning it.
  void _openPaywall() {
    // Two steps, the same pair the delete flow uses: unwind whatever is stacked
    // over the shell, then tell it which tab to show. Route-level navigation
    // cannot do the second part — go_router reuses the existing shell and never
    // re-runs its initState.
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    MainNavigationScreen.requestTab(kAddPlantTabIndex);
  }

  Future<void> _refreshPlantData() async {
    final p = await PlantService().getPlantById(_plant.id);
    if (p != null && mounted) {
      setState(() => _plant = p);
      _updateWateringCountdown();
    }
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _openHealthCheckModal() async {
    // Money first, then the care rules: an expired account should meet the
    // paywall, not a lecture about watering the plant before scanning it.
    if (!await _requirePaidAccess(GateAction.healthCheck)) return;
    if (!mounted) return;

    // The gate lives here as well as on the buttons: the analysis is now also
    // reachable from a task row, and a check run while the plant is still
    // thirsty is exactly what the watering-first sequence exists to prevent.
    final blocked = _analyzeBlockedReason();
    if (blocked != null) {
      _toast(blocked, _kSun);
      return;
    }

    HapticFeedback.lightImpact();
    final asked = await showModalBottomSheet<HealthCheckRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthCheckModal(
        plantId: _plant.id,
        plantName: _plant.name,
        analysisMode: _healthCheckMode,
        onHealthCheckComplete: _handleHealthCheckComplete,
      ),
    );
    if (!mounted || asked == null) return;

    // The check is already saved, so coming back means reopening it from
    // history — the same result, now a stored record.
    await _askInChat(
      _analysisQuestion(asked),
      () async => _openStoredResultSheet(asked),
      topic: ChatTopic.diagnostics,
    );
  }

  String _analysisQuestion(HealthCheckRecord record) => record.status == 'issue'
      ? l10n.healthAskQuestionIssue
      : l10n.healthAskQuestionOk;

  /// A task leads to the subject it is about, not to a topic named "tasks".
  ///
  /// Someone who taps "Water Sunny" and then asks a question is thinking about
  /// watering, not about which screen they came from — so the answer belongs in
  /// the same thread as the watering card's.
  String _topicForTask(CareTask task) => switch (task.category) {
    TaskCategory.water => ChatTopic.water,
    TaskCategory.light => ChatTopic.light,
    TaskCategory.soil => ChatTopic.soil,
    TaskCategory.fertilizer => ChatTopic.fertilizer,
    TaskCategory.scan => ChatTopic.diagnostics,
    TaskCategory.other => ChatTopic.general,
  };

  Future<void> _openPlantChat({String? question}) async {
    if (!await _requirePaidAccess(GateAction.chat)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantChatScreen(
          plant: _plant,
          initialQuestion: question,
          topic: ChatTopic.general,
        ),
      ),
    );
  }

  /// SPEC 1.4: leaving the chat puts the user back on the sheet they left from.
  ///
  /// Every entry point — care card, task, analysis result — goes through here,
  /// so none of them can quietly forget to come back. The 120 ms is the
  /// handoff's: reopening on the same frame reads as if the chat never closed.
  Future<void> _askInChat(
    String question,
    Future<void> Function() reopen, {
    String topic = ChatTopic.general,
  }) async {
    if (!await _requirePaidAccess(GateAction.chat)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantChatScreen(
          plant: _plant,
          initialQuestion: question,
          topic: topic,
          // A confirmed change rewrites the very figures this screen is
          // showing behind the chat.
          onPlantChanged: _refreshPlantData,
        ),
      ),
    );
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await reopen();
  }

  void _handleHealthCheckComplete(Map<String, dynamic> result) async {
    try {
      final now = DateTime.now();
      int? newDays;
      bool newShouldWater = false;

      final dFromAI = result['watering_interval_days'];
      if (dFromAI != null) {
        newDays = dFromAI is int ? dFromAI : int.tryParse(dFromAI.toString());
        newShouldWater = result['should_water_now'] == true;
      }
      if (newDays == null || newDays <= 0) {
        final mode = result['mode'] as String?;
        final hrsKey = mode == 'recheck_only'
            ? 'next_check_in_hours'
            : 'next_after_watering_in_hours';
        final hrs = result[hrsKey];
        if (hrs != null) {
          final h = hrs is int ? hrs : int.tryParse(hrs.toString());
          if (h != null && h > 0) {
            newDays = (h / 24).round().clamp(1, 60);
            newShouldWater = mode != 'recheck_only';
          }
        }
      }

      DateTime? newNext;
      if (newDays != null && newDays > 0) {
        newNext = PlantService.calculateNextWateringAt(
          from: now,
          intervalDays: newDays,
          preferredTime: _plant.preferredTime ?? '18:00',
        );
      }

      // The analyzer types these as strings but is not bound by that, and a
      // stray number here would blow up the whole check on an implicit cast.
      String? str(dynamic v) {
        if (v == null || v is Map || v is List) return null;
        final s = v.toString().trim();
        return s.isEmpty ? null : s;
      }

      final care = result['care_recommendations'] as Map?;
      final newMoisture =
          str(result['moisture_level']) ?? str(care?['moisture']);
      final newLight = str(result['light']) ?? str(care?['light']);
      final newAmountMl = result['amount_ml'];
      final newRangeMl = result['range_ml'];

      // The scan is the only thing allowed to raise the score (SPEC 1.1). Every
      // other change can subtract penalties; none of them lifts the ceiling.
      final scanned = result['health_score'];
      final newScanScore =
          (scanned is num
                  ? scanned.toInt()
                  : int.tryParse(scanned?.toString() ?? ''))
              ?.clamp(0, 100);

      final updated = _plant.copyWith(
        scanScore: newScanScore ?? _plant.scanScore,
        healthStatus: result['status'],
        healthMessage: result['message'],
        lastHealthCheck: now,
        aiPlantSize: str(result['plant_size']) ?? _plant.aiPlantSize,
        aiPotSize: str(result['pot_size']) ?? _plant.aiPotSize,
        aiGrowthStage: str(result['growth_stage']) ?? _plant.aiGrowthStage,
        aiMoistureLevel: newMoisture ?? _plant.aiMoistureLevel,
        aiLight: newLight ?? _plant.aiLight,
        aiCareTips: _plant.aiCareTips,
        careDetails:
            result['care_details'] as Map<String, String>? ??
            _plant.careDetails,
        interestingFacts: _plant.interestingFacts,
        wateringAmountMl: newAmountMl != null
            ? (newAmountMl is int
                  ? newAmountMl
                  : newAmountMl is double
                  ? newAmountMl.toInt()
                  : int.tryParse(newAmountMl.toString()))
            : _plant.wateringAmountMl,
        wateringRangeMl: newRangeMl is List
            ? List<int>.from(
                newRangeMl.map(
                  (e) => e is int ? e : int.tryParse(e.toString()) ?? 0,
                ),
              )
            : _plant.wateringRangeMl,
        nextAfterWateringHours:
            result['next_after_watering_in_hours'] ??
            _plant.nextAfterWateringHours,
        nextCheckHours: result['next_check_in_hours'] ?? _plant.nextCheckHours,
        wateringMode: str(result['mode']) ?? _plant.wateringMode,
        nextDueAt: newNext ?? _plant.nextDueAt,
        nextWatering: newNext ?? _plant.nextWatering,
        wateringIntervalDays: newDays ?? _plant.wateringIntervalDays,
        shouldWaterNow: newShouldWater,
      );

      await PlantService().updatePlant(updated);
      await _syncPlanWithAnalysis(result);
      if (!mounted) return;
      setState(() => _plant = updated);
      _updateWateringCountdown();
      await _loadHealthCheckCount();
      // No toast: this now runs while the result sheet is still open, and the
      // verdict it would announce is already the headline the user is reading.
    } catch (e) {
      if (mounted) _toast(l10n.errorUpdatingPlant(e.toString()), _kWarm);
    }
  }

  /// Folds a finished analysis into the plant's plan.
  ///
  /// The recommendations shown in the result and the tasks in "what to do" are
  /// the same objects — SPEC 3.4 requires their titles to match word for word,
  /// which only holds if the plan is built from the result rather than typed
  /// again. There is no "add to plan" button: arriving is the whole point.
  Future<void> _syncPlanWithAnalysis(Map<String, dynamic> result) async {
    final service = TaskService();
    try {
      // The check itself satisfies the "rescan" trigger, so that task retires
      // (SPEC 1.3.5) rather than lingering next to its own result.
      await service.completeCategory(_plant.id, TaskCategory.scan);

      final raw = result['recommendations'];
      if (raw is! List || raw.isEmpty) return;

      // dueAt = now keeps ageDays at 0: a recommendation the user received
      // seconds ago must never be presented as overdue (SPEC 1.3.6).
      final now = DateTime.now();
      final tasks = <CareTask>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final rec = HealthRecommendation.fromMap(
          Map<String, dynamic>.from(item),
        );
        if (rec.title.isEmpty) continue;
        tasks.add(
          CareTask(
            id: '',
            plantId: _plant.id,
            userId: '',
            title: rec.title,
            detail: rec.explanation,
            source: TaskSource.analysis,
            category: _taskCategoryFor(rec),
            dueAt: now,
            body: rec.explanation,
          ),
        );
      }
      if (tasks.isEmpty) return;

      await service.createFromAnalysis(plantId: _plant.id, tasks: tasks);
    } catch (e) {
      // The check is already saved; a failed plan sync must not undo it.
      debugPrint(
        '⚠️ Could not sync analysis recommendations into the plan: $e',
      );
    }
  }

  /// Best-effort category for a recommendation so the row gets a sensible icon.
  /// The analyzer categorises findings but not actions, so this reads the title.
  TaskCategory _taskCategoryFor(HealthRecommendation rec) {
    final text = '${rec.title} ${rec.explanation}'.toLowerCase();
    bool has(List<String> words) => words.any(text.contains);

    if (has(['полив', 'вод', 'water', 'moist', 'влаж']))
      return TaskCategory.water;
    if (has(['свет', 'солнц', 'light', 'sun'])) return TaskCategory.light;
    if (has(['почв', 'грунт', 'горшок', 'пересад', 'soil', 'repot'])) {
      return TaskCategory.soil;
    }
    if (has(['подкорм', 'удобр', 'fertil'])) return TaskCategory.fertilizer;
    if (has(['скан', 'провер', 'фото', 'scan', 'check']))
      return TaskCategory.scan;
    return TaskCategory.other;
  }

  Future<void> _waterPlant() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _wateredJustNow = true;
      _dropletBurst++;
    });
    try {
      await PlantService().waterPlant(_plant.id);
      // The trigger is satisfied, so the watering task retires with it — the
      // home deck must not still be asking for water the user just gave
      // (SPEC 1.3.5).
      try {
        await TaskService().completeCategory(
          _plant.id,
          TaskCategory.water,
          source: TaskSource.schedule,
        );
      } catch (e) {
        debugPrint('⚠️ Could not close the watering task: $e');
      }
      await _refreshPlantData();
      await _loadHealthCheckCount();
      if (!mounted) return;
      _updateWateringCountdown();
      HapticFeedback.heavyImpact();
      // LEGACY SNACKBAR (disabled 2026-08-03) — the green "… has been watered!"
      // badge from the screenshot. Haptic + the updated card already confirm it.
      // _toast(l10n.plantWateredSuccess(_plant.name), _kAccent);
    } catch (e) {
      if (!mounted) return;
      // Optimistic update failed — roll the widget back and surface the error.
      setState(() => _wateredJustNow = false);
      _toast(l10n.errorWateringPlant(e), _kWarm);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      // The dialog's own context, not the screen's: both buttons mean "close
      // this dialog", and popping via the screen's context only happened to
      // work because the dialog was the topmost route.
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: _kWarm),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.deletePlant,
                style: const TextStyle(
                  color: _kWarm,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(l10n.deletePlantConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePlant();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kWarm,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlant() async {
    try {
      setState(() => _isLoading = true);
      // Resolved before the await chain: the toast and the unwind both need a
      // live navigator, and `mounted` alone has proven unreliable here.
      final navigator = Navigator.of(context, rootNavigator: true);

      await PlantService().deletePlant(_plant.id);
      // Without this the plant's tasks outlive it: the deck hides them because
      // it drops tasks whose plant is gone, but they keep loading, keep
      // counting on the all-tasks screen and never expire on their own.
      try {
        await TaskService().deleteForPlant(_plant.id);
      } catch (e) {
        debugPrint('⚠️ Could not clear tasks of the deleted plant: $e');
      }

      // No farewell toast, on purpose. Announcing the deletion means asking a
      // ScaffoldMessenger to show a snack bar from a screen that is about to be
      // torn down, and it throws every time — the messenger still holds this
      // route's Scaffold and looking up a deactivated element's ancestor is an
      // error. Deferring it a frame does not help either; the messenger only
      // drops the dead Scaffold when it rebuilds.
      //
      // That throw is what used to break deleting a second plant: it escaped
      // into the catch below, the unwind never ran, and the user was left on
      // the page of a plant that no longer existed. The message was never worth
      // that — the user lands on Home and the plant is visibly gone.
      //
      // Two steps, because either one alone has failed in practice. popUntil
      // clears this screen and anything still stacked over it — the "⋯" sheet
      // or the confirm dialog; the notifier then puts the shell on Home, which
      // route-level navigation cannot do because go_router reuses the existing
      // MainNavigationScreen and never re-runs its initState.
      debugPrint('🗑️ Plant ${_plant.id} deleted — returning to Home');
      navigator.popUntil((route) => route.isFirst);
      MainNavigationScreen.requestTab(0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(l10n.errorDeletingPlant(e.toString()), _kWarm);
    }
  }

  void _toast(String message, Color background) {
    // Resolved in didChangeDependencies rather than here: toasts fire after
    // awaits, by which point this element can already be deactivated — and an
    // ancestor lookup on a deactivated element throws even while mounted is
    // still true.
    //
    // Guarded on top of that, because holding the messenger is not enough:
    // `showSnackBar` walks the messenger's own list of registered Scaffolds,
    // and a Scaffold from a screen that was popped while a snack bar was up
    // stays in that list until it is rebuilt. Looking up its ancestor throws.
    //
    // That is how deleting a second plant used to fail: this throw escaped
    // into the caller's catch, the screen never unwound, and the user was left
    // staring at a plant that no longer existed. A toast is decoration — it
    // must never take down the operation it is announcing.
    try {
      _messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not show a toast: $e');
    }
  }

  // ── watering schedule ─────────────────────────────────────────────────────

  DateTime _nextWateringDate() => _plant.nextDueAt ?? _plant.nextWatering;

  void _startWateringCountdownTimer() {
    _wateringCountdownTimer?.cancel();
    _updateWateringCountdown();
    _wateringCountdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateWateringCountdown(),
    );
  }

  void _updateWateringCountdown() {
    if (!mounted) return;
    if (_plant.shouldWaterNow) {
      setState(() => _wateringCountdownDays = null);
      return;
    }
    final target = _nextWateringDate();
    final now = DateTime.now().toLocal();
    final days = DateTime(
      target.year,
      target.month,
      target.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    setState(() => _wateringCountdownDays = days <= 0 ? null : days);
  }

  bool _canWaterPlant() {
    if (_wateredJustNow) return false;
    if (_plant.shouldWaterNow) return true;
    return !_nextWateringDate().isAfter(DateTime.now());
  }

  /// True until the first watering is actually logged.
  ///
  /// Adding a plant stamps `lastWatered` with the creation time so the cycle
  /// has an anchor, but the user never poured anything — printing "last watered
  /// today" under a card that says the plant is thirsty is the app arguing with
  /// itself. [_wateringSubtitle] drops the claim until it is true.
  bool get _neverWatered =>
      _plant.lastWatered.isAtSameMomentAs(_plant.createdAt);

  String _wateringSubtitle(int interval) {
    if (_neverWatered && !_wateredJustNow) return _everyN(interval);
    final last = _plant.lastWateredAt ?? _plant.lastWatered;
    final day = DateFormat.MMMd(_localeTag).format(last);
    return '${l10n.lastWatered} $day · ${_everyN(interval)}';
  }

  double _cycleProgress() {
    final last = _plant.lastWateredAt ?? _plant.lastWatered;
    final total = _nextWateringDate().difference(last).inSeconds;
    if (total <= 0) return 1.0;
    return (DateTime.now().difference(last).inSeconds / total).clamp(0.0, 1.0);
  }

  String _nextWateringValue() {
    if (_wateredJustNow) {
      final interval = _wateringInterval();
      return interval == 1 ? l10n.nextIn1Day : l10n.nextInNDays(interval);
    }
    if (_canWaterPlant()) return l10n.nowLabel;
    if (_wateringCountdownDays == 1) return l10n.wateringTomorrow;
    if (_wateringCountdownDays != null) {
      return l10n.nextInNDays(_wateringCountdownDays!);
    }
    return l10n.nowLabel;
  }

  String _waitingButtonLabel() {
    if (_wateringCountdownDays == 1) return l10n.nextIn1Day;
    if (_wateringCountdownDays != null) {
      return l10n.nextInNDays(_wateringCountdownDays!);
    }
    return l10n.iHaveWatered;
  }

  int _wateringInterval() =>
      _plant.wateringIntervalDays ?? _plant.wateringFrequency;

  // ── health status ─────────────────────────────────────────────────────────

  /// Live score of this plant, 0-100 (SPEC 1.1).
  ///
  /// Replaces the old keyword sniffing of `healthMessage`: every plant has a
  /// score at all times, and it is derived, never guessed from prose.
  int get _score => livePlantScore(_plant, _tasks);

  bool get _needsAttention => plantNeedsAttention(_score);

  Map<String, dynamic>? _tryParsePlantAssistant(String? msg) {
    if (msg == null || !msg.trim().startsWith('{')) return null;
    try {
      final m = jsonDecode(msg.trim()) as Map<String, dynamic>;
      if (m['status'] != null ||
          m['praise_phrase'] != null ||
          m['problem_name'] != null) {
        return m;
      }
    } catch (_) {
      // Not an assistant payload — fall back to the raw message.
    }
    return null;
  }

  // ── AI text extraction ────────────────────────────────────────────────────

  Map<String, String> _careSections = const {};
  String? _parsedFrom;

  /// Section bodies keyed by [CareSection], reparsed only when the blob changes.
  Map<String, String> get _care {
    final tips = _plant.aiCareTips;
    if (tips != _parsedFrom) {
      _parsedFrom = tips;
      _careSections = parseCareSections(tips);
    }
    return _careSections;
  }

  String _section(String key) => _care[key] ?? '';

  /// A compact label straight from the analyzer, or null when this plant was
  /// analysed before those fields existed — every caller has a fallback.
  String? _detail(String key) {
    final v = _plant.careDetails?[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Prefers the analyzer's own short label, falling back to trimming the
  /// section prose.
  String _rowValue(String detailKey, String body) =>
      _detail(detailKey) ?? _summarize(body);

  /// "Every 1 day" reads wrong in every language, so the daily case has its own
  /// phrasing rather than a plural branch.
  String _everyN(int days) => days == 1 ? l10n.everyDay : l10n.everyNDays(days);

  /// A care row shows a value at a glance, so give it the opening sentence
  /// rather than an arbitrary slice of the paragraph. Anything still too long
  /// is cut on a word boundary.
  String _summarize(String text, [int max = 44]) {
    var s = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[-•*\s]+'), '').trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (s.isEmpty) return '';
    // Decimals such as "pH 6.0" are not sentence ends: require a space after.
    final stop = RegExp(r'[.;!?](\s|$)').firstMatch(s);
    if (stop != null) s = s.substring(0, stop.start).trim();
    if (s.length <= max) return s;
    final space = s.lastIndexOf(' ', max);
    return '${s.substring(0, space > max ~/ 2 ? space : max).trimRight()}…';
  }

  String _moistureLabel() {
    final v = _plant.aiMoistureLevel;
    if (v == null || v.isEmpty) return '';
    final l = v.toLowerCase();
    if (l.contains('very dry') || l.contains('arid'))
      return l10n.moistureLevelVeryDry;
    if (l.contains('slightly moist') || l.contains('slightly damp')) {
      return l10n.moistureLevelSlightlyMoist;
    }
    if (l.contains('very moist')) return l10n.moistureLevelVeryMoist;
    if (l.contains('dry')) return l10n.moistureLevelDry;
    if (l.contains('moist') || l.contains('damp'))
      return l10n.moistureLevelMoist;
    if (l.contains('wet') || l.contains('saturated')) return l10n.moistureWet;
    // The analyser is told to keep this field an English enum, and "moderate"
    // is the value it returns most often — without this branch it fell through
    // to the raw value and the card read "Moderate" in every language.
    if (l.contains('moderate') ||
        l.contains('medium') ||
        l.contains('average')) {
      return l10n.medium;
    }
    return v;
  }

  // The keyword matching below only ever worked on English prose, and the
  // analyzer writes `aiLight` in the user's language — so for everyone else it
  // silently returned the default. It survives purely for plants analysed
  // before `careDetails` existed.

  String _lightHours() {
    final structured = _detail(CareDetail.lightHours);
    if (structured != null) return structured;
    final l = _plant.aiLight?.toLowerCase();
    if (l == null) return '4–6';
    final m = RegExp(r'(\d+)\s*(?:hours?|hrs?|ч)').firstMatch(l);
    if (m != null) return m.group(1)!;
    if (l.contains('full sun') || l.contains('direct sun')) return '6–8';
    if (l.contains('bright indirect')) return '8–12';
    if (l.contains('low light')) return '2–3';
    return '4–6';
  }

  String _lightType() {
    final structured = _detail(CareDetail.lightType);
    if (structured != null) return structured;
    final l = _plant.aiLight?.toLowerCase();
    if (l == null) return l10n.lightTypeBrightIndirect;
    if (l.contains('full sun') || l.contains('direct sun')) {
      return l10n.lightTypeDirect;
    }
    if (l.contains('partial sun')) return l10n.lightTypePartialSun;
    if (l.contains('bright indirect')) return l10n.lightTypeBrightIndirect;
    if (l.contains('low light') || l.contains('shade')) {
      return l10n.lightTypeLowLight;
    }
    return l10n.lightTypeBrightIndirect;
  }

  /// Older plants only carry the free-text `aiWateringAmount` ("about 250 ml"),
  /// so the dose badge falls back to the first millilitre figure in it.
  int? _doseMl() {
    final stored = _plant.wateringAmountMl;
    if (stored != null && stored > 0) return stored;
    final raw = _plant.aiWateringAmount;
    if (raw == null) return null;
    final m = RegExp(
      r'(\d+)\s*(?:ml|мл|ml\.)',
      caseSensitive: false,
    ).firstMatch(raw);
    final parsed = m != null ? int.tryParse(m.group(1)!) : null;
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  bool _hasNoIssues(String? t) {
    if (t == null || t.trim().isEmpty) return true;
    const empty = {'none detected', 'no specific issues detected', 'no issues'};
    return empty.contains(t.trim().toLowerCase());
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // The scrim darkens the top of the photo specifically so white status-bar
    // glyphs stay legible.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBase,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            Positioned.fill(child: _buildScrim()),
            _buildScrollContent(),
            _buildTopNav(),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x44000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Layer 1: fixed full-bleed photo ──────────────────────────────────────
  // background: url(photo) center 42% / cover; transform: scale(1.02)
  // `center 42%` for a cover fit maps to Alignment(0, 2 * 0.42 - 1).

  Widget _buildBackdrop() {
    const fallback = ColoredBox(color: Color(0xFF2A3E24));
    const alignment = Alignment(0, -0.16);
    final url = _plant.imageUrl;

    Widget image = fallback;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          image = Image.memory(
            base64Decode(url.split(',')[1]),
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (_, __, ___) => fallback,
          );
        } catch (_) {
          image = fallback;
        }
      } else if (url.startsWith('http')) {
        image = Image.network(
          url,
          fit: BoxFit.cover,
          alignment: alignment,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    }
    return Transform.scale(scale: 1.02, child: image);
  }

  // ─── Layer 2: photo scrim ─────────────────────────────────────────────────
  // rgba(0,0,0,.22) 0% → transparent 22% → transparent 40%
  // → rgba(235,240,233,.5) 56% → #EDF0EC 70%
  // The 40% stop carries the base RGB so the fade to the neutral base does not
  // dip through grey on the way.

  Widget _buildScrim() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.22, 0.40, 0.56, 0.70, 1.0],
          colors: [
            Color(0x38000000),
            Color(0x00000000),
            Color(0x00EDF0EC),
            Color(0x80EBF0E9),
            Color(0xFFEDF0EC),
            Color(0xFFEDF0EC),
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }

  // ─── Layer 4: top nav ─────────────────────────────────────────────────────
  // top: 52px = safe area + 8. Glass circles are 38 px inside a 44 px target,
  // so the wrapper sits 3 px higher than the visual edge.

  Widget _buildTopNav() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 5,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _navButton(
            glyph: _Svg.chevronLeft,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // The paid controls keep their place and gain a padlock — a button
          // that disappears reads as a bug, a padlock reads as a rule.
          GateLocked(
            locked: _paidLocked,
            dim: false,
            child: _navButton(glyph: _Svg.chat, onTap: _openPlantChat),
          ),
          const SizedBox(width: 8),
          _navButton(glyph: _Svg.more, onTap: _showMoreMenu),
        ],
      ),
    );
  }

  Widget _navButton({required String glyph, required VoidCallback onTap}) {
    return _PressScale(
      scale: 0.94,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: _kNavFilter,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x47FFFFFF), // rgba(255,255,255,.28)
                    border: Border.all(
                      color: const Color(0x99FFFFFF),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: _Glyph(glyph, size: 17, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MoreMenuSheet(
        editLabel: l10n.edit,
        deleteLabel: l10n.deletePlant,
        onEdit: () {
          Navigator.pop(ctx);
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => EditPlantScreen(plant: _plant),
                ),
              )
              .then((_) => _refreshPlantData());
        },
        onDelete: () {
          Navigator.pop(ctx);
          _showDeleteConfirmation();
        },
      ),
    );
  }

  // ─── Layer 3: scroll content ──────────────────────────────────────────────
  // 430 px spacer on the 812 pt reference canvas ≈ 53% of the viewport; the
  // scrim stops are proportional, so the spacer tracks the viewport too.

  Widget _buildScrollContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.53),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleCard(),
                const SizedBox(height: 12),
                _buildWateringCard(),
                const SizedBox(height: 12),
                _buildTodoBlock(),
                _buildSegmentedControl(),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_activeTab),
                    child: switch (_activeTab) {
                      0 => _buildCareTab(),
                      1 => _buildAboutTab(),
                      _ => _buildHistoryTab(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glass surface (.g) — the core primitive ──────────────────────────────
  // radius 26 · rgba(255,255,255,.62) · blur(26px) → sigma 13
  // · .5px rgba(255,255,255,.75) · two shadow layers
  // · inset 0 1px 0 rgba(255,255,255,.85) specular top edge
  //
  // The shadow must live OUTSIDE the ClipRRect — a clip discards anything drawn
  // beyond the child's bounds, which is where box shadows are painted.

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double radius = 26,
    Color fill = _kGlassFill,
  }) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: _kCardShadow),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: _kGlassFilter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: shape,
              border: Border.all(color: _kGlassBorder, width: 0.5),
            ),
            child: Stack(
              children: [
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: ColoredBox(color: _kGlassSpecular),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Title card ───────────────────────────────────────────────────────────
  // padding 16 18 · align center · name 27/600/-.03em/1.08
  // · latin 13/400 · health chip with a pulsing dot

  /// The name is whatever the owner typed; the line under it is the botanical
  /// identification. When identification failed, `species` holds a placeholder
  /// like "Unknown Species" — showing that is worse than showing nothing, so
  /// fall back to the cultivar the analyzer wrote into the care blob.
  String _botanicalName() {
    const placeholders = {
      'unknown',
      'unknown species',
      'unknown plant',
      'n/a',
      'none',
    };
    for (final candidate in [_plant.species, _section(CareSection.cultivar)]) {
      final s = candidate.trim();
      if (s.isEmpty ||
          s == _plant.name ||
          placeholders.contains(s.toLowerCase())) {
        continue;
      }
      return s;
    }
    return '';
  }

  Widget _buildTitleCard() {
    final latin = _botanicalName();

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plant.name,
                  style: _font(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 27 * -0.03,
                    height: 1.08,
                    color: _kInk,
                  ),
                ),
                if (latin.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    latin,
                    // .sci resets the inherited tracking to 0
                    style: _font(fontSize: 13, letterSpacing: 0, color: _kMut),
                  ),
                ],
              ],
            ),
          ),
          // Always present: SPEC 1.1 has no "no data" state, so the chip is not
          // conditional on a check having been run.
          const SizedBox(width: 12),
          _healthChip(),
        ],
      ),
    );
  }

  // pill: padding 6 11 · rgba(tint,.14) · .5px rgba(tint,.22) · 12.5/600
  // dot: 7 px, pulse 2.4 s — ring grows 0 → 5 px while alpha fades .4 → 0
  Widget _healthChip() {
    final healthy = !_needsAttention;
    // Amber, not the destructive red: a check that flagged something is a nudge,
    // not an error. Text is darkened to stay legible on glass over a photo.
    final tone = healthy ? _kAccent : kGlassAttnText;
    final label = healthy
        ? l10n.healthStatusHealthy
        : l10n.healthNeedsAttention;
    final blockedReason = _analyzeBlockedReason();

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: healthy ? _kAccent.withAlpha(36) : kGlassAttnBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withAlpha(56), width: 0.5), // .22
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final t = _pulseCtrl.value;
              final phase = t <= 0.5 ? t * 2 : (1 - t) * 2;
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone,
                  boxShadow: [
                    BoxShadow(
                      color: tone.withAlpha((102 * (1 - phase)).round()),
                      blurRadius: 0,
                      spreadRadius: 5 * phase,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _font(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
          if (blockedReason == null) ...[
            const SizedBox(width: 5),
            _Glyph(_Svg.scan, size: 13, color: tone.withAlpha(191)), // .75
          ],
        ],
      ),
    );

    if (blockedReason != null) return chip;

    // Visual size stays as designed; the tap target is padded out to 44 px.
    return Semantics(
      button: true,
      label: l10n.healthAnalyzeCta,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openHealthCheckModal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: GateLocked(locked: _paidLocked, child: chip),
        ),
      ),
    );
  }

  // ─── Watering widget (primary) ────────────────────────────────────────────

  Widget _buildWateringCard() {
    final canWater = _canWaterPlant();
    final amount = _doseMl();
    final interval = _wateringInterval();
    final progress = _wateredJustNow ? 0.04 : _cycleProgress();

    return _glass(
      child: Stack(
        children: [
          const Positioned.fill(child: _WateringSheen()),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 11.5/600 · letter-spacing .08em · uppercase
                          Text(
                            l10n.nextWatering.toUpperCase(),
                            style: _font(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 11.5 * 0.08,
                              color: _kMut,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // 30/600 · letter-spacing -.035em · line-height 1
                          Text(
                            _nextWateringValue(),
                            style: _font(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 30 * -0.035,
                              height: 1.0,
                              color: _kInk,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _wateringSubtitle(interval),
                            style: _font(fontSize: 13, color: _kMut),
                          ),
                        ],
                      ),
                    ),
                    if (amount != null && amount > 0) ...[
                      const SizedBox(width: 12),
                      _doseBlock(amount),
                    ],
                  ],
                ),
                const SizedBox(height: 15),
                _cycleBar(progress),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _wateredJustNow
                          ? l10n.cycleJustStarted
                          : l10n.cyclePercentComplete((progress * 100).round()),
                      style: _font(fontSize: 11.5, color: _kMut2),
                    ),
                    Text(
                      l10n.nDays(interval),
                      style: _font(fontSize: 11.5, color: _kMut2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _wateringCta(canWater),
                const SizedBox(height: 9),
                _analyzeHealthButton(),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: _DropletBurst(trigger: _dropletBurst)),
          ),
        ],
      ),
    );
  }

  // rgba(46,134,200,.12) · .5px rgba(46,134,200,.2) · radius 16 · padding 9 12
  // value 15/600 in --water over `ML` 10/600 uppercase .04em in --mut
  Widget _doseBlock(int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _kWater.withAlpha(31), // .12
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWater.withAlpha(51), width: 0.5), // .2
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$amount',
            style: _font(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kWater,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.millilitersShort,
            style: _font(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 10 * 0.04,
              color: _kMut,
            ),
          ),
          // Second unit under a hairline (SPEC 3.2): millilitres are exact but
          // unimaginable, glasses are the thing the user actually pours with.
          Container(
            width: 34,
            height: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: _kWater.withAlpha(46),
          ),
          Text(
            _glassesLabel(amount),
            style: _font(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: kGlassBlueText,
            ),
          ),
        ],
      ),
    );
  }

  /// Millilitres as glasses, rounded to a quarter. The base is a 200 ml glass;
  /// change the constant, not the text, if production ever uses another one.
  String _glassesLabel(int ml) {
    const glassMl = 200;
    final quarters = (ml * 4 / glassMl).round().clamp(1, 1 << 20);
    if (quarters == 4) return l10n.glassesOne;

    final whole = quarters ~/ 4;
    const marks = ['', '¼', '½', '¾'];
    final fraction = marks[quarters % 4];
    final value = whole == 0
        ? fraction
        : (fraction.isEmpty ? '$whole' : '$whole $fraction');
    return l10n.glassesAmount(value);
  }

  // track 6 px radius 4 rgba(20,30,15,.10) · fill gradient #7BC0EA → #2E86C8
  Widget _cycleBar(double progress) {
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x19141E0F),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 800),
              curve: _kProgressCurve,
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7BC0EA), Color(0xFF2E86C8)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // full width · radius 18 · padding 15 · #3E8E3B · white 16/600/-.01em
  // shadow 0 8px 20px -8px rgba(62,142,59,.7) · press scale(.975) · ripple 700 ms
  // Confirmed state: rgba(62,142,59,.16) fill, accent text, no shadow, disabled.
  /// Shortcut back into the latest check's action list.
  ///
  /// Once the analysis sheet is closed the recommendations are easy to lose, so
  /// the banner keeps them one tap away until every step is ticked off — at
  /// which point it disappears on its own.
  /// "What to do" — SPEC 3.3. Replaces the old recommendations banner.
  ///
  /// Watering never appears here: it is the hero widget right above, and the
  /// spec forbids the duplicate. Everything else this plant owes is one list,
  /// the same objects the home deck shows.
  Widget _buildTodoBlock() {
    final open = _tasks.map((t) => t.id).toSet();
    final merged = [
      ..._tasks,
      ..._justCompletedTasks.values.where((t) => !open.contains(t.id)),
    ];
    final visible = TodoBlock.visibleTasks(merged, DateTime.now());
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glass(
        padding: EdgeInsets.zero,
        child: TodoBlock(
          tasks: visible,
          justCompleted: _justCompletedTasks.keys.toSet(),
          // The scan row says why it is locked instead of offering a tick that
          // would be a lie.
          lockedReason: (task) =>
              isScheduledScan(task) ? _analyzeBlockedReason() : null,
          onOpen: _openTaskSheet,
          onToggle: (task, done) =>
              done ? _completeTask(task) : _reopenTask(task),
        ),
      ),
    );
  }

  /// Marks a task done, keeping the row visible for a beat.
  ///
  /// The tick is optimistic on purpose: the write is a round-trip to Firestore
  /// and a checkbox that waits for it feels broken. A failure puts the row back.
  Future<void> _completeTask(CareTask task) async {
    setState(
      () => _justCompletedTasks = {..._justCompletedTasks, task.id: task},
    );
    try {
      // Feeding leaves its mark on the plant, the way watering does. Without it
      // the scheduler has no idea the chore was done and hands it back.
      if (task.category == TaskCategory.fertilizer) {
        await PlantService().markFertilised(_plant.id);
      }
      await TaskService().complete(task.id);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _justCompletedTasks = {..._justCompletedTasks}..remove(task.id),
      );
      _toast(l10n.errorUpdatingPlant(e.toString()), _kWarm);
    }
  }

  Future<void> _reopenTask(CareTask task) async {
    setState(
      () => _justCompletedTasks = {..._justCompletedTasks}..remove(task.id),
    );
    try {
      await TaskService().reopen(task.id);
    } catch (_) {
      // The stream is the source of truth; a failed reopen simply leaves the
      // task as it was on the server and the next snapshot restores the tick.
    }
  }

  /// Opens the task sheet and applies whatever the user chose there.
  Future<void> _openTaskSheet(CareTask task) async {
    // A scheduled scan is not a task you tick — it is the health check itself.
    // Tapping it runs the analysis, and the gate decides whether it can.
    if (isScheduledScan(task)) {
      await _openHealthCheckModal();
      return;
    }

    final choice = await showTaskSheet(context: context, task: task);
    if (!mounted || choice == null) return;

    switch (choice) {
      case TaskSheetResult.done:
        await _completeTask(task);
      case TaskSheetResult.later:
        // "Later" never removes the task or touches the counter (SPEC 1.3.4).
        try {
          await TaskService().postpone(task.id);
        } catch (_) {
          // Ordering only; a failed write leaves the task where it was.
        }
      case TaskSheetResult.ask:
        await _askInChat(
          l10n.taskAskQuestion(task.title),
          () => _openTaskSheet(task),
          topic: _topicForTask(task),
        );
    }
  }

  /// Reopens a stored check in the result view.
  ///
  /// Reading history must not touch the plant: the verdict, score and steps all
  /// come from the record, and ticking a step writes back to that check only.
  Future<void> _openStoredResultSheet(HealthCheckRecord record) async {
    var current = record;

    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        // Same shape as the analysis sheet — reopening a check is the same view,
        // so it must not arrive in a different kind of container.
        builder: (sheetContext, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            18 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.94,
          ),
          decoration: const BoxDecoration(
            color: Color(0xF5FCFDFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Color(0x66142010),
                blurRadius: 50,
                spreadRadius: -18,
                offset: Offset(0, -20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber and date row stay outside the scroll view. The sheet's
              // own drag-to-dismiss loses the gesture arena to a scrollable, so
              // with everything inside one the grabber was drawn but dead.
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x29141E0F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(_localeTag).format(current.timestamp),
                      style: _font(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _kMut,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 32 px visual, 44 px hit area — same close button as the
                  // analysis sheet.
                  _PressScale(
                    scale: 0.9,
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0x12141E0F), // rgba(20,30,15,.07)
                          shape: BoxShape.circle,
                        ),
                        child: const _Glyph(_Svg.close, size: 15, color: _kMut),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // `Flexible`, not `Expanded`: a short check hugs its content and
              // only scrolls once it hits the 94% cap.
              Flexible(
                child: SingleChildScrollView(
                  child: HealthResultView(
                    record: current,
                    onClose: () => Navigator.of(sheetContext).pop(),
                    onAsk: () => Navigator.of(sheetContext).pop('ask'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || choice != 'ask') return;
    await _askInChat(
      _analysisQuestion(current),
      () async => _openStoredResultSheet(current),
      topic: ChatTopic.diagnostics,
    );
  }

  /// Why the analysis entry points are disabled, or null when they are live.
  ///
  /// The gate itself is deliberately unchanged: a check only counts once the
  /// cycle has been closed with a watering, and two per cycle is the budget. The
  /// design asks for the entry points to stay visible regardless, so instead of
  /// hiding them we say what is blocking.
  String? _analyzeBlockedReason() {
    if (_canDoHealthCheck()) return null;
    if (_canWaterPlant()) return l10n.healthLockedNeedsWatering;
    return l10n.healthLockedLimitReached;
  }

  /// Secondary CTA under "I have watered" — the primary way into the analysis.
  Widget _analyzeHealthButton() {
    final blockedReason = _analyzeBlockedReason();
    final enabled = blockedReason == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.55,
          child: GateLocked(
            locked: _paidLocked,
            // Already dimmed by the Opacity above when the care rules block it.
            dim: false,
            child: _RippleButton(
              // Locked by subscription is still tappable: the tap is what opens
              // the sheet that explains why. Only the care rules disable it.
              enabled: enabled || _paidLocked,
              onTap: _openHealthCheckModal,
              fill: const Color(0x242E86C8), // rgba(46,134,200,.14)
              border: Border.all(color: const Color(0x422E86C8), width: 0.5),
              shadow: const [],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Glyph(_Svg.scan, size: 17, color: Color(0xFF1F6BA5)),
                  const SizedBox(width: 8),
                  Text(
                    l10n.healthAnalyzeCta,
                    style: _font(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: kGlassBlueText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The care-rule reason only. A subscription lock explains itself in the
        // sheet, so repeating it here would be a second, quieter refusal.
        if (!enabled) ...[
          const SizedBox(height: 7),
          Text(
            blockedReason,
            textAlign: TextAlign.center,
            style: _font(fontSize: 11.5, color: _kMut2),
          ),
        ],
      ],
    );
  }

  Widget _wateringCta(bool canWater) {
    final done = _wateredJustNow;

    final Color fill;
    final Color foreground;
    final List<BoxShadow> shadow;
    final String glyph;
    final String label;

    if (done) {
      fill = _kAccent.withAlpha(41); // .16
      foreground = _kAccent;
      shadow = const [];
      glyph = _Svg.check;
      label = l10n.wateringDone;
    } else if (canWater) {
      fill = _kAccent;
      foreground = Colors.white;
      shadow = const [
        BoxShadow(
          color: Color(0xB33E8E3B),
          blurRadius: 20,
          spreadRadius: -8,
          offset: Offset(0, 8),
        ),
      ];
      glyph = _Svg.drop;
      label = l10n.iHaveWatered;
    } else {
      // Waiting out the cycle: a legible white glass rather than a dimmed CTA.
      fill = const Color(0xCCFFFFFF);
      foreground = _kInk2;
      shadow = const [];
      glyph = _Svg.clock;
      label = _waitingButtonLabel();
    }

    return _RippleButton(
      enabled: canWater && !done,
      onTap: _waterPlant,
      fill: fill,
      border: (!done && !canWater)
          ? Border.all(color: const Color(0x22141E0F), width: 0.5)
          : null,
      shadow: shadow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Glyph(glyph, size: 17, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: _font(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 16 * -0.01,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Segmented control ────────────────────────────────────────────────────

  Widget _buildSegmentedControl() {
    return _glass(
      radius: 22,
      padding: const EdgeInsets.all(4),
      child: _LiquidSegmentedControl(
        selected: _activeTab,
        onChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = i);
        },
        tabs: [
          _SegTab(_Svg.drop, l10n.tabCare),
          _SegTab(_Svg.leaf, l10n.tabAbout),
          _SegTab(_Svg.gallery, l10n.tabHistory),
        ],
      ),
    );
  }

  // ─── Tab: Care ────────────────────────────────────────────────────────────
  // Column of glass rows, gap 9. Each row opens the detail sheet.

  Widget _buildCareTab() {
    final interval = _wateringInterval();
    final amount = _doseMl();
    final range = _plant.wateringRangeMl;

    final waterBody = _section(CareSection.water);
    final soilBody = _section(CareSection.soil);
    final moistureBody = _section(CareSection.soilMoisture);
    final moistureCheck = _section(CareSection.moistureCheck);
    final lightBody = _section(CareSection.light);
    final tempBody = _section(CareSection.temperature);
    final fertBody = _section(CareSection.fertilizer);
    final placementBody = _section(CareSection.placement);

    // The watering sheet is where the finger test belongs: it is the check you
    // run right before you decide to water.
    final waterSheetBody = [
      waterBody,
      moistureCheck,
    ].where((s) => s.isNotEmpty).join('\n\n');

    final rows = <Widget>[
      _careRow(
        tone: _CareTone.water,
        glyph: _Svg.drop,
        title: l10n.careSectionWater,
        topic: ChatTopic.water,
        value: amount != null
            ? '${_everyN(interval)} · ${l10n.milliliters(amount)}'
            : _everyN(interval),
        body: waterSheetBody,
        keyValues: [
          (l10n.careKvFrequency, l10n.nDays(interval)),
          if (amount != null)
            (
              l10n.wateringAmount,
              range != null && range.length == 2
                  ? '${range[0]}–${l10n.milliliters(range[1])}'
                  : l10n.milliliters(amount),
            ),
          if (_detail(CareDetail.wateringSeason) case final season?)
            (l10n.careKvSeason, season),
        ],
      ),
      if (soilBody.isNotEmpty)
        _careRow(
          tone: _CareTone.leaf,
          glyph: _Svg.soil,
          title: l10n.careSectionSoil,
          topic: ChatTopic.soil,
          value: _rowValue(CareDetail.soilShort, soilBody),
          body: soilBody,
        ),
      if (_plant.aiMoistureLevel != null)
        _careRow(
          tone: _CareTone.leaf,
          glyph: _Svg.dropOutline,
          title: l10n.careSectionSoilMoisture,
          topic: ChatTopic.soil,
          value: [
            _moistureLabel(),
            if (_plant.idealSoilMoistureMin != null &&
                _plant.idealSoilMoistureMax != null)
              '${_plant.idealSoilMoistureMin}–${_plant.idealSoilMoistureMax}%',
          ].where((s) => s.isNotEmpty).join(' · '),
          body: moistureBody.isNotEmpty
              ? moistureBody
              : (_plant.aiMoistureLevel ?? ''),
          showMoistureScale: true,
        ),
      if (_plant.aiLight != null)
        _careRow(
          tone: _CareTone.sun,
          glyph: _Svg.sun,
          title: l10n.careSectionLight,
          topic: ChatTopic.light,
          value: '${l10n.nHours(_lightHours())} · ${_lightType()}',
          body: lightBody.isNotEmpty ? lightBody : _plant.aiLight!,
          keyValues: [
            (l10n.lightDaily, l10n.nHours(_lightHours())),
            (l10n.lightType, _lightType()),
          ],
        ),
      if (tempBody.isNotEmpty)
        _careRow(
          tone: _CareTone.warm,
          glyph: _Svg.thermometer,
          title: l10n.careSectionTemperature,
          topic: ChatTopic.temperature,
          value: _rowValue(CareDetail.temperatureShort, tempBody),
          body: tempBody,
          keyValues: [
            if (_detail(CareDetail.temperatureOptimal) case final v?)
              (l10n.careKvOptimal, v),
            if (_detail(CareDetail.temperatureMinimum) case final v?)
              (l10n.careKvMinimum, v),
          ],
        ),
      if (fertBody.isNotEmpty)
        _careRow(
          tone: _CareTone.leaf,
          glyph: _Svg.fertilizer,
          title: l10n.careSectionFertilizer,
          topic: ChatTopic.fertilizer,
          value: _rowValue(CareDetail.fertilizerShort, fertBody),
          body: fertBody,
          keyValues: [
            if (_detail(CareDetail.fertilizerFrequency) case final v?)
              (l10n.careKvFrequency, v),
            if (_detail(CareDetail.fertilizerDose) case final v?)
              (l10n.careKvDose, v),
          ],
        ),
      if (placementBody.isNotEmpty)
        _careRow(
          tone: _CareTone.leaf,
          glyph: _Svg.pin,
          title: l10n.careSectionPlacement,
          topic: ChatTopic.light,
          value: _rowValue(CareDetail.placementShort, placementBody),
          body: placementBody,
        ),
      if (!_hasNoIssues(_plant.aiSpecificIssues))
        _buildIssuesCard(_plant.aiSpecificIssues!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          rows[i],
        ],
      ],
    );
  }

  // padding 13 15 · radius 22 · tile 40×40 radius 14 · icon 19
  // title 15.5/600/-.015em · value 12.5/500 ellipsized · chevron 15 #8B9285
  Widget _careRow({
    required _CareTone tone,
    required String glyph,
    required String title,
    required String value,
    required String body,
    // Required rather than defaulted: a row that forgets its topic would open a
    // chat that silently drops back to the general one, and the only symptom is
    // a vaguer answer nobody traces back to here.
    required String topic,
    List<(String, String)> keyValues = const [],
    bool showMoistureScale = false,
  }) {
    final (tint, foreground) = _toneColors(tone);
    final tappable =
        body.isNotEmpty || keyValues.isNotEmpty || showMoistureScale;

    return _PressScale(
      scale: 0.985,
      onTap: tappable
          ? () => _openCareSheet(
              tone: tone,
              glyph: glyph,
              title: title,
              value: value,
              body: body,
              topic: topic,
              keyValues: keyValues,
              showMoistureScale: showMoistureScale,
            )
          : null,
      child: _glass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x99FFFFFF), width: 0.5),
              ),
              child: Center(child: _Glyph(glyph, size: 19, color: foreground)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _font(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.015,
                      color: _kInk,
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _kMut,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (tappable) ...[
              const SizedBox(width: 8),
              const _Glyph(_Svg.chevronRight, size: 15, color: _kChev),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color) _toneColors(_CareTone t) => switch (t) {
    _CareTone.water => (_kWaterBg, _kWater),
    _CareTone.leaf => (_kLeafBg, _kAccent),
    _CareTone.sun => (_kSunBg, _kSun),
    _CareTone.warm => (_kWarmBg, _kWarm),
  };

  Future<void> _openCareSheet({
    required _CareTone tone,
    required String glyph,
    required String title,
    required String value,
    required String body,
    required String topic,
    required List<(String, String)> keyValues,
    required bool showMoistureScale,
  }) async {
    HapticFeedback.lightImpact();
    final (tint, foreground) = _toneColors(tone);

    // A custom route rather than showModalBottomSheet: the scrim must fade in
    // place while only the sheet rises, and barrierColor cannot carry a blur.
    final choice = await Navigator.of(context).push<String>(
      _CareSheetRoute(
        builder: (_) => _CareDetailSheet(
          glyph: glyph,
          tint: tint,
          foreground: foreground,
          title: title,
          value: value,
          body: body,
          keyValues: keyValues,
          showMoistureScale: showMoistureScale,
          moistureMin: _plant.idealSoilMoistureMin,
          moistureMax: _plant.idealSoilMoistureMax,
          dryLabel: l10n.moistureDry,
          wetLabel: l10n.moistureWet,
          askLabel: l10n.careAskAbout(title.toLowerCase()),
        ),
      ),
    );
    if (!mounted || choice != 'ask') return;

    await _askInChat(
      l10n.careAskQuestion(title),
      () => _openCareSheet(
        tone: tone,
        glyph: glyph,
        title: title,
        value: value,
        body: body,
        topic: topic,
        keyValues: keyValues,
        showMoistureScale: showMoistureScale,
      ),
      topic: topic,
    );
  }

  // Specific issues — padding 16 18 on rgba(255,251,240,.62)
  Widget _buildIssuesCard(String text) {
    final bullets = text
        .split('\n')
        .map((s) => s.replaceAll(RegExp(r'^[-•*]\s*'), '').trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    if (bullets.isEmpty) return const SizedBox.shrink();

    return _glass(
      fill: _kIssuesFill,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Glyph(_Svg.infoCircle, size: 17, color: _kSun),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l10n.specificIssues,
                  style: _font(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 15.5 * -0.015,
                    color: _kSun,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: _kSun.withAlpha(166),
                      shape: BoxShape.circle,
                    ), // .65
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      b,
                      style: _font(
                        fontSize: 13,
                        height: 1.5,
                        color: _kIssuesText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Tab: About ───────────────────────────────────────────────────────────
  // Glass cards, gap 9, padding 17 18. Header: 34×34 tile radius 12, icon 16,
  // title 16.5/600/-.02em. Body 14/1.55.

  Widget _buildAboutTab() {
    // Growth Rate / Personality / Toxicity live as sections inside aiCareTips —
    // the model has no dedicated fields for them.
    final growth = _section(CareSection.growthRate);
    final personality = _section(CareSection.personality);
    final toxicity = _section(CareSection.toxicity);
    final growthBody = [
      growth,
      personality,
    ].where((s) => s.isNotEmpty).join('\n\n');
    final description = _plant.aiGeneralDescription?.trim().isNotEmpty ?? false
        ? _plant.aiGeneralDescription!
        : _section(CareSection.generalDescription);

    // Short trait chips. interestingFacts are full sentences and already have
    // their own card, so they must not be reused here.
    final traits =
        <String>[
              ?_plant.aiGrowthStage,
              ?_plant.aiPlantSize,
              ?_plant.aiPotSize,
              _lightType(),
            ]
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length <= 28)
            .toList();

    final cards = <Widget>[
      if (description.isNotEmpty)
        _aboutCard(
          glyph: _Svg.leaf,
          tint: _kLeafBg,
          foreground: _kAccent,
          title: l10n.aboutPlantTitle,
          body: description,
          tags: traits,
        ),
      if (growthBody.isNotEmpty)
        _aboutCard(
          glyph: _Svg.trendingUp,
          tint: _kLeafBg,
          foreground: _kAccent,
          title:
              '${l10n.careSectionGrowthRate} & '
              '${l10n.careSectionPersonality.toLowerCase()}',
          body: growthBody,
        ),
      if (toxicity.isNotEmpty)
        _aboutCard(
          glyph: _Svg.warningTriangle,
          tint: _kWarmBg,
          foreground: _kWarm,
          title: l10n.careSectionToxicity,
          body: toxicity,
        ),
      if (_plant.interestingFacts?.isNotEmpty ?? false)
        _factsCard(_plant.interestingFacts!),
    ];

    if (cards.isEmpty) {
      return _glass(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Text(
          l10n.noDataAvailable,
          textAlign: TextAlign.center,
          style: _font(fontSize: 14, color: _kMut),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          cards[i],
        ],
      ],
    );
  }

  Widget _aboutCard({
    required String glyph,
    required Color tint,
    required Color foreground,
    required String title,
    required String body,
    List<String> tags = const [],
  }) {
    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(glyph: glyph, tint: tint, foreground: foreground),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: _font(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 16.5 * -0.02,
                    color: _kInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(body, style: _font(fontSize: 14, height: 1.55, color: _kInk2)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final t in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB8FFFFFF), // rgba(255,255,255,.72)
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xD9FFFFFF),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      t,
                      style: _font(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kInk2,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 34×34 tile, radius 12, .5px rgba(255,255,255,.6), icon 16
  Widget _iconTile({
    required String glyph,
    required Color tint,
    required Color foreground,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x99FFFFFF), width: 0.5),
      ),
      child: Center(child: _Glyph(glyph, size: 16, color: foreground)),
    );
  }

  // Fact boxes: rgba(255,255,255,.6), .5px rgba(255,255,255,.8), radius 16,
  // padding 12 14, 6 px accent dot.
  Widget _factsCard(List<String> facts) {
    final items = facts.where((f) => f.trim().isNotEmpty).take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(glyph: _Svg.sparkle, tint: _kSunBg, foreground: _kSun),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  l10n.interestingFactsTitle,
                  style: _font(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 16.5 * -0.02,
                    color: _kInk,
                  ),
                ),
              ),
            ],
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 13 : 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x99FFFFFF), // rgba(255,255,255,.6)
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xCCFFFFFF),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: const BoxDecoration(
                        color: _kAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: _font(fontSize: 13, height: 1.5, color: _kInk2),
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

  // ─── Tab: History ─────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<HealthCheckRecord>>(
          stream: _healthCheckStream,
          builder: (context, snap) {
            final checks = [...?snap.data]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return _glass(
              fill: _kHistoryFill,
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        const _Glyph(_Svg.gallery, size: 17, color: _kWater),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            l10n.healthCheckHistoryTitle,
                            style: _font(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 16 * -0.02,
                              color: _kWater,
                            ),
                          ),
                        ),
                        // No "+" here: SPEC 3.4 leaves exactly two entry points to
                        // the analysis — the widget button and the health chip.
                        // History is for reading, so a third one only made the
                        // check-per-cycle budget harder to reason about.
                      ],
                    ),
                  ),
                  // An failed query and a genuinely empty history used to render
                  // the same "no checks yet" state, which is how a broken read
                  // stayed invisible.
                  if (snap.hasError)
                    _buildHistoryError(snap.error!)
                  else if (checks.isEmpty)
                    _buildEmptyHistory()
                  else
                    for (final c in checks.take(5)) _buildHistoryRow(c),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 11), // .rows gap 9 + .del margin-top 2
        Center(child: _deleteButton()),
      ],
    );
  }

  // padding 26 10 8 · 56 px circle · title 15.5/600 · copy 13, max-width 210
  /// Shown when the history query itself fails. The message is intentionally the
  /// raw error: this is a state the user should report, not one they can fix.
  Widget _buildHistoryError(Object error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
      child: Column(
        children: [
          const _Glyph(_Svg.warningTriangle, size: 24, color: _kWarm),
          const SizedBox(height: 10),
          Text(
            l10n.healthHistoryLoadFailed,
            textAlign: TextAlign.center,
            style: _font(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _font(fontSize: 12, color: _kMut),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Padding(
      // .hempty padding 26 10 8, inside the card's own 18 px horizontal inset.
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 8),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kWater.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: _Glyph(_Svg.gallery, size: 24, color: _kWater),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.noHealthChecksYet,
            style: _font(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              l10n.healthCheckHistoryEmptyHint,
              textAlign: TextAlign.center,
              style: _font(fontSize: 13, height: 1.45, color: _kMut),
            ),
          ),
        ],
      ),
    );
  }

  String _verdictOf(HealthCheckRecord record, Map<String, dynamic>? assistant) {
    final praise = assistant?['praise_phrase']?.toString().trim();
    if (praise != null && praise.isNotEmpty) return praise;
    final problem = assistant?['problem_name']?.toString().trim();
    if (problem != null && problem.isNotEmpty) return problem;
    return record.status == 'ok' ? l10n.healthy : l10n.healthIssueDetected;
  }

  static String? _checkImageUrl(HealthCheckRecord record) =>
      record.imageUrls.isNotEmpty ? record.imageUrls.first : record.imageUrl;

  Widget _buildHistoryRow(HealthCheckRecord record) {
    final ok = record.status == 'ok';
    final imgUrl = _checkImageUrl(record);
    final assistant = _tryParsePlantAssistant(record.message);
    final verdict = _verdictOf(record, assistant);

    return _PressScale(
      scale: 0.985,
      onTap: () => _openHealthCheckSheet(record, assistant),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _historyThumbFallback(),
                    )
                  : _historyThumbFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd(_localeTag).format(record.timestamp),
                    style: _font(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    verdict,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _font(fontSize: 12, color: ok ? _kAccent : _kWarm),
                  ),
                ],
              ),
            ),
            if (record.score != null) ...[
              _scorePill(record.score!),
              const SizedBox(width: 8),
            ],
            const _Glyph(_Svg.chevronRight, size: 15, color: _kChev),
          ],
        ),
      ),
    );
  }

  /// Score badge on a timeline row. Green above the healthy floor, amber below —
  /// the same threshold the backend ties `health_score` to `status`, so the pill
  /// never disagrees with the verdict next to it.
  Widget _scorePill(int score) {
    final good = score >= kHealthyScoreFloor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: good ? _kLeafBg : kGlassAttnBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: _font(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: good ? _kAccent : const Color(0xFFA5701A),
        ),
      ),
    );
  }

  String _severityLabel(String raw) => switch (raw.toLowerCase().trim()) {
    'low' || 'mild' || 'minor' => l10n.severityLow,
    'medium' || 'moderate' => l10n.severityMedium,
    'high' || 'severe' || 'critical' => l10n.severityHigh,
    _ => raw,
  };

  /// Expands a stored check into the same glass sheet the care rows use. The
  /// analyzer writes one of two shapes — a praise/summary pair when the plant
  /// is fine, or a problem with action steps when it is not.
  void _openHealthCheckSheet(
    HealthCheckRecord record,
    Map<String, dynamic>? assistant,
  ) {
    HapticFeedback.selectionClick();

    // Checks recorded since scoring landed get the full result view — the same
    // one a fresh analysis shows. Older records have none of those fields and
    // fall through to the prose sheet below.
    if (record.score != null ||
        record.findings.isNotEmpty ||
        record.recommendations.isNotEmpty) {
      _openStoredResultSheet(record);
      return;
    }

    final ok = record.status == 'ok';

    String? text(String key) {
      final v = assistant?[key]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final steps =
        (assistant?['action_steps'] as List?)
            ?.map((s) => s.toString().trim())
            .where((s) => s.isNotEmpty)
            .map((s) => '• $s') ??
        const <String>[];

    final paragraphs = <String>[
      ?text('health_summary'),
      ?text('problem_description'),
      ...steps,
      ?text('reassurance'),
      ?text('maintenance_footer'),
    ];
    // Older checks stored the raw model reply instead of a JSON payload.
    final body = paragraphs.isNotEmpty
        ? paragraphs.join('\n')
        : record.message.trim();

    final severity = text('severity');
    final followUp = assistant?['follow_up_days'];
    final followUpDays = followUp is int
        ? followUp
        : int.tryParse('${followUp ?? ''}');

    Navigator.of(context).push(
      _CareSheetRoute(
        builder: (_) => _CareDetailSheet(
          glyph: ok ? _Svg.check : _Svg.warningTriangle,
          tint: ok ? _kLeafBg : _kWarmBg,
          foreground: ok ? _kAccent : _kWarm,
          title: _verdictOf(record, assistant),
          value: DateFormat.yMMMMd(
            _localeTag,
          ).add_jm().format(record.timestamp),
          body: body.isNotEmpty ? body : l10n.noDataAvailable,
          keyValues: [
            if (severity != null)
              (l10n.healthCheckSeverity, _severityLabel(severity)),
            if (followUpDays != null && followUpDays > 0)
              (l10n.healthCheckFollowUp, l10n.nDays(followUpDays)),
          ],
          imageUrl: _checkImageUrl(record),
          dryLabel: l10n.moistureDry,
          wetLabel: l10n.moistureWet,
        ),
      ),
    );
  }

  Widget _historyThumbFallback() => Container(
    width: 46,
    height: 46,
    color: _kLeafBg,
    child: Center(
      child: _Glyph(_Svg.flower, size: 20, color: _kAccent.withAlpha(153)),
    ),
  );

  // rgba(255,255,255,.55) + blur(20px) · .5px rgba(198,86,68,.28) · 14/600
  Widget _deleteButton() {
    return _PressScale(
      scale: 0.97,
      onTap: _showDeleteConfirmation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0x8CFFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _kWarm.withAlpha(71),
                width: 0.5,
              ), // .28
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Glyph(_Svg.trash, size: 15, color: _kWarm),
                const SizedBox(width: 7),
                Text(
                  l10n.deletePlant,
                  style: _font(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kWarm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CareTone { water, leaf, sun, warm }

// ════════════════════════════════════════════════════════════════════════════
//  Watering widget decoration
// ════════════════════════════════════════════════════════════════════════════

/// Diagonal specular streak: an 80% × 200% band offset to top −60% / left −20%
/// and rotated 12°, so the highlight lands in the upper-left corner rather than
/// washing across the middle of the card.
class _WateringSheen extends StatelessWidget {
  const _WateringSheen();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -0.20 * c.maxWidth,
              top: -0.60 * c.maxHeight,
              width: 0.80 * c.maxWidth,
              height: 2.0 * c.maxHeight,
              child: Transform.rotate(
                angle: 12 * math.pi / 180,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    // linear-gradient(100deg, transparent, rgba(255,255,255,.55), transparent)
                    gradient: LinearGradient(
                      begin: Alignment(-0.985, -0.174),
                      end: Alignment(0.985, 0.174),
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x8CFFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ~10 droplets spawned across the top of the widget with random 0–550 ms
/// delays; each falls 95 px over 1.1 s ease-in, scaling .5 → 1.05, fading in at
/// 18% and out at the end.
class _DropletBurst extends StatefulWidget {
  final int trigger;
  const _DropletBurst({required this.trigger});

  @override
  State<_DropletBurst> createState() => _DropletBurstState();
}

class _DropletBurstState extends State<_DropletBurst>
    with SingleTickerProviderStateMixin {
  static const _count = 10;
  static const _fall = Duration(milliseconds: 1100);
  static const _maxDelay = Duration(milliseconds: 550);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _fall + _maxDelay,
  );
  final _rng = math.Random();
  late List<(double left, double top, double delay)> _drops;

  @override
  void initState() {
    super.initState();
    _drops = const [];
  }

  @override
  void didUpdateWidget(_DropletBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) {
      _drops = List.generate(_count, (_) {
        final delayFraction =
            _rng.nextDouble() *
            (_maxDelay.inMilliseconds / _ctrl.duration!.inMilliseconds);
        return (
          0.10 + _rng.nextDouble() * 0.78, // left 10–88%
          10 + _rng.nextDouble() * 22, // top 10–32 px
          delayFraction,
        );
      });
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_drops.isEmpty) return const SizedBox.shrink();

    // Reduced motion: skip the particles entirely.
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();

    final span = _fall.inMilliseconds / _ctrl.duration!.inMilliseconds;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        if (!_ctrl.isAnimating && _ctrl.value == 0) {
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, c) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (left, top, delay) in _drops)
                _droplet(
                  c.maxWidth * left,
                  top,
                  ((_ctrl.value - delay) / span).clamp(0.0, 1.0),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _droplet(double left, double top, double t) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final eased = Curves.easeIn.transform(t);
    final opacity = t < 0.18 ? t / 0.18 : (1 - (t - 0.18) / 0.82);
    return Positioned(
      left: left,
      top: top - 8 + eased * 103,
      child: Opacity(
        opacity: (opacity * 0.95).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.5 + eased * 0.55,
          child: const Text('💧', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Interaction primitives
// ════════════════════════════════════════════════════════════════════════════

/// `transform: scale(n)` on press over 140 ms. A null [onTap] renders the child
/// inert while keeping its layout identical.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const _PressScale({required this.child, this.onTap, this.scale = 0.985});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Watering CTA: press scale(.975) plus a white 50% ripple that grows from the
/// touch point to scale(9) over 700 ms ease-out while fading.
class _RippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final Color fill;
  final BoxBorder? border;
  final List<BoxShadow> shadow;

  const _RippleButton({
    required this.child,
    required this.onTap,
    required this.enabled,
    required this.fill,
    required this.shadow,
    this.border,
  });

  @override
  State<_RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<_RippleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Offset? _origin;
  bool _down = false;

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails d) {
    setState(() {
      _down = true;
      _origin = d.localPosition;
    });
    if (!MediaQuery.disableAnimationsOf(context)) _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? _handleTapDown : null,
      onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.fill,
            borderRadius: radius,
            border: widget.border,
            boxShadow: widget.shadow,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: widget.child,
                ),
                if (_origin != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _ripple,
                        builder: (context, _) {
                          if (_ripple.value == 0 || _ripple.isCompleted) {
                            return const SizedBox.shrink();
                          }
                          final t = Curves.easeOut.transform(_ripple.value);
                          return CustomPaint(
                            painter: _RipplePainter(
                              origin: _origin!,
                              radius: t * 9 * 24,
                              opacity: (1 - t) * 0.5,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset origin;
  final double radius;
  final double opacity;

  const _RipplePainter({
    required this.origin,
    required this.radius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      origin,
      radius,
      Paint()..color = Colors.white.withAlpha((255 * opacity).round()),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.opacity != opacity || old.origin != origin;
}

// ════════════════════════════════════════════════════════════════════════════
//  Segmented control
// ════════════════════════════════════════════════════════════════════════════

class _SegTab {
  final String glyph;
  final String label;
  const _SegTab(this.glyph, this.label);
}

/// Liquid-slide segmented control. The knob animates left/width over 340 ms
/// cubic-bezier(.32,.72,.25,1) behind the labels; label colour crossfades over
/// 200 ms. This motion is the signature of the screen.
class _LiquidSegmentedControl extends StatelessWidget {
  final List<_SegTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const _LiquidSegmentedControl({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // `.seg` is padding 4 + gap 4, and the knob is pinned to each button's
        // own offsetLeft/offsetWidth, so it spans the full inner height.
        const gap = 4.0;
        final button = (c.maxWidth - gap * (tabs.length - 1)) / tabs.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 340),
              curve: _kKnobCurve,
              left: selected * (button + gap),
              top: 0,
              bottom: 0,
              width: button,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _kKnob,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x47141E0F),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                // inset 0 1px 0 #fff
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 1,
                    width: double.infinity,
                    child: ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            ),
            // The Row is the only unpositioned child, so it sets the height the
            // knob stretches to — matching `.seg button`'s 11 px padding.
            Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(child: _tab(i)),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _tab(int i) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(i),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: i == selected ? _kInk : _kMut),
        duration: const Duration(milliseconds: 200),
        builder: (context, color, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Glyph(tabs[i].glyph, size: 15, color: color ?? _kMut),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  tabs[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: _font(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
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

// ════════════════════════════════════════════════════════════════════════════
//  Care detail sheet
// ════════════════════════════════════════════════════════════════════════════

/// Route for the care detail sheet. Enter is 420 ms; the child owns both the
/// scrim fade and the sheet rise so they can animate independently.
class _CareSheetRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  _CareSheetRoute({required this.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  bool get barrierDismissible => false; // the scrim handles its own taps

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  // The page goes straight into the Overlay, so it needs a Material of its own
  // to supply a DefaultTextStyle — without one, text inherits WidgetsApp's debug
  // error style and picks up its yellow double underline.
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Material(type: MaterialType.transparency, child: builder(context));
}

/// Inset floating sheet: 8 px insets, radius 34, max-height 76%,
/// rgba(252,253,251,.82) over blur(40px), with its own blurred scrim.
///
/// Enter: translateY(70px) + opacity 0 → 0 over 420 ms `_kSheetCurve`, scrim
/// fading in over 300 ms. Dismiss on scrim tap, close button, or a downward
/// drag on the grabber past 90 px.
class _CareDetailSheet extends StatefulWidget {
  final String glyph;
  final Color tint;
  final Color foreground;
  final String title;
  final String value;
  final String body;
  final List<(String, String)> keyValues;
  final bool showMoistureScale;
  final int? moistureMin;
  final int? moistureMax;
  final String dryLabel;
  final String wetLabel;
  final String? imageUrl;

  /// Label of the "ask assistant" row. Empty hides it — the sheet is also used
  /// for cards that have nothing to ask about.
  final String askLabel;

  const _CareDetailSheet({
    required this.glyph,
    required this.tint,
    required this.foreground,
    required this.title,
    required this.value,
    required this.body,
    required this.keyValues,
    required this.dryLabel,
    required this.wetLabel,
    this.askLabel = '',
    this.imageUrl,
    this.showMoistureScale = false,
    this.moistureMin,
    this.moistureMax,
  });

  @override
  State<_CareDetailSheet> createState() => _CareDetailSheetState();
}

class _CareDetailSheetState extends State<_CareDetailSheet>
    with SingleTickerProviderStateMixin {
  static const _dismissThreshold = 90.0;

  late final AnimationController _snapBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() {}));

  double _drag = 0;
  double _dragAtRelease = 0;

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  double get _dragOffset => _snapBack.isAnimating
      ? _dragAtRelease * (1 - Curves.easeOut.transform(_snapBack.value))
      : _drag;

  void _onDragUpdate(DragUpdateDetails d) {
    _snapBack.stop();
    setState(() => _drag = math.max(0, _drag + d.delta.dy));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_drag > _dismissThreshold || d.velocity.pixelsPerSecond.dy > 700) {
      Navigator.of(context).pop();
      return;
    }
    _dragAtRelease = _drag;
    _drag = 0;
    _snapBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final animation = ModalRoute.of(context)?.animation;

    return AnimatedBuilder(
      animation: animation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, _) {
        final raw = animation?.value ?? 1.0;
        final rise = _kSheetCurve
            .transform(raw.clamp(0.0, 1.0))
            .clamp(0.0, 1.0);
        // Scrim fades over 300 ms of the 420 ms enter.
        final scrimT = Curves.easeOut.transform((raw / 0.71).clamp(0.0, 1.0));

        return Stack(
          children: [
            // Scrim: rgba(18,24,14,.28) + blur(6px) → sigma 3. Tap to dismiss.
            Positioned.fill(
              child: Opacity(
                opacity: scrimT,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: const ColoredBox(color: Color(0x4712180E)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8 + media.padding.bottom,
              child: Transform.translate(
                offset: Offset(0, 70 * (1 - rise) + _dragOffset),
                child: Opacity(opacity: rise, child: _sheet(context, media)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheet(BuildContext context, MediaQueryData media) {
    final paragraphs = widget.body
        .split('\n')
        .map((s) => s.replaceAll(RegExp(r'^[-•*]\s*'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.76),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(34)),
          boxShadow: [
            BoxShadow(
              color: Color(0x6614200F),
              blurRadius: 50,
              spreadRadius: -18,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(34)),
          child: BackdropFilter(
            filter: _kSheetFilter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xD1FCFDFB), // rgba(252,253,251,.82)
                borderRadius: const BorderRadius.all(Radius.circular(34)),
                border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber + header are the drag handle; the body keeps its
                  // own scrolling.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 5,
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0x29141E0F,
                            ), // rgba(20,30,15,.16)
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        _header(context),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.imageUrl?.isNotEmpty ?? false) _photo(),
                          if (widget.keyValues.isNotEmpty) _keyValueStrip(),
                          if (widget.showMoistureScale) _moistureScale(),
                          for (var i = 0; i < paragraphs.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == paragraphs.length - 1 ? 0 : 12,
                              ),
                              child: Text(
                                paragraphs[i],
                                style: _font(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: _kInk2,
                                ),
                              ),
                            ),
                          if (widget.askLabel.isNotEmpty)
                            BotanlyAskRow(
                              label: widget.askLabel,
                              // Popped with a result rather than pushing the
                              // chat from here: the host owns the return trip
                              // back to this sheet (SPEC 1.4).
                              onTap: () => Navigator.of(context).pop('ask'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: _kLeafBg),
          ),
        ),
      ),
    );
  }

  // gap 13 · 44×44 tile radius 16 icon 21 · title 21/600/-.03em
  // · value pill 12/600 · 32 px close button rgba(20,30,15,.07)
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.tint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xB3FFFFFF), width: 0.5),
            ),
            child: Center(
              child: _Glyph(widget.glyph, size: 21, color: widget.foreground),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: _font(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 21 * -0.03,
                    color: _kInk,
                  ),
                ),
                if (widget.value.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.value,
                      style: _font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PressScale(
            scale: 0.9,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0x12141E0F), // rgba(20,30,15,.07)
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: _Glyph(_Svg.close, size: 14, color: _kMut),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Equal cells · rgba(255,255,255,.7) · .5px rgba(255,255,255,.9) · radius 16
  // · padding 11 8 · caption 10/600 uppercase .06em over value 14.5/600
  Widget _keyValueStrip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          for (var i = 0; i < widget.keyValues.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB3FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xE6FFFFFF),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.keyValues[i].$1.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10 * 0.06,
                        color: _kMut,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.keyValues[i].$2,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _font(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 8 px bar · gradient #E8D3A6 → #A9CE8C → #3E8E3B → #2E86C8
  // · 20 px white knob with a 3 px accent ring
  Widget _moistureScale() {
    final min = widget.moistureMin;
    final max = widget.moistureMax;
    final midpoint = (min != null && max != null)
        ? ((min + max) / 2 / 100).clamp(0.0, 1.0)
        : 0.38;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE8D3A6),
                            Color(0xFFA9CE8C),
                            Color(0xFF3E8E3B),
                            Color(0xFF2E86C8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth - 20) * midpoint,
                    top: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: _kAccent, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x38000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.dryLabel, style: _font(fontSize: 11, color: _kMut2)),
              if (min != null && max != null)
                Text('$min–$max%', style: _font(fontSize: 11, color: _kMut2)),
              Text(widget.wetLabel, style: _font(fontSize: 11, color: _kMut2)),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  More menu
// ════════════════════════════════════════════════════════════════════════════

class _MoreMenuSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editLabel;
  final String deleteLabel;

  const _MoreMenuSheet({
    required this.onEdit,
    required this.onDelete,
    required this.editLabel,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x6614200F),
            blurRadius: 50,
            spreadRadius: -18,
            offset: Offset(0, -20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: BackdropFilter(
          filter: _kSheetFilter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD1FCFDFB),
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x29141E0F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                _item(_Svg.edit, _kAccent, editLabel, _kInk, onEdit),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0x12141E0F),
                ),
                _item(_Svg.trash, _kWarm, deleteLabel, _kWarm, onDelete),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    String glyph,
    Color iconColor,
    String label,
    Color textColor,
    VoidCallback onTap,
  ) {
    return _PressScale(
      scale: 0.99,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _Glyph(glyph, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: _font(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
