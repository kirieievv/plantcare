/// The "Add plant" tab when the paid tier is closed (SPEC 9, part 1).
///
/// It replaces the four-step flow rather than covering it: there is no step
/// progress here, because there are no steps to come. The screen it replaced
/// was a green banner floating over an empty flow that announced "plant limit
/// reached" no matter why access had actually stopped — which, for someone
/// whose trial had simply run out with one plant in the garden, was untrue.
///
/// Three things it has to do, in this order of importance:
///   1. name the real reason, with the date;
///   2. say what the user still has, because the fear is "I lost my garden";
///   3. offer the way back without hunting for it.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
// `accentSpans` lives with the add-plant flow: the green word in a headline is
// placed by the translation, and both screens split the string the same way.
import 'package:plant_care/screens/add_plant_screen_v4.dart' show accentSpans;
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// Breathing room between the footer and the tab bar.
///
/// Only this — no tab-bar height. The shell runs `extendBody: true` with a
/// `bottomNavigationBar`, and Flutter folds the bar's height into
/// `MediaQuery.padding.bottom` for everything drawn underneath it: inside this
/// tab that value is 127, not the 34 of the home indicator. `SafeArea` already
/// clears the whole menu, so adding a hand-measured 82 on top of it pushed the
/// footer a finger's width into the middle of the card.
const double _kFooterGap = 8;

/// Which plan the user has selected on the screen.
enum _Plan { year, month }

class SubscriptionLockedScreen extends StatefulWidget {
  /// Why the screen is being shown. Drives every piece of copy on it.
  final LockedReason reason;

  /// How many plants the garden holds — quoted back as reassurance.
  final int plantCount;

  final SubscriptionInfo info;

  /// Called when the user buys or restores successfully, so the shell can
  /// re-render into the real flow.
  final VoidCallback? onUnlocked;

  const SubscriptionLockedScreen({
    super.key,
    required this.reason,
    required this.plantCount,
    required this.info,
    this.onUnlocked,
  });

  @override
  State<SubscriptionLockedScreen> createState() =>
      _SubscriptionLockedScreenState();
}

class _SubscriptionLockedScreenState extends State<SubscriptionLockedScreen> {
  _Plan _plan = _Plan.year;
  bool _busy = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String get _localeTag => Localizations.localeOf(context).toLanguageTag();

