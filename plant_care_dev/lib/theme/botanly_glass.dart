/// Design tokens and icon set for the "Liquid Glass" surfaces — the plant detail
/// screen and everything presented on top of it (care sheets, health check).
///
/// These started out private to `plant_details_screen.dart`. They live here so a
/// second screen can match the first exactly instead of re-typing hex values;
/// the numbers come straight from the design handoff and should be changed there
/// first, not here.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Typography
//
//  The prototype uses `-apple-system, BlinkMacSystemFont, "SF Pro Text", …`,
//  i.e. the platform font, with a global `letter-spacing: -.01em` on <body>.
//  Set [kUseSystemFont] to false to fall back to the Botanly brand face used
//  by the rest of the app (DM Sans via botanly_theme.dart) — the screens then
//  match the app instead of the prototype.
// ─────────────────────────────────────────────────────────────────────────────

const kUseSystemFont = true;

// `-apple-system` switches optical size at 20 pt: Display above, Text below.
// These are the engine aliases for the platform UI font — measured on device,
// `.SF Pro Display` silently resolves to the Text variant, while
// `CupertinoSystemDisplay` yields the real (tighter) Display cut.
const _kFontDisplay = 'CupertinoSystemDisplay';
const _kFontText = 'CupertinoSystemText';
const _kFontFallback = <String>[
  '.SF Pro Text',
  '.SF UI Text',
  'Helvetica Neue',
  'Roboto', // Android
];

/// Drop-in for the prototype's text styling. [letterSpacing] is absolute px;
/// when omitted it resolves to the `-.01em` inherited from the document body.
TextStyle glassFont({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  double? letterSpacing,
  double? height,
  Color? color,
}) {
  final tracking = letterSpacing ?? fontSize * -0.01;
  if (!kUseSystemFont) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: tracking,
      height: height,
      color: color,
    );
  }
  return TextStyle(
    fontFamily: fontSize >= 20 ? _kFontDisplay : _kFontText,
    fontFamilyFallback: _kFontFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: tracking,
    height: height,
    color: color,
  );
}

// ── Text ────────────────────────────────────────────────────────────────────
const kGlassInk = Color(0xFF12160F); //  --ink   primary text
const kGlassInk2 = Color(0xFF333B2F); //  --ink2  body text
const kGlassMut = Color(0xFF5A6155); //  --mut   labels / secondary
const kGlassMut2 = Color(0xFF6B7266); //  --mut2  meta text
const kGlassChevron = Color(0xFF8B9285); //  row chevrons

// ── Accents ─────────────────────────────────────────────────────────────────
const kGlassAccent = Color(0xFF3E8E3B); //  --accent  green CTA
const kGlassWater = Color(0xFF2E86C8); //  --water   watering / history blue
const kGlassSun = Color(0xFFC7891F); //  --sun     light / warnings
const kGlassWarm = Color(0xFFC65644); //  temperature / destructive

// ── Surfaces ────────────────────────────────────────────────────────────────
const kGlassBase = Color(0xFFEDF0EC); //  neutral base under the glass
const kGlassFill = Color(0x9EFFFFFF); //  rgba(255,255,255,.62)
const kGlassBorder = Color(0xBFFFFFFF); //  rgba(255,255,255,.75)
const kGlassSpecular = Color(
  0xD9FFFFFF,
); //  inset 0 1px 0 rgba(255,255,255,.85)
const kGlassKnob = Color(0xE6FFFFFF); //  --glass-hi  rgba(255,255,255,.9)

const kGlassIssuesFill = Color(0x9EFFFBF0); //  rgba(255,251,240,.62)
const kGlassHistoryFill = Color(0x99F0F7FC); //  rgba(240,247,252,.6)
const kGlassIssuesText = Color(0xFF7C6528);

// ── Category tints ──────────────────────────────────────────────────────────
const kGlassLeafBg = Color(0x213E8E3B); //  rgba(62,142,59,.13)
const kGlassWaterBg = Color(0x212E86C8); //  rgba(46,134,200,.13)
const kGlassSunBg = Color(0x24C7891F); //  rgba(199,137,31,.14)
const kGlassWarmBg = Color(0x21C65644); //  rgba(198,86,68,.13)

