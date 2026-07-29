import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tokens from HTML prototypes: `…/Botanly /screens/` (index.html, splash_screen.html,
// main_navigation_screen.html, auth_screen.html, …)

// ──────────────────────────── Colors ────────────────────────────

class BotanlyColors {
  // `dashboard_screen.html` / `main_navigation_screen.html` :root
  static const Color sage = Color(0xFF5FA346);
  static const Color sageDark = Color(0xFF3A5332);
  static const Color sageLight = Color(0xFF7EC665);
  static const Color sagePale = Color(0xFFCCE8B8);
  static const Color sagePale2 = Color(0xFFE8F1E5);
  static const Color sageSoft = Color(0xFFF3F8F1);
  static const Color moss = Color(0xFF2D3D2A);

  // Auth/Splash flow tokens (splash_screen.html, auth_screen.html, forgot_*.html)
  static const Color authSage = Color(0xFF4A6741);
  static const Color authSageLight = Color(0xFF6B8F61);
  static const Color authSagePale = Color(0xFFD4E3CF);

  // Auth gradient colors (linear-gradient 135deg #D6EDD6 → #F5FAF5 → #E8F5E8)
  static const Color authGradStart = Color(0xFFD6EDD6);
  static const Color authGradMid = Color(0xFFF5FAF5);
  static const Color authGradEnd = Color(0xFFE8F5E8);

  /// `dashboard_screen.html` — active nav icon chip
  static const Color navActiveFill = Color(0xFF5FA346);
  static const Color navGreenLight = Color(0xFF7BC67E);
  static const Color navGreenDark = Color(0xFF5AB85D);
  static const Color navBarBg = Color(0xFFFFFFFF);
  static const Color navIconMuted = Color(0xFF9E9E9E);
  static const Color navLabelMuted = Color(0xFF9E9E9E);

  static const Color authBg = Color(0xFFEEF2EA);
  static const Color paper = Color(0xFFF7F7F7);
  static const Color cabinetBg = Color(0xFFFFFFFF);
  static const Color chromeBg = Color(0xFFE8E8E8);

  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkSoft = Color(0xFF4A5C46);
  static const Color inkMute = Color(0xFF909090);
  static const Color line = Color(0xFFEBEBEB);
  static const Color sand = Color(0xFFEBEBEB);

  static const Color amber = Color(0xFFC97C1A);
  static const Color amberPale = Color(0xFFFAECD4);

  static const Color red = Color(0xFFB94040);
  static const Color redPale = Color(0xFFFBE6E6);

  static const Color blue = Color(0xFF4A91C8);
  static const Color bluePale = Color(0xFFE4EFF8);

  static const Color yellow = Color(0xFFDABF78);
  static const Color yellowPale = Color(0xFFFFFAEE);
  static const Color yellowText = Color(0xFFC9A052);
  static const Color yellowBody = Color(0xFF9C8456);
  static const Color yellowBorder = Color(0xFFF5EBCC);
}

// ──────────────────────────── Typography ────────────────────────────

class BotanlyText {
  static TextStyle plantName({Color? color}) => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: -.5,
        height: 1.05,
        color: color ?? BotanlyColors.moss,
      );

  static TextStyle sectionTitle({Color? color}) => GoogleFonts.fraunces(
        fontSize: 19,
        fontWeight: FontWeight.w400,
        letterSpacing: -.3,
        height: 1.1,
        color: color ?? BotanlyColors.sage,
      );

  static TextStyle cardTitle({Color? color}) => GoogleFonts.fraunces(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -.2,
        height: 1.2,
        color: color ?? BotanlyColors.moss,
      );

  static TextStyle smallHeading({Color? color}) => GoogleFonts.fraunces(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        letterSpacing: -.2,
        color: color ?? BotanlyColors.sage,
      );

  static TextStyle topbarTitle({Color? color}) => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -.4,
        color: color ?? BotanlyColors.moss,
      );

  static TextStyle body({Color? color}) => GoogleFonts.dmSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w300,
        height: 1.6,
        color: color ?? const Color(0xFF6A6A6A),
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color ?? BotanlyColors.inkSoft,
      );

  static TextStyle statValue({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: color ?? BotanlyColors.sageDark,
      );

  static TextStyle microLabel({Color? color}) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: .4,
        color: color ?? BotanlyColors.inkMute,
      );

  static TextStyle button({Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w600,
        letterSpacing: .1,
        color: color ?? Colors.white,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w300,
        color: color ?? BotanlyColors.inkMute,
      );

  static TextStyle latin({Color? color}) => GoogleFonts.fraunces(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: color ?? BotanlyColors.inkMute,
      );
}

// ──────────────────────────── Shadows ────────────────────────────

class BotanlyShadows {
  static const card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const cardElevated = [
    BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  /// splash_screen.html .btn-primary
  static const splashPrimaryBtn = [
    BoxShadow(
      color: Color(0x595FA346),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const primaryGlow = [
    BoxShadow(color: Color(0x595FA346), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const primaryGlowStrong = [
    BoxShadow(color: Color(0x735FA346), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const fab = [
    BoxShadow(color: Color(0x665FA346), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// `dashboard_screen.html` `.nav-item.active .nav-icon`
  static const navActiveIconDrop = [
    BoxShadow(
      color: Color(0x594A9E3F),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// main_navigation_screen.html .nav-item.active .nav-pill
  static const navActivePill = [
    BoxShadow(
      color: Color(0x595AB85D),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];
}

// ──────────────────────────── Radii ────────────────────────────

class BotanlyRadii {
  static const xs = 8.0;
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 16.0;
  static const xxl = 20.0;
  static const pill = 999.0;
}

// ──────────────────────────── Theme builder ────────────────────────────

ThemeData buildBotanlyTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BotanlyColors.cabinetBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BotanlyColors.sage,
      primary: BotanlyColors.sage,
      onPrimary: Colors.white,
      secondary: BotanlyColors.sageLight,
      surface: Colors.white,
      onSurface: BotanlyColors.ink,
      brightness: Brightness.light,
    ),
    fontFamily: GoogleFonts.dmSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: BotanlyColors.moss,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: BotanlyText.cardTitle(),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(BotanlyRadii.xxl)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BotanlyColors.sage,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BotanlyRadii.md),
        ),
        textStyle: BotanlyText.button(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BotanlyRadii.md),
        borderSide: BorderSide(color: BotanlyColors.moss.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BotanlyRadii.md),
        borderSide: BorderSide(color: BotanlyColors.moss.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BotanlyRadii.md),
        borderSide: const BorderSide(color: BotanlyColors.sage, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
