import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/theme/botanly_theme.dart';

/// Reusable building blocks for the auth flow as defined by HTML prototypes
/// `splash_screen.html`, `auth_screen.html`, `forgot_password_*.html`.
///
/// Color and dimension tokens are taken straight from the HTML so the Flutter
/// surface stays pixel-close to the prototype while keeping app logic intact.

const _kAuthGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    BotanlyColors.authGradStart,
    BotanlyColors.authGradMid,
    BotanlyColors.authGradEnd,
  ],
  stops: [0.0, 0.5, 1.0],
);

class BotanlyAuthBackground extends StatelessWidget {
  final Widget child;
  const BotanlyAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _kAuthGradient),
      child: child,
    );
  }
}

/// Scaffold shell for splash / auth / forgot screens.
/// Centers a 420px column on wide screens, adds gradient bg, top back button.
class BotanlyAuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;
  final bool centerVertically;

  const BotanlyAuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(32, 8, 32, 40),
    this.centerVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    final scrollChild = Padding(
      padding: padding,
      child: child,
    );

    return Scaffold(
      backgroundColor: BotanlyColors.chromeBg,
      body: BotanlyAuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  if (showBackButton)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(onTap: onBack),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: centerVertically
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height -
                                        (showBackButton ? 100 : 50),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [scrollChild],
                              ),
                            )
                          : scrollChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: BotanlyColors.moss.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

/// Fraunces wordmark + DM Sans subtitle, like .wordmark / .subtitle in HTML.
class BotanlyWordmark extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double titleSize;
  const BotanlyWordmark({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: -titleSize * 0.02,
            height: 1.0,
            color: BotanlyColors.moss,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.15,
              height: 1.5,
              color: BotanlyColors.moss.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

/// Translucent text field as in HTML auth flow .field input.
class BotanlyAuthField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final bool showToggleObscure;
  final TextInputType keyboardType;
  final String? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  const BotanlyAuthField({
    super.key,
    this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.showToggleObscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.inputFormatters,
  });

  @override
  State<BotanlyAuthField> createState() => _BotanlyAuthFieldState();
}

class _BotanlyAuthFieldState extends State<BotanlyAuthField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = BotanlyColors.moss.withValues(alpha: 0.5);
    return SizedBox(
      height: 52,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofocus: widget.autofocus,
        autofillHints:
            widget.autofillHints != null ? [widget.autofillHints!] : null,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        inputFormatters: widget.inputFormatters,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: BotanlyColors.moss,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: BotanlyColors.moss.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: widget.icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Icon(widget.icon, color: iconColor, size: 20),
                ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 20),
          suffixIcon: widget.showToggleObscure
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: BotanlyColors.moss.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _border(focused: true),
          disabledBorder: _border(),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: focused
            ? BotanlyColors.moss.withValues(alpha: 0.6)
            : BotanlyColors.moss.withValues(alpha: 0.2),
        width: focused ? 1.5 : 1,
      ),
    );
  }
}

/// Primary auth submit button: gradient sage→moss, h:56, radius:18.
class BotanlyAuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const BotanlyAuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: loading
                ? const LinearGradient(
                    colors: [Color(0xFFBDBDBD), Color(0xFFBDBDBD)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BotanlyColors.authSage,
                      BotanlyColors.moss,
                    ],
                  ),
            boxShadow: loading
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x594A6741),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.32,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button (splash 'Log In').
class BotanlyAuthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const BotanlyAuthSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: BotanlyColors.moss.withValues(alpha: 0.45),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: BotanlyColors.moss.withValues(alpha: 0.75),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.32,
            color: BotanlyColors.moss.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

/// Inline error box (matches .error-box .show in HTML).
class BotanlyAuthErrorBox extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry padding;
  const BotanlyAuthErrorBox({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