// ── Health check result ─────────────────────────────────────────────────────
/// Score-ring and verdict colours for a check that flagged a problem. Deeper
/// than [kGlassWarm] because they sit on glass over a photo, where the lighter
/// warm red drops below the contrast floor the handoff sets.
const kGlassAlert = Color(0xFFB4552F);
const kGlassAlertRing = Color(0xFFD9803F);

/// Amber "needs attention" chip. Text is darkened per the handoff's contrast
/// rule — muted tokens on glass are opaque, never translucent.
const kGlassAttnBg = Color(0x29C7891F); //  rgba(199,137,31,.16)
const kGlassAttnText = Color(0xFF7A5511);

/// Green for *text* on glass. [kGlassAccent] is the fill colour and is too light
/// to read at small sizes over a photo; the handoff caps green text at this.
const kGlassGreenText = Color(0xFF2F6B29);

/// Blue for text on glass, same reasoning as [kGlassGreenText].
const kGlassBlueText = Color(0xFF1F6BA5);

/// Score at or above which a plant reads as healthy. Mirrors the backend rule
/// tying `health_score` to `plant_assistant.status`.
const kHealthyScoreFloor = 75;

/// Icon and tint for a [HealthFinding] category. Unknown keys never reach here —
/// both the backend and `HealthFinding.fromMap` coerce them to `leaves`.
({String glyph, Color fg, Color bg}) glassFindingStyle(String category) {
  switch (category) {
    case 'light':
      return (glyph: BotanlySvg.sun, fg: kGlassSun, bg: kGlassSunBg);
    case 'water':
      return (glyph: BotanlySvg.drop, fg: kGlassWater, bg: kGlassWaterBg);
    case 'soil':
      return (glyph: BotanlySvg.soil, fg: kGlassAccent, bg: kGlassLeafBg);
    case 'pests':
      return (
        glyph: BotanlySvg.warningTriangle,
        fg: kGlassWarm,
        bg: kGlassWarmBg,
      );
    case 'leaves':
    default:
      return (glyph: BotanlySvg.leaf, fg: kGlassAccent, bg: kGlassLeafBg);
  }
}

class BotanlySvg {
  const BotanlySvg._();

  static const _open =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"';
  static const _solid =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="currentColor"';

  static const drop =
      '$_solid><path d="M12 2.6C8.8 7 5.8 10.6 5.8 14a6.2 6.2 0 '
      '0 0 12.4 0c0-3.4-3-7-6.2-11.4z"/></svg>';

  static const dropOutline =
      '$_open stroke-width="1.8"><path d="M12 2.6L5.5 '
      '10.5a6.5 6.5 0 0013 0L12 2.6z"/></svg>';

  static const leaf =
      '$_open stroke-width="1.8"><path d="M5 19c0-9 6-14 '
      '15-14 0 9-6 14-15 14Z"/><path d="M5 19c3-6 7-9 12-10"/></svg>';

  static const gallery =
      '$_open stroke-width="1.8"><rect x="3" y="4" '
      'width="18" height="16" rx="3"/><circle cx="8.5" cy="9.5" r="1.4"/>'
      '<polyline points="20 15 15 10 5 20"/></svg>';

  static const soil =
      '$_open stroke-width="1.8"><path d="M2 18h20M4 18c0-3 '
      '2-5 4-5s3 1.5 4 1.5S14.5 13 16 13s4 2 4 5"/><path d="M12 13V8M12 '
      '8c-1-3-4-4-6-4 0 3 2 5 6 4ZM12 8c1-2.5 3.5-3.5 5.5-3.5 0 2.5-2 '
      '4.5-5.5 3.5Z"/></svg>';

  // ── weather (SPEC 12) ──────────────────────────────────────────────────
  //
  // Four states, matching what the provider's codes collapse to. Colour does
  // the talking in the header, so the shapes stay plain.
  static const cloud =
      '$_open stroke-width="1.9" stroke-linejoin="round"><path d="M7 18h9.5a3.5 '
      '3.5 0 0 0 .3-7 5.5 5.5 0 0 0-10.5 1.4A3.2 3.2 0 0 0 7 18z"/></svg>';

