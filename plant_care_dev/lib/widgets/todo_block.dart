/// "What to do" — this plant's open tasks (SPEC 3.3).
///
/// Replaces the old recommendations banner. Watering is deliberately absent: it
/// is the hero widget directly above, and the spec forbids showing it twice.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/task_visuals.dart';

class TodoBlock extends StatelessWidget {
  /// This plant's open tasks, already sorted. Watering is filtered out here so
  /// callers cannot forget to.
  final List<CareTask> tasks;

  /// Tasks closed in this session, kept so the row can show its struck-through
  /// state for a beat before the stream drops it.
  final Set<String> justCompleted;

  final void Function(CareTask task) onOpen;
  final void Function(CareTask task, bool done) onToggle;

  /// Returns a reason when a task cannot simply be ticked off, or null when it
  /// can. A scheduled health check is the case in point: it is closed by running
  /// the analysis, never by a checkmark, and while the plant is thirsty it
  /// cannot be run at all.
  final String? Function(CareTask task)? lockedReason;

  const TodoBlock({
    super.key,
    required this.tasks,
    required this.onOpen,
    required this.onToggle,
    this.justCompleted = const {},
    this.lockedReason,
  });

  /// Drops the scheduled watering chore only.
  ///
  /// SPEC 3.3 keeps watering out because the hero widget above already owns it —
  /// but that is about the chore, not about the subject. An analysis saying
  /// "let the soil dry out more" is advice, and hiding it left the plant with a
  /// recommendation the user could see on the home deck and nowhere here.
  static List<CareTask> visibleTasks(List<CareTask> tasks, DateTime now) =>
      sortTasks(
        tasks
            .where(
              (t) =>
                  !(t.source == TaskSource.schedule &&
                      t.category == TaskCategory.water),
            )
            .where((t) => t.isActiveAt(now) || t.done)
            .toList(),
        now,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // No tasks at all → no block. "All done" is only for a list that had rows.
    if (tasks.isEmpty) return const SizedBox.shrink();

    final open = tasks.where((t) => !_isDone(t)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kGlassAttnBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const BotanlyGlyph(
                    BotanlySvg.sparkle,
                    size: 17,
                    color: kGlassSun,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.healthWhatToDo,
                    style: glassFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.02,
                      color: kGlassInk,
                    ),
                  ),
                ),
                if (open.isNotEmpty)
                  Text(
                    '${open.length}',
                    style: glassFont(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: kGlassMut2,
                    ),
                  ),
              ],
            ),
          ),
          if (open.isEmpty)
            _AllDone(label: l10n.taskAllDone)
          else
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _TaskRow(
                task: tasks[i],
                now: now,
                done: _isDone(tasks[i]),
                locked: _isLocked(tasks[i]),
                lockedNote: lockedReason?.call(tasks[i]),
                onOpen: () => onOpen(tasks[i]),
                onToggle: (v) => onToggle(tasks[i], v),
              ),
            ],
        ],
      ),
    );
  }

  bool _isDone(CareTask t) => t.done || justCompleted.contains(t.id);

  /// A scheduled scan has no checkbox at all: ticking it would mark the plant
  /// checked without a check ever running, and the scheduler would hand the task
  /// straight back.
  static bool _isLocked(CareTask t) => isScheduledScan(t);
}

class _AllDone extends StatelessWidget {
  final String label;

  const _AllDone({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: kGlassAccent.withAlpha(31), // rgba(62,142,59,.12)
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGlassAccent.withAlpha(51), width: 0.5),
      ),
      child: Row(
        children: [
          const BotanlyGlyph(
            BotanlySvg.check,
            size: 16,
            color: kGlassGreenText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: glassFont(
                fontSize: 13.5,
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

/// Row: 34 px glyph, title 14.5/600, detail up to two lines, one badge, and a
/// 28 px tick with a 44 px hit area.
class _TaskRow extends StatelessWidget {
  final CareTask task;
  final DateTime now;
  final bool done;
  final bool locked;
  final String? lockedNote;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  const _TaskRow({
    required this.task,
    required this.now,
    required this.done,
    required this.onOpen,
    required this.onToggle,
    this.locked = false,
    this.lockedNote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = taskBadge(task, now, l10n);
    final detail = task.detail.isNotEmpty
        ? task.detail
        : task.body.split('|').first.trim();

    return AnimatedOpacity(
      opacity: done ? 0.45 : 1,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xD1FFFFFF), // rgba(255,255,255,.82)
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
          ),
          child: Row(
            children: [
              TaskGlyphTile(task.category),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style:
                          glassFont(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 14.5 * -0.015,
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
                        // Wraps to two lines rather than truncating at one: the
                        // handoff clamps at 2, and a one-line detail loses the
                        // half of the sentence that says why.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: glassFont(
                          fontSize: 12.5,
                          height: 1.35,
                          color: kGlassMut,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(child: TaskBadgePill(badge)),
                        if (lockedNote != null && lockedNote!.isNotEmpty) ...[
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              lockedNote!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: glassFont(
                                fontSize: 11.5,
                                color: kGlassAttnText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              if (locked)
                const BotanlyGlyph(
                  BotanlySvg.chevronRight,
                  size: 15,
                  color: kGlassChevron,
                )
              else
                _Tick(done: done, onTap: () => onToggle(!done)),
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
        // Visual stays 28 px; the tap target is padded out to 44.
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
