import 'package:flutter/material.dart';
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

  static String _flagFor(String code) =>
      _languages.firstWhere((l) => l.$1 == code, orElse: () => ('en', '🇬🇧', 'English')).$2;

  static String _nameFor(String code) =>
      _languages.firstWhere((l) => l.$1 == code, orElse: () => ('en', '🇬🇧', 'English')).$3;

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
                Text(_flagFor(code), style: const TextStyle(fontSize: 16)),
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
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 22)),
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
                          Icon(Icons.check_rounded,
                              size: 20, color: BotanlyColors.sage),
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
