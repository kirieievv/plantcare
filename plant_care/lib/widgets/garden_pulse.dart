/// Garden pulse — the ring and the plant orbit (SPEC 2.2).
///
/// The ring is the honest average of the plants' live scores, and it goes amber
/// the moment any single plant drops below the warning line: an average that
/// hides a dying plant is worse than no number at all.
///
/// The orbit holds the whole garden — six seats on the near ring, the rest
/// floating farther out. It never degrades into a horizontal strip: a strip
/// clips at both edges and reads as neither a circle nor a list.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/models/plant.dart';
import 'package:plant_care/models/task.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/garden_clouds.dart';

/// Stand-in when the screen has no gesture wired up — the clouds then only
/// answer to [GardenPulse.loading].
final _noPull = ValueNotifier<double>(0);

/// One plant as the orbit needs it.
typedef OrbitPlant = ({Plant plant, int score, bool needsWater});

class GardenPulse extends StatefulWidget {
  final GardenHealth garden;
  final List<OrbitPlant> plants;

  /// Caption under the score. Composed by the caller because it names the plant
  /// dragging the garden down, which is a localisation decision, not a layout one.
  final String caption;
  final String label;

  final void Function(Plant plant) onOpenPlant;

  /// Only reachable past the ten-plant product limit — the "+N" seat.
  final VoidCallback? onShowAll;

  /// Bumped to make the ring rain droplets — a watering task closed on the deck
  /// shows its effect here, where the score it repaired lives.
  final int dropletBurst;

  /// No data yet. The score, the caption and the real orbit are all withheld:
  /// a number rendered before the answer arrives is a number that is wrong.
  final bool loading;

  /// Read by screen readers in place of the withheld score, and printed over
  /// the clouds while the request is out.
  final String loadingLabel;

  /// How far the pull-to-refresh gesture has travelled, 0 → 1 at its trigger
  /// point. The clouds roll in with it.
  final ValueListenable<double>? pullProgress;

  const GardenPulse({
    super.key,
    required this.garden,
    required this.plants,
    required this.caption,
    required this.label,
    required this.onOpenPlant,
    this.onShowAll,
    this.dropletBurst = 0,
    this.loading = false,
    this.loadingLabel = '',
    this.pullProgress,
  });

  @override
  State<GardenPulse> createState() => _GardenPulseState();
}

