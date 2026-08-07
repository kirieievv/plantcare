/// The task sheet — one construction for every screen that opens a task.
///
/// SPEC 2.4 and 3.3 describe the same sheet: parameter tiles, the explanation,
/// an "ask assistant" row, and "Done" / "Later" pinned at the bottom. The plant
/// screen and the home deck both open this, so the two can never drift.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';
import 'package:plant_care/widgets/botanly_sheet.dart';
import 'package:plant_care/widgets/task_visuals.dart';

/// Opens [task] and resolves to what the user chose, or null if they dismissed
/// the sheet without deciding.
enum TaskSheetResult { done, later, ask }

Future<TaskSheetResult?> showTaskSheet({
  required BuildContext context,
  required CareTask task,
  DateTime? now,
}) {
  return showBotanlySheet<TaskSheetResult>(
    context: context,
    builder: (_) => TaskSheet(task: task, now: now ?? DateTime.now()),
  );
}

class TaskSheet extends StatelessWidget {
  final CareTask task;
  final DateTime now;

  const TaskSheet({super.key, required this.task, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = taskStyle(task.category);
    final badge = taskBadge(task, now, l10n);

    // Paragraphs are separated by "|" the way the handoff encodes them; a body
    // written as plain prose still renders as one paragraph.
    final paragraphs = task.body.isEmpty
        ? (task.detail.isEmpty ? const <String>[] : [task.detail])
        : task.body
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return BotanlySheet(
      header: BotanlySheetHeader(
        glyph: style.glyph,
        tint: style.bg,
        foreground: style.fg,
        title: task.title,
        badgeText: badge.text,
        badgeBg: badge.bg,
        badgeFg: badge.fg,
      ),
      // A scheduled scan never reaches this sheet from the app's own screens —
      // they route it to the plant instead — but the guard belongs here too.
      footer: isScheduledScan(task)
          ? BotanlyButton(
              label: l10n.taskLater,
              kind: BotanlyButtonKind.ghost,
              onTap: () => Navigator.of(context).pop(TaskSheetResult.later),
            )
          : _Footer(
        doneLabel: task.done ? l10n.taskDoneAlready : l10n.taskDone,
        laterLabel: l10n.taskLater,
        onDone: () => Navigator.of(context).pop(TaskSheetResult.done),
        onLater: () => Navigator.of(context).pop(TaskSheetResult.later),
      ),
      children: [
        if (task.kv.isNotEmpty)
          BotanlySheetKeyValues([
            for (final pair in task.kv) (pair[0], pair[1]),
          ]),
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i == paragraphs.length - 1 ? 0 : 12),
            child: Text(
              paragraphs[i],
              style: glassFont(fontSize: 15, height: 1.6, color: kGlassInk2),
            ),
          ),
        BotanlyAskRow(
          label: l10n.taskAskAssistant,
          onTap: () => Navigator.of(context).pop(TaskSheetResult.ask),
        ),
      ],
    );
  }
}

/// "Done" carries the sheet at 1.6 flex against "Later" at 1 — pressing Later is
/// meant to be easy, not equal (SPEC 1.3.4: it parks the task, never drops it).
class _Footer extends StatelessWidget {
  final String doneLabel;
  final String laterLabel;
  final VoidCallback onDone;
  final VoidCallback onLater;

  const _Footer({
    required this.doneLabel,
    required this.laterLabel,
    required this.onDone,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 16,
          child: _Button(
            label: doneLabel,
            glyph: BotanlySvg.check,
            background: kGlassAccent,
            foreground: Colors.white,
            onTap: onDone,
            elevated: true,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          flex: 10,
          child: _Button(
            label: laterLabel,
            background: const Color(0x0F141E0F), // rgba(20,30,15,.06)
            foreground: kGlassInk2,
            onTap: onLater,
          ),
        ),
      ],
    );
  }
}

class _Button extends StatefulWidget {
  final String label;
  final String? glyph;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool elevated;

  const _Button({
    required this.label,
    this.glyph,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.elevated = false,
  });

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.elevated
                ? [
                    BoxShadow(
                      color: kGlassAccent.withAlpha(90),
                      blurRadius: 22,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.glyph != null) ...[
                BotanlyGlyph(widget.glyph!, size: 16, color: widget.foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 15.5,
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
