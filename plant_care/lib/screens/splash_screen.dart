import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// Splash entry — design from `Botanly /screens/splash_screen.html`.
/// Logic: identical to production (Get Started → register, Log In → login).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BotanlyAuthScaffold(
      showBackButton: false,
      centerVertically: true,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          Text(
            'Botanly',
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 48,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.96,
              height: 1.0,
              color: BotanlyColors.moss,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.splashTagline,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
              height: 1.5,
              color: BotanlyColors.moss.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 64),
          BotanlyAuthPrimaryButton(
            label: l10n.getStarted,
            onPressed: () => context.push('/register'),
          ),
          const SizedBox(height: 14),
          BotanlyAuthSecondaryButton(
            label: l10n.logIn,
            onPressed: () => context.push('/login'),
          ),
          const SizedBox(height: 24),
          Center(child: _LanguagePill()),
          const SizedBox(height: 24),
          Text(
            l10n.splashDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              height: 1.7,
              color: BotanlyColors.moss.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Flag glyph ────────────────────────────────────────────────────────────────

/// Renders a language's flag. Most locales use the system emoji, but `ru` is
/// drawn from a bundled asset — the flag of Donetsk Oblast — so the picker
/// never shows the Russian tricolour.
class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({
    required this.code,
    required this.emoji,
    required this.fontSize,
  });

  final String code;
  final String emoji;
  final double fontSize;

  /// Locales whose flag comes from an asset instead of an emoji glyph.
  static const _assetFlags = {'ru': 'assets/flags/donetsk.svg'};

  @override
  Widget build(BuildContext context) {
    final asset = _assetFlags[code];
    if (asset == null) {
      return Text(emoji, style: TextStyle(fontSize: fontSize));
    }
    // Emoji flags sit at roughly 0.78 of the font size and are 3:2 wide, so the
    // asset lines up with its neighbours in the same list.
    final height = fontSize * 0.78;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SvgPicture.asset(
        asset,
        height: height,
        width: height * 1.5,
        fit: BoxFit.fill,
      ),
    );
  }
}

// ── Language pill button ───────────────────────────────────────────────────────

class _LanguagePill extends StatelessWidget {
  static const _languages = [
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
    ('es', '🇪🇸', 'Español'),
    ('fr', '🇫🇷', 'Français'),
    ('ru', '🇷🇺', 'Русский'),
    ('uk', '🇺🇦', 'Українська'),
  ];

  static String _flagFor(String code) => _languages
      .firstWhere((l) => l.$1 == code, orElse: () => ('en', '🇬🇧', 'English'))
      .$2;

  static String _nameFor(String code) => _languages
      .firstWhere((l) => l.$1 == code, orElse: () => ('en', '🇬🇧', 'English'))
      .$3;

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LanguageSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.localeNotifier,
      builder: (context, locale, _) {
        final code = locale.languageCode;
        return GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BotanlyColors.moss.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LanguageFlag(code: code, emoji: _flagFor(code), fontSize: 16),
                const SizedBox(width: 7),
                Text(
                  _nameFor(code),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: BotanlyColors.moss.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: BotanlyColors.moss.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Language picker bottom sheet ──────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  static const _languages = [
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
    ('es', '🇪🇸', 'Español'),
    ('fr', '🇫🇷', 'Français'),
    ('ru', '🇷🇺', 'Русский'),
    ('uk', '🇺🇦', 'Українська'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.localeNotifier,
      builder: (context, locale, _) {
        final current = locale.languageCode;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BotanlyColors.moss.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              for (final (code, flag, name) in _languages) ...[
                InkWell(
                  onTap: () {
                    LanguageService.setLanguage(code);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        _LanguageFlag(code: code, emoji: flag, fontSize: 22),
                        const SizedBox(width: 14),
                        Text(
                          name,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: code == current
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: code == current
                                ? BotanlyColors.moss
                                : BotanlyColors.moss.withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        if (code == current)
                          Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: BotanlyColors.sage,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }
}
