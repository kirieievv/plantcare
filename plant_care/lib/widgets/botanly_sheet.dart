/// The inset glass bottom sheet used across Botanly.
///
/// Care details, tasks and anything else that slides up share this chrome: 8 px
/// insets, radius 34, `rgba(252,253,251,.82)` over `blur(40px)`, max-height 76%,
/// its own blurred scrim, and a drag-to-dismiss grabber. It lives here rather
/// than on a screen because the same sheet opens from the plant screen, the task
/// deck and the all-tasks screen, and three copies would drift apart.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/theme/botanly_glass.dart';

/// 420 ms rise, matching the handoff's `cubic-bezier(.22,1,.36,1)`.
const kBotanlySheetCurve = Cubic(0.22, 1.0, 0.36, 1.0);

/// Route for [BotanlySheet].
///
/// A `PopupRoute` rather than `showModalBottomSheet`: the scrim has to fade in
/// place while only the sheet rises, and `barrierColor` cannot carry a blur.
class BotanlySheetRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;

  BotanlySheetRoute({required this.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  bool get barrierDismissible => false; // the scrim handles its own taps

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  // The page goes straight into the Overlay, so it needs a Material of its own
  // to supply a DefaultTextStyle — without one, text inherits WidgetsApp's debug
  // error style and picks up its yellow double underline.
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Material(type: MaterialType.transparency, child: builder(context));
}

Future<T?> showBotanlySheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  HapticFeedback.lightImpact();
  return Navigator.of(context).push(BotanlySheetRoute<T>(builder: builder));
}

/// Header slot: 44 px glyph tile, title, and an optional pill under it.
class BotanlySheetHeader {
  final String glyph;
  final Color tint;
  final Color foreground;
  final String title;

  /// Pill under the title. Empty text hides it.
  final String badgeText;
  final Color? badgeBg;
  final Color? badgeFg;

  const BotanlySheetHeader({
    required this.glyph,
    required this.tint,
    required this.foreground,
    required this.title,
    this.badgeText = '',
    this.badgeBg,
    this.badgeFg,
  });
}

/// Enter: translateY(70px) + opacity 0 → 1 over 420 ms, scrim fading over the
/// first 300 ms. Dismisses on scrim tap, the close button, or a downward drag on
/// the grabber past 90 px.
class BotanlySheet extends StatefulWidget {
  final BotanlySheetHeader header;

  /// Scrolling body.
  final List<Widget> children;

  /// Pinned under the body — buttons that must stay reachable while the body
  /// scrolls, e.g. "Done" and "Later" on a task.
  final Widget? footer;

  const BotanlySheet({
    super.key,
    required this.header,
    required this.children,
    this.footer,
  });

  @override
  State<BotanlySheet> createState() => _BotanlySheetState();
}

class _BotanlySheetState extends State<BotanlySheet>
    with SingleTickerProviderStateMixin {
  static const _dismissThreshold = 90.0;

  late final AnimationController _snapBack;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => setState(() {}));
  }

  double _drag = 0;
  double _dragAtRelease = 0;

  @override
  void dispose() {
    _snapBack.dispose();
    super.dispose();
  }

  double get _dragOffset => _snapBack.isAnimating
      ? _dragAtRelease * (1 - Curves.easeOut.transform(_snapBack.value))
      : _drag;

  void _onDragUpdate(DragUpdateDetails d) {
    _snapBack.stop();
    setState(() => _drag = math.max(0, _drag + d.delta.dy));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_drag > _dismissThreshold || d.velocity.pixelsPerSecond.dy > 700) {
      Navigator.of(context).pop();
      return;
    }
    _dragAtRelease = _drag;
    _drag = 0;
    _snapBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final animation = ModalRoute.of(context)?.animation;

    return AnimatedBuilder(
      animation: animation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, _) {
        final raw = animation?.value ?? 1.0;
        final rise = kBotanlySheetCurve
            .transform(raw.clamp(0.0, 1.0))
            .clamp(0.0, 1.0);
        // Scrim fades over 300 ms of the 420 ms enter.
        final scrimT = Curves.easeOut.transform((raw / 0.71).clamp(0.0, 1.0));

        return Stack(
          children: [
            // Scrim: rgba(18,24,14,.28) + blur(6px) → sigma 3. Tap to dismiss.
            Positioned.fill(
              child: Opacity(
                opacity: scrimT,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: const ColoredBox(color: Color(0x4712180E)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8 + media.padding.bottom,
              child: Transform.translate(
                offset: Offset(0, 70 * (1 - rise) + _dragOffset),
                child: Opacity(opacity: rise, child: _sheet(media)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheet(MediaQueryData media) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.76),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(34)),
          boxShadow: [
            BoxShadow(
              color: Color(0x6614200F),
              blurRadius: 50,
              spreadRadius: -18,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(34)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // blur(40px)
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xD1FCFDFB), // rgba(252,253,251,.82)
                borderRadius: const BorderRadius.all(Radius.circular(34)),
                border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber and header are the drag handle; the body keeps its
                  // own scrolling.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 5,
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0x29141E0F,
                            ), // rgba(20,30,15,.16)
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        _header(context),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        widget.footer == null ? 24 : 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children,
                      ),
                    ),
                  ),
                  if (widget.footer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: widget.footer!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // gap 13 · 44×44 tile radius 16 icon 21 · title 21/600/-.03em
  // · value pill 12/600 · 32 px close button rgba(20,30,15,.07)
  Widget _header(BuildContext context) {
    final h = widget.header;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: h.tint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xB3FFFFFF), width: 0.5),
            ),
            child: Center(
              child: BotanlyGlyph(h.glyph, size: 21, color: h.foreground),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.title,
                  style: glassFont(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 21 * -0.03,
                    color: kGlassInk,
                  ),
                ),
                if (h.badgeText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: h.badgeBg ?? h.tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      h.badgeText,
                      style: glassFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: h.badgeFg ?? h.foreground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0x12141E0F), // rgba(20,30,15,.07)
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: BotanlyGlyph(BotanlySvg.close, size: 14, color: kGlassMut),
          ),
        ),
      ),
    );
  }
}

/// Up to three equal cells: caption 10/600 uppercase over value 14.5/600.
class BotanlySheetKeyValues extends StatelessWidget {
  final List<(String, String)> pairs;

  const BotanlySheetKeyValues(this.pairs, {super.key});

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      // IntrinsicHeight, because the cells must be equal height and `stretch`
      // alone asks for infinite height inside the sheet's scroll view. Cheap
      // here: at most three short cells.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pairs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3FFFFFF), // rgba(255,255,255,.7)
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xE6FFFFFF),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pairs[i].$1.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: glassFont(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 10 * 0.06,
                          color: kGlassMut,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pairs[i].$2,
                        textAlign: TextAlign.center,
                        style: glassFont(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: kGlassInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Ask assistant" row — the one way into the chat from inside a sheet.
class BotanlyAskRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const BotanlyAskRow({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: kGlassAccent.withAlpha(28), // rgba(62,142,59,.11)
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kGlassAccent.withAlpha(66), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGlassAccent.withAlpha(41), // .16
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const BotanlyGlyph(
                  BotanlySvg.chat,
                  size: 15,
                  color: kGlassGreenText,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: glassFont(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 15.5 * -0.015,
                    color: kGlassGreenText,
                  ),
                ),
              ),
              BotanlyGlyph(
                BotanlySvg.chevronRight,
                size: 15,
                color: kGlassGreenText.withAlpha(140),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