  static const rain =
      '$_open stroke-width="1.9" stroke-linejoin="round"><path d="M7 15h9.5a3.5 '
      '3.5 0 0 0 .3-7 5.5 5.5 0 0 0-10.5 1.4A3.2 3.2 0 0 0 7 15z"/><path '
      'd="M9 19l-.6 1.6M13 19l-.6 1.6M17 19l-.6 1.6"/></svg>';

  static const snowflake =
      '$_open stroke-width="1.9" stroke-linejoin="round"><path d="M12 3v18M4.5 '
      '7.5l15 9M19.5 7.5l-15 9"/></svg>';

  static const sun =
      '$_open stroke-width="1.8"><circle cx="12" cy="12" '
      'r="4.6"/><path d="M12 1.6v2.2M12 20.2v2.2M1.6 12h2.2M20.2 12h2.2M4.6 '
      '4.6l1.6 1.6M17.8 17.8l1.6 1.6M19.4 4.6l-1.6 1.6M6.2 17.8l-1.6 '
      '1.6"/></svg>';

  static const thermometer =
      '$_open stroke-width="1.8"><path d="M14 '
      '14.8V3.6a2.4 2.4 0 00-4.8 0v11.2a4.4 4.4 0 104.8 0z"/></svg>';

  static const fertilizer =
      '$_open stroke-width="1.8"><path d="M12 22V12M12 '
      '12C12 7 17 5 17 5M12 12C12 7 7 5 7 5"/></svg>';

  static const pin =
      '$_open stroke-width="1.8"><path d="M12 21.5s7-6.2 '
      '7-11.2a7 7 0 10-14 0c0 5 7 11.2 7 11.2z"/><circle cx="12" cy="10.3" '
      'r="2.6"/></svg>';

  static const trendingUp =
      '$_open stroke-width="1.8"><polyline points="22 7 '
      '13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>';

  static const warningTriangle =
      '$_open stroke-width="1.8"><path d="M12 '
      '3.2l9 16H3z"/><path d="M12 10v4M12 16.8h.01"/></svg>';

  static const infoCircle =
      '$_open stroke-width="1.8"><circle cx="12" '
      'cy="12" r="9.2"/><path d="M12 7.6v5"/><circle cx="12" cy="16.2" '
      'r=".7" fill="currentColor"/></svg>';

  static const sparkle =
      '$_solid><path d="M12 2l1.8 6.2L20 10l-6.2 1.8L12 '
      '18l-1.8-6.2L4 10l6.2-1.8z"/></svg>';

  static const chevronRight =
      '$_open stroke-width="2.4"><polyline points="9 6 15 12 9 18"/></svg>';

  static const chevronLeft =
      '$_open stroke-width="2.2"><polyline points="15 18 9 12 15 6"/></svg>';

  static const chat =
      '$_open stroke-width="2"><path d="M21 12a8.5 8.5 0 '
      '01-8.5 8.5H5l-2 2V12A8.5 8.5 0 0111.5 3.5h1A8.5 8.5 0 0121 12z"/></svg>';

  static const more =
      '$_solid><circle cx="12" cy="5" r="1.5"/><circle '
      'cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>';

  static const plus =
      '$_open stroke-width="2.2"><path d="M12 5.5v13M5.5 '
      '12h13"/></svg>';

  static const trash =
      '$_open stroke-width="1.8"><polyline points="3.5 6.5 '
      '5.5 6.5 20.5 6.5"/><path d="M8.5 6.5V4.6a2 2 0 012-2h3a2 2 0 012 '
      '2v1.9m2.6 0-1 13.4a2 2 0 01-2 1.9H9a2 2 0 01-2-1.9L6 6.5"/></svg>';

  static const check =
      '$_open stroke-width="2.6"><path d="M4 12.5l5 5L20 6.5"/></svg>';

  static const close =
      '$_open stroke-width="2.4"><path d="M6 6l12 12M18 6 6 18"/></svg>';

  static const clock =
      '$_open stroke-width="1.8"><circle cx="12" cy="12" '
      'r="9.2"/><path d="M12 6.8V12l4 2.4"/></svg>';

