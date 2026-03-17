import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plant_care/services/auth_service.dart';

import 'forgot_password_new_password_screen.dart';

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

    if (_error.isNotEmpty) {
      setState(() => _error = '');
    }

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
      width: 48,
      child: TextField(
        controller: _digitControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofocus: index == 0,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent again.')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We sent a 6-digit code to ${widget.email}.'),
              const SizedBox(height: 16),
              const Text('PIN code'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigitInput),
              ),
              if (_isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              TextButton(
                onPressed: (_resendSeconds > 0 || _isSubmitting) ? null : _resendCode,
                child: Text(
                  _resendSeconds > 0 ? 'Resend code in ${_resendSeconds}s' : 'Resend code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
