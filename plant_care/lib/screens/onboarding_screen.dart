import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const int _total = 5;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingService.markComplete();
    if (mounted) context.go('/home');
  }

  void _goToPage(int i) {
    _ctrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _page == _total - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6EF),
      body: Stack(
        children: [
          // Subtle radial background
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          // Main page content
          PageView.builder(
            controller: _ctrl,
            itemCount: _total,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _OnboardingPage(index: i, l10n: l10n),
          ),

          // ── Dot indicators + CTA footer ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 0, 34, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_total, (i) {
                        final active = i == _page;
                        return GestureDetector(
                          onTap: () => _goToPage(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF4F9A32)
                                  : const Color(0xFFBFD4AA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),

                    // CTA — only on last page
                    AnimatedSize(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOut,
                      child: isLast
                          ? SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _finish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F9A32),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(
                                    0xFF4F9A32,
                                  ).withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  l10n.onboardingGetStarted,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Skip pill (top-right, hidden on last page) ──
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isLast ? 0 : 1,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: GestureDetector(
                    onTap: isLast ? null : _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFD4E6C0),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A223A18),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.onboardingSkip,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A7C5D),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: Color(0xFF6A7C5D),
                          ),
                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Single page
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final int index;
  final AppLocalizations l10n;

  const _OnboardingPage({required this.index, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final data = _pageData(index, l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 96, 34, 140),
      child: Column(
        children: [
          // ── Illustration ──
          SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo ring
                Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 0.85,
                      colors: [Color(0xFFF1F8EA), Color(0xFFDCECC9)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x384F9A32),
                        blurRadius: 50,
                        offset: Offset(0, 20),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFD0E8B8),
                      width: 1.5,
                    ),
                  ),
                ),
                // Dashed inner ring
                SvgPicture.string(_dashedRing, width: 194, height: 194),
                // Illustration
                SvgPicture.string(data.svgString, width: 140, height: 140),
                // Sparkle top-right
                Positioned(
                  top: 24,
                  right: 30,
                  child: SvgPicture.string(
                    _sparkStar,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4F9A32),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Accent dot bottom-left
                Positioned(
                  bottom: 40,
                  left: 24,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0913F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 44),

          // ── Copy ──
          Text(
            data.eyebrow.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: Color(0xFF4F9A32),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.12,
                letterSpacing: -0.3,
                color: Color(0xFF1C3318),
              ),
              children: [
                TextSpan(text: data.titlePlain),
                TextSpan(
                  text: data.titleItalic,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4F9A32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15.5,
              height: 1.5,
              color: Color(0xFF6A7C5D),
            ),
          ),
        ],
      ),
    );
  }

  _PageData _pageData(int i, AppLocalizations l) {
    switch (i) {
      case 0:
        return _PageData(
          eyebrow: l.onboarding1Eyebrow,
          titlePlain: l.onboarding1Title,
          titleItalic: l.onboarding1TitleItalic,
          body: l.onboarding1Body,
          svgString: _svgSprout,
        );
      case 1:
        return _PageData(
          eyebrow: l.onboarding2Eyebrow,
          titlePlain: l.onboarding2Title,
          titleItalic: l.onboarding2TitleItalic,
          body: l.onboarding2Body,
          svgString: _svgCamera,
        );
      case 2:
        return _PageData(
          eyebrow: l.onboarding3Eyebrow,
          titlePlain: l.onboarding3Title,
          titleItalic: l.onboarding3TitleItalic,
          body: l.onboarding3Body,
          svgString: _svgDroplet,
        );
      case 3:
        return _PageData(
          eyebrow: l.onboarding4Eyebrow,
          titlePlain: l.onboarding4Title,
          titleItalic: l.onboarding4TitleItalic,
          body: l.onboarding4Body,
          svgString: _svgShield,
        );
      default:
        return _PageData(
          eyebrow: l.onboarding5Eyebrow,
          titlePlain: l.onboarding5Title,
          titleItalic: l.onboarding5TitleItalic,
          body: l.onboarding5Body,
          svgString: _svgTree,
        );
    }
  }
}

class _PageData {
  final String eyebrow;
  final String titlePlain;
  final String titleItalic;
  final String body;
  final String svgString;

