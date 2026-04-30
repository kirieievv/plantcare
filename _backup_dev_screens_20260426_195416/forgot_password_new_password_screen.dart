import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class ForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String email;
  final String pin;
  const ForgotPasswordNewPasswordScreen({
    super.key,
    required this.email,
    required this.pin,
  });

  @override
  State<ForgotPasswordNewPasswordScreen> createState() =>
      _ForgotPasswordNewPasswordScreenState();
}

class _ForgotPasswordNewPasswordScreenState
    extends State<ForgotPasswordNewPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _newCtrl.text;
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (pw != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.resetPasswordWithPin(
        email: widget.email,
        pin: widget.pin,
        newPassword: pw,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successful',
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(isRegistration: false),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD6EDD6), Color(0xFFF5FAF5), Color(0xFFE8F5E8)],
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
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: BotanlyColors.moss.withOpacity(.7), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Text('Botanly',
                            style: GoogleFonts.fraunces(
                              fontSize: 36,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: BotanlyColors.moss,
                            )),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Set a new password',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: BotanlyColors.moss.withOpacity(.55),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _PwField(
                        controller: _newCtrl,
                        label: 'New password',
                        show: _showNew,
                        onToggle: () =>
                            setState(() => _showNew = !_showNew),
                      ),
                      const SizedBox(height: 14),
                      _PwField(
                        controller: _confirmCtrl,
                        label: 'Confirm password',
                        show: _showConfirm,
                        onToggle: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: BotanlyColors.redPale,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFECC6C6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: BotanlyColors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: GoogleFonts.dmSans(
                                      color: BotanlyColors.red,
                                      fontSize: 13,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BotanlyColors.sage,
                            disabledBackgroundColor:
                                const Color(0xFFCDD5CB),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            shadowColor:
                                BotanlyColors.sage.withOpacity(.4),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white)),
                                )
                              : Text('Update password',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .5,
                                  )),
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

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  const _PwField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.6),
        border: Border.all(color: BotanlyColors.moss.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              color: BotanlyColors.moss.withOpacity(.5), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !show,
              style:
                  GoogleFonts.dmSans(color: BotanlyColors.moss, fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.dmSans(
                  color: BotanlyColors.moss.withOpacity(.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              show
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: BotanlyColors.moss.withOpacity(.4),
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}
