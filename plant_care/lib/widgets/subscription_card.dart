import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';
import '../theme/botanly_theme.dart';

/// Card displayed in ProfileScreen showing subscription status.
class SubscriptionCard extends StatelessWidget {
  final SubscriptionInfo info;

  const SubscriptionCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _gradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BotanlyColors.sage.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(l10n),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (info.isTrial && info.trialDaysRemaining != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.subscriptionTrialDaysLeft(info.trialDaysRemaining!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildMetric(
                  l10n,
                  icon: Icons.local_florist_rounded,
                  label: l10n.labelPlants,
                  value: '${info.plantLimit == 0 ? "—" : info.plantLimit}',
                ),
                const SizedBox(width: 20),
                if (info.isTrial && info.trialExpiresAt != null)
                  _buildMetric(
                    l10n,
                    icon: Icons.calendar_today_rounded,
                    label: l10n.labelEnds,
                    value: formatSubDate(info.trialExpiresAt!),
                  ),
                if (info.isActive && info.expiresAt != null)
                  _buildMetric(
                    l10n,
                    icon: Icons.calendar_today_rounded,
                    label: l10n.labelRenews,
                    value: formatSubDate(info.expiresAt!),
                  ),
                const Spacer(),
                _actionButton(context, l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon() {
    IconData icon;
    switch (info.status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.grandfathered:
        icon = Icons.verified_rounded;
      case SubscriptionStatus.trial:
        icon = Icons.timer_rounded;
      case SubscriptionStatus.expired:
        icon = Icons.lock_outline_rounded;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  LinearGradient _gradient() {
    switch (info.status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.grandfathered:
        return const LinearGradient(
          colors: [BotanlyColors.sageDark, BotanlyColors.sage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SubscriptionStatus.trial:
        return const LinearGradient(
          colors: [Color(0xFF3A7D44), Color(0xFF57A85A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SubscriptionStatus.expired:
        return const LinearGradient(
          colors: [Color(0xFF6B4B3A), Color(0xFF9B6B50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _title(AppLocalizations l10n) {
    switch (info.status) {
      case SubscriptionStatus.active:
        return l10n.subscriptionActiveTitle;
      case SubscriptionStatus.grandfathered:
        return l10n.subscriptionGrandfatheredTitle;
      case SubscriptionStatus.trial:
        return l10n.subscriptionTrialTitle;
      case SubscriptionStatus.expired:
        return l10n.subscriptionExpiredTitle;
    }
  }

  String _subtitle(AppLocalizations l10n) {
    switch (info.status) {
      case SubscriptionStatus.active:
        if (info.expiresAt != null) {
          return l10n.subscriptionActiveUntil(formatSubDate(info.expiresAt!));
        }
        return l10n.subscriptionActiveTitle;
      case SubscriptionStatus.grandfathered:
        return l10n.subscriptionActiveTitle;
      case SubscriptionStatus.trial:
        if (info.trialExpiresAt != null) {
          return l10n.subscriptionTrialEndsOn(
            formatSubDate(info.trialExpiresAt!),
          );
        }
        return l10n.subscriptionTrialTitle;
      case SubscriptionStatus.expired:
        return l10n.subscriptionExpiredMessage;
    }
  }

  Widget _buildMetric(
    AppLocalizations l10n, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, AppLocalizations l10n) {
    if (info.isExpired) {
      return GestureDetector(
        onTap: () => showPaywall(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.subscriptionUpgrade,
            style: const TextStyle(
              color: BotanlyColors.sageDark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (info.isTrial) {
      return GestureDetector(
        onTap: () => showPaywall(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.subscriptionUpgrade,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Active / Grandfathered — manage subscription
    return GestureDetector(
      onTap: () async {
        // Open native subscription management
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          l10n.subscriptionManage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
