import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:plant_care/theme/botanly_theme.dart';

/// Animated plant sprout loader matching the Botanly brand.
///
/// Shows a growing stem, blooming leaves, halo pulse and optional caption.
/// Use [size] to control overall dimensions (default 120).
class BotanlyLoader extends StatefulWidget {
  final double size;
  final bool showCaption;

  const BotanlyLoader({super.key, this.size = 120, this.showCaption = false});

  @override
  State<BotanlyLoader> createState() => _BotanlyLoaderState();
}

class _BotanlyLoaderState extends State<BotanlyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              size: Size(s, s),
              painter: _SproutPainter(_ctrl.value),
            ),
          ),
        ),
        if (widget.showCaption) ...[
          SizedBox(height: s * 0.18),
          _BotanlyDots(controller: _ctrl),
        ],
      ],
    );
  }
}

class _SproutPainter extends CustomPainter {
  final double t; // 0..1 loop progress

  _SproutPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final scale = s / 100; // design is 100x100

    canvas.save();
    canvas.scale(scale);

    // Bob up/down: -3px at t=0.5
    final bobY = -3.0 * math.sin(t * 2 * math.pi);
    canvas.translate(0, bobY);

    _drawHalo(canvas);
    _drawGround(canvas);
    _drawStem(canvas);
    _drawLeftLeaf(canvas);
    _drawRightLeaf(canvas);

    canvas.restore();
  }

  void _drawHalo(Canvas canvas) {
    // Pulse: scale 0.85..1.15, opacity 0.45..0.85
    final pulse = math.sin(t * 2 * math.pi);
    final haloScale = 0.85 + 0.3 * (0.5 + 0.5 * pulse);
    final haloOpacity = 0.45 + 0.4 * (0.5 + 0.5 * pulse);

    canvas.save();
    canvas.translate(50, 50);
    canvas.scale(haloScale);
    final hPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7EC665).withValues(alpha: haloOpacity),
          const Color(0xFF7EC665).withValues(alpha: 0),
        ],
        stops: const [0, 0.7],
      ).createShader(const Rect.fromLTWH(-50, -50, 100, 100));
    canvas.drawCircle(Offset.zero, 50, hPaint);
    canvas.restore();
  }

  void _drawGround(Canvas canvas) {
    final gPaint = Paint()
      ..color = const Color(0xFFCCE8B8).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(20, 86), const Offset(80, 86), gPaint);
  }

  void _drawStem(Canvas canvas) {
    // Stem grows from t=0 to t=0.35
    final stemT = (t / 0.35).clamp(0.0, 1.0);
    if (stemT == 0) return;

    final path = Path()
      ..moveTo(50, 86)
      ..cubicTo(48, 70, 52, 60, 50, 40);

    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(
      0,
      metric.length * Curves.easeOut.transform(stemT),
    );

    final sPaint = Paint()
      ..color = const Color(0xFF4A8C33)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(visiblePath, sPaint);
  }

  void _drawLeftLeaf(Canvas canvas) {
    // Bloom: t=0.32..0.60
    final raw = ((t - 0.32) / 0.28).clamp(0.0, 1.0);
    if (raw == 0) return;
    final bloom = Curves.easeOut.transform(raw);
    final overshoot = raw < 0.82 ? bloom * 1.08 : 1.0;

    final leafPath = Path()
      ..moveTo(50, 56)
      ..cubicTo(38, 56, 28, 50, 22, 42)
      ..cubicTo(28, 36, 38, 34, 46, 38)
      ..cubicTo(50, 41, 50, 48, 50, 56)
      ..close();

    canvas.save();
    canvas.translate(50, 56);
    canvas.scale(overshoot);
    final initRotation = -30.0 * (1.0 - bloom);
    canvas.rotate(initRotation * math.pi / 180);
    canvas.translate(-50, -56);

    final lPaint = Paint()..color = BotanlyColors.sage;
    canvas.drawPath(leafPath, lPaint);

    // Vein: fades in after t=0.55
    final veinT = ((t - 0.55) / 0.15).clamp(0.0, 1.0);
    if (veinT > 0) {
      final vOpacity =
          0.55 *
          veinT *
          (t < 0.85 ? 1.0 : (0.7 + 0.3 * ((1.0 - t) / 0.15).clamp(0.0, 1.0)));
      final vPaint = Paint()
        ..color = Colors.white.withValues(alpha: vOpacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(50, 56), const Offset(26, 44), vPaint);
    }

    canvas.restore();
  }

  void _drawRightLeaf(Canvas canvas) {
    // Bloom: t=0.38..0.65
    final raw = ((t - 0.38) / 0.27).clamp(0.0, 1.0);
    if (raw == 0) return;
    final bloom = Curves.easeOut.transform(raw);
    final overshoot = raw < 0.82 ? bloom * 1.08 : 1.0;

    final leafPath = Path()
      ..moveTo(50, 50)
      ..cubicTo(62, 50, 72, 44, 78, 36)
      ..cubicTo(72, 30, 62, 28, 54, 32)
      ..cubicTo(50, 35, 50, 42, 50, 50)
      ..close();

    canvas.save();
    canvas.translate(50, 50);
    canvas.scale(overshoot);
    final initRotation = 30.0 * (1.0 - bloom);
    canvas.rotate(initRotation * math.pi / 180);
    canvas.translate(-50, -50);

    final lPaint = Paint()..color = BotanlyColors.sage;
    canvas.drawPath(leafPath, lPaint);

    // Vein
    final veinT = ((t - 0.55) / 0.15).clamp(0.0, 1.0);
    if (veinT > 0) {
      final vOpacity =
          0.55 *
          veinT *
          (t < 0.85 ? 1.0 : (0.7 + 0.3 * ((1.0 - t) / 0.15).clamp(0.0, 1.0)));
      final vPaint = Paint()
        ..color = Colors.white.withValues(alpha: vOpacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(50, 50), const Offset(74, 38), vPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SproutPainter old) => old.t != t;
}

/// Three bouncing dots shown below the sprout.
class _BotanlyDots extends StatelessWidget {
  final AnimationController controller;

  const _BotanlyDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final dotT = ((controller.value * 1.4 - i * 0.143) % 1.0);
            final scale = 0.7 + 0.3 * _dotCurve(dotT);
            final opacity = 0.4 + 0.6 * _dotCurve(dotT);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: BotanlyColors.sageDark.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _dotCurve(double t) {
    if (t < 0.4) return math.sin(t / 0.4 * math.pi / 2);
    if (t < 0.8) return math.cos((t - 0.4) / 0.4 * math.pi / 2);
    return 0;
  }
}
