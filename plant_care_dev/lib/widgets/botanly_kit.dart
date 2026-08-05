/// Shared components of the Liquid Glass language (handoff v4, ORDER stage 0).
///
/// The four screens built on top of this — add plant, my plants, profile,
/// settings — are supposed to look like one app, which only holds if the chip,
/// the switch, the field and the toast exist once. Values come from the CSS in
/// `screens/*.html`; change them there first.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plant_care/theme/botanly_glass.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Background
// ─────────────────────────────────────────────────────────────────────────────

/// The universal screen background (ORDER stage 0.3).
///
/// Base #EDF0EC, three corner washes and three blurred blobs drifting over
/// 20-28 s. Every screen uses it except the plant screen, whose background is
/// the plant's own photo. No single plant's photo belongs here — there are many.
class BotanlyBackground extends StatefulWidget {
  const BotanlyBackground({super.key});

  @override
  State<BotanlyBackground> createState() => _BotanlyBackgroundState();
}

class _BotanlyBackgroundState extends State<BotanlyBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _drifts;

  @override
  void initState() {
    super.initState();
    _drifts = [
      for (final seconds in [20, 24, 28])
        AnimationController(vsync: this, duration: Duration(seconds: seconds))
          ..repeat(reverse: true),
    ];
  }

  @override
  void dispose() {
    for (final c in _drifts) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFEDF0EC),
        gradient: RadialGradient(
          center: Alignment(-0.76, -1.16),
          radius: 1.2,
          colors: [Color(0x333E8E3B), Color(0x003E8E3B)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.92, -0.96),
                  radius: 0.9,
                  colors: [Color(0x26C7891F), Color(0x00C7891F)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 1.12),
                  radius: 1.2,
                  colors: [Color(0x1F2E86C8), Color(0x002E86C8)],
                ),
              ),
            ),
          ),
          _blob(
            controller: _drifts[0],
            size: 250,
            left: -70,
            top: -50,
            color: kGlassAccent.withAlpha(107),
            travel: const Offset(36, 50),
            scaleTo: 1.14,
          ),
          _blob(
            controller: _drifts[1],
            size: 190,
            right: -60,
            top: 60,
            color: kGlassSun.withAlpha(82),
            travel: const Offset(-44, 36),
            scaleFrom: 1.08,
            scaleTo: 0.94,
          ),
          _blob(
            controller: _drifts[2],
            size: 240,
            left: 60,
            top: 300,
            color: kGlassWater.withAlpha(51),
            travel: const Offset(26, -44),
            scaleTo: 1.16,
          ),
        ],
      ),
    );
  }

  Widget _blob({
    required AnimationController controller,
    required double size,
    required Color color,
    required Offset travel,
    double? left,
    double? right,
    double? top,
    double scaleFrom = 1,
    double scaleTo = 1,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(controller.value);
        return Positioned(
          left: left,
          right: right,
          top: top,
          child: Transform.translate(
            offset: Offset(travel.dx * t, travel.dy * t),
            child: Transform.scale(
              scale: scaleFrom + (scaleTo - scaleFrom) * t,
              child: _BlurredCircle(size: size, color: color),
            ),
          ),
        );
      },
    );
  }
}

/// A soft blob. Painted as a radial gradient rather than a blurred circle: a
/// `BackdropFilter` here would blur the entire scrolling list behind it.
class _BlurredCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurredCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          stops: const [0.35, 1],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Press feedback — `transform: scale(.97…985)` over 140 ms, everywhere.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlyPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const BotanlyPress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  @override
  State<BotanlyPress> createState() => _BotanlyPressState();
}

class _BotanlyPressState extends State<BotanlyPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Buttons — `.btn` 18 radius, 15.5/600. Primary is filled and lifted.
// ─────────────────────────────────────────────────────────────────────────────

enum BotanlyButtonKind { primary, ghost, destructive }

class BotanlyButton extends StatelessWidget {
  final String label;
  final String? glyph;
  final BotanlyButtonKind kind;
  final VoidCallback? onTap;
  final bool loading;

