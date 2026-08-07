/// The subscription widget — four states, one card (handoff v4, ORDER stage 5).
///
/// Every string comes from `app_*.arb`, and each state says one thing once: the
/// v3 card repeated its headline in the caption for the expired state and its
/// title in the body for early members, which is what made it read as noise.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/theme/botanly_glass.dart';
import 'package:plant_care/widgets/botanly_kit.dart';

/// One date format across the whole app: "10 авг 2026".
String botanlyDate(BuildContext context, DateTime date) => DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);

class BotanlySubscriptionCard extends StatelessWidget {
  final SubscriptionInfo info;

  /// Opens the management sheet (active / early member) or the paywall.
  final VoidCallback onPrimary;

  const BotanlySubscriptionCard({
    super.key,
    required this.info,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = _view(context, l10n);

    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(
                      label: view.pill,
                      glyph: view.pillGlyph,
                      background: view.pillBg,
                      foreground: view.pillFg,
                    ),
                    const Spacer(),
                    if (view.meta.isNotEmpty)
                      Text(
                        view.meta.toUpperCase(),
                        style: glassFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 11 * 0.1,
                          color: kGlassMut2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (view.days != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${view.days}',
                        style: glassFont(
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 44 * -0.04,
                          height: 1,
                          color: kGlassInk,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          view.daysUnit,
                          style: glassFont(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kGlassMut,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  RichText(
                    text: TextSpan(
                      style: glassFont(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 24 * -0.03,
                        color: kGlassInk,
                      ),
                      children: [
                        TextSpan(text: '${view.heroLead} '),
                        TextSpan(
                          text: view.heroAccent,
                          style: const TextStyle(
                            color: kGlassAccent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    BotanlyGlyph(view.lineGlyph, size: 15, color: kGlassMut),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        view.line,
                        style: glassFont(fontSize: 13, color: kGlassMut),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0x14141E0F)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    view.foot,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: glassFont(fontSize: 12.5, color: kGlassMut),
                  ),
                ),
                const SizedBox(width: 10),
                if (view.ctaFilled)
                  BotanlyButton(label: view.cta, onTap: onPrimary)
                else
                  BotanlyPress(
                    onTap: onPrimary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            view.cta,
                            style: glassFont(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kGlassGreenText,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const BotanlyGlyph(
                            BotanlySvg.chevronRight,
                            size: 14,
                            color: kGlassGreenText,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CardView _view(BuildContext context, AppLocalizations l10n) {
    final expires = info.expiresAt;
    final date = expires == null ? '' : botanlyDate(context, expires);
    final daysLeft = expires == null
        ? null
        : expires.difference(DateTime.now()).inDays.clamp(0, 3650);

    switch (info.status) {
      case SubscriptionStatus.active:
        return _CardView(
          pill: l10n.subPillPremium,
          pillGlyph: BotanlySvg.check,
          pillBg: kGlassLeafBg,
          pillFg: kGlassGreenText,
          meta: l10n.subMetaActivePlan,
          heroLead: l10n.subHeroActiveLead,
          heroAccent: l10n.subHeroActiveAccent,
          lineGlyph: BotanlySvg.clock,
          line: daysLeft == null
              ? l10n.subActiveSubscription
              : l10n.subRenewsInDays(daysLeft, date),
          foot: l10n.subFootAutoRenew,
          cta: l10n.subscriptionManage,
          ctaFilled: false,
        );

      case SubscriptionStatus.trial:
        return _CardView(
          pill: l10n.subPillFreeTrial,
          pillGlyph: BotanlySvg.clock,
          pillBg: kGlassSunBg,
          pillFg: kGlassAttnText,
          meta: '',
          days: info.trialDaysRemaining ?? daysLeft ?? 0,
          daysUnit: l10n.subDaysLeft,
          lineGlyph: BotanlySvg.clock,
          line: date.isEmpty ? l10n.subDaysLeft : l10n.subTrialUntil(date),
          foot: l10n.subFootTrial,
          cta: l10n.subscriptionUpgrade,
          ctaFilled: true,
        );

      case SubscriptionStatus.grandfathered:
        return _CardView(
          pill: l10n.subPillEarlyMember,
          pillGlyph: BotanlySvg.sparkle,
          pillBg: kGlassSunBg,
          pillFg: kGlassAttnText,
          meta: l10n.subMetaNoCharges,
          heroLead: l10n.subHeroForeverLead,
          heroAccent: l10n.subHeroForeverAccent,
          lineGlyph: BotanlySvg.sparkle,
          // The caption carries the whole explanation, so the headline does not
          // have to repeat "early member" a second time.
          line: l10n.subGrantedEarlyMember,
          foot: l10n.subFootForever,
          cta: l10n.subCtaDetails,
          ctaFilled: false,
        );

      case SubscriptionStatus.expired:
        return _CardView(
          pill: l10n.subPillFreePlan,
          pillGlyph: BotanlySvg.close,
          pillBg: const Color(0x12141E0F),
          pillFg: kGlassMut,
          meta: '',
          heroLead: l10n.subHeroEndedLead,
          heroAccent: l10n.subHeroEndedAccent,
          lineGlyph: BotanlySvg.clock,
          line: date.isEmpty ? l10n.subTrialEnded : l10n.subEndedOn(date),
          foot: l10n.subFootFree,
          cta: l10n.subCtaResume,
          ctaFilled: true,
        );
    }
  }
}

class _CardView {
  final String pill;
  final String pillGlyph;
  final Color pillBg;
  final Color pillFg;
  final String meta;
  final String heroLead;
  final String heroAccent;
  final int? days;
  final String daysUnit;
  final String lineGlyph;
  final String line;
  final String foot;
  final String cta;
  final bool ctaFilled;

  const _CardView({
    required this.pill,
    required this.pillGlyph,
    required this.pillBg,
    required this.pillFg,
    required this.meta,
    required this.lineGlyph,
    required this.line,
    required this.foot,
    required this.cta,
    required this.ctaFilled,
    this.heroLead = '',
    this.heroAccent = '',
    this.days,
    this.daysUnit = '',
  });
}

class _Pill extends StatelessWidget {
  final String label;
  final String glyph;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.label,
    required this.glyph,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotanlyGlyph(glyph, size: 13, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: glassFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