class _GardenPulseState extends State<GardenPulse>
    with TickerProviderStateMixin {
  static const _blockHeight = 322.0;
  static const _ringSize = 164.0;
  static const _nearRadius = 110.0;
  static const _farRadius = 150.0;

  /// The white disc the ring is painted around.
  static const _coreDiameter = _ringSize - 2 * _RingPainter.stroke; // 148

  /// Text inside a circle is bounded by the inscribed square, not by the
  /// diameter: a line as wide as the disc has its ends in the corners, where
  /// there is no disc left. 148 / √2 ≈ 105.
  ///
  /// This is why the block was already wrong at 100%: the column was 132 wide,
  /// 27 px past the edge. Short strings simply never reached the corners.
  /// Derived from the ring rather than hardcoded, so resizing the dial keeps
  /// the text inside it.
  static final _coreBox = _coreDiameter / math.sqrt2;

  /// How far the type inside the dial is allowed to follow the system size.
  ///
  /// Only this block is capped; everywhere else the OS setting works in full,
  /// which is the accessibility half of the bargain. Here the geometry is the
  /// content: a circle cannot grow with the type, so past this point the text
  /// would leave the ring rather than be read.
  ///
  /// This is a ceiling, not a switch — it holds for every step from 115% up,
  /// AX5 included, and below it the block scales like everything else.
  ///
  /// Why 1.15 and not more. Everything in the safe square except the score
  /// grows with the cap, and the score takes what is left: 36 px at 100%,
  /// 31 at 110%, 26 at 115%. From there each further 5% costs the score about
  /// 3.5 px, so somewhere around 1.2–1.25 it hits the 22 px floor. Raising the
  /// cap buys the label and the verdict a pixel or so and takes four off the
  /// one number the block exists to show.
  static const _maxTextScale = 1.15;

  /// The system scaler as this block honours it.
  ///
  /// Used for the parts that are measured rather than laid out by a `Text` —
  /// the gaps and the plant-name slot — so they follow the same cap as the
  /// glyphs do.
  TextScaler _scaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _maxTextScale);

  /// Seat angles per plant count, 0° pointing right and negatives pointing up.
  /// Straight from the handoff: the sixth layout is the widest the near ring
  /// takes before labels start to touch.
  static const _nearAngles = <List<double>>[
    [-90],
    [-90, 90],
    [-90, 30, 150],
    [-90, 10, 90, 170],
    [-90, -18, 54, 126, 198],
    [-90, -30, 30, 90, 150, 210],
  ];
  static const _nearSeats = 6;

  /// Sides and upper diagonals. The bottom of the far orbit stays empty — the
  /// hint line and the task deck live directly under the ring.
  static const _farAngles = <double>[0, 180, -58, -122];

  /// The placeholder orbit while loading: the three-plant layout, unlabelled.
  static const _loadingAngles = <double>[-90, 30, 150];

  late final AnimationController _halo;
  late final AnimationController _drops;

  @override
  void initState() {
    super.initState();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _drops = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
  }

  @override
  void didUpdateWidget(covariant GardenPulse old) {
    super.didUpdateWidget(old);
    if (widget.dropletBurst != old.dropletBurst) _drops.forward(from: 0);
  }

  @override
  void dispose() {
    _halo.dispose();
    _drops.dispose();
    super.dispose();
  }

  Color get _tone => widget.garden.hasWeak ? kGlassSun : kGlassAccent;

  @override
  Widget build(BuildContext context) {
    // The cap covers the whole block, dial and orbit alike: the plant names sit
    // in seats placed by angle, so they run into each other for the same reason
    // the score runs out of the ring.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: SizedBox(
        height: _blockHeight,
        child: Stack(
          alignment: Alignment.center,
          // Labels reach outside the seats by design; clipping them is what
          // cropped the plants' names.
          clipBehavior: Clip.none,
          children: [
            // The halo is a heartbeat. There is nothing to beat for yet.
            if (!widget.loading) _buildHalo(),
            _buildRing(),
            // Over the ring, under the seats: the weather hides the score,
            // never the garden (pull_to_refresh_flow §7).
            _clouds(),
            ...(widget.loading ? _loadingSeats() : _seats()),
            if (!widget.loading) _buildDroplets(),
          ],
        ),
      ),
    );
  }

  /// The refresh weather. Repaints on its own as the finger moves, so a pull
  /// does not rebuild the garden under it.
  Widget _clouds() {
    return ValueListenableBuilder<double>(
      valueListenable: widget.pullProgress ?? _noPull,
      builder: (_, progress, __) => GardenClouds(
        progress: progress,
        busy: widget.loading,
        caption: widget.loadingLabel,
      ),
    );
  }

  // ── orbit ─────────────────────────────────────────────────────────────────

  List<Widget> _seats() {
    final plants = widget.plants;
    if (plants.isEmpty) return const [];

    final near = math.min(plants.length, _nearSeats);
    final nearAngles = _nearAngles[near - 1];
    final overflow = plants.length - near - _farAngles.length;

    return [
      for (var i = 0; i < near; i++)
        _seat(
          angle: nearAngles[i],
          radius: _nearRadius,
          child: _OrbitSeat(
            key: ValueKey('orbit-seat-${plants[i].plant.id}'),
            plant: plants[i],
            far: false,
            labelAbove: _labelAbove(nearAngles[i], far: false),
            onTap: () => _open(plants[i]),
          ),
        ),
      // Past ten the garden would need an eleventh seat; the product caps the
      // garden at ten, so the last seat becomes "+N" instead of the orbit
      // growing or spilling into a row (§2.5).
      for (var i = near; i < plants.length && i - near < _farAngles.length; i++)
        if (!(overflow > 0 && i - near == _farAngles.length - 1))
          _seat(
            angle: _farAngles[i - near],
            radius: _farRadius,
            child: _Drift(
              index: i - near,
              child: _OrbitSeat(
                key: ValueKey('orbit-seat-${plants[i].plant.id}'),
                plant: plants[i],
                far: true,
                labelAbove: _labelAbove(_farAngles[i - near], far: true),
                onTap: () => _open(plants[i]),
              ),
            ),
          ),
      if (overflow > 0)
        _seat(
          angle: _farAngles.last,
          radius: _farRadius,
          child: _Drift(
            index: _farAngles.length - 1,
            child: _MoreSeat(
              count: overflow + 1,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onShowAll?.call();
              },
            ),
          ),
        ),
    ];
  }

  List<Widget> _loadingSeats() => [
    for (final angle in _loadingAngles)
      _seat(
        angle: angle,
        radius: _nearRadius,
        child: _PlaceholderSeat(labelAbove: _labelAbove(angle, far: false)),
      ),
  ];

  /// A label that reaches inward lands on the ring, so it goes radially out.
  /// The two far seats on the sides are the exception: above there they crowd
  /// the ring, so they hang below.
  bool _labelAbove(double angle, {required bool far}) {
    if (far && (angle == 0 || angle == 180)) return false;
    return math.sin(angle * math.pi / 180) < 0;
  }

  Widget _seat({
    required double angle,
    required double radius,
    required Widget child,
  }) {
    final rad = angle * math.pi / 180;
    return Transform.translate(
      offset: Offset(radius * math.cos(rad), radius * math.sin(rad)),
      child: child,
    );
  }

  void _open(OrbitPlant p) {
    HapticFeedback.selectionClick();
    widget.onOpenPlant(p.plant);
  }

  // ── ring ──────────────────────────────────────────────────────────────────

  Widget _buildHalo() {
    return AnimatedBuilder(
      animation: _halo,
      builder: (_, __) {
        final t = _halo.value;
        // scale .98 → 1.28, opacity .65 → 0 by 70% of the cycle.
        final scale = 0.98 + 0.30 * t;
        final opacity = t >= 0.7 ? 0.0 : 0.65 * (1 - t / 0.7);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: _ringSize,
              height: _ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _tone.withAlpha(71), width: 1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRing() {
    final loading = widget.loading;

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tinted lift under the dial: `0 14px 40px -16px rgba(62,142,59,.5)`,
          // recoloured with the ring so an amber garden does not glow green.
          // While loading there is no verdict to tint it with.
          if (!loading)
            Container(
              width: _ringSize,
              height: _ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _tone.withAlpha(128),
                    blurRadius: 40,
                    spreadRadius: -16,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          if (loading)
            CustomPaint(
              size: const Size.square(_ringSize),
              painter: const _RingPainter(progress: 0, color: kGlassAccent),
            )
          else
            TweenAnimationBuilder<double>(
              tween: Tween(end: widget.garden.score / 100),
              duration: const Duration(milliseconds: 900),
              curve: const Cubic(0.3, 0.7, 0.3, 1),
              builder: (_, progress, __) => CustomPaint(
                size: const Size.square(_ringSize),
                painter: _RingPainter(progress: progress, color: _tone),
              ),
            ),
          // Core: `inset 8` filled with rgba(255,255,255,.88).
          //
          // In CSS that white sits over the conic gradient, so the middle comes
          // out cream, not white — the tint is part of the look. The ring here
          // is painted as a band, so the same result is mixed explicitly.
          Container(
            width: _ringSize - 2 * _RingPainter.stroke,
            height: _ringSize - 2 * _RingPainter.stroke,
            decoration: BoxDecoration(
              color: loading
                  ? const Color(0xE0FFFFFF)
                  : Color.lerp(_tone, Colors.white, 0.88),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14142010),
                  blurRadius: 18,
                  spreadRadius: -6,
                ),
              ],
            ),
          ),
          SizedBox(
            width: _coreBox,
            height: _coreBox,
            child: loading ? _loadingCore() : _core(context),
          ),
        ],
      ),
    );
  }

  /// Below this the score stops being the headline of the block and becomes
  /// just another line of text.
  static const _minScoreSize = 22.0;

  static const _scoreSize = 36.0;

  static final _captionStyle = glassFont(
    fontSize: 12.5,
    height: 1.3,
    color: kGlassMut,
  );

  static final _labelStyle = glassFont(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 11 * 0.12,
    height: 1.15,
    color: kGlassMut2,
  );

  /// How tall [text] renders inside the safe square.
  double _lineBoxHeight(
    String text,
    TextStyle style,
    TextScaler scaler,
    int maxLines,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      textScaler: scaler,
    )..layout(maxWidth: _coreBox);
    return painter.size.height;
  }

  Widget _core(BuildContext context) {
    final scaler = _scaler(context);

    // Relative, not the old fixed 4 and 5: at a raised size a fixed gap leaves
    // the score hanging away from the verdict and pulls the optical centre up.
    // 0.34 em of the caption's own size, which lands on the same ~4 px at 100%.
    final gap = scaler.scale(12.5) * 0.34;

    // The score is the only element with slack — the label and the verdict are
    // already at reading size — so it is the one that gives way. Its size is
    // measured rather than fitted: `FittedBox` alone has no floor and, at the
    // cap, quietly took the number under 22.
    //
    // The handoff warns about exactly this shape of bug: the children must not
    // shrink on their own, or the measurement describes a layout that isn't
    // the one on screen. Hence real text metrics, at the same scaler the
    // `Text` widgets below will use.
    final labelHeight = _lineBoxHeight(
      widget.label.toUpperCase(),
      _labelStyle,
      scaler,
      2,
    );
    var captionLines = 2;
    var captionHeight = _lineBoxHeight(
      widget.caption,
      _captionStyle,
      scaler,
      captionLines,
    );

    double slack() => _coreBox - labelHeight - captionHeight - 2 * gap;

    // Last resort before the number becomes unreadable: the verdict gives up
    // its second line. It is a summary of the list right below it; the score
    // has nowhere else to be shown.
    if (slack() < _minScoreSize) {
      captionLines = 1;
      captionHeight = _lineBoxHeight(
        widget.caption,
        _captionStyle,
        scaler,
        captionLines,
      );
    }

    // Floored to a whole point: a paragraph rounds its line box up, so a score
    // sized 26.88 renders 27 and the column overflows by the tenth of a pixel
    // that rounding invented.
    final scoreSize = slack().floorToDouble().clamp(
      _minScoreSize,
      scaler.scale(_scoreSize),
    );

    return Semantics(
      container: true,
      // The cap gives a reader of large type smaller glyphs than they asked
      // for, so the whole dial is offered to VoiceOver as one sentence, at
      // whatever size the system reads it.
      label: '${widget.label}: ${widget.garden.score}. ${widget.caption}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _coreLabel(),
          SizedBox(height: gap),
          // Already sized against the system setting above; scaling it a
          // second time here is what the no-scaling wrapper prevents.
          MediaQuery.withNoTextScaling(
            child: Text(
              '${widget.garden.score}',
              maxLines: 1,
              softWrap: false,
              style: glassFont(
                fontSize: scoreSize,
                fontWeight: FontWeight.w600,
                letterSpacing: scoreSize * -0.045,
                height: 1,
                color: kGlassInk,
              ),
            ),
          ),
          SizedBox(height: gap),
          Text(
            widget.caption,
            textAlign: TextAlign.center,
            maxLines: captionLines,
            overflow: TextOverflow.ellipsis,
            style: _captionStyle,
          ),
        ],
      ),
    );
  }

  /// Three bars where the score and the verdict will be: 66×30, 104×11, 74×11.
  /// The core empties out while the request is out: the weather has taken the
  /// score, and the clouds carry the "we are fetching" line themselves. Only
  /// the screen-reader label stays behind.
  Widget _loadingCore() {
    return Semantics(
      label: widget.loadingLabel,
      child: const SizedBox(height: 96),
    );
  }

  /// Two lines are enough for every locale we ship; the ellipsis is the last
  /// resort rather than the plan. Hiding the label at large type was the other
  /// option and it loses what the number means.
  Widget _coreLabel() => Text(
    widget.label.toUpperCase(),
    textAlign: TextAlign.center,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: _labelStyle,
  );

  /// Six drops falling out of the ring when a watering task is closed.
  Widget _buildDroplets() {
    return AnimatedBuilder(
      animation: _drops,
      builder: (_, __) {
        if (!_drops.isAnimating) return const SizedBox.shrink();
        return SizedBox(
          width: _ringSize,
          height: _blockHeight,
          child: Stack(
            children: [
              for (var i = 0; i < 6; i++)
                _Droplet(
                  progress: (_drops.value - i * 0.06).clamp(0.0, 1.0),
                  dx: 26.0 + i * 22,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Droplet extends StatelessWidget {
  final double progress;
  final double dx;

  const _Droplet({required this.progress, required this.dx});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final opacity = progress < 0.2
        ? progress / 0.2
        : 1 - (progress - 0.2) / 0.8;
    return Positioned(
      left: dx,
      top: 80 + 110 * progress,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: 7,
          height: 9,
          decoration: const BoxDecoration(
            color: kGlassWater,
            borderRadius: BorderRadius.all(Radius.elliptical(7, 9)),
          ),
        ),
      ),
    );
  }
}

/// The gentle vertical float of the far orbit: `translateY(0 → -7px → 0)` over
/// 9 s, with two other durations and offsets so neighbours never bob in unison.
/// The near ring does not drift — it is anchored to the dial.
class _Drift extends StatefulWidget {
  final int index;
  final Widget child;

  const _Drift({required this.index, required this.child});

  @override
  State<_Drift> createState() => _DriftState();
}

class _DriftState extends State<_Drift> with SingleTickerProviderStateMixin {
  static const _seconds = [9, 11, 10, 9];
  static const _phase = [0.0, 2.4 / 11, 4.8 / 10, 0.55];

  late final AnimationController _float;
  late final double _offset;

  @override
  void initState() {
    super.initState();
    final i = widget.index % _seconds.length;
    _offset = _phase[i];
    _float = AnimationController(
      vsync: this,
      duration: Duration(seconds: _seconds[i]),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) {
        final t = (_float.value + _offset) % 1.0;
        // ease-in-out between 0 and -7 and back.
        final dy = -3.5 * (1 - math.cos(2 * math.pi * t));
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// A glass circle with a leaf, its name radially outside, and a status dot.
///
/// Tapping opens the plant and nothing else: SPEC 2.2 bans per-plant actions
/// here, because a "water" button on a tiny orbit circle is a misfire waiting
/// to happen.
class _OrbitSeat extends StatefulWidget {
  final OrbitPlant plant;

  /// Farther out, smaller and quieter — hierarchy by weight and colour, never
  /// by dropping the label below 11 px.
  final bool far;
  final bool labelAbove;
  final VoidCallback onTap;

  const _OrbitSeat({
    super.key,
    required this.plant,
    required this.far,
    required this.labelAbove,
    required this.onTap,
  });

  @override
  State<_OrbitSeat> createState() => _OrbitSeatState();
}

class _OrbitSeatState extends State<_OrbitSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blip;

  bool _down = false;

  @override
  void initState() {
    super.initState();
    // Eager, even though only a plant with a status dot ever reads it: a lazy
    // field first touched in dispose() builds its ticker against a dead element.
    _blip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _blip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plant;
    final far = widget.far;
    final attention = p.score < kHealthWarnThreshold;
    final size = far ? 40.0 : 52.0;

    final circle = Stack(
      clipBehavior: Clip.none,
      children: [
        GlassSurface(
          blur: 18,
          shape: BoxShape.circle,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: BotanlyGlyph(
                BotanlySvg.leaf,
                size: far ? 17 : 22,
                color: kGlassAccent.withAlpha(153),
              ),
            ),
          ),
        ),
        if (p.needsWater || attention)
          Positioned(
            top: -1,
            right: -1,
            child: AnimatedBuilder(
              animation: _blip,
              builder: (_, __) {
                // Only the watering dot blips; amber is a state, not an alarm,
                // and two competing pulses read as noise.
                final spread = p.needsWater ? 6 * _pulse(_blip.value) : 0.0;
                final tone = p.needsWater ? kGlassWater : kGlassSun;
                final dot = far ? 12.0 : 14.0;
                return Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEDF0EC),
                      width: far ? 2 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tone.withAlpha(
                          (140 * (1 - _pulse(_blip.value))).round(),
                        ),
                        spreadRadius: spread,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );

    return GestureDetector(
      // The 44 px box is wider than the far circle it holds; opaque makes the
      // whole target live, not just the pixels the circle paints.
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 380),
        curve: const Cubic(0.32, 0.72, 0.25, 1),
        child: Opacity(
          opacity: far ? 0.9 : 1,
          child: _SeatFrame(
            size: size,
            labelAbove: widget.labelAbove,
            far: far,
            label: Text(
              p.plant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: glassFont(
                fontSize: 11,
                fontWeight: far ? FontWeight.w500 : FontWeight.w600,
                letterSpacing: 0,
                height: 1.3,
                color: far ? kGlassMut2 : kGlassMut,
              ),
            ),
            child: circle,
          ),
        ),
      ),
    );
  }

  double _pulse(double t) => t <= 0.5 ? t * 2 : (1 - t) * 2;
}

/// The "+N" seat — only reachable if the ten-plant limit is ever raised. The
/// orbit stays a circle; the overflow opens the list instead of growing it.
class _MoreSeat extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreSeat({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: 0.9,
        child: _SeatFrame(
          size: 40,
          far: true,
          labelAbove: false,
          label: const SizedBox.shrink(),
          child: GlassSurface(
            blur: 18,
            shape: BoxShape.circle,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  '+$count',
                  style: glassFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kGlassGreenText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A neutral seat while the garden loads: no icon, no dot, no tap — just the
/// shape the real orbit will take.
class _PlaceholderSeat extends StatelessWidget {
  final bool labelAbove;

  const _PlaceholderSeat({required this.labelAbove});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _SeatFrame(
        size: 52,
        far: false,
        labelAbove: labelAbove,
        label: const Center(child: GlassSkeleton(width: 44, height: 9)),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x6BFFFFFF), // rgba(255,255,255,.42)
            shape: BoxShape.circle,
            border: Border.all(color: kGlassBorder, width: 0.5),
            boxShadow: kGlassShadow,
          ),
        ),
      ),
    );
  }
}

/// The circle sits exactly on the orbit; the label floats outside it without
/// moving it — `top: -17px` / `bottom: -17px` from the circle's edge (14 for
/// the far ring), the way the prototype's absolutely positioned label does.
class _SeatFrame extends StatelessWidget {
  final double size;
  final bool far;
  final bool labelAbove;
  final Widget label;
  final Widget child;

  const _SeatFrame({
    required this.size,
    required this.far,
    required this.labelAbove,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gap = far ? 14.0 : 17.0;
    final labelBox = SizedBox(
      width: far ? 84.0 : 96.0,
      // One line of the 11 px name at whatever scale the block ended up with.
      // The old flat 14 fit exactly at 100% and clipped the descenders at
      // anything above it. `MediaQuery` here is already the capped one — the
      // block wraps everything it draws.
      height: MediaQuery.textScalerOf(context).scale(11) * 1.3,
      child: label,
    );

    // The far circle is 40 px by design, which is under the 44 px floor for a
    // touch target. The box grows to 44 while the circle stays 40 and stays
    // centred, so the seat still lands exactly on the orbit.
    //
    // Known limit: the label is positioned outside this box, and a Stack does
    // not hit-test what it paints beyond its own bounds — so the name is read
    // only, and the circle is the tap target. Growing the box to swallow the
    // label would make neighbouring seats overlap and steal each other's taps.
    final box = math.max(size, 44.0);
    final pad = (box - size) / 2;

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          if (labelAbove)
            Positioned(top: pad - gap, child: labelBox)
          else
            Positioned(bottom: pad - gap, child: labelBox),
        ],
      ),
    );
  }
}

/// Progress ring: the score sweeps clockwise from twelve o'clock, the rest is
/// the neutral track.
///
/// Drawn as a band rather than a filled pie with a disc on top. The disc is
/// translucent by design, and over a pie it turned the whole middle of the
/// widget amber-beige instead of the white the handoff asks for.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  /// Band width — `inset: 8px` on a 164 px ring in the handoff.
  static const stroke = 8.0;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    final radius = (size.width - stroke) / 2;
    final band = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x17141E0F); // rgba(20,30,15,.09)
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    canvas.drawArc(
      band,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
