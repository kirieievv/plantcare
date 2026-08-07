/// "Clouds over the garden" — the refresh animation for the garden ring.
///
/// The metaphor: the score is not shown because the weather is closed in. The
/// mass rolls in with the pull, then breathes while the request is out, with sun
/// rays raking through the gaps from behind and fog turning inside the ring.
///
/// Everything here is decoration over the dial: it never takes a hit test and
/// never affects layout, and it is painted *under* the plant seats so the garden
/// itself stays readable (§7).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:plant_care/theme/botanly_glass.dart';

/// One puff of the mass, straight from the prototype's twelve `.clouds i` rules.
///
/// [rx]/[ry] are the eight CSS border-radius percentages — a puff is never a
/// circle, which is what keeps the mass from reading as a pile of balls.
class _Puff {
  final double w, h, left, top;
  final double blur;
  final double opacity;
  final double rotation;
  final List<double> rx;
  final List<double> ry;

  /// Depth order; puffs sharing a blur are drawn in one filtered layer.
  final int z;

  const _Puff({
    required this.w,
    required this.h,
    required this.left,
    required this.top,
    required this.z,
    this.blur = 4,
    this.opacity = 1,
    this.rotation = 0,
    required this.rx,
    required this.ry,
  });

  BorderRadius get radius => BorderRadius.only(
    topLeft: Radius.elliptical(w * rx[0] / 100, h * ry[0] / 100),
    topRight: Radius.elliptical(w * rx[1] / 100, h * ry[1] / 100),
    bottomRight: Radius.elliptical(w * rx[2] / 100, h * ry[2] / 100),
    bottomLeft: Radius.elliptical(w * rx[3] / 100, h * ry[3] / 100),
  );
}

const _cloudBox = Size(340, 306);

const _puffs = <_Puff>[
  _Puff(
    w: 176,
    h: 118,
    left: 4,
    top: 98,
    z: 3,
    rx: [62, 48, 56, 44],
    ry: [70, 66, 40, 38],
  ),
  _Puff(
    w: 156,
    h: 112,
    left: 182,
    top: 78,
    z: 3,
    rx: [44, 60, 40, 58],
    ry: [62, 72, 36, 42],
  ),
  _Puff(
    w: 196,
    h: 112,
    left: 72,
    top: 136,
    z: 4,
    rotation: -3,
    rx: [54, 46, 62, 40],
    ry: [58, 64, 44, 46],
  ),
  _Puff(
    w: 134,
    h: 98,
    left: -16,
    top: 130,
    z: 2,
    blur: 7,
    opacity: 0.9,
    rx: [58, 42, 48, 56],
    ry: [66, 58, 44, 40],
  ),
  _Puff(
    w: 142,
    h: 100,
    left: 210,
    top: 136,
    z: 2,
    blur: 7,
    opacity: 0.9,
    rx: [40, 62, 56, 44],
    ry: [56, 68, 42, 46],
  ),
  _Puff(
    w: 184,
    h: 100,
    left: 74,
    top: 56,
    z: 4,
    rotation: 2,
    rx: [50, 54, 44, 60],
    ry: [64, 60, 40, 44],
  ),
  _Puff(
    w: 128,
    h: 90,
    left: 38,
    top: 136,
    z: 5,
    blur: 3,
    rx: [60, 44, 54, 46],
    ry: [68, 56, 46, 38],
  ),
  _Puff(
    w: 138,
    h: 92,
    left: 172,
    top: 144,
    z: 5,
    blur: 3,
    rx: [44, 58, 46, 56],
    ry: [58, 70, 38, 44],
  ),
  _Puff(
    w: 158,
    h: 96,
    left: 90,
    top: 104,
    z: 6,
    blur: 3,
    rx: [56, 48, 58, 42],
    ry: [62, 62, 42, 44],
  ),
  _Puff(
    w: 112,
    h: 80,
    left: 10,
    top: 50,
    z: 2,
    blur: 8,
    opacity: 0.72,
    rx: [52, 52, 44, 58],
    ry: [64, 58, 44, 40],
  ),
  _Puff(
    w: 118,
    h: 84,
    left: 216,
    top: 40,
    z: 2,
    blur: 8,
    opacity: 0.72,
    rx: [46, 58, 54, 46],
    ry: [60, 66, 40, 44],
  ),
  _Puff(
    w: 126,
    h: 86,
    left: 110,
    top: 186,
    z: 3,
    blur: 6,
    opacity: 0.86,
    rx: [58, 44, 50, 54],
    ry: [66, 58, 44, 42],
  ),
];

