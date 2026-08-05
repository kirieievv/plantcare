/// Home — garden pulse, today's deck, the plant list (SPEC part 2).
///
/// Replaces the old dashboard. The background is deliberately generic: there are
/// many plants, so no single plant's photo belongs here.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/plant_health.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/utils/chat_topics.dart';
import 'package:plant_care/screens/all_tasks_screen.dart';
import 'package:plant_care/screens/plant_chat_screen.dart';
import 'package:plant_care/screens/plant_details_screen.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/services/weather_service.dart';
import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/widgets/garden_pulse.dart';
import 'package:plant_care/widgets/pull_to_refresh.dart';
import 'package:plant_care/widgets/task_deck.dart';
import 'package:plant_care/widgets/task_sheet.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  /// Switches the tab bar — "Add Plant" is a tab, not a route.
  final void Function(int index)? onTabChange;

  const HomeScreen({super.key, this.user, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tasks = TaskService();

  /// Kept across tab switches: the tab bar rebuilds this screen from scratch
  /// every time it comes back, and a skeleton over data we already hold reads
  /// as a stutter. First entry and an explicit refresh are the only two moments
  /// the skeleton is honest (§3.4).
  static List<Plant>? _cachedPlants;
  static List<CareTask>? _cachedTasks;

  StreamSubscription<List<Plant>>? _plantSub;
  StreamSubscription<List<CareTask>>? _taskSub;
  StreamSubscription<SubscriptionInfo>? _subSub;
  StreamSubscription<WeatherReading>? _weatherSub;

  /// Null until something is known. The header simply omits the weather block
  /// while it is — the screen never waits on this to draw (SPEC 12, §4).
  WeatherReading? _weather;

  /// Whether the paid doors are shut. Watched rather than read once, so paying
  /// removes the reminder bar without a restart (SPEC 10, §5.3).
  bool _subLocked = false;
  bool _subTrialEnded = false;

  /// Null until the answer arrives. Everything the screen renders from data is
  /// gated on these two being non-null — that is what keeps a "100" from
  /// flashing before the garden is known (§3.1).
  List<Plant>? _plants;
  List<CareTask>? _openTasks;
  Object? _error;

  /// Bumped when a watering task is closed, so the ring rains.
  int _dropletBurst = 0;

  /// The pull gesture's travel, 0 → 1. Owned here so the ring can watch it
  /// without the whole list rebuilding on every pointer move.
  final _pullProgress = ValueNotifier<double>(0);
  final _scroll = ScrollController();

  /// A pull-triggered request is in flight. Data is *not* dropped while it is:
  /// if the request fails, the score has to come back to its last known value
  /// rather than to an empty ring (§5).
  bool _refreshing = false;
  bool _gotPlants = false;
  bool _gotTasks = false;
  DateTime? _refreshStart;
  Timer? _minHold;
  Timer? _timeout;

  /// Shortest and longest the refresh animation may run. The handoff's floor is
  /// 600 ms; a full second is held instead, so the clouds roll in and breathe
  /// rather than blink. Past 10 s the request counts as failed (§5).
  static const _minRefresh = Duration(milliseconds: 1000);
  static const _maxRefresh = Duration(seconds: 10);

  bool get _loading =>
      _refreshing ||
      (_error == null && (_plants == null || _openTasks == null));
  bool get _failed => _error != null && (_plants == null || _openTasks == null);

  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _plants = _cachedPlants;
    _openTasks = _cachedTasks;
    _listen();
    _watchSubscription();
    _watchWeather();
  }

  /// Cache first, network second.
  ///
  /// Yesterday's city is still the right city, so the header can draw at once
  /// and correct itself a moment later if anything changed.
  void _watchWeather() {
    _weatherSub = WeatherService().stream.listen((reading) {
      if (mounted) setState(() => _weather = reading);
    });

    WeatherService().loadCached().then((reading) {
      if (mounted) setState(() => _weather = reading);
      // Failures are silent by design: no city means the header shows the date
      // alone, which is the specified fallback.
      WeatherService().refresh();
    });
  }

  void _watchSubscription() {
    void apply(SubscriptionInfo info) {
      final locked = !info.hasAccess;
      final trial = info.rawStatus == SubscriptionStatus.trial;
      if (!mounted) return;
      if (locked == _subLocked && trial == _subTrialEnded) return;
      setState(() {
        _subLocked = locked;
        _subTrialEnded = trial;
      });
    }

    final current = SubscriptionService().currentInfo;
    if (current != null) apply(current);
    _subSub = SubscriptionService().stream.listen(apply);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolved here rather than at use: a refresh can finish after this element
    // is deactivated, and an ancestor lookup then throws.
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _plantSub?.cancel();
    _taskSub?.cancel();
    _subSub?.cancel();
    _weatherSub?.cancel();
    _minHold?.cancel();
    _timeout?.cancel();
    _pullProgress.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _listen() {
    _plantSub?.cancel();
    _taskSub?.cancel();
    _plantSub = PlantService().getPlants().listen((plants) {
      setState(() {
        _plants = _cachedPlants = plants;
        _error = null;
      });
      _gotPlants = true;
      _maybeEndRefresh();
    }, onError: _onStreamError);
    _taskSub = _tasks.watchOpenTasks().listen((tasks) {
      setState(() {
        _openTasks = _cachedTasks = tasks;
        _error = null;
      });
      _gotTasks = true;
      _maybeEndRefresh();
    }, onError: _onStreamError);
  }

  void _onStreamError(Object e) {
    // With data already on screen the failure belongs in a toast, not in place
    // of the garden; only a cold start has nothing to fall back to.
    if (_plants == null || _openTasks == null) setState(() => _error = e);
    if (_refreshing) _endRefresh(failed: true);
  }

  /// Pull released past the threshold. A gesture during a request never starts
  /// a second one (§2.2).
  void _refresh() {
    if (_loading) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    _gotPlants = false;
    _gotTasks = false;
    _refreshStart = DateTime.now();
    _timeout?.cancel();
    _timeout = Timer(_maxRefresh, () => _endRefresh(failed: true));
    _listen();
  }

  void _maybeEndRefresh() {
    if (!_refreshing || !_gotPlants || !_gotTasks) return;
    final left = _minRefresh - DateTime.now().difference(_refreshStart!);
    if (left > Duration.zero) {
      _minHold?.cancel();
      _minHold = Timer(left, _endRefresh);
    } else {
      _endRefresh();
    }
  }

  void _endRefresh({bool failed = false}) {
    if (!_refreshing) return;
    _minHold?.cancel();
    _timeout?.cancel();
    setState(() => _refreshing = false);

    if (failed) {
      refreshErrorHaptic();
      _messenger?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.refreshFailed),
          backgroundColor: kGlassAlert,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      refreshSuccessHaptic();
    }
  }

  Future<void> _complete(CareTask task) async {
    if (task.category == TaskCategory.water) {
      setState(() => _dropletBurst++);
    }
    try {
      // "Done" on a watering task means the user watered: the plant has to be
      // told, or it stays overdue and the scheduler hands the task straight
      // back (SPEC 1.3.5). Feeding leaves its own mark for the same reason.
      if (task.category == TaskCategory.water) {
        await PlantService().waterPlant(task.plantId);
      } else if (task.category == TaskCategory.fertilizer) {
        await PlantService().markFertilised(task.plantId);
      }
      await _tasks.complete(task.id);
    } catch (_) {
      // The stream is the source of truth: a failed write simply leaves the
      // task where it was, and the next snapshot puts the card back.
    }
  }

  Future<void> _postpone(CareTask task) async {
    try {
      await _tasks.postpone(task.id);
    } catch (_) {
      // Ordering only.
    }
  }

  Future<void> _openTask(CareTask task, List<Plant> plants) async {
    // A scheduled health check is run, not ticked — and running it needs the
    // plant's own screen (photos, the gate, the analysis sheet). Send the user
    // there instead of offering a sheet that cannot finish the job.
    if (isScheduledScan(task)) {
      final plant = plants.where((p) => p.id == task.plantId).firstOrNull;
      if (plant != null) _openPlant(plant);
      return;
    }

    final choice = await showTaskSheet(context: context, task: task);
    if (!mounted || choice == null) return;
    switch (choice) {
      case TaskSheetResult.done:
        await _complete(task);
      case TaskSheetResult.later:
        await _postpone(task);
      case TaskSheetResult.ask:
        final question = AppLocalizations.of(
          context,
        )!.taskAskQuestion(task.title);
        await _openChat(task, plants, question);
        if (!mounted) return;
        // SPEC 1.4: the chat hands the user back to the sheet they left.
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        await _openTask(task, plants);
    }
  }

  Future<void> _openChat(
    CareTask task,
    List<Plant> plants,
    String question,
  ) async {
    final plant = plants.where((p) => p.id == task.plantId).firstOrNull;
    if (plant == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantChatScreen(
          plant: plant,
          initialQuestion: question,
          // Same rule as on the plant screen: the task leads to the subject it
          // is about, so a watering chore and the watering card land in one
          // thread rather than two.
          topic: switch (task.category) {
            TaskCategory.water => ChatTopic.water,
            TaskCategory.light => ChatTopic.light,
            TaskCategory.soil => ChatTopic.soil,
            TaskCategory.fertilizer => ChatTopic.fertilizer,
            TaskCategory.scan => ChatTopic.diagnostics,
            TaskCategory.other => ChatTopic.general,
          },
        ),
      ),
    );
  }

  void _openPlant(Plant plant) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PlantDetailsScreen(plant: plant)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loading = _loading;

    final plants = _plants ?? const <Plant>[];
    final allTasks = _openTasks ?? const <CareTask>[];
    final now = DateTime.now();

    // Tasks whose plant is gone would otherwise haunt the deck.
    final ids = plants.map((p) => p.id).toSet();
    final live = allTasks.where((t) => ids.contains(t.plantId)).toList();
    // `isActiveAt` is what decides the empty state: it keeps overdue tasks in
    // today and keeps a postponed one there too, so neither collapses the deck
    // (tasks_empty_state_flow §3). What is not active is simply not shown here
    // — "All tasks" owns the "Later" section.
    final today = sortTasks(live.where((t) => t.isActiveAt(now)).toList(), now);

    final garden = gardenHealthOf(plants, live, now: now);

    return Scaffold(
      backgroundColor: const Color(0xFFEDF0EC),
      body: Stack(
        children: [
          const Positioned.fill(child: BotanlyBackground()),
          BotanlyPullToRefresh(
            controller: _scroll,
            progress: _pullProgress,
            busy: loading,
            onRefresh: _refresh,
            child: ScrollConfiguration(
              // Clamping, not bouncing: the pull is ours to draw, and an iOS
              // rubber band under it would double the travel.
              behavior: const NoGlowScrollBehavior(),
              child: Semantics(
                label: l10n.pullToRefreshHint,
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 104),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  children: [
                    _Header(
                      l10n: l10n,
                      onProfile: () => widget.onTabChange?.call(3),
                      weather: _weather,
                    ),
                    // Room for the top plant's name, which by design reaches
                    // just above the dial.
                    const SizedBox(height: 14),
                    // The one and only mention of the subscription outside the
                    // paid doors themselves (SPEC 10, §3). No pop-up on launch,
                    // no blur over the garden — one calm line that says what
                    // still works, and a way back.
                    if (_subLocked)
                      _LockBar(
                        l10n: l10n,
                        trial: _subTrialEnded,
                        onTap: () => widget.onTabChange?.call(2),
                      ),
                    if (_failed)
                      _ErrorCard(
                        message: l10n.gardenLoadError,
                        retryLabel: l10n.retry,
                        onRetry: () {
                          setState(() => _error = null);
                          _listen();
                        },
                      )
                    else ...[
                      GardenPulse(
                        garden: garden,
                        label: l10n.gardenHealthLabel,
                        caption: _gardenCaption(garden, l10n),
                        dropletBurst: _dropletBurst,
                        loading: loading,
                        loadingLabel: l10n.refreshingGarden,
                        pullProgress: _pullProgress,
                        plants: [
                          for (final p in plants)
                            (
                              plant: p,
                              score: livePlantScore(
                                p,
                                live.where((t) => t.plantId == p.id),
                                now: now,
                              ),
                              needsWater: _needsWater(p, now),
                            ),
                        ],
                        onOpenPlant: _openPlant,
                        onShowAll: () => widget.onTabChange?.call(1),
                      ),
                      // The garden score is the average of the last scans.
                      // With no subscription there are no new scans, so the
                      // number freezes — saying so is the honest move; a stale
                      // number shown plainly reads as "the garden is fine".
                      if (_subLocked && plants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const BotanlyGlyph(
                                BotanlySvg.clock,
                                size: 13,
                                color: kGlassMut2,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  l10n.gateStaleScore,
                                  textAlign: TextAlign.center,
                                  style: glassFont(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: kGlassMut2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (loading || plants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                          child: Text(
                            l10n.homeOrbitHint,
                            textAlign: TextAlign.center,
                            style: glassFont(fontSize: 12, color: kGlassMut2),
                          ),
                        ),
                      _SectionLabel(
                        title: l10n.allTasksToday,
                        // Counters and the link stay empty until they can be right.
                        count: loading ? 0 : today.length,
                        // Zero is an answer here, so it is printed rather than
                        // hidden. The link stays live with it: "All tasks" also
                        // holds the "Later" section, which an empty today does
                        // not empty (tasks_empty_state_flow §2.3).
                        showZero: !loading,
                        action: loading ? null : l10n.homeAllTasksLink,
                        onAction: () => Navigator.of(context).push(
                          allTasksRoute(
                            onAsk: (task, question) =>
                                _openChat(task, plants, question),
                            onOpenPlant: (plantId) {
                              final plant = plants
                                  .where((p) => p.id == plantId)
                                  .firstOrNull;
                              if (plant != null) _openPlant(plant);
                            },
                          ),
                        ),
                      ),
                      // The deck is replaced, not disabled: closing a task before the
                      // data lands would leave the ring and the counters out of step
                      // with it until the request returns (§3.3).
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: _DeckSkeleton(),
                        )
                      else
                        TaskDeck(
                          tasks: today,
                          onOpen: (t) => _openTask(t, plants),
                          onDone: _complete,
                          onLater: _postpone,
                        ),
                      // 14 for the collapsed line; the deck adds the other 4
                      // itself so the gap shrinks with it.
                      const SizedBox(height: 14),
                      _SectionLabel(
                        title: l10n.myPlants,
                        count: loading ? 0 : plants.length,
                      ),
                      if (loading)
                        for (var i = 0; i < 3; i++) ...[
                          const _RowSkeleton(),
                          const SizedBox(height: 9),
                        ]
                      else
                        for (final plant in plants) ...[
                          _PlantRow(
                            plant: plant,
                            score: livePlantScore(
                              plant,
                              live.where((t) => t.plantId == plant.id),
                              now: now,
                            ),
                            onTap: () => _openPlant(plant),
                          ),
                          const SizedBox(height: 9),
                        ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _needsWater(Plant plant, DateTime now) {
    final due = plant.nextDueAt ?? plant.nextWatering;
    return plant.shouldWaterNow || !due.isAfter(now);
  }

  String _gardenCaption(GardenHealth garden, AppLocalizations l10n) {
    if (!garden.hasWeak) return l10n.gardenAllGood;
    if (garden.isSinglePlantToBlame) {
      return l10n.gardenOneWeak(garden.weakPlantNames.first);
    }
    return l10n.gardenManyWeak(garden.weakPlantNames.length);
  }
}

class _Header extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onProfile;

  /// Location and temperature, or nulls while they are unknown.
  final WeatherReading? weather;

  const _Header({
    required this.l10n,
    required this.onProfile,
    this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMMEEEEd(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and weather share one line (SPEC 12, §2). No card, no
                // chip, no sheet — and the row is not tappable, because at this
                // stage there is nothing behind it, and a control that opens
                // nothing annoys more than its absence.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        date.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: glassFont(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 11.5 * 0.09,
                          color: kGlassMut,
                        ),
                      ),
                    ),
                    // Missing weather removes the whole block rather than
                    // leaving a dash behind: an empty slot reads as breakage.
                    if (weather?.location != null && weather?.weather != null)
                      _WeatherBit(reading: weather!),
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: glassFont(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 27 * -0.035,
                      color: kGlassInk,
                    ),
                    children: [
                      TextSpan(text: '${l10n.homeGardenTitleLead} '),
                      TextSpan(
                        text: l10n.homeGardenTitleAccent,
                        style: const TextStyle(color: kGlassAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: l10n.profile,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onProfile();
              },
              child: const GlassSurface(
                blur: 18,
                shape: BoxShape.circle,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: BotanlyGlyph(
                      BotanlySvg.profile,
                      size: 18,
                      color: kGlassInk2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The request failed. A message and a way out — never an endless skeleton and
/// never a fabricated score (§7).
class _ErrorCard extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        children: [
          const BotanlyGlyph(
            BotanlySvg.warningTriangle,
            size: 26,
            color: kGlassAlert,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: glassFont(fontSize: 14, height: 1.4, color: kGlassInk2),
          ),
          const SizedBox(height: 16),
          BotanlyPress(
            scale: 0.98,
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: kGlassAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                retryLabel,
                style: glassFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The deck's silhouette while the data is out: icon tile, two lines, two
/// buttons. Same card, same radii — only the content is withheld.
class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const GlassSkeleton(width: 44, height: 44, radius: 15),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.58,
                      alignment: Alignment.centerLeft,
                      child: const GlassSkeleton(height: 12),
                    ),
                    const SizedBox(height: 7),
                    FractionallySizedBox(
                      widthFactor: 0.38,
                      alignment: Alignment.centerLeft,
                      child: const GlassSkeleton(height: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(flex: 3, child: GlassSkeleton(height: 46, radius: 18)),
              SizedBox(width: 9),
              Expanded(flex: 2, child: GlassSkeleton(height: 46, radius: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One plant row, withheld: thumbnail, name, watering line, score pill.
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const GlassSkeleton(width: 44, height: 44, radius: 14),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.52,
                  alignment: Alignment.centerLeft,
                  child: const GlassSkeleton(height: 11),
                ),
                const SizedBox(height: 7),
                FractionallySizedBox(
                  widthFactor: 0.34,
                  alignment: Alignment.centerLeft,
                  child: const GlassSkeleton(height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const GlassSkeleton(width: 34, height: 22),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;

  /// Print a literal "0" instead of dropping the counter. "Today: 0" is
  /// information; a missing counter reads as "not loaded yet".
  final bool showZero;
  final String? action;
  final VoidCallback? onAction;

  const _SectionLabel({
    required this.title,
    required this.count,
    this.showZero = false,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 9),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: glassFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 11.5 * 0.1,
              color: kGlassMut,
            ),
          ),
          const SizedBox(width: 9),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action!,
                      style: glassFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: kGlassGreenText,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const BotanlyGlyph(
                      BotanlySvg.chevronRight,
                      size: 13,
                      color: kGlassGreenText,
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          if (count > 0 || showZero)
            Text(
              '$count',
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: kGlassMut2,
              ),
            ),
        ],
      ),
    );
  }
}

/// Glass row: 44 px placeholder, name, watering line, score pill (SPEC 2.6).
class _PlantRow extends StatefulWidget {
  final Plant plant;
  final int score;
  final VoidCallback onTap;

  const _PlantRow({
    required this.plant,
    required this.score,
    required this.onTap,
  });

  @override
  State<_PlantRow> createState() => _PlantRowState();
}

class _PlantRowState extends State<_PlantRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warn = plantNeedsAttention(widget.score);
    final water = _wateringLine(widget.plant, l10n);

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Thumb(imageUrl: widget.plant.imageUrl),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: glassFont(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 15.5 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: water.tone.withAlpha(33),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: BotanlyGlyph(
                            BotanlySvg.drop,
                            size: 12,
                            color: water.tone,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            water.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: glassFont(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: water.tone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: warn ? kGlassAttnBg : kGlassLeafBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${widget.score}',
                  style: glassFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: warn ? kGlassAttnText : kGlassGreenText,
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

/// Production watering wording, unchanged: today / tomorrow / in N / overdue N.
({String label, Color tone}) _wateringLine(Plant plant, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = plant.nextDueAt ?? plant.nextWatering;
  final days = DateTime(due.year, due.month, due.day).difference(today).inDays;

  final waterNow =
      plant.shouldWaterNow &&
      plant.wateringMode != 'recheck_only' &&
      (plant.wateringAmountMl == null || plant.wateringAmountMl! > 0);

  if (!waterNow && days < 0) {
    return (label: l10n.wateringOverdueNDays(days.abs()), tone: kGlassAlert);
  }
  if (waterNow) return (label: l10n.nowLabel, tone: kGlassAttnText);
  if (days == 0) return (label: l10n.wateringToday, tone: kGlassAttnText);
  if (days == 1) return (label: l10n.wateringTomorrow, tone: kGlassGreenText);
  return (label: l10n.wateringInNDays(days), tone: kGlassGreenText);
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;

  const _Thumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kGlassLeafBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x99FFFFFF), width: 0.5),
      ),
      child: BotanlyGlyph(
        BotanlySvg.leaf,
        size: 23,
        color: kGlassAccent.withAlpha(128),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// The one line about the subscription the whole app is allowed to show
/// outside the paid doors themselves (SPEC 10, §3).
///
/// It leads with what still works, because the fear a lapsed user actually has
/// is that the garden stopped being looked after. The way back is a pill on the
/// right rather than a full-width button — this is a reminder, not a demand.
class _LockBar extends StatelessWidget {
  final AppLocalizations l10n;

  /// A finished trial and a cancelled subscription need different first lines.
  final bool trial;
  final VoidCallback onTap;

  const _LockBar({
    required this.l10n,
    required this.trial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BotanlyPress(
        scale: 0.99,
        onTap: onTap,
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGlassAttnBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const BotanlyGlyph(
                  BotanlySvg.lock,
                  size: 16,
                  color: kGlassAttnText,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trial
                          ? l10n.gateBarTitleTrial
                          : l10n.gateBarTitleExpired,
                      style: glassFont(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 13.5 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.gateBarBody,
                      style: glassFont(
                        fontSize: 11.5,
                        height: 1.35,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: kGlassAccent.withAlpha(36),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.gateBarAction,
                  style: glassFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: kGlassGreenText,
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

/// The weather half of the header line: dot, icon, temperature, city.
///
/// The icon carries the condition by colour, the temperature is tabular so it
/// does not jitter between 9° and 36°, and the city is the part that gives way
/// when the line runs out of room — the number is what people read.
class _WeatherBit extends StatelessWidget {
  final WeatherReading reading;

  const _WeatherBit({required this.reading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weather = reading.weather!;
    final location = reading.location!;

    final (String glyph, Color tint) = switch (weather.condition) {
      WeatherCondition.sun => (BotanlySvg.sun, kGlassSun),
      WeatherCondition.cloud => (BotanlySvg.cloud, kGlassMut2),
      WeatherCondition.rain => (BotanlySvg.rain, kGlassWater),
      WeatherCondition.cold => (BotanlySvg.snowflake, kGlassWater),
    };

    // Country decides the unit, not the interface language (SPEC 6.1): someone
    // in Germany reading the app in English still sees Celsius.
    final degrees = weather.temperatureIn(
      fahrenheit: location.usesFahrenheit,
    );

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 7),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0x38141E0F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          BotanlyGlyph(glyph, size: 13, color: tint),
          const SizedBox(width: 5),
          Text(
            l10n.weatherDegrees('$degrees'),
            style: glassFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: kGlassInk2,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              location.city.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 11.5 * 0.04,
                color: kGlassMut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
