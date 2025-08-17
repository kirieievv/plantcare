import 'package:flutter/material.dart';

class AppTheme {
  // KLM Style Color Palette
  static const Color primaryBlue = Color(0xFF1976D2); // KLM Blue
  static const Color darkBlue = Color(0xFF0D47A1); // Dark Blue
  static const Color lightBlue = Color(0xFFE3F2FD); // Light Blue
  static const Color accentGreen = Color(0xFF4CAF50); // Success Green
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color mediumGrey = Color(0xFFE9ECEF);
  static const Color darkGrey = Color(0xFF6C757D);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color borderGrey = Color(0xFFDEE2E6);
  static const Color shadowGrey = Color(0xFF000000);

  // Modern Typography
  static const String fontFamily = 'Inter';
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    fontFamily: fontFamily,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    letterSpacing: -0.2,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.6,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.5,
    letterSpacing: 0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    fontFamily: fontFamily,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Modern Spacing
  static const double spacingXS = 6.0;
  static const double spacingS = 12.0;
  static const double spacingM = 20.0;
  static const double spacingL = 28.0;
  static const double spacingXL = 40.0;
  static const double spacingXXL = 56.0;

  // Modern Border Radius
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  // KLM Style Shadows
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  // Glassmorphism Effect
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x1AFFFFFF),
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  // Modern Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowMedium,
    border: Border.all(color: white, width: 1),
  );
  
  // Glassmorphism Card
  static BoxDecoration glassCardDecoration = BoxDecoration(
    color: white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: glassShadow,
    border: Border.all(color: white.withOpacity(0.2), width: 1),
  );
  
  // Gradient Card
  static BoxDecoration gradientCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    ),
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: shadowMedium,
  );

  // KLM Style Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 0,
    shadowColor: primaryBlue.withOpacity(0.2),
  );
  
  // Gradient Button
  static ButtonStyle gradientButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 0,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: lightGrey,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 0,
  );

  static ButtonStyle blueButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 2,
  );

  // Input Field Styles
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Color? borderColor,
    Color? prefixIconColor,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixIconColor ?? primaryBlue) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor ?? mediumGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor ?? mediumGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      filled: true,
      fillColor: lightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
    );
  }
} 