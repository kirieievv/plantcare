/// The "Add plant" tab when every slot is taken (SPEC 11).
///
/// Deliberately *not* the same screen as a lapsed subscription. There the user
/// cannot generate anything at all; here they can — they have simply run out of
/// room. Conflating the two produces the message this replaced, which announced
/// a plant limit to people whose trial had ended with one plant in the garden.
///
/// The screen therefore offers two ways out, not one. Pushing only the paid
/// route when the user has a legitimate way to solve it themselves reads as a
/// squeeze, and it costs nothing: whoever is willing to pay still pays.
library;

import 'package:flutter/material.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/screens/add_plant_screen_v4.dart' show accentSpans;
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// How many cells the bed draws — the premium allowance, always.
///
/// The empty ones are the point: "up to 10" is an abstraction, ten squares with
/// three of them full is not.
const int _kBedCells = 10;

enum _Plan { year, month }

class PlantLimitScreen extends StatefulWidget {
  /// Live plants. Soft-deleted ones hold no slot (SPEC 11, §1.2).
  final int usedSlots;

  final SubscriptionInfo info;

  /// Opens the plant list so the user can remove one.
  final VoidCallback onFreeUpSlot;

  const PlantLimitScreen({
    super.key,
    required this.usedSlots,
    required this.info,
    required this.onFreeUpSlot,
  });

  @override
  State<PlantLimitScreen> createState() => _PlantLimitScreenState();
}