  static const edit =
      '$_open stroke-width="1.8"><path d="M4 20h4l10-10a2.8 '
      '2.8 0 00-4-4L4 16v4z"/><path d="M13.5 6.5l4 4"/></svg>';

  static const flower =
      '$_open stroke-width="1.8"><circle cx="12" cy="12" '
      'r="2.6"/><path d="M12 9.4C12 6 10 4 12 4s0 2 0 5.4M12 14.6c0 3.4 2 '
      '5.4 0 5.4s0-2 0-5.4M9.4 12C6 12 4 14 4 12s2 0 5.4 0M14.6 12c3.4 0 '
      '5.4-2 5.4 0s-2 0-5.4 0"/></svg>';

  /// Head and shoulders — the avatar button in the home header.
  static const profile =
      '$_open stroke-width="1.8"><circle cx="12" cy="8" '
      'r="3.5"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>';

  /// Magnifier over a leaf — the "analyze health" entry point.
  static const scan =
      '$_open stroke-width="1.8"><circle cx="11" cy="11" '
      'r="7.2"/><path d="M16.4 16.4L21 21"/><path d="M8.4 13.2c0-3.4 2.2-5.2 '
      '5.6-5.2 0 3.4-2.2 5.2-5.6 5.2Z"/></svg>';

  /// Circular arrow — reload the garden.
  static const refresh =
      '$_open stroke-width="2"><path d="M20 11a8 8 0 '
      '10-2.3 5.7"/><path d="M20 4v7h-7"/></svg>';

  /// Two-lobed leaf — the name field on the edit screen.
  static const leafPair =
      '$_open stroke-width="1.9"><path d="M12 22V12m0 '
      '0C12 7 16 3 21 3c0 6-4 9-9 9zm0 0C12 7 8 3 3 3c0 6 4 9 9 9z"/></svg>';

  /// Arrow out of a tray — "change photo".
  static const upload =
      '$_open stroke-width="1.9"><path d="M12 16V4M8 8l4-4 '
      '4 4"/><path d="M4 15v3a2 2 0 002 2h12a2 2 0 002-2v-3"/></svg>';

  /// Curved arrow back to start — "restore previous photo".
  static const revert =
      '$_open stroke-width="2"><path d="M4 10h7a5 5 0 '
      '11-5 5"/><path d="M4 6v4h4"/></svg>';

  /// Closed padlock — marks an AI-owned, read-only value.
  static const lock =
      '$_open stroke-width="2"><rect x="5" y="10.5" '
      'width="14" height="10" rx="3"/><path d="M8.5 10.5V8a3.5 3.5 0 017 '
      '0v2.5"/></svg>';

  /// Floppy disk — the save CTA.
  static const floppy =
      '$_open stroke-width="2"><path d="M5 4h11l3 '
      '3v13H5z"/><path d="M8.5 4v5h7V4M8.5 20v-6h7v6"/></svg>';

  /// Small sun with rays — the species row on the edit screen.
  static const speciesSun =
      '$_open stroke-width="1.9"><circle cx="12" '
      'cy="12" r="2.6"/><path d="M12 4.2V6M12 18v1.8M4.2 12H6M18 12h1.8M6.8 '
      '6.8 8 8M16 16l1.2 1.2M17.2 6.8 16 8M8 16l-1.2 1.2"/></svg>';

  /// Lightbulb — advice banner and the upload-step hint.
  static const bulb =
      '$_open stroke-width="1.8"><path d="M9.2 17.4h5.6M10 '
      '20.4h4"/><path d="M12 2.8a6.2 6.2 0 00-3.6 11.3v1.1h7.2v-1.1A6.2 6.2 '
      '0 0012 2.8z"/></svg>';
}

/// Renders one of the [BotanlySvg] paths at [size], recoloured to [color].
class BotanlyGlyph extends StatelessWidget {
  final String svg;
  final double size;
  final Color color;

