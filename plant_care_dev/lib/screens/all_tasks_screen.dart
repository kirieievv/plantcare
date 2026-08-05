/// Every task, grouped into today and later (SPEC 2.5).
///
/// Not a tab: a full-screen layer inside Home that slides in from the right. The
/// five-tab bar is fixed by product, and the deck and this screen are two views
/// of one list — ticking here moves the deck and the other way round.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/services/plant_service.dart';
import 'package:plant_care/services/task_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/task_sheet.dart';
import 'package:plant_care/widgets/task_visuals.dart';

/// Slides in from the right over 420 ms, matching the handoff's `slideIn`.
Route<void> allTasksRoute({
  required Future<void> Function(CareTask task, String question) onAsk,
  required void Function(String plantId) onOpenPlant,
}) {
  return PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    // Material, because this page goes straight into the navigator over a
    // transparent route: without one, text inherits WidgetsApp's debug style and
    // every line renders with yellow underlines.
    pageBuilder: (_, __, ___) => Material(
      type: MaterialType.transparency,
      child: AllTasksScreen(onAsk: onAsk, onOpenPlant: onOpenPlant),
    ),
    transitionsBuilder: (_, animation, __, child) {
      final t = const Cubic(0.22, 1, 0.36, 1).transform(animation.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(34 * (1 - t), 0),
          child: child,
        ),
      );
    },
  );
}

class AllTasksScreen extends StatefulWidget {
  /// Asked in the plant's chat. The screen has no plant of its own, so the host
  /// resolves which chat to open. Awaited, because the user has to land back on
  /// the task sheet when the chat closes (SPEC 1.4).
  final Future<void> Function(CareTask task, String question) onAsk;

  /// Opens a plant by id — the health check can only be run from its screen.
  final void Function(String plantId) onOpenPlant;

  const AllTasksScreen({
    super.key,
    required this.onAsk,
    required this.onOpenPlant,
  });

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final _service = TaskService();

  /// Held in a field, not built in `build`: a fresh stream on every rebuild
  /// would resubscribe to Firestore on each frame.
  final Stream<List<Plant>> _plants = PlantService().getPlants();

  /// Ticked here but not yet gone from the stream — same trick as the plant
  /// screen: the row has to cross itself out before it leaves.
  Map<String, CareTask> _justCompleted = const {};

  Future<void> _complete(CareTask task) async {
    setState(() => _justCompleted = {..._justCompleted, task.id: task});
    try {
      // Same rule as the deck: closing a watering task waters the plant, and
      // feeding leaves its mark so the scheduler knows it happened.
      if (task.category == TaskCategory.water) {
        await PlantService().waterPlant(task.plantId);
      } else if (task.category == TaskCategory.fertilizer) {
        await PlantService().markFertilised(task.plantId);
      }
      await _service.complete(task.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _justCompleted = {..._justCompleted}..remove(task.id));
    }
  }

  Future<void> _reopen(CareTask task) async {
    setState(() => _justCompleted = {..._justCompleted}..remove(task.id));
    try {
      await _service.reopen(task.id);
    } catch (_) {
      // The stream restores whatever the server actually holds.
    }
  }

