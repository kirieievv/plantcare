import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/services/auth_service.dart';

import 'forgot_password_new_password_screen.dart';

const Color _dark = Color(0xFF1B3A1B);

class ForgotPasswordPinScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordPinScreen({super.key, required this.email});

  @override
  State<ForgotPasswordPinScreen> createState() => _ForgotPasswordPinScreenState();
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
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
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

  Future<void> _verifyAndContinue(String pin) async {
    if (_isSubmitting) return;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return;

    setState(() {
      _isSubmitting = true;
      _error = '';
    });
    try {
      await AuthService.verifyPasswordResetPin(email: widget.email, pin: pin);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ForgotPasswordNewPasswordScreen(
            email: widget.email,
            pin: pin,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _clearPinInputs();
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _currentPin => _digitControllers.map((c) => c.text).join();

  void _clearPinInputs() {
    for (final controller in _digitControllers) {
      controller.clear();
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

    if (_error.isNotEmpty) setState(() => _error = '');

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

  Widget _buildDigitInput(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofocus: index == 0,
        style: GoogleFonts.lato(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _dark,
        ),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dark.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dark.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _dark.withOpacity(0.7), width: 1.5),
          ),
        ),
        onChanged: (value) => _handleDigitChanged(index, value),
      ),
    );
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
              style: GoogleFonts.lato(fontSize: 13)),
          backgroundColor: _dark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD6EDD6),
              Color(0xFFF5FAF5),
              Color(0xFFE8F5E8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: _dark.withOpacity(0.7), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          'Botanly',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          l10n.enterVerificationCode,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: _dark.withOpacity(0.55),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        l10n.weSentACodeTo,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: _dark.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.email,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _dark,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, _buildDigitInput),
                      ),

                      if (_isSubmitting)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_dark),
                              ),
                            ),
                          ),
                        ),

                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: GoogleFonts.lato(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Center(
                        child: TextButton(
                          onPressed: (_resendSeconds > 0 || _isSubmitting) ? null : _resendCode,
                          style: TextButton.styleFrom(foregroundColor: _dark),
                          child: Text(
                            _resendSeconds > 0
                                ? l10n.resendCodeInSeconds(_resendSeconds)
                                : l10n.resendCode,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: _resendSeconds > 0
                                  ? _dark.withOpacity(0.35)
                                  : _dark.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
