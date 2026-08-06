import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/subscription_service.dart';
import '../l10n/app_localizations.dart';

/// Shown after a successful Stripe Checkout redirect.
/// Waits up to 10 s for the webhook to activate the subscription,
/// then lets the user continue to the app.
class StripeSuccessScreen extends StatefulWidget {
  const StripeSuccessScreen({super.key});

  @override
  State<StripeSuccessScreen> createState() => _StripeSuccessScreenState();
}

class _StripeSuccessScreenState extends State<StripeSuccessScreen> {
  bool _activated = false;
  late final StreamSubscription<SubscriptionInfo> _sub;
  int _dots = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _sub = SubscriptionService().stream.listen((info) {
      if (info.isActive && mounted) {
        setState(() => _activated = true);
        _dotTimer?.cancel();
      }
    });

    // Animating waiting dots
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF3),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _activated
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF4CAF50).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _activated
                        ? Icons.check_rounded
                        : Icons.hourglass_top_rounded,
                    color: _activated ? Colors.white : const Color(0xFF4CAF50),
                    size: 52,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _activated
                      ? (l10n?.stripeSuccessTitle ?? 'Subscription activated!')
                      : (l10n?.stripeSuccessWaiting ??
                            'Activating your subscription${_waitingDots(_dots)}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2A1A),
                  ),
                ),
                const SizedBox(height: 12),
                if (_activated)
                  Text(
                    l10n?.stripeSuccessSubtitle ??
                        'Welcome to Botanly Premium! You now have access to all features.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A6741),
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n?.stripeSuccessButton ?? 'Go to my plants',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
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

  String _waitingDots(int n) => '.' * n + ' ' * (3 - n);
}
