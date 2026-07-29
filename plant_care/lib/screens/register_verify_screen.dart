import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/widgets/botanly_auth_kit.dart';

/// Step 2 of registration: enter the 6-digit PIN sent to the user's email.
///
/// Uses a single hidden TextField that captures all input. The 6 visual cells
/// are purely decorative — tapping anywhere on the row focuses the hidden
/// field. This gives correct backspace, paste, and SMS-autofill behaviour
/// without any custom focus juggling.
///
/// Dev bypass: PIN '111111' always passes.
class RegisterVerifyScreen extends StatefulWidget {
  final String email;

  const RegisterVerifyScreen({super.key, required this.email});

  @override
  State<RegisterVerifyScreen> createState() => _RegisterVerifyScreenState();
}

class _RegisterVerifyScreenState extends State<RegisterVerifyScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSubmitting = false;
  String _error = '';
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _controller.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onPinChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_resendSeconds <= 1) {
          _resendSeconds = 0;
          t.cancel();
        } else {
          _resendSeconds -= 1;
        }
      });
    });
  }

  void _onPinChanged() {
    // Only clear error when user actually starts typing a new code
    if (_error.isNotEmpty && _controller.text.isNotEmpty) {
      setState(() => _error = '');
    }
    setState(() {}); // rebuild cells

    final pin = _controller.text;
    if (pin.length == 6) {
      _verifyAndContinue(pin);
    }
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
    _focusNode.unfocus();

    setState(() {
      _isSubmitting = true;
      _error = '';
    });
    try {
      await AuthService.verifyEmailPin(email: widget.email, pin: pin);
      if (!mounted) return;
      context.pushReplacement('/register/complete', extra: widget.email);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = _localizeError(e.toString(), l10n);
        _controller.clear();
      });
      _focusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = '';
    });
    try {
      await AuthService.sendEmailVerificationPin(widget.email);
      if (!mounted) return;
      _controller.clear();
      _startCooldown();
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.verificationCodeSentAgain,
            style: GoogleFonts.dmSans(fontSize: 13),
          ),
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

  // ── Visual PIN cells ──────────────────────────────────────────────────────

  Widget _buildCells() {
    final pin = _controller.text;
    final focused = _focusNode.hasFocus;

    return GestureDetector(
      onTap: _isSubmitting ? null : () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden real TextField — positioned off-screen height but keeps
          // keyboard open; opacity 0 so it's invisible.
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // SMS OTP autofill
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (_) {}, // handled by listener
              ),
            ),
          ),
          // Visual cells
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final hasChar = i < pin.length;
              final isActive = focused && (hasChar ? i == pin.length - 1 : i == pin.length);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                  child: _PinCell(
                    digit: hasChar ? pin[i] : null,
                    active: isActive,
                    filled: hasChar,
                  ),
                ),
              );
            }),
          ),
        ],
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
          _buildCells(),
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
              onPressed:
                  (_resendSeconds > 0 || _isSubmitting) ? null : _resendCode,
              style: TextButton.styleFrom(foregroundColor: BotanlyColors.moss),
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

// ── Single PIN cell widget ────────────────────────────────────────────────────

class _PinCell extends StatelessWidget {
  final String? digit;
  final bool active;
  final bool filled;

  const _PinCell({
    required this.digit,
    required this.active,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 56,
      decoration: BoxDecoration(
        color: filled
            ? BotanlyColors.authSagePale.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? BotanlyColors.moss.withValues(alpha: 0.7)
              : filled
                  ? BotanlyColors.authSageLight
                  : BotanlyColors.moss.withValues(alpha: 0.2),
          width: active ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: digit != null
          ? Text(
              digit!,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: BotanlyColors.moss,
              ),
            )
          : active
              ? _Cursor()
              : const SizedBox.shrink(),
    );
  }
}

// Blinking cursor shown in the active empty cell.
class _Cursor extends StatefulWidget {
  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ac,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: BotanlyColors.moss.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