/// `width, height, margin-left, rotation°, opacity` of the five sun rays.
const _rays = <List<double>>[
  [30, 320, -58, -14, 1.0],
  [20, 296, -16, -5, 0.85],
  [36, 332, 22, 8, 0.92],
  [17, 284, 66, 17, 0.74],
  [24, 308, -98, -22, 0.66],
];

class GardenClouds extends StatefulWidget {
  /// Pull progress, 0 → 1 at the trigger threshold. The mass fades in with it
  /// and contracts onto the ring (scale 1.3 → 1.0).
  final double progress;

  /// The request is out: the mass breathes, the sun pulses, the fog turns.
  final bool busy;

  /// "Собираем данные сада…" — sits over the mass, at the ring's centre.
  final String caption;

  const GardenClouds({
    super.key,
    required this.progress,
    required this.busy,
    required this.caption,
  });

  @override
  State<GardenClouds> createState() => _GardenCloudsState();
}

class _GardenCloudsState extends State<GardenClouds>
    with TickerProviderStateMixin {
  /// One clock for the puffs (they read it at three different rates), one for
  /// the fog, one for the sunlight. Fewer controllers than moving parts, so the
  /// three rhythms stay independent without three tickers per puff.
  late final AnimationController _breath;
  late final AnimationController _fog;
  late final AnimationController _beam;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 41000), // 6 × 7.4 × 8.2 ≈ common
    );
    _fog = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _beam = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _syncClocks();
  }

  @override
  void didUpdateWidget(covariant GardenClouds old) {
    super.didUpdateWidget(old);
    if (widget.busy != old.busy) _syncClocks();
  }

  /// Animations only run while the request is out — a mass that breathes under
  /// the finger would fight the pull.
  void _syncClocks() {
    for (final c in [_breath, _fog, _beam]) {
      if (widget.busy) {
        if (!c.isAnimating) c.repeat();
      } else {
        c.stop();
        c.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _fog.dispose();
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0);
    final visible = widget.busy || p > 0;
    if (!visible) return const SizedBox.shrink();

    final opacity = widget.busy ? 1.0 : p;
    final scale = widget.busy ? 1.0 : 1.3 - 0.3 * p;

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Behind the mass, so the light breaks through the gaps.
            if (widget.busy) ...[_sunRays(), _fogDisc()],
            Transform.scale(scale: scale, child: _cloudMass()),
            if (widget.busy) ...[_glow(), _caption()],
          ],
        ),
      ),
    );
  }

  // ── the mass ──────────────────────────────────────────────────────────────

  Widget _cloudMass() {
    // Each puff carries its own blur rather than sharing one per depth: blurring
    // a whole layer melts the overlaps into a single blob, and the lobes are
    // what make the mass read as cloud instead of fog.
    final ordered = [..._puffs]..sort((a, b) => a.z.compareTo(b.z));

    return SizedBox(
      width: _cloudBox.width,
      height: _cloudBox.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final puff in ordered)
            Positioned(
              left: puff.left,
              top: puff.top,
              child: _breathe(
                index: _puffs.indexOf(puff),
                child: Opacity(
                  opacity: puff.opacity,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: puff.blur / 2,
                      sigmaY: puff.blur / 2,
                    ),
                    child: Transform.rotate(
                      angle: puff.rotation * math.pi / 180,
                      child: _puffBody(puff),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _puffBody(_Puff puff) {
    return Container(
      width: puff.w,
      height: puff.h,
      decoration: BoxDecoration(
        borderRadius: puff.radius,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.44), // 40% 28%
          radius: 0.62,
          stops: [0.0, 0.52, 0.76, 1.0],
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFCFDFB),
            Color(0xFFEDF1EA),
            Color(0xFFE1E7DE),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42283626), // rgba(40,54,38,.26)
            blurRadius: 26,
            spreadRadius: -14,
            offset: Offset(0, 12),
          ),
        ],
      ),
      // Flutter has no inset shadow: the lit top edge and the shaded underside
      // are painted as an overlay instead.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: puff.radius,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.32, 0.78, 1.0],
            colors: [
              Color(0xB3FFFFFF),
              Color(0x00FFFFFF),
              Color(0x00969F92),
              Color(0x40969F92),
            ],
          ),
        ),
      ),
    );
  }

  /// `translate(7px, -6px) scale(1.05)` over 6 s, with 7.4 s and 8.2 s variants
  /// on every second and every third puff — the mass never pulses as one body.
  Widget _breathe({required int index, required Widget child}) {
    if (!widget.busy) return child;

    final n = index + 1;
    final (period, delay) = n % 3 == 0
        ? (8.2, 3.4)
        : n % 2 == 0
        ? (7.4, 1.8)
        : (6.0, 0.0);

    return AnimatedBuilder(
      animation: _breath,
      builder: (_, inner) {
        final seconds = _breath.value * _breath.duration!.inMilliseconds / 1000;
        final t = ((seconds + delay) % period) / period;
        // ease-in-out between the two poses and back.
        final k = (1 - math.cos(2 * math.pi * t)) / 2;
        return Transform.translate(
          offset: Offset(7 * k, -6 * k),
          child: Transform.scale(scale: 1 + 0.05 * k, child: inner),
        );
      },
      child: child,
    );
  }

  // ── light ─────────────────────────────────────────────────────────────────

  Widget _sunRays() {
    // The rays' box hangs 17 px below the ring's centre, so the fan opens from
    // above the dial and spills downward through the mass.
    return Transform.translate(
      offset: const Offset(0, 17),
      child: AnimatedBuilder(
        animation: _beam,
        builder: (_, child) => Opacity(opacity: _beamOpacity, child: child),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: SizedBox(
            width: 340,
            height: 340,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final ray in _rays)
                  Positioned(
                    left: 170 + ray[2],
                    top: 10,
                    child: Transform.rotate(
                      angle: ray[3] * math.pi / 180,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: ray[4],
                        child: Container(
                          width: ray[0],
                          height: ray[1],
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.4, 0.86],
                              colors: [
                                Color(0xF2FFE496),
                                Color(0x80FFDE8C),
                                Color(0x00FFDE8C),
                              ],
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
      ),
    );
  }

  /// `0 → .5, 50% → 1` — the sun pulses against the clouds' breathing.
  double get _beamOpacity {
    final k = (1 - math.cos(2 * math.pi * _beam.value)) / 2;
    return 0.5 + 0.5 * k;
  }

  Widget _glow() {
    return Transform.translate(
      offset: const Offset(0, -11),
      child: AnimatedBuilder(
        animation: _beam,
        builder: (_, child) => Opacity(opacity: _beamOpacity, child: child),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                stops: [0.0, 0.7],
                colors: [Color(0xD9FFF0BE), Color(0x00FFF0BE)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fog turning inside the ring: a conic sweep of translucent whites, 5 s.
  Widget _fogDisc() {
    return RotationTransition(
      turns: _fog,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              colors: [
                Color(0x00FFFFFF),
                Color(0xD9FFFFFF),
                Color(0x00FFFFFF),
                Color(0xB3FFFFFF),
                Color(0x00FFFFFF),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _caption() {
    return SizedBox(
      width: 200,
      child: Text(
        widget.caption,
        textAlign: TextAlign.center,
        style:
            glassFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5246),
            ).copyWith(
              shadows: const [
                Shadow(color: Color(0xE6FFFFFF), offset: Offset(0, 1)),
              ],
            ),
      ),
    );
  }
}