  Future<void> _open(CareTask task) async {
    // The health check belongs to the plant screen — see the deck for why.
    if (isScheduledScan(task)) {
      widget.onOpenPlant(task.plantId);
      return;
    }

    final choice = await showTaskSheet(context: context, task: task);
    if (!mounted || choice == null) return;
    switch (choice) {
      case TaskSheetResult.done:
        await _complete(task);
      case TaskSheetResult.later:
        try {
          await _service.postpone(task.id);
        } catch (_) {
          // Ordering only.
        }
      case TaskSheetResult.ask:
        final l10n = AppLocalizations.of(context)!;
        await widget.onAsk(task, l10n.taskAskQuestion(task.title));
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        await _open(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 17, sigmaY: 17), // blur(34px)
      child: Container(
        color: const Color(0xDBEDF0EC), // rgba(237,240,236,.86)
        child: StreamBuilder<List<Plant>>(
          stream: _plants,
          builder: (context, plantSnap) {
            // Same rule as the deck (home_screen §build): a task whose plant is
            // gone is not shown. Without it this screen counted tasks the deck
            // did not, and the two disagreed on the very same data. While the
            // plants are still loading nothing is filtered — an empty id set
            // would blank the list for a frame.
            final plantIds = plantSnap.data?.map((p) => p.id).toSet();
            return StreamBuilder<List<CareTask>>(
              stream: _service.watchOpenTasks(),
              builder: (context, snap) {
                final raw = snap.data ?? const <CareTask>[];
                final open = plantIds == null
                    ? raw
                    : raw.where((t) => plantIds.contains(t.plantId)).toList();
                final openIds = open.map((t) => t.id).toSet();
                final all = [
                  ...open,
                  ..._justCompleted.values.where(
                    (t) => !openIds.contains(t.id),
                  ),
                ];

                final today = sortTasks(
                  all.where((t) => t.isActiveAt(now)).toList(),
                  now,
                );
                final later = all.where((t) => !t.isActiveAt(now)).toList()
                  ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
                final done = today.where(_isDone).length;

                return Column(
                  children: [
                    _nav(
                      context,
                      l10n,
                      subtitle: l10n.allTasksSubtitle(
                        today.length,
                        later.length,
                      ),
                      done: done,
                      total: today.length,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _groupLabel(l10n.allTasksToday, today.length - done),
                          if (today.isEmpty)
                            _AllClear(label: l10n.allTasksNothingToday)
                          else
                            for (final task in today) ...[
                              _TaskItem(
                                task: task,
                                now: now,
                                done: _isDone(task),
                                onTap: () => _open(task),
                                // No tick for a scheduled health check: it is
                                // closed by running the analysis (see task.dart).
                                onToggle: isScheduledScan(task)
                                    ? null
                                    : (v) =>
                                          v ? _complete(task) : _reopen(task),
                              ),
                              const SizedBox(height: 9),
                            ],
                          if (later.isNotEmpty) ...[
                            _groupLabel(l10n.allTasksLater, later.length),
                            // The rule only matters while today still has work; once
                            // it is clear, the note is just noise (SPEC 2.5).
                            if (today.length - done > 0)
                              _RuleNote(text: l10n.allTasksRuleNote),
                            for (final task in later) ...[
                              _TaskItem(
                                task: task,
                                now: now,
                                done: false,
                                when: _whenLabel(
                                  task.dueAt,
                                  now,
                                  l10n,
                                  Localizations.localeOf(
                                    context,
                                  ).toLanguageTag(),
                                ),
                                onTap: () => _open(task),
                              ),
                              const SizedBox(height: 9),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _isDone(CareTask t) => t.done || _justCompleted.containsKey(t.id);

  Widget _groupLabel(String text, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 11.5 * 0.1,
                color: kGlassMut,
              ),
            ),
          ),
          if (count > 0)
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

  Widget _nav(
    BuildContext context,
    AppLocalizations l10n, {
    required String subtitle,
    required int done,
    required int total,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 56, 18, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const GlassSurface(
              blur: 18,
              shape: BoxShape.circle,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: BotanlyGlyph(
                    BotanlySvg.chevronLeft,
                    size: 17,
                    color: kGlassInk2,
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
                  l10n.allTasksTitle,
                  style: glassFont(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 21 * -0.03,
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
          const SizedBox(width: 12),
          _ProgressRing(done: done, total: total),
        ],
      ),
    );
  }
}

String _whenLabel(
  DateTime due,
  DateTime now,
  AppLocalizations l10n,
  String localeTag,
) {
  final days = DateTime(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days <= 1) return l10n.whenTomorrow;
  // Inside the week the weekday is more useful than a count; past it, a count
  // is more useful than a weekday seven days out. The locale tag is required —
  // without it `intl` prints the weekday in English whatever the app language.
  if (days < 7) return DateFormat.EEEE(localeTag).format(due);
  if (days == 7) return l10n.whenInAWeek;
  return l10n.whenInNDays(days);
}

class _ProgressRing extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressRing({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 800),
            curve: const Cubic(0.3, 0.7, 0.3, 1),
            builder: (_, value, __) => CustomPaint(
              size: const Size.square(44),
              painter: _ProgressPainter(value),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xEBFFFFFF),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$done/$total',
            style: glassFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: kGlassInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;

  const _ProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0x1A141E0F));
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      true,
      Paint()..color = kGlassAccent,
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.progress != progress;
}

class _TaskItem extends StatelessWidget {
  final CareTask task;
  final DateTime now;
  final bool done;
  final String? when;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggle;

  const _TaskItem({
    required this.task,
    required this.now,
    required this.done,
    required this.onTap,
    this.when,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = taskBadge(task, now, l10n);
    final detail = task.detail.isNotEmpty
        ? task.detail
        : task.body.split('|').first.trim();

    return AnimatedOpacity(
      opacity: done ? 0.5 : 1,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              TaskGlyphTile(task.category, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          glassFont(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 15.5 * -0.015,
                            color: kGlassInk,
                          ).copyWith(
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0x59141E0F),
                          ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: glassFont(
                          fontSize: 12.5,
                          height: 1.3,
                          color: kGlassMut,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(child: TaskBadgePill(badge)),
                        // One pill per task (SPEC 1.3.1): an overdue task shows
                        // its overdue pill and nothing else. "Postponed" is a
                        // second marker, so it only appears when the pill next
                        // to it is the calm "scheduled"/"after analysis" one.
                        if (task.postponedAt != null &&
                            !task.isOverdueAt(now)) ...[
                          const SizedBox(width: 7),
                          Text(
                            l10n.taskPostponed.toUpperCase(),
                            style: glassFont(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 11 * 0.03,
                              color: kGlassMut2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (when != null)
                Text(
                  when!,
                  style: glassFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kGlassMut2,
                  ),
                )
              else if (onToggle != null)
                _Tick(done: done, onTap: () => onToggle!(!done)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;

  const _Tick({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? kGlassAccent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? kGlassAccent : const Color(0x33141E0F),
                  width: 1.5,
                ),
              ),
              child: BotanlyGlyph(
                BotanlySvg.check,
                size: 14,
                color: done ? Colors.white : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleNote extends StatelessWidget {
  final String text;

  const _RuleNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x8CFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xCCFFFFFF), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: BotanlyGlyph(
              BotanlySvg.infoCircle,
              size: 15,
              color: kGlassMut2,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: glassFont(fontSize: 12.5, height: 1.45, color: kGlassMut),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  final String label;

  const _AllClear({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kGlassAccent.withAlpha(26),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kGlassAccent.withAlpha(51), width: 0.5),
      ),
      child: Row(
        children: [
          const BotanlyGlyph(
            BotanlySvg.check,
            size: 17,
            color: kGlassGreenText,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: glassFont(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kGlassGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