class _PlantLimitScreenState extends State<PlantLimitScreen>
    with SingleTickerProviderStateMixin {
  _Plan _plan = _Plan.year;
  bool _busy = false;

  /// Drives the "here is what opens up" sweep across the empty cells.
  late final AnimationController _sweep;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool get _isPremium =>
      widget.info.status == SubscriptionStatus.active ||
      widget.info.status == SubscriptionStatus.grandfathered;

  int get _limit => widget.info.plantLimit;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  /// Buys the selected plan in place.
  ///
  /// The plans are on this screen, so the purchase happens on this screen.
  /// Pushing the paywall to sell the very same two rows would be a second
  /// screen for a decision the user has already made here.
  Future<void> _purchase() async {
    setState(() => _busy = true);
    try {
      final packages = await SubscriptionService().fetchPackages();
      if (packages.isEmpty) {
        if (mounted) _toast(l10n.lockedRestoreNothing);
        return;
      }
      final wanted = _plan == _Plan.year ? 'annual' : 'monthly';
      final package = packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains(wanted),
        orElse: () => packages.first,
      );
      await SubscriptionService().purchase(package);
      // Nothing to navigate on success: the tab watches the subscription and
      // swaps itself back to the add-plant flow once the slots open up.
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
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
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGlassBase,
      body: Stack(
        children: [
          const Positioned.fill(child: BotanlyBackground()),
          Positioned.fill(child: SafeArea(bottom: false, child: _body())),
          // Nothing to sell to a premium user who is simply full, so the
          // footer — and with it the whole purchase path — is not drawn.
          if (!_isPremium)
            Positioned(left: 0, right: 0, bottom: 0, child: _footer()),
        ],
      ),
    );
  }

  Widget _body() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        (_isPremium ? 24 : 150) + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _header(),
        _bedCard(),
        const SizedBox(height: 14),
        _reasonCard(),
        if (!_isPremium) ...[const SizedBox(height: 14), _plansCard()],
      ],
    );
  }

  Widget _header() {
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
                  l10n.limitLabel.toUpperCase(),
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

  // ── the bed ───────────────────────────────────────────────────────────────

  String get _planLabel {
    if (_isPremium) return l10n.limitPlanPremium;
    return widget.info.rawStatus == SubscriptionStatus.trial
        ? l10n.limitPlanTrial
        : l10n.limitPlanFree;
  }

  Widget _bedCard() {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.usedSlots}',
                style: glassFont(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 30 * -0.04,
                  color: kGlassInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.limitCountOf(_limit),
                  style: glassFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kGlassMut,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kGlassAttnBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _planLabel.toUpperCase(),
                  style: glassFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 11 * 0.05,
                    color: kGlassAttnText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bedGrid(),
          if (!_isPremium) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(filled: true, label: l10n.limitLegendUsed),
                const SizedBox(width: 16),
                _LegendDot(filled: false, label: l10n.limitLegendLocked),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bedGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        const gap = 8.0;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Column(
          children: [
            for (var row = 0; row < _kBedCells ~/ columns; row++) ...[
              if (row > 0) const SizedBox(height: gap),
              Row(
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: gap),
                    _cell(row * columns + col, cell),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cell(int index, double size) {
    final used = index < widget.usedSlots;
    // Everything past the current allowance is what a subscription would open.
    final beyondPlan = index >= _limit;

    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) {
        // Each locked cell lights in turn, 70 ms apart, so the sweep reads as
        // "these open up" rather than as one undifferentiated flash.
        var glow = 0.0;
        if (beyondPlan && _sweep.isAnimating) {
          final start = (index - _limit) * 0.07;
          final t = (_sweep.value - start).clamp(0.0, 1.0);
          glow = t < 0.16 ? t / 0.16 : (1 - (t - 0.16) / 0.84).clamp(0.0, 1.0);
        }

        return Transform.scale(
          scale: 1 + 0.08 * glow,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: used
                  ? kGlassAccent.withAlpha(36)
                  : Color.lerp(
                      const Color(0x8CFFFFFF),
                      kGlassAccent.withAlpha(46),
                      glow,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: used
                    ? kGlassAccent.withAlpha(61)
                    : Color.lerp(const Color(0x2E141E0F), kGlassAccent, glow)!,
                width: used ? 1 : 1.5,
              ),
            ),
            child: used
                ? const BotanlyGlyph(
                    BotanlySvg.leaf,
                    size: 20,
                    color: kGlassAccent,
                  )
                : BotanlyGlyph(
                    BotanlySvg.lock,
                    size: 15,
                    color: Color.lerp(kGlassMut2, kGlassAccent, glow)!,
                  ),
          ),
        );
      },
    );
  }

  // ── reason and the two ways out ───────────────────────────────────────────

  Widget _reasonCard() {
    final (String Function(String) lead, String accent) = _isPremium
        ? (l10n.limitLeadPremium, l10n.limitLeadPremiumAccent)
        : widget.info.rawStatus == SubscriptionStatus.trial
        ? (l10n.limitLeadTrial, l10n.limitLeadTrialAccent)
        : (l10n.limitLeadFree, l10n.limitLeadFreeAccent(_limit));

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 8),
          Text(
            _isPremium ? l10n.limitBodyPremium : l10n.limitBody,
            style: glassFont(fontSize: 13, height: 1.45, color: kGlassMut),
          ),
          const SizedBox(height: 15),
          if (!_isPremium) ...[
            _PathRow(
              glyph: BotanlySvg.trendingUp,
              tint: kGlassLeafBg,
              color: kGlassGreenText,
              title: l10n.limitPathUpgrade,
              body: l10n.limitPathUpgradeDesc,
              // Shows what would open rather than jumping straight to payment:
              // the user asked "why", not "how much".
              onTap: () => _sweep.forward(from: 0),
            ),
            const SizedBox(height: 8),
          ],
          _PathRow(
            glyph: BotanlySvg.leaf,
            tint: kGlassWaterBg,
            color: kGlassBlueText,
            title: l10n.limitPathFree,
            body: l10n.limitPathFreeDesc,
            onTap: widget.onFreeUpSlot,
          ),
        ],
      ),
    );
  }

  // ── plans and footer ──────────────────────────────────────────────────────

  Widget _plansCard() {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              l10n.limitPremiumTitle.toUpperCase(),
              style: glassFont(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 11 * 0.09,
                color: kGlassMut2,
              ),
            ),
          ),
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

  Widget _footer() {
    final planLabel = _plan == _Plan.year
        ? l10n.lockedPlanYear.toLowerCase()
        : l10n.lockedPlanMonth.toLowerCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          // SafeArea alone — inside a tab, `padding.bottom` already carries the
          // floating menu, and adding a measured height on top of it puts the
          // button in the middle of the card.
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  BotanlyButton(
                    label: l10n.limitCtaUpgrade(planLabel),
                    glyph: BotanlySvg.trendingUp,
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final bool filled;
  final String label;

  const _LegendDot({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled
                ? kGlassAccent.withAlpha(36)
                : const Color(0x8CFFFFFF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: filled
                  ? kGlassAccent.withAlpha(61)
                  : const Color(0x2E141E0F),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: glassFont(fontSize: 11.5, color: kGlassMut2)),
      ],
    );
  }
}

class _PathRow extends StatelessWidget {
  final String glyph;
  final Color tint;
  final Color color;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _PathRow({
    required this.glyph,
    required this.tint,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: BotanlyPress(
        scale: 0.99,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xC7FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xEBFFFFFF), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: BotanlyGlyph(glyph, size: 16, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: glassFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 14.5 * -0.015,
                        color: kGlassInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: glassFont(
                        fontSize: 12.5,
                        height: 1.35,
                        color: kGlassMut,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const BotanlyGlyph(
                BotanlySvg.chevronRight,
                size: 15,
                color: kGlassChevron,
              ),
            ],
          ),
        ),
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
              AnimatedContainer(
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
              ),
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