  const BotanlyGlyph(
    this.svg, {
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// `saturate(180%)` as a colour matrix.
///
/// Every glass surface in the prototype is `blur(N) saturate(180%)`. The
/// saturation is not decoration: it is what keeps the greens and ambers of the
/// background alive through the glass. Without it the same fill reads grey and
/// the card looks a shade darker than the design.
const kGlassSaturate180 = ColorFilter.matrix(<double>[
  1.6296, -0.5720, -0.0576, 0, 0, //
  -0.1704, 1.2280, -0.0576, 0, 0, //
  -0.1704, -0.5720, 1.7424, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// A CSS `backdrop-filter: blur(cssBlur) saturate(180%)`.
///
/// CSS blur radius N maps to a Gaussian sigma of N/2, and `ColorFilter` is
/// itself an `ImageFilter`, so the two compose.
ImageFilter glassFrost(double cssBlur) => ImageFilter.compose(
  outer: kGlassSaturate180,
  inner: ImageFilter.blur(sigmaX: cssBlur / 2, sigmaY: cssBlur / 2),
);

/// The glass primitive (DESIGN-SYSTEM §2).
///
/// One surface for every floating thing: same fill, same border, same shadow.
/// The different look from screen to screen is the blur working against a
/// different background, not a different token — so this is the only place
/// those numbers are allowed to live.
class GlassSurface extends StatelessWidget {
  /// 26 for cards and rows, 18 for round buttons, 34-40 for sheets. CSS blur
  /// radius is roughly twice a Gaussian sigma, hence the halving.
  final double blur;
  final double radius;
  final Color fill;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;
  final Widget child;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 26,
    this.radius = 26,
    this.fill = kGlassFill,
    this.padding,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final circle = shape == BoxShape.circle;
    final border = BorderRadius.circular(circle ? 999 : radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: circle ? null : border,
        shape: shape,
        boxShadow: kGlassShadow,
      ),
      child: ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: glassFrost(blur),
          child: Stack(
            children: [
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: circle ? null : border,
                  shape: shape,
                  border: Border.all(color: kGlassBorder, width: 0.5),
                ),
                child: child,
              ),
              // `inset 0 1px 0 rgba(255,255,255,.85)` — the bright lip along the
              // top edge. Flutter has no inset shadow, so it is a hairline
              // inside the clip, which the rounding tapers at the corners.
              //
              // It sits outside the padded container on purpose: nested inside,
              // it landed a padding's worth below the edge and drew a white line
              // straight across the card.
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: IgnorePointer(child: ColoredBox(color: kGlassSpecular)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The handoff's `.sk` loading placeholder.
///
/// A white band sweeping over a dark-tinted pill: `rgba(20,30,15,.07)` under
/// `linear-gradient(90deg, rgba(255,255,255,.35), rgba(255,255,255,.85) 45%,
/// rgba(255,255,255,.35) 90%)`, 180 px wide, 1.15 s linear, forever.
///
/// It exists so a screen can hold its shape while the data is still in flight —
/// the alternative is rendering a number that is not yet true.
class GlassSkeleton extends StatefulWidget {
  /// Null stretches to the parent's width.
  final double? width;
  final double height;
  final double radius;

  const GlassSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 999,
  });

  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}

class _GlassSkeletonState extends State<GlassSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (_, __) => CustomPaint(
          painter: _SkeletonPainter(t: _sweep.value, radius: widget.radius),
          size: Size(widget.width ?? double.infinity, widget.height),
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final double t;
  final double radius;

  const _SkeletonPainter({required this.t, required this.radius});

  static const _band = 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x12141E0F), // rgba(20,30,15,.07)
    );

    // `background-position: -180px → 180px` on a 180 px band, so the highlight
    // enters from the left and leaves past the right edge.
    final start = -_band + t * (size.width + 2 * _band);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.45, 0.9],
          colors: [Color(0x59FFFFFF), Color(0xD9FFFFFF), Color(0x59FFFFFF)],
        ).createShader(Rect.fromLTWH(start, 0, _band, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.t != t || old.radius != radius;
}

/// `0 8px 30px -8px rgba(20,30,15,.18)` plus `0 2px 8px -2px rgba(20,30,15,.10)`.
const kGlassShadow = [
  BoxShadow(
    color: Color(0x2E141E0F),
    blurRadius: 30,
    spreadRadius: -8,
    offset: Offset(0, 8),
  ),
  BoxShadow(
    color: Color(0x1A141E0F),
    blurRadius: 8,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
];
