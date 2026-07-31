import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Organic / botanical color palette for the plant chat screen.
/// Independent from the app's Material ThemeData so it can be tweaked
/// without affecting any other screen.
class ChatTheme {
  ChatTheme._();

  // ─── Palette ────────────────────────────────────────────────────
  static const Color sage       = Color(0xFF4A6741);
  static const Color sageLt     = Color(0xFF6B8F61);
  static const Color moss       = Color(0xFF2D3D2A);
  static const Color cream      = Color(0xFFF5F0E8);
  static const Color paper      = Color(0xFFFAF8F3);
  static const Color sand       = Color(0xFFE8E0D0);
  static const Color tan        = Color(0xFFC4B99A);
  static const Color textDark   = Color(0xFF2A2318);
  static const Color muted      = Color(0xFF8A7E6E);
  static const Color bubbleOut  = Color(0xFF3D5C38);
  static const Color bubbleIn   = Color(0xFFFFFFFF);

  // ─── Typography ─────────────────────────────────────────────────

  /// Serif display font — header title
  static TextStyle headerTitle = GoogleFonts.fraunces(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: moss,
    letterSpacing: -0.01 * 17,
  );

  /// Sans-serif body — message text
  static TextStyle messageText({required bool isUser}) => GoogleFonts.dmSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w300,
        height: 1.55,
        color: isUser ? Colors.white : textDark,
      );

  static TextStyle timeText({required bool isUser}) => GoogleFonts.dmSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w400,
        color: isUser ? Colors.white.withValues(alpha: 0.55) : muted,
      );

  static TextStyle sourceTagText = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.03 * 10,
    color: sage,
  );

  static TextStyle quickPillText = GoogleFonts.dmSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: sage,
  );

  static TextStyle inputHintText = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: tan,
  );

  static TextStyle inputText = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: textDark,
  );

  static TextStyle quotaText = GoogleFonts.dmSans(
    fontSize: 10.5,
    fontWeight: FontWeight.w300,
    color: muted,
  );

  static TextStyle dateDividerText = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.04 * 11,
    color: muted,
  );

  static TextStyle statusText = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w300,
    color: sageLt,
  );

  // ─── Decorations ────────────────────────────────────────────────

  static BoxDecoration bubbleDecoration({required bool isUser}) => BoxDecoration(
        color: isUser ? bubbleOut : bubbleIn,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
        ),
        boxShadow: isUser
            ? [BoxShadow(color: moss.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 2))]
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 3, offset: const Offset(0, 1)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 0, spreadRadius: 1),
              ],
      );

  static BoxDecoration sourceTagDecoration = BoxDecoration(
    color: cream,
    border: Border.all(color: sand),
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration quickPillDecoration({bool hovered = false}) => BoxDecoration(
        color: hovered ? sage : Colors.transparent,
        border: Border.all(color: sageLt, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      );

  static BoxDecoration inputWrapDecoration({bool focused = false}) => BoxDecoration(
        color: cream,
        border: Border.all(
          color: focused ? sageLt : sand,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(22),
      );

  static BoxDecoration attachBtnDecoration({bool hovered = false}) => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hovered ? sage : sand,
          width: 1.5,
        ),
      );

  static BoxDecoration sendBtnDecoration = BoxDecoration(
    shape: BoxShape.circle,
    color: sage,
    boxShadow: [
      BoxShadow(
        color: sage.withValues(alpha: 0.35),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ─── Avatar gradient ─────────────────────────────────────────────
  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7AAF6A), Color(0xFF4A6741)],
  );
}
