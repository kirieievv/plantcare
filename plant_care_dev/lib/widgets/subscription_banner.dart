import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import '../services/subscription_service.dart';
import '../theme/botanly_theme.dart';

/// Bottom banner shown when user reaches their plant limit.
/// Place inside a Stack over the plant list.
class PlantLimitBanner extends StatelessWidget {
  final SubscriptionInfo info;

  const PlantLimitBanner({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = info.isTrial
        ? l10n.subscriptionPlantLimitBannerTrial(
            info.config.subscriptionPlantLimit,
          )
        : l10n.subscriptionPlantLimitBannerExpired;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BotanlyColors.sageDark, BotanlyColors.sage],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: BotanlyColors.sage.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.subscriptionPlantLimitReached,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showPaywall(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.subscriptionUpgrade,
                      style: const TextStyle(
                        color: BotanlyColors.sageDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
}

/// Inline read-only notice bar for expired users.
class ExpiredReadOnlyBar extends StatelessWidget {
  const ExpiredReadOnlyBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        color: Colors.orange.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.orange.shade700,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.subscriptionReadOnlyNotice,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => showPaywall(context),
              child: Text(
                l10n.subscriptionUpgrade,
                style: const TextStyle(
                  color: BotanlyColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
