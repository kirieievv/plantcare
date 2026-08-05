/// What the app does at a paid door when the subscription is gone (SPEC 10).
///
/// The rule the whole feature rests on: **everything already generated stays.**
/// Plants, check history, care cards, the watering schedule — all of it was
/// paid for by the trial, and taking it back punishes someone for not buying
/// immediately. Only *new* AI calls are closed, and there are exactly three of
/// them in the app: adding a plant, the health check, the assistant chat.
///
/// So this file does not hide buttons. A control that vanishes reads as a bug;
/// a control with a padlock reads as a rule. The lock explains, the sheet says
/// what is still there, and the way back is one tap away.
library;

import 'package:flutter/material.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/screens/add_plant_screen_v4.dart' show accentSpans;
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// Which paid door the user just knocked on. Only changes the sheet's title.
enum GateAction { healthCheck, chat }

/// The padlock badge that marks a paid control (SPEC 4, `.lk`).
///
/// Sits in the corner of the control it belongs to rather than replacing it,
/// so the button keeps its place and its meaning.
class GateLockBadge extends StatelessWidget {
  final double size;

  const GateLockBadge({super.key, this.size = 17});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1F141E0F), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141E0F).withAlpha(64),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BotanlyGlyph(
        BotanlySvg.lock,
        size: size * 0.53,
        color: kGlassAttnText,
      ),
    );
  }
}

/// Wraps a paid control so it carries the padlock without moving.
class GateLocked extends StatelessWidget {
  final Widget child;
  final bool locked;

  /// Dims the control. Off for controls that are already faint.
  final bool dim;

  const GateLocked({
    super.key,
    required this.child,
    required this.locked,
    this.dim = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: dim ? 0.55 : 1, child: child),
        const Positioned(top: -2, right: -2, child: GateLockBadge()),
      ],
    );
  }
}

/// The sheet shown when a locked control is tapped.
///
/// Deliberately reassuring before it is commercial: the first thing a user
/// fears is that the garden is gone, so the two "still works" lines come before
/// the call to action.
Future<bool> showSubscriptionGate(
  BuildContext context, {
  required GateAction action,
  required VoidCallback onResume,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _GateSheet(action: action, onResume: onResume),
  );
  return result ?? false;
}

class _GateSheet extends StatelessWidget {
  final GateAction action;
  final VoidCallback onResume;

  const _GateSheet({required this.action, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = action == GateAction.healthCheck
        ? l10n.gateSheetHealth
        : l10n.gateSheetChat;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: ColoredBox(
            color: const Color(0xD1FCFDFB),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The grab handle every other sheet on the plant screen has —
                  // this one must not feel like a different kind of thing.
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x26141E0F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _MiniDome(),
                  const SizedBox(height: 14),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: glassFont(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                        letterSpacing: 21 * -0.03,
                        color: kGlassInk,
                      ),
                      children: accentSpans(title, l10n.gateSheetAccent),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    l10n.gateSheetBody,
                    textAlign: TextAlign.center,
                    style: glassFont(
                      fontSize: 13,
                      height: 1.45,
                      color: kGlassMut,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _KeepLine(text: l10n.gateSheetKeepWatering),
                  const SizedBox(height: 8),
                  _KeepLine(text: l10n.gateSheetKeepHistory),
                  const SizedBox(height: 16),
                  BotanlyButton(
                    label: l10n.gateSheetCta,
                    glyph: BotanlySvg.lock,
                    onTap: () {
                      Navigator.of(context).pop(true);
                      onResume();
                    },
                  ),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        l10n.gateSheetLater,
                        style: glassFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: kGlassMut,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bell jar from the locked screen, at a tenth of the drama.
///
/// No `BackdropFilter` here either: nested blurs leave a rectangular seam where
/// they meet, and this sits inside a blurred sheet.
class _MiniDome extends StatelessWidget {
  const _MiniDome();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.elliptical(50, 54),
                    bottom: Radius.elliptical(46, 40),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xB3FFFFFF),
                      Color(0x4DFFFFFF),
                      Color(0x8CFFFFFF),
                    ],
                    stops: [0, 0.46, 1],
                  ),
                  border: Border.all(
                    color: const Color(0xF2FFFFFF),
                    width: 0.5,
                  ),
                ),
              ),
              const BotanlyGlyph(
                BotanlySvg.leaf,
                size: 38,
                color: kGlassAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeepLine extends StatelessWidget {
  final String text;

  const _KeepLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kGlassLeafBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const BotanlyGlyph(
            BotanlySvg.check,
            size: 13,
            color: kGlassGreenText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: glassFont(fontSize: 12.5, height: 1.4, color: kGlassInk2),
          ),
        ),
      ],
    );
  }
}
