import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../services/auth_service.dart';
import 'forgot_password_new_password_screen.dart';

class ForgotPasswordPinScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordPinScreen({super.key, required this.email});

  @override
  State<ForgotPasswordPinScreen> createState() =>
      _ForgotPasswordPinScreenState();
}

class _ForgotPasswordPinScreenState extends State<ForgotPasswordPinScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _ctrls.map((c) => c.text).join();
    if (pin.length != 6) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.verifyPasswordResetPin(
          email: widget.email, pin: pin);
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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await AuthService.requestPasswordResetPin(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code resent',
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.moss,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(),
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: BotanlyColors.red,
        ),
      );
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
                          'Enter the 6-digit code',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: BotanlyColors.moss.withOpacity(.55),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          widget.email,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: BotanlyColors.inkMute,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 44,
                            height: 56,
                            child: TextField(
                              controller: _ctrls[i],
                              focusNode: _nodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: GoogleFonts.fraunces(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: BotanlyColors.moss,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white.withOpacity(.6),
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: BotanlyColors.moss
                                          .withOpacity(.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: BotanlyColors.sage,
                                      width: 1.5),
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 5) {
                                  _nodes[i + 1].requestFocus();
                                } else if (v.isEmpty && i > 0) {
                                  _nodes[i - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: BotanlyColors.redPale,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFECC6C6)),
                          ),
                          child: Text(_error!,
                              style: GoogleFonts.dmSans(
                                color: BotanlyColors.red,
                                fontSize: 13,
                              )),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verify,
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
                              : Text('Verify code',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .5,
                                  )),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: _resend,
                          child: Text(
                            'Resend code',
                            style: GoogleFonts.dmSans(
                              color: BotanlyColors.sage,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
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
