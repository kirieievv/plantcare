import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// UI from `Botanly /screens/forgot_password_pin_screen.html`.
/// Logic identical to production: 6-digit PIN, auto-advance, paste, resend
/// cooldown, verify via AuthService.
class ForgotPasswordPinScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordPinScreen({super.key, required this.email});

  @override
  State<ForgotPasswordPinScreen> createState() =>
      _ForgotPasswordPinScreenState();
}

class _ForgotPasswordPinScreenState extends State<ForgotPasswordPinScreen> {
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isSubmitting = false;
  String _error = '';
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_resendSeconds <= 1) {
          _resendSeconds = 0;
          timer.cancel();
        } else {
          _resendSeconds -= 1;
        }
      });
    });
  }

  String _localizeError(String code, AppLocalizations l10n) {
    switch (code) {
      case 'INVALID_PIN': return l10n.errorInvalidPin;
      case 'PIN_EXPIRED': return l10n.errorPinExpired;
      case 'PIN_NOT_FOUND': return l10n.errorPinNotFound;
      case 'TOO_MANY_ATTEMPTS': return l10n.errorTooManyAttempts;
      case 'SEND_FAILED': return l10n.errorSendFailed;
      default: return l10n.errorGeneric;
    }
  }

  Future<void> _verifyAndContinue(String pin) async {
    if (_isSubmitting) return;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return;

    setState(() {
      _isSubmitting = true;
      _error = '';
    });
    try {
      await AuthService.verifyPasswordResetPin(
          email: widget.email, pin: pin);
      if (!mounted) return;
      context.pushReplacement('/forgot-password/reset', extra: <String, String>{
        'email': widget.email,
        'pin': pin,
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = _localizeError(e.toString(), l10n);
        _clearPinInputs();
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _currentPin =>
      _digitControllers.map((c) => c.text).join();

  void _clearPinInputs() {
    for (final c in _digitControllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      FocusScope.of(context).requestFocus(_focusNodes.first);
    }
  }

  void _handleDigitChanged(int index, String value) {
    if (_isSubmitting) return;

    String sanitized = value.replaceAll(RegExp(r'\D'), '');
    if (sanitized.length > 1) {
      sanitized = sanitized.substring(sanitized.length - 1);
    }
    if (_digitControllers[index].text != sanitized) {
      _digitControllers[index].text = sanitized;
      _digitControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _digitControllers[index].text.length),
      );
    }

    // Only clear error when user starts typing a new digit
    if (_error.isNotEmpty && sanitized.isNotEmpty) setState(() => _error = '');

    if (sanitized.isNotEmpty) {
      if (index < _focusNodes.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    final pin = _currentPin;
    if (RegExp(r'^\d{6}$').hasMatch(pin)) {
      _verifyAndContinue(pin);
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = '';
    });
    try {
      await AuthService.requestPasswordResetPin(widget.email);
      if (!mounted) return;
      _clearPinInputs();
      _startCooldown();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.verificationCodeSentAgain,
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = _localizeError(e.toString(), l10n));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _digitInput(int index) {
    final filled = _digitControllers[index].text.isNotEmpty;
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 48),
        child: SizedBox(
          height: 56,
          child: TextField(
            controller: _digitControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: index == 0,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: BotanlyColors.moss,
            ),
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: filled
                  ? BotanlyColors.authSagePale.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.6),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: _border(),
              enabledBorder: filled
                  ? _border(color: BotanlyColors.authSageLight)
                  : _border(),
              focusedBorder: _border(focused: true),
            ),
            onChanged: (value) => _handleDigitChanged(index, value),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false, Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color ??
            (focused
                ? BotanlyColors.moss.withValues(alpha: 0.7)
                : BotanlyColors.moss.withValues(alpha: 0.2)),
        width: focused ? 1.5 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BotanlyAuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BotanlyWordmark(
            title: 'Botanly',
            subtitle: l10n.enterVerificationCode,
          ),
          const SizedBox(height: 40),
          Text(
            l10n.weSentACodeTo,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.4,
              color: BotanlyColors.moss.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.email,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BotanlyColors.moss,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 6; i++) ...[
                _digitInput(i),
                if (i < 5) const SizedBox(width: 8),
              ],
            ],
          ),
          if (_isSubmitting)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(BotanlyColors.moss),
                  ),
                ),
              ),
            ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            BotanlyAuthErrorBox(message: _error),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: (_resendSeconds > 0 || _isSubmitting)
                  ? null
                  : _resendCode,
              style: TextButton.styleFrom(
                foregroundColor: BotanlyColors.moss,
              ),
              child: Text(
                _resendSeconds > 0
                    ? l10n.resendCodeInSeconds(_resendSeconds)
                    : l10n.resendCode,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: _resendSeconds > 0
                      ? BotanlyColors.moss.withValues(alpha: 0.35)
                      : BotanlyColors.moss.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