  /// The date the reason line quotes, already formatted for the locale.
  String? get _endedOn {
    final date = widget.info.accessEndedAt;
    if (date == null) return null;
    // An explicit locale: `intl` silently falls back to en_US otherwise, and
    // the one date on this screen would be the only English thing on it.
    return DateFormat.yMMMd(_localeTag).format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGlassBase,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: BotanlyBackground()),
          Positioned.fill(child: SafeArea(bottom: false, child: _body())),
          // Full-bleed, not inset: the scrim has to reach both edges and carry
          // on to the bottom of the screen, or the list keeps showing through
          // beside the button and under it.
          //
          // The clearance is left to SafeArea, which already knows how tall
          // the shell's menu is (see [_kFooterGap]).
          Positioned(left: 0, right: 0, bottom: 0, child: _footer()),
        ],
      ),
    );
  }

  Widget _body() {
    return ListView(
      // Clears the pinned footer. `padding.bottom` already carries the tab
      // bar (see [_kFooterGap]); the extra covers the button, the restore link
      // and the scrim above them.
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        150 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _header(),
        const _GlassDome(),
        const SizedBox(height: 14),
        _reasonCard(),
        const SizedBox(height: 14),
        _plansCard(),
      ],
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _header() {
    final label = switch (widget.reason) {
      LockedReason.trialEnded => l10n.lockedLabelTrial,
      LockedReason.freeLimit => l10n.lockedLabelLimit,
      LockedReason.subscriptionExpired => l10n.lockedLabelCancelled,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BotanlyGlyph(BotanlySvg.lock, size: 12, color: kGlassMut),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: glassFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 11.5 * 0.09,
                    color: kGlassMut,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: glassFont(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                letterSpacing: 27 * -0.035,
                color: kGlassInk,
              ),
              children: accentSpans(
                l10n.addPlantHeaderPhoto,
                l10n.addPlantHeaderPhotoAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── reason ────────────────────────────────────────────────────────────────

  Widget _reasonCard() {
    final limit = widget.info.plantLimit;
    final date = _endedOn;

    final (String pill, bool warn) = switch (widget.reason) {
      LockedReason.trialEnded => (l10n.lockedPillTrial, true),
      LockedReason.freeLimit => (
        l10n.lockedPillLimit(widget.plantCount, limit),
        false,
      ),
      LockedReason.subscriptionExpired => (l10n.lockedPillCancelled, true),
    };

    final (
      String Function(String) lead,
      String accent,
    ) = switch (widget.reason) {
      LockedReason.trialEnded => (
        l10n.lockedLeadTrial,
        l10n.lockedLeadTrialAccent,
      ),
      LockedReason.freeLimit => (
        l10n.lockedLeadLimit,
        l10n.lockedLeadLimitAccent(limit),
      ),
      LockedReason.subscriptionExpired => (
        l10n.lockedLeadCancelled,
        l10n.lockedLeadCancelledAccent,
      ),
    };

    // The date line is skipped rather than faked when there is no date: an
    // account with no recorded end date should say nothing, not "null".
    final String? sub = switch (widget.reason) {
      LockedReason.trialEnded =>
        date == null ? null : l10n.lockedSubTrial(date),
      LockedReason.freeLimit => l10n.lockedSubLimit,
      LockedReason.subscriptionExpired =>
        date == null ? null : l10n.lockedSubCancelled(date),
    };

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(
            text: pill,
            glyph: warn ? BotanlySvg.clock : BotanlySvg.lock,
            warn: warn,
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: glassFont(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.14,
                letterSpacing: 24 * -0.035,
                color: kGlassInk,
              ),
              children: accentSpans(lead, accent),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: BotanlyGlyph(
                    BotanlySvg.clock,
                    size: 14,
                    color: kGlassMut2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub,
                    style: glassFont(
                      fontSize: 13,
                      height: 1.35,
                      color: kGlassMut,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.info.billingIssue) ...[
            const SizedBox(height: 12),
            _Note(
              title: l10n.billingIssueTitle,
              body: l10n.billingIssueBody,
              glyph: BotanlySvg.warningTriangle,
            ),
          ],
          if (widget.info.hasDuplicateSubscriptions) ...[
            const SizedBox(height: 12),
            _Note(
              title: l10n.duplicateSubscriptionTitle,
              body: l10n.duplicateSubscriptionBody,
              glyph: BotanlySvg.warningTriangle,
            ),
          ],
          _GroupLabel(l10n.lockedKeepTitle),
          _Line(
            glyph: BotanlySvg.leaf,
            tint: kGlassLeafBg,
            color: kGlassGreenText,
            title: l10n.lockedKeepPlants(widget.plantCount),
            body: l10n.lockedKeepPlantsDesc,
          ),
          const SizedBox(height: 8),
          _Line(
            glyph: BotanlySvg.dropOutline,
            tint: kGlassLeafBg,
            color: kGlassGreenText,
            title: l10n.lockedKeepReminders,
            body: l10n.lockedKeepRemindersDesc,
          ),
          _GroupLabel(l10n.lockedUnlockTitle),
          _Line(
            glyph: BotanlySvg.plus,
            tint: kGlassSunBg,
            color: kGlassAttnText,
            title: l10n.lockedUnlockNewPlants,
            body: l10n.lockedUnlockNewPlantsDesc,
          ),
          const SizedBox(height: 8),
          _Line(
            glyph: BotanlySvg.scan,
            tint: kGlassSunBg,
            color: kGlassAttnText,
            title: l10n.lockedUnlockHealth,
            body: l10n.lockedUnlockHealthDesc,
          ),
          const SizedBox(height: 8),
          _Line(
            glyph: BotanlySvg.chat,
            tint: kGlassSunBg,
            color: kGlassAttnText,
            title: l10n.lockedUnlockChat,
            body: l10n.lockedUnlockChatDesc,
          ),
        ],
      ),
    );
  }

  // ── plans ─────────────────────────────────────────────────────────────────

  Widget _plansCard() {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanRow(
            title: l10n.lockedPlanYear,
            note: l10n.lockedPlanYearNote,
            badge: l10n.lockedPlanBadge,
            selected: _plan == _Plan.year,
            onTap: () => setState(() => _plan = _Plan.year),
          ),
          const SizedBox(height: 8),
          _PlanRow(
            title: l10n.lockedPlanMonth,
            note: l10n.lockedPlanMonthNote,
            selected: _plan == _Plan.month,
            onTap: () => setState(() => _plan = _Plan.month),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              l10n.lockedFinePrint,
              style: glassFont(fontSize: 11.5, height: 1.45, color: kGlassMut2),
            ),
          ),
        ],
      ),
    );
  }

  // ── footer ────────────────────────────────────────────────────────────────

  Widget _footer() {
    final planLabel = _plan == _Plan.year
        ? l10n.lockedPlanYear.toLowerCase()
        : l10n.lockedPlanMonth.toLowerCase();
    // "Upgrade" for someone who still has access and just ran out of room;
    // "Resume" for someone whose access stopped. The verb is the difference
    // between an offer and a repair.
    final cta = widget.reason == LockedReason.freeLimit
        ? l10n.lockedCtaUpgrade(planLabel)
        : l10n.lockedCtaResume(planLabel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      // Stretch, not the default centre: without it the scrim shrinks to the
      // width of the button and the list keeps showing through beside it.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A scrim, not a panel. A solid fill was tried and looked worse than
        // the problem: `kGlassBase` is flat, the background behind it is not,
        // and the block of grey between the button and the tab bar read as a
        // hole punched in the screen. Nothing needs hiding down there anyway —
        // the list's bottom padding keeps the content above this point.
        Container(
          width: double.infinity,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00EDF0EC), Color(0xD9EDF0EC)],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xD9EDF0EC),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, _kFooterGap),
              child: Column(
                children: [
                  BotanlyButton(
                    label: cta,
                    glyph: BotanlySvg.lock,
                    loading: _busy,
                    onTap: _busy ? null : _purchase,
                  ),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text(
                        l10n.lockedRestore,
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
      ],
    );
  }

  Future<void> _purchase() async {
    setState(() => _busy = true);
    try {
      final packages = await SubscriptionService().fetchPackages();
      if (packages.isEmpty) {
        if (mounted) _toast(l10n.lockedRestoreNothing);
        return;
      }
      // Match the selected plan by identifier, falling back to the first
      // package rather than guessing by position — store ordering is not ours.
      final wanted = _plan == _Plan.year ? 'annual' : 'monthly';
      final package = packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains(wanted),
        orElse: () => packages.first,
      );
      final ok = await SubscriptionService().purchase(package);
      if (ok && mounted) widget.onUnlocked?.call();
    } catch (e) {
      if (mounted) _toast(_readable(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final restored = await SubscriptionService().restorePurchases();
      if (!mounted) return;
      _toast(restored ? l10n.lockedRestoreDone : l10n.lockedRestoreNothing);
      if (restored) widget.onUnlocked?.call();
    } catch (e) {
      if (mounted) _toast(_readable(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _readable(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pieces
// ─────────────────────────────────────────────────────────────────────────────

/// A sprout under a bell jar: the garden is kept, not lost.
///
/// Deliberately built from gradients, a hairline edge and inner shadows rather
/// than a blur — a `BackdropFilter` nested inside the glass surfaces around it
/// leaves a visible rectangular seam where the two blurs meet.
class _GlassDome extends StatefulWidget {
  const _GlassDome();

  @override
  State<_GlassDome> createState() => _GlassDomeState();
}

class _GlassDomeState extends State<_GlassDome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _pop.forward();
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 16,
            child: Container(
              width: 190,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  colors: [
                    kGlassAccent.withAlpha(51),
                    kGlassAccent.withAlpha(0),
                  ],
                  stops: const [0, 0.72],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.elliptical(84, 91),
                  bottom: Radius.elliptical(77, 67),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x9EFFFFFF),
                    Color(0x3DFFFFFF),
                    Color(0x80FFFFFF),
                  ],
                  stops: [0, 0.46, 1],
                ),
                border: Border.all(color: const Color(0xE6FFFFFF), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF141E0F).withAlpha(64),
                    blurRadius: 40,
                    spreadRadius: -20,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              // The highlight down the left shoulder — what makes it read as
              // glass rather than as a grey circle.
              child: Stack(
                children: [
                  Positioned(
                    left: 30,
                    top: 20,
                    child: Transform.rotate(
                      angle: -0.28,
                      child: Container(
                        width: 34,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xE6FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 78,
            child: BotanlyGlyph(BotanlySvg.leaf, size: 58, color: kGlassAccent),
          ),
          Positioned(
            bottom: 118,
            left: MediaQuery.of(context).size.width / 2 + 24,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(
                CurvedAnimation(
                  parent: _pop,
                  curve: const Cubic(0.2, 1.3, 0.4, 1),
                ),
              ),
              child: FadeTransition(
                opacity: _pop,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xEBFFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: kGlassBorder, width: 0.5),
                    boxShadow: kGlassShadow,
                  ),
                  child: const BotanlyGlyph(
                    BotanlySvg.lock,
                    size: 19,
                    color: kGlassAttnText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final String glyph;
  final bool warn;

  const _Pill({required this.text, required this.glyph, required this.warn});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: warn ? kGlassAttnBg : const Color(0x12141E0F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BotanlyGlyph(
              glyph,
              size: 12,
              color: warn ? kGlassAttnText : kGlassInk2,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                text,
                style: glassFont(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: warn ? kGlassAttnText : kGlassInk2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uppercase section label with the hairline rule running off to the right.
class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: glassFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 11 * 0.09,
              color: kGlassMut2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 0.5, color: const Color(0x1A141E0F)),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String title;
  final String body;

  const _Line({
    required this.glyph,
    required this.tint,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xC7FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xEBFFFFFF), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: BotanlyGlyph(glyph, size: 14, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: glassFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 14 * -0.015,
                    color: kGlassInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: glassFont(
                    fontSize: 12.5,
                    height: 1.4,
                    color: kGlassMut,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber warning inside the reason card — a failing payment or a double
/// subscription. Shown here rather than only in the profile, because this is
/// the screen the user is looking at when they wonder what went wrong.
class _Note extends StatelessWidget {
  final String title;
  final String body;
  final String glyph;

  const _Note({required this.title, required this.body, required this.glyph});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: kGlassAttnBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: BotanlyGlyph(glyph, size: 15, color: kGlassAttnText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: glassFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: kGlassAttnText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: glassFont(
                    fontSize: 12.5,
                    height: 1.4,
                    color: kGlassAttnText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String title;
  final String note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanRow({
    required this.title,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: BotanlyPress(
        scale: 0.985,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? kGlassAccent.withAlpha(26)
                : const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? kGlassAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _Radio(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: glassFont(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 15.5 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: glassFont(fontSize: 12.5, color: kGlassMut),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kGlassAccent.withAlpha(41),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: glassFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kGlassGreenText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;

  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? kGlassAccent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? kGlassAccent : const Color(0x33141E0F),
          width: 1.5,
        ),
      ),
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
