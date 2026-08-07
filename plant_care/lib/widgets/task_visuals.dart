/// Shared look of a care task.
///
/// The plant screen's "what to do" block, the home deck and the all-tasks screen
/// draw the same objects, so the icon and the badge are decided once here. Three
/// copies of this switch is how a task ends up amber in one place and green in
/// another.
library;

import 'package:flutter/material.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/theme/botanly_glass.dart';

typedef TaskStyle = ({String glyph, Color fg, Color bg});
typedef TaskBadge = ({String text, Color fg, Color bg});

TaskStyle taskStyle(TaskCategory category) => switch (category) {
      TaskCategory.water => (
          glyph: BotanlySvg.drop,
          fg: kGlassWater,
          bg: kGlassWaterBg
        ),
      TaskCategory.light => (
          glyph: BotanlySvg.sun,
          fg: kGlassSun,
          bg: kGlassSunBg
        ),
      TaskCategory.soil => (
          glyph: BotanlySvg.soil,
          fg: kGlassAccent,
          bg: kGlassLeafBg
        ),
      TaskCategory.fertilizer => (
          glyph: BotanlySvg.fertilizer,
          fg: kGlassAccent,
          bg: kGlassLeafBg
        ),
      TaskCategory.scan => (
          glyph: BotanlySvg.scan,
          fg: kGlassWater,
          bg: kGlassWaterBg
        ),
      TaskCategory.other => (
          glyph: BotanlySvg.leaf,
          fg: kGlassAccent,
          bg: kGlassLeafBg
        ),
    };

/// The single badge a task row is allowed to show (SPEC 1.3.1).
///
/// Overdue wins over the source: a late task has one thing to say, and where it
/// came from is still readable inside the sheet. Two badges at once is a bug.
TaskBadge taskBadge(CareTask task, DateTime now, AppLocalizations l10n) {
  final age = task.ageDaysAt(now);
  if (age > 0) {
    return (
      text: l10n.taskBadgeOverdue(age),
      fg: kGlassAlert,
      bg: kGlassWarmBg,
    );
  }
  if (task.source == TaskSource.analysis) {
    return (
      text: l10n.taskBadgeAnalysis,
      fg: kGlassBlueText,
      bg: kGlassWaterBg,
    );
  }
  return (
    text: l10n.taskBadgeScheduled,
    fg: kGlassGreenText,
    bg: kGlassLeafBg,
  );
}

/// Uppercase pill used for the badge in rows, sheets and cards.
class TaskBadgePill extends StatelessWidget {
  final TaskBadge badge;

  const TaskBadgePill(this.badge, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badge.text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: glassFont(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 11 * 0.03,
          color: badge.fg,
        ),
      ),
    );
  }
}

/// Rounded square holding a task's glyph. 34 px everywhere it appears.
class TaskGlyphTile extends StatelessWidget {
  final TaskCategory category;
  final double size;

  const TaskGlyphTile(this.category, {super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final style = taskStyle(category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(size * 12 / 34),
        border: Border.all(color: const Color(0x99FFFFFF), width: 0.5),
      ),
      child: BotanlyGlyph(style.glyph, size: size * 17 / 34, color: style.fg),
    );
  }
}
