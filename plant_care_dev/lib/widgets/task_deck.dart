/// The task deck — one action, now (SPEC 2.3).
///
/// The top card is live, the next two are visible as backings, the rest are not
/// drawn. Buttons are the primary way through the deck; the swipes duplicate
/// them for people who already know the gesture.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/task_visuals.dart';

class TaskDeck extends StatefulWidget {
  /// Sorted, watering included — on the home screen watering is a task like any
  /// other; the "no duplicates" rule only applies to the plant screen.
  final List<CareTask> tasks;

  final void Function(CareTask task) onOpen;
  final void Function(CareTask task) onDone;
  final void Function(CareTask task) onLater;

  /// "Today" for the overdue counter. Defaults to the wall clock; tests pass a
  /// fixed value, because a card that reads the clock itself renders a
  /// different age every real day and no golden can survive midnight.
  final DateTime? now;

  const TaskDeck({
    super.key,
    required this.tasks,
    required this.onOpen,
    required this.onDone,
    required this.onLater,
    this.now,
  });

  @override
  State<TaskDeck> createState() => _TaskDeckState();
}

class _TaskDeckState extends State<TaskDeck>
    with SingleTickerProviderStateMixin {
  static const _height = 150.0;

  /// The collapsed block. A line, not a card — see [_EmptyDeck].
  static const _emptyHeight = 50.0;

  /// The deck is a pile of overlapping cards, so it needs a number rather than
  /// an intrinsic height — and a `Stack` clips what sticks out, which is how a
  /// number blind to the system text size ends up cutting the buttons off the
  /// bottom of the card. These two follow the (already capped) scaler.
  double _box(double base) => MediaQuery.textScalerOf(context).scale(base);
  static const _collapse = Duration(milliseconds: 300);
  static const _collapseCurve = Cubic(0.22, 1, 0.36, 1);
  static const _swipeThreshold = 96.0;

  // Built in initState, not lazily: a deck disposed before it ever animated
  // would otherwise create its ticker inside dispose(), where the element tree
  // is already gone.
  late final AnimationController _fly;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  double _drag = 0;
  bool _flashing = false;

  /// Resolved once per build from the widget, so every card in one frame ages
  /// against the same instant.
  DateTime get _now => widget.now ?? DateTime.now();

  /// Which way the departing card leaves: right for done, left for later.
  double _flyDirection = 1;

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  Future<void> _resolve(CareTask task, {required bool done}) async {
    if (_fly.isAnimating) return;
    setState(() {
      _flashing = done;
      _flyDirection = done ? 1 : -1;
    });
    HapticFeedback.lightImpact();
    await _fly.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _drag = 0;
      _flashing = false;
    });
    _fly.value = 0;
    done ? widget.onDone(task) : widget.onLater(task);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Deck and empty line are one container that resizes, not two blocks that
    // swap: the last card flies out and the block then shrinks after it, which
    // is what stops the whole screen from jumping up by 100 px in one frame.
    if (widget.tasks.isEmpty) {
      return AnimatedContainer(
        duration: _collapse,
        curve: _collapseCurve,
        height: _box(_emptyHeight),
        child: _EmptyDeck(title: l10n.deckAllClearTitle),
      );
    }

    // Three at most: the deck says "one action now", and a fourth backing only
    // adds visual noise behind a card nobody is looking at yet.
    final shown = widget.tasks.take(3).toList();

    return AnimatedContainer(
      duration: _collapse,
      curve: _collapseCurve,
      height: _box(_height),
      // The reference gives the deck 18 px of air and the collapsed line 14.
      // The screen supplies 14 to both, so only the difference lives here.
      margin: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          for (var i = shown.length - 1; i >= 1; i--)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Transform.translate(
                offset: Offset(0, 10.0 * i),
                child: Transform.scale(
                  scale: 1 - 0.04 * i,
                  child: _Card(task: shown[i], live: false, now: _now),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _fly,
              builder: (_, child) {
                final t = _fly.value;
                final offset = _drag + _flyDirection * 460 * t;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    setState(() => _drag += d.delta.dx),
                onHorizontalDragEnd: (_) {
                  // A scheduled health check cannot be swiped away as done — it
                  // is closed by running the analysis, nothing else.
                  if (_drag > _swipeThreshold &&
                      !isScheduledScan(shown.first)) {
                    _resolve(shown.first, done: true);
                  } else if (_drag < -_swipeThreshold) {
                    _resolve(shown.first, done: false);
                  } else {
                    setState(() => _drag = 0);
                  }
                },
                child: _Card(
                  // Named so tests (and a11y traversal) can tell the live card
                  // from the invisible backings behind it.
                  key: const ValueKey('deck-live-card'),
                  task: shown.first,
                  live: true,
                  now: _now,
                  flashing: _flashing,
                  onTap: () => widget.onOpen(shown.first),
                  onDone: () => _resolve(shown.first, done: true),
                  onLater: () => _resolve(shown.first, done: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final CareTask task;
  final bool live;
  final bool flashing;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onDone;
  final VoidCallback? onLater;

  const _Card({
    super.key,
    required this.task,
    required this.live,
    required this.now,
    this.flashing = false,
    this.onTap,
    this.onDone,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final age = task.ageDaysAt(now);
    final detail = task.detail.isNotEmpty
        ? task.detail
        : task.body.split('|').first.trim();

    return GlassSurface(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          if (flashing)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kGlassAccent.withAlpha(61), // rgba(62,142,59,.24)
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          // The backing cards keep the full content at zero opacity: they are
          // the same card, and dropping their content would shrink them into
          // thin strips instead of the stacked deck the handoff draws.
          Opacity(
            opacity: live ? 1 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  ignoring: !live,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
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
                                // Two lines for the same reason the subline has
                                // them: at a raised text size one line turned
                                // "Пересканировать растение" into
                                // "Пересканировать раст…", and the verb is the
                                // whole instruction.
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: glassFont(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 15.5 * -0.015,
                                  color: kGlassInk,
                                ),
                              ),
                              if (detail.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  detail,
                                  // Two lines, not an ellipsis: the subline is the
                                  // dose and the reason, and half of either is
                                  // worse than a taller card (SPEC 2.3).
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: glassFont(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    color: kGlassMut,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (age > 0) ...[
                          const SizedBox(width: 10),
                          _OverdueMark(label: l10n.taskOverdueShort(age)),
                        ] else ...[
                          const SizedBox(width: 10),
                          const BotanlyGlyph(
                            BotanlySvg.chevronRight,
                            size: 15,
                            color: kGlassChevron,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: !live,
                  child: Row(
                    children: [
                      // The health check has no "done": tapping the card opens
                      // the plant, and the analysis closes the task itself.
                      if (!isScheduledScan(task))
                        Expanded(
                          flex: 16,
                          child: _DeckButton(
                            label: l10n.taskDone,
                            glyph: BotanlySvg.check,
                            background: kGlassAccent,
                            foreground: Colors.white,
                            elevated: true,
                            onTap: onDone,
                          ),
                        ),
                      if (!isScheduledScan(task)) const SizedBox(width: 8),
                      Expanded(
                        flex: 10,
                        child: _DeckButton(
                          label: l10n.taskLater,
                          background: const Color(0xB3FFFFFF),
                          foreground: kGlassMut,
                          bordered: true,
                          onTap: onLater,
                        ),
                      ),
                    ],
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

class _OverdueMark extends StatelessWidget {
  final String label;

  const _OverdueMark({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: kGlassWarm,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: glassFont(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: kGlassAlert,
          ),
        ),
      ],
    );
  }
}

class _DeckButton extends StatefulWidget {
  final String label;
  final String? glyph;
  final Color background;
  final Color foreground;
  final bool elevated;
  final bool bordered;
  final VoidCallback? onTap;

  const _DeckButton({
    required this.label,
    this.glyph,
    required this.background,
    required this.foreground,
    this.elevated = false,
    this.bordered = false,
    this.onTap,
  });

  @override
  State<_DeckButton> createState() => _DeckButtonState();
}

class _DeckButtonState extends State<_DeckButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(16),
            border: widget.bordered
                ? Border.all(color: const Color(0x1F141E0F), width: 0.5)
                : null,
            boxShadow: widget.elevated
                ? [
                    BoxShadow(
                      color: kGlassAccent.withAlpha(90),
                      blurRadius: 18,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.glyph != null) ...[
                BotanlyGlyph(widget.glyph!, size: 15, color: widget.foreground),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.foreground,
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

/// Never an empty box: an ordinary day with nothing due still says so, and says
/// what is coming next (SPEC 2.3).
/// Nothing left for today — a line, not a card (tasks_empty_state_flow §2.1).
///
/// It used to be a 150 px card with a caption promising the next task "tomorrow
/// morning". That promise was false: watering follows the plant's own cycle and
/// advice only arrives after an analysis, so no date could be named. Without it
/// the caption was noise, and without the caption the card was mostly padding.
class _EmptyDeck extends StatelessWidget {
  final String title;

  const _EmptyDeck({required this.title});

  @override
  Widget build(BuildContext context) {
    // Top-aligned rather than stretched: the row is content-tall inside the
    // 50 px block, which is what keeps the green pill the same height here as
    // in the reference.
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: kGlassAccent.withAlpha(26), // rgba(62,142,59,.10)
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kGlassAccent.withAlpha(51), width: 0.5),
        ),
        child: Row(
          children: [
            const BotanlyGlyph(BotanlySvg.check, size: 17, color: kGlassAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: glassFont(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: kGlassGreenText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
