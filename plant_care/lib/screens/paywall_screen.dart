import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';
import '../services/stripe_service.dart';
import '../theme/botanly_theme.dart';
import '../widgets/botanly_loader.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _service = SubscriptionService();

  // ── Mobile (RevenueCat) state ──
  List<Package> _packages = [];
  Package? _selected;

  // ── Web (Stripe) state ──
  static const _stripeMonthlyPriceId = 'price_1TMvPAJPrVn4SU24q8YHgAnZ';
  static const _stripeAnnualPriceId = 'price_1TUtTfJPrVn4SU247QRftkP2';
  String _selectedStripePriceId = _stripeAnnualPriceId;

  // ── Shared state ──
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      setState(() => _loading = false);
    } else {
      _loadPackages();
    }
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await _service.fetchPackages();
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _selected = _pickDefaultPackage(packages);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Package? _pickDefaultPackage(List<Package> packages) {
    final annual = packages
        .where(
          (p) =>
              p.packageType == PackageType.annual ||
              p.storeProduct.identifier.contains('annual'),
        )
        .toList();
    if (annual.isNotEmpty) return annual.first;
    return packages.isNotEmpty ? packages.first : null;
  }

  bool _isAnnual(Package p) =>
      p.packageType == PackageType.annual ||
      p.storeProduct.identifier.contains('annual');

  Future<void> _purchase() async {
    if (_selected == null) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final success = await _service.purchase(_selected!);
      if (!mounted) return;
      if (success) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (e is PlatformException && e.details?['userCancelled'] == true) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      final l10n = AppLocalizations.of(context)!;
      final success = await _service.restorePurchases();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.paywallRestoreNotFound)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _stripeCheckout() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final url = await StripeService.createCheckoutUrl(
        priceId: _selectedStripePriceId,
        successUrl: '${Uri.base.origin}/stripe-success',
        cancelUrl: '${Uri.base.origin}/home',
      );
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, webOnlyWindowName: '_self');
      } else {
        setState(() => _error = AppLocalizations.of(context)!.paywallError);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                  child: _closeButton(),
                ),
              ),
              const Expanded(child: Center(child: BotanlyLoader(size: 80))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(l10n),
                  const SizedBox(height: 22),
                  _buildSectionDivider(),
                  const SizedBox(height: 2),
                  kIsWeb ? _buildStripeCards(l10n) : _buildPackageCards(l10n),
                  const SizedBox(height: 8),
                  if (_error != null) ...[
                    _buildErrorBox(_error!),
                    const SizedBox(height: 12),
                  ],
                  kIsWeb ? _buildStripeCTAButton(l10n) : _buildCTAButton(l10n),
                  const SizedBox(height: 12),
                  _buildTrustRow(),
                  const SizedBox(height: 12),
                  _buildRestoreRow(l10n),
                  const SizedBox(height: 10),
                  _buildLegalLinksRow(),
                ],
              ),
            ),
            // Floating close button
            Positioned(top: 16, right: 16, child: _closeButton()),
          ],
        ),
      ),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(false),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0x0F2D3D2A),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: BotanlyColors.moss,
        ),
      ),
    );
  }

  // ── Hero section ──

  Widget _buildHero(AppLocalizations l10n) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BotanlyColors.sage.withValues(alpha: 0.10)),
      ),
      child: Stack(
        children: [
          // Base gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF4FAEE), Colors.white],
                ),
              ),
            ),
          ),
          // Green top-left glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.3, -1.3),
                  radius: 2.0,
                  colors: [
                    BotanlyColors.sage.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Green top-right glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.4, -1.2),
                  radius: 1.8,
                  colors: [
                    BotanlyColors.sageLight.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Leaf decoration
          Positioned(
            top: -10,
            right: -12,
            child: Opacity(
              opacity: 0.4,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _PaywallLeafPainter(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            BotanlyColors.sageLight,
                            BotanlyColors.sageDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: BotanlyColors.sage.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BOTANLY · PREMIUM',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: BotanlyColors.sageDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title — split first word plain, rest italic
                Builder(
                  builder: (ctx) {
                    final title = AppLocalizations.of(ctx)!.paywallHeroTitle;
                    final spaceIdx = title.indexOf(' ');
                    final part1 = spaceIdx >= 0
                        ? '${title.substring(0, spaceIdx)} '
                        : title;
                    final part2 = spaceIdx >= 0
                        ? title.substring(spaceIdx + 1)
                        : '';
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: part1,
                            style: GoogleFonts.fraunces(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1.0,
                              color: BotanlyColors.moss,
                              height: 1.05,
                            ),
                          ),
                          if (part2.isNotEmpty)
                            TextSpan(
                              text: part2,
                              style: GoogleFonts.fraunces(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -1.0,
                                color: BotanlyColors.sage,
                                fontStyle: FontStyle.italic,
                                height: 1.05,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paywallHeroDescription,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    color: BotanlyColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 2×2 perks grid
                Row(
                  children: [
                    Expanded(
                      child: _buildPerk(
                        Icons.eco_rounded,
                        l10n.paywallFeature1(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPerk(
                        Icons.notifications_active_rounded,
                        l10n.paywallFeature2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerk(
                        Icons.smart_toy_rounded,
                        l10n.paywallFeature3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPerk(
                        Icons.edit_rounded,
                        l10n.paywallFeature4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerk(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: BotanlyColors.sage.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: BotanlyColors.sageSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: BotanlyColors.sageDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: BotanlyColors.moss,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0x1F2D3D2A))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.paywallChoosePlan,
              style: GoogleFonts.dmMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: BotanlyColors.inkMute,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0x1F2D3D2A))),
      ],
    );
  }

  // ── Mobile (RevenueCat) plan cards ──

  Widget _buildPackageCards(AppLocalizations l10n) {
    if (_packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              l10n.paywallError,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: BotanlyColors.inkMute,
              ),
            ),
            // The cause, spelled out. An empty plan list only happens when the
            // store is misconfigured, and the person who can fix that is
            // whoever is holding the phone. A screenshot of "something went
            // wrong" is worth nothing; a screenshot naming the offering, the
            // key or the missing agreement is worth the whole investigation.
            if (_error != null && _error!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: BotanlyColors.inkMute,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: _packages.map((pkg) {
        final isSelected = _selected == pkg;
        final annual = _isAnnual(pkg);
        return _buildPlanCard(
          isSelected: isSelected,
          name: annual ? l10n.paywallAnnual : l10n.paywallMonthly,
          nameItalic: annual,
          price: pkg.storeProduct.priceString,
          perMonth: annual
              ? l10n.paywallPerMonth(_monthlyFromAnnual(pkg.storeProduct.price))
              : null,
          badge: annual ? l10n.paywallBestValue : null,
          onTap: () => setState(() => _selected = pkg),
        );
      }).toList(),
    );
  }

  String _monthlyFromAnnual(double annualPrice) {
    final monthly = annualPrice / 12;
    return NumberFormat.simpleCurrency().format(monthly);
  }

  // ── Web (Stripe) plan cards ──

  Widget _buildStripeCards(AppLocalizations l10n) {
    final plans = [
      (
        id: _stripeAnnualPriceId,
        name: l10n.paywallAnnual,
        nameItalic: true,
        price: r'$21.99 billed yearly',
        perMonth: l10n.paywallPerMonth(r'$1.83'),
        badge: l10n.paywallBestValue,
      ),
      (
        id: _stripeMonthlyPriceId,
        name: l10n.paywallMonthly,
        nameItalic: false,
        price: r'$1.99 / month',
        perMonth: l10n.paywallCancelAnytime,
        badge: null as String?,
      ),
    ];

    return Column(
      children: plans
          .map(
            (plan) => _buildPlanCard(
              isSelected: _selectedStripePriceId == plan.id,
              name: plan.name,
              nameItalic: plan.nameItalic,
              price: plan.price,
              perMonth: plan.perMonth,
              badge: plan.badge,
              onTap: () => setState(() => _selectedStripePriceId = plan.id),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlanCard({
    required bool isSelected,
    required String name,
    bool nameItalic = false,
    required String price,
    String? perMonth,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4FAEE) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? BotanlyColors.sage : const Color(0xFFE4EBE1),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BotanlyColors.sage.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? BotanlyColors.sage
                          : const Color(0xFFE4EBE1),
                      width: 2,
                    ),
                    color: isSelected ? BotanlyColors.sage : Colors.white,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: BotanlyColors.moss,
                          letterSpacing: -0.3,
                          fontStyle: nameItalic
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: BotanlyColors.inkSoft,
                        ),
                      ),
                      if (perMonth != null)
                        Text(
                          perMonth,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            color: BotanlyColors.inkMute,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Badge
            if (badge != null)
              Positioned(
                top: -25,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC08E3C), Color(0xFFA47626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC08E3C).withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── CTA buttons ──

  Widget _buildCTAButton(AppLocalizations l10n) {
    final selectedIsAnnual = _selected != null && _isAnnual(_selected!);
    final label = _packages.isEmpty
        ? l10n.paywallError
        : '${l10n.paywallStartPremium} · ${selectedIsAnnual ? l10n.paywallAnnual : l10n.paywallMonthly}';

    return _mossCTAButton(
      label: label,
      loading: _purchasing,
      onTap: (_selected != null && !_purchasing) ? _purchase : null,
    );
  }

  Widget _buildStripeCTAButton(AppLocalizations l10n) {
    final isAnnual = _selectedStripePriceId == _stripeAnnualPriceId;
    return _mossCTAButton(
      label:
          '${l10n.paywallStartPremium} · ${isAnnual ? l10n.paywallAnnual : l10n.paywallMonthly}',
      loading: _purchasing,
      onTap: _purchasing ? null : _stripeCheckout,
    );
  }

  Widget _mossCTAButton({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: onTap != null
            ? BotanlyColors.moss
            : BotanlyColors.moss.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BotanlyColors.moss.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Trust + restore ──

  Widget _buildTrustRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 11,
          color: BotanlyColors.inkMute,
        ),
        const SizedBox(width: 5),
        Builder(
          builder: (ctx) {
            final l = AppLocalizations.of(ctx)!;
            return Text(
              kIsWeb ? l.paywallSecured : l.paywallSecuredApple,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: BotanlyColors.inkMute,
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BotanlyColors.inkMute.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 14),
        Builder(
          builder: (ctx) => Text(
            AppLocalizations.of(ctx)!.paywallCancelAnytime,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: BotanlyColors.inkMute,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestoreRow(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        GestureDetector(
          onTap: _restoring ? null : _restore,
          child: _restoring
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: BotanlyColors.sageDark,
                  ),
                )
              : Text(
                  l10n.paywallRestore,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BotanlyColors.sageDark,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dashed,
                    decorationColor: BotanlyColors.sage.withValues(alpha: 0.4),
                  ),
                ),
        ),
        Text(
          ' · ${l10n.paywallAutoRenews} · ',
          style: GoogleFonts.dmSans(fontSize: 12, color: BotanlyColors.inkMute),
        ),
        Text(
          l10n.paywallTerms.split(' ').first,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: BotanlyColors.sageDark,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
            decorationColor: BotanlyColors.sage.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLinksRow() {
    const privacyUrl = 'https://botanly.tech/privacy.html';
    const eulaUrl =
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
    final linkStyle = GoogleFonts.dmSans(
      fontSize: 11,
      color: BotanlyColors.inkMute,
      decoration: TextDecoration.underline,
      decorationColor: BotanlyColors.inkMute.withValues(alpha: 0.4),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        GestureDetector(
          onTap: () =>
              launchUrl(Uri.parse(privacyUrl), webOnlyWindowName: '_blank'),
          child: Text('Privacy Policy', style: linkStyle),
        ),
        if (!kIsWeb) ...[
          Text(
            '·',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: BotanlyColors.inkMute,
            ),
          ),
          GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse(eulaUrl), webOnlyWindowName: '_blank'),
            child: Text('Terms of Use', style: linkStyle),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        error,
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
      ),
    );
  }
}

// ── Leaf decorator for paywall hero ──
class _PaywallLeafPainter extends CustomPainter {
  const _PaywallLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCDEE9B), Color(0xFF5FA346)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final sx = size.width / 140;
    final sy = size.height / 140;

    final path = Path()
      ..moveTo(76 * sx, 130 * sy)
      ..quadraticBezierTo(40 * sx, 95 * sy, 70 * sx, 40 * sy)
      ..cubicTo(95 * sx, 32 * sy, 110 * sx, 28 * sy, 125 * sx, 12 * sy)
      ..relativeCubicTo(3 * sx, 30 * sy, 4 * sx, 52 * sy, -6 * sx, 72 * sy)
      ..relativeCubicTo(-10 * sx, 20 * sy, -30 * sx, 30 * sy, -43 * sx, 36 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PaywallLeafPainter _) => false;
}

/// Show paywall as a modal. Returns true if user subscribed.
Future<bool?> showPaywall(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const PaywallScreen(),
    ),
  );
}

/// Show paywall only if the user is not already subscribed.
Future<void> showPaywallIfNeeded(
  BuildContext context,
  SubscriptionInfo info,
) async {
  if (info.isActive) return;
  await showPaywall(context);
}

/// Format a date nicely for subscription display.
String formatSubDate(DateTime dt) {
  return DateFormat('d MMM yyyy').format(dt);
}