  const BotanlyButton({
    super.key,
    required this.label,
    this.glyph,
    this.kind = BotanlyButtonKind.primary,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;

    final (Color bg, Color fg) = switch (kind) {
      BotanlyButtonKind.primary => (kGlassAccent, Colors.white),
      BotanlyButtonKind.ghost => (const Color(0x0F141E0F), kGlassInk2),
      BotanlyButtonKind.destructive => (kGlassWarm, Colors.white),
    };

    return BotanlyPress(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        // Disabled is dimmed rather than greyed: the button keeps its shape, so
        // the eye does not have to re-find it when it becomes available.
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kind == BotanlyButtonKind.primary && enabled
                ? [
                    BoxShadow(
                      color: kGlassAccent.withAlpha(204),
                      blurRadius: 22,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 9),
              ] else if (glyph != null) ...[
                BotanlyGlyph(glyph!, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glassFont(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Filter chip — `.chip`, with an optional count. Filled green when on.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlyChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const BotanlyChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? kGlassAccent : kGlassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.transparent : kGlassBorder,
          width: 0.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: kGlassAccent.withAlpha(204),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: glassFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : kGlassInk2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(56)
                    : const Color(0x12141E0F),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: glassFont(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kGlassMut2,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return BotanlyPress(
      scale: 0.97,
      onTap: onTap,
      // The visual is short; the row it lives in is 44 tall so the target is too.
      child: SizedBox(height: 44, child: Center(child: content)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Switch — `.sw` 50×30, knob 24 with a 3 px inset.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const BotanlySwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        // 50×30 visual inside a 44-tall target.
        child: SizedBox(
          width: 50,
          height: 44,
          child: Center(
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 30,
                decoration: BoxDecoration(
                  color: value ? kGlassAccent : const Color(0x24141E0F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33141E0F),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Text field — `.inp`: near-opaque white on glass, green focus ring.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlyField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? glyph;
  final bool obscure;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final int maxLines;
  final String? errorText;

  const BotanlyField({
    super.key,
    required this.controller,
    required this.hint,
    this.glyph,
    this.obscure = false,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
    this.trailing,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  State<BotanlyField> createState() => _BotanlyFieldState();
}

class _BotanlyFieldState extends State<BotanlyField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final error = widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xDBFFFFFF), // rgba(255,255,255,.86)
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: error != null
                  ? kGlassWarm.withAlpha(115)
                  : (focused ? kGlassAccent.withAlpha(115) : const Color(0xF2FFFFFF)),
              width: 0.5,
            ),
            boxShadow: focused && error == null
                ? [
                    BoxShadow(
                      color: kGlassAccent.withAlpha(31),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.glyph != null) ...[
                BotanlyGlyph(
                  widget.glyph!,
                  size: 17,
                  color: kGlassAccent.withAlpha(153),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscure,
                  maxLines: widget.maxLines,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  cursorColor: kGlassAccent,
                  style: glassFont(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: kGlassInk,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    // The app theme fills its inputs and gives them an outline
                    // for every state. Clearing `border` alone left those state
                    // borders in place, so the glass field drew a second frame
                    // inside itself.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: widget.hint,
                    hintStyle: glassFont(fontSize: 15.5, color: kGlassMut2),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Text(
              error,
              style: glassFont(fontSize: 12.5, color: kGlassAlert),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Glass list row — `.row`: 44 icon tile, title, subtitle, chevron.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlyListRow extends StatelessWidget {
  final String glyph;
  final Color glyphColor;
  final Color glyphBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BotanlyListRow({
    super.key,
    required this.glyph,
    required this.title,
    this.glyphColor = kGlassAccent,
    this.glyphBg = kGlassLeafBg,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BotanlyPress(
      scale: 0.985,
      onTap: onTap,
      child: GlassSurface(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: glyphBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x99FFFFFF), width: 0.5),
              ),
              child: BotanlyGlyph(glyph, size: 21, color: glyphColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glassFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.015,
                      color: kGlassInk,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: glassFont(fontSize: 13, color: kGlassMut),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const BotanlyGlyph(
                        BotanlySvg.chevronRight,
                        size: 15,
                        color: kGlassChevron,
                      )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section label — `.sec h2`, 11.5/700 uppercase with .1em tracking.
// ─────────────────────────────────────────────────────────────────────────────

class BotanlySectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const BotanlySectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: glassFont(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 11.5 * 0.1,
                color: kGlassMut,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Toast — `.toast`: dark glass above the tab bar, auto-dismissing.
// ─────────────────────────────────────────────────────────────────────────────

/// Replaces SnackBar app-wide (v4 §6 of the settings stage). Sits above the tab
/// bar rather than under it, which is where a SnackBar lands once the bar
/// floats.
void showBotanlyToast(
  BuildContext context,
  String message, {
  bool success = true,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      success: success,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  final String message;
  final bool success;
  final VoidCallback onDone;

  const _Toast({
    required this.message,
    required this.success,
    required this.onDone,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 86 + MediaQuery.of(context).padding.bottom,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(
          opacity: _c.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - _c.value)),
            child: child,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xEB1C2C1A), // rgba(28,44,26,.92)
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                BotanlyGlyph(
                  widget.success ? BotanlySvg.check : BotanlySvg.warningTriangle,
                  size: 17,
                  color: widget.success
                      ? const Color(0xFF8BE89F)
                      : const Color(0xFFF0B4A6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: glassFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFEAF3E8),
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
}