  const _PageData({
    required this.eyebrow,
    required this.titlePlain,
    required this.titleItalic,
    required this.body,
    required this.svgString,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Background painter — two soft radial blobs
// ─────────────────────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFE5F2D8).withValues(alpha: 0.9),
              const Color(0xFFF4F6EF).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width * 0.15, 0),
              width: size.width * 1.6,
              height: size.height,
            ),
          );
    canvas.drawRect(Offset.zero & size, p1);

    final p2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFC8E3B0).withValues(alpha: 0.55),
              const Color(0xFFF4F6EF).withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.width, size.height),
              width: size.width * 1.8,
              height: size.height * 1.2,
            ),
          );
    canvas.drawRect(Offset.zero & size, p2);
  }

  @override
  bool shouldRepaint(_BgPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG strings from the design handoff
// ─────────────────────────────────────────────────────────────────────────────

const _dashedRing = '''
<svg viewBox="0 0 194 194" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="97" cy="97" r="95.25" stroke="#CADEB4" stroke-width="1.5" stroke-dasharray="4 4" opacity="0.7"/>
</svg>''';

const _sparkStar = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 0c.6 4.9 2.1 6.4 7 7-4.9.6-6.4 2.1-7 7-.6-4.9-2.1-6.4-7-7 4.9-.6 6.4-2.1 7-7Z"/>
</svg>''';

// Screen 1 — Sprout
const _svgSprout = '''
<svg viewBox="0 0 64 64" fill="none" stroke="#3F8127" stroke-width="2.4"
     stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M32 56V30" stroke="#4F9A32"/>
  <path d="M32 34c-2-9-9-13-19-13 0 10 7 15 19 15Z" fill="#DCECC9" stroke="#4F9A32"/>
  <path d="M32 30c2-7 8-10 17-10 0 8-6 12-17 13Z" fill="#BFE0A0" stroke="#4F9A32"/>
  <path d="M20 56h24l-2 4H22l-2-4Z" fill="#E7C9A8" stroke="#C79A6E"/>
</svg>''';

// Screen 2 — Camera + leaf
const _svgCamera = '''
<svg viewBox="0 0 64 64" fill="none" stroke="#4F9A32" stroke-width="2.4"
     stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 22v-4a4 4 0 0 1 4-4h4M50 22v-4a4 4 0 0 0-4-4h-4
           M14 42v4a4 4 0 0 0 4 4h4M50 42v4a4 4 0 0 1-4 4h-4"/>
  <path d="M40 26c-12 0-16 6-16 14 8 0 16-3 16-14Z" fill="#DCECC9" stroke="#3F8127"/>
  <path d="M24 40c6-1 11-4 14-9" stroke="#3F8127"/>
</svg>''';

// Screen 3 — Droplet + check
const _svgDroplet = '''
<svg viewBox="0 0 64 64" fill="none" stroke="#4F9A32" stroke-width="2.4"
     stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M32 10c8 11 13 17 13 24a13 13 0 0 1-26 0c0-7 5-13 13-24Z"
        fill="#DCECC9" stroke="#3F8127"/>
  <path d="M26 35l4 4 8-8" stroke="#3F8127"/>
</svg>''';

// Screen 4 — Shield + cross
const _svgShield = '''
<svg viewBox="0 0 64 64" fill="none" stroke="#4F9A32" stroke-width="2.4"
     stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M32 8 14 15v13c0 11 8 20 18 23 10-3 18-12 18-23V15L32 8Z"
        fill="#DCECC9" stroke="#3F8127"/>
  <path d="M32 24v12M26 30h12" stroke="#3F8127"/>
</svg>''';

// Screen 5 — Thriving tree
const _svgTree = '''
<svg viewBox="0 0 64 64" fill="none" stroke="#4F9A32" stroke-width="2.4"
     stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M32 52V28" stroke="#4F9A32"/>
  <path d="M32 34c-3-8-9-11-18-11 0 9 7 13 18 13Z" fill="#DCECC9" stroke="#4F9A32"/>
  <path d="M32 30c3-8 9-11 18-11 0 9-7 13-18 13Z" fill="#BFE0A0" stroke="#4F9A32"/>
  <path d="M22 38c4 0 8 2 10 6 2-4 6-6 10-6" stroke="#3F8127"/>
  <path d="M20 52h24l-2.5 5h-19L20 52Z" fill="#E7C9A8" stroke="#C79A6E"/>
</svg>''';
