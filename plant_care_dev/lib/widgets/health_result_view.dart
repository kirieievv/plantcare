import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/models/plant.dart';
import 'package:plant_care/theme/botanly_glass.dart';

/// The result of one health check: score ring, verdict, findings and the
/// "what to do" checklist.
///
/// The same view backs a freshly finished analysis and a record reopened from
/// the History timeline, so everything it draws comes from the [record] passed
/// in — never from the plant's current state. Reading a past check must not make
/// it look like today's verdict.
class HealthResultView extends StatelessWidget {
  final HealthCheckRecord record;

  /// Dismisses the result. There is no "save" any more — SPEC 3.4 has the check
  /// persisted the moment it is ready, so the only thing left to do is leave.
  final VoidCallback? onClose;
  final VoidCallback? onAsk;

  const HealthResultView({
    super.key,
    required this.record,
    this.onClose,
    this.onAsk,
  });

  bool get _isIssue => record.status == 'issue';

  Color get _accent => _isIssue ? kGlassAlert : kGlassAccent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verdict = _verdictOf(record, l10n);
    final recs = record.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _scoreRow(verdict),
        if (record.findings.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final f in record.findings) ...[
            _findingCard(f),
            const SizedBox(height: 8),
          ],
        ],
        if (recs.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionHeader(l10n, recs.length),
          const SizedBox(height: 10),
          for (final rec in recs) ...[
            _recommendationCard(rec),
            const SizedBox(height: 9),
          ],
        ],
        const SizedBox(height: 10),
        _actions(l10n),
      ],
    );
  }

  // ── score + verdict ───────────────────────────────────────────────────────

  Widget _scoreRow(({String title, String sub}) verdict) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (record.score != null) ...[
          _ScoreRing(score: record.score!, color: _accent),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verdict.title,
                style: glassFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 18 * -0.02,
                  color: kGlassInk,
                ),
              ),
              if (verdict.sub.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  verdict.sub,
                  style: glassFont(fontSize: 13, height: 1.4, color: kGlassMut),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── findings ──────────────────────────────────────────────────────────────

  Widget _findingCard(HealthFinding f) {
    final style = glassFindingStyle(f.category);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Opaque white, not a translucent tint: the sheet behind is already a
        // light neutral, so a .7 white card was invisible against it.
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: BotanlyGlyph(style.glyph, size: 15, color: style.fg),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.title,
                  style: glassFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kGlassInk,
                  ),
                ),
                if (f.text.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    f.text,
                    style: glassFont(
                      fontSize: 12.5,
                      height: 1.45,
                      color: kGlassMut,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── what to do ────────────────────────────────────────────────────────────

  Widget _sectionHeader(AppLocalizations l10n, int count) {
    // Both halves are flexible: "what to do" and the badge are one long line in
    // German, and a fixed layout put the badge off the edge of the sheet.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n.healthWhatToDo.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12 * 0.07,
                    color: kGlassMut,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kGlassSunBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: glassFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kGlassAttnText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // SPEC 3.4: the result's list and the plan hold the same objects, so the
        // badge is a statement of fact, not a button — nothing is left to add.
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: kGlassAccent.withAlpha(36), // rgba(62,142,59,.14)
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.healthAddedToPlan.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: glassFont(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 11 * 0.03,
                color: kGlassGreenText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Read-only by design: ticking a recommendation off happens in "what to do"
  /// on the plant screen, where the task itself lives. A second checkbox here
  /// would be a second source of truth for the same object.
  Widget _recommendationCard(HealthRecommendation rec) {
    // Priority 3 is "nice to have" — the handoff mutes it so the eye lands on 1.
    final muted = rec.priority >= 3;

    return Opacity(
      opacity: muted ? 0.72 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Filled, not tinted: the number is the ranking, and a solid chip
                // is what separates step 1 from the rest at a glance.
                color: muted ? kGlassLeafBg : kGlassAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${rec.priority}',
                style: glassFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muted ? kGlassGreenText : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: glassFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kGlassInk,
                    ),
                  ),
                  if (rec.explanation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      rec.explanation,
                      style: glassFont(
                        fontSize: 12.5,
                        height: 1.45,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Widget _actions(AppLocalizations l10n) {
    final buttons = <Widget>[
      if (onClose != null)
        Expanded(
          child: _actionButton(
            label: l10n.healthClose,
            onTap: onClose!,
            primary: true,
          ),
        ),
      if (onAsk != null)
        Expanded(
          child: _actionButton(
            label: l10n.healthAskAssistant,
            onTap: onAsk!,
            // Ghost beside "close"; on its own it has to carry the row.
            primary: onClose == null,
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          buttons[i],
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? kGlassAccent : const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: kGlassBorder, width: 0.5),
          // The handoff's green glow is tuned for glass over a photo, where it
          // dissolves. On the sheet's flat neutral it reads as a green smudge
          // behind the button, so it is dialled down to a plain lift.
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: kGlassAccent.withAlpha(56),
                    blurRadius: 14,
                    spreadRadius: -10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: glassFont(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: primary ? Colors.white : kGlassInk,
          ),
        ),
      ),
    );
  }
}

/// Title and one-line summary for a check.
///
/// The analyzer writes these into `plant_assistant`, which the modal stores as a
/// JSON string in [HealthCheckRecord.message]. Older records hold plain prose
/// instead, so the raw message is the fallback and the title comes from status.
({String title, String sub}) _verdictOf(
  HealthCheckRecord record,
  AppLocalizations l10n,
) {
  final isIssue = record.status == 'issue';
  final fallbackTitle = isIssue
      ? l10n.healthNeedsAttention
      : l10n.healthStatusHealthy;

  final raw = record.message.trim();
  if (!raw.startsWith('{')) {
    return (title: fallbackTitle, sub: raw);
  }

  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    String pick(String key) => m[key]?.toString().trim() ?? '';

    final title = isIssue ? pick('problem_name') : pick('praise_phrase');
    final sub = isIssue
        ? pick('problem_description')
        : [
            pick('health_summary'),
            pick('maintenance_footer'),
          ].where((s) => s.isNotEmpty).join(' ');

    return (title: title.isNotEmpty ? title : fallbackTitle, sub: sub);
  } catch (_) {
    // Not an assistant payload — show the message as written.
    return (title: fallbackTitle, sub: raw);
  }
}

/// 76 px progress ring with the score in the middle.
class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _RingPainter(progress: score / 100, color: color),
        child: Center(
          child: Text(
            '$score',
            style: glassFont(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 24 * -0.02,
              color: kGlassInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x1A141E0F); // rgba(20,30,15,.10)
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [color.withAlpha(140), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
