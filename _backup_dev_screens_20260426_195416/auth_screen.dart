import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/botanly_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'main_navigation_screen.dart';
import 'forgot_password_email_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isRegistration;
  const AuthScreen({super.key, this.isRegistration = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isReg = widget.isRegistration;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final pw = _passwordCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (_isReg && pw != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_isReg && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isReg) {
        await AuthService.signUp(
          email: email,
          password: pw,
          name: _nameCtrl.text.trim(),
        );
      } else {
        await AuthService.signIn(
          email: email,
          password: pw,
          rememberMe: true,
        );
      }

      await NotificationService().initialize();

      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(initialIndex: 0),
        ),
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
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: BotanlyColors.moss.withOpacity(.7),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 8),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            'Botanly',
                            style: GoogleFonts.fraunces(
                              fontSize: 44,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -.6,
                              color: BotanlyColors.moss,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _isReg ? 'Create your garden' : 'Welcome back',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: BotanlyColors.inkMute,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        if (_isReg) ...[
                          _BotanlyField(
                            controller: _nameCtrl,
                            label: 'Full name',
                            icon: Icons.person_outline,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 14),
                        ],

                        _BotanlyField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ],
                        ),
                        const SizedBox(height: 14),
                        _BotanlyField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          autofillHints: _isReg
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          trailing: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: BotanlyColors.inkMute,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),

                        if (_isReg) ...[
                          const SizedBox(height: 14),
                          _BotanlyField(
                            controller: _confirmCtrl,
                            label: 'Confirm password',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                        ],

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: _error!),
                        ],

                        if (!_isReg) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordEmailScreen(),
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.dmSans(
                                  color: BotanlyColors.sage,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        _PrimaryButton(
                          label: _isReg ? 'Sign up' : 'Sign in',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isReg = !_isReg;
                              _error = null;
                            }),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: BotanlyColors.inkSoft,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isReg
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: _isReg ? 'Sign in' : 'Register',
                                    style: const TextStyle(
                                      color: BotanlyColors.sage,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
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

// ─────────────────────── shared widgets ───────────────────────

class _BotanlyField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final List<String>? autofillHints;

  const _BotanlyField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
    this.autofillHints,
  });

  @override
  State<_BotanlyField> createState() => _BotanlyFieldState();
}

class _BotanlyFieldState extends State<_BotanlyField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.6),
        border: Border.all(
          color: focused
              ? BotanlyColors.sage
              : BotanlyColors.moss.withOpacity(.2),
          width: focused ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(widget.icon,
              color: BotanlyColors.moss.withOpacity(.5), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              autofillHints: widget.autofillHints,
              style: GoogleFonts.dmSans(
                color: BotanlyColors.moss,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: GoogleFonts.dmSans(
                  color: BotanlyColors.moss.withOpacity(.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BotanlyColors.redPale,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECC6C6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: BotanlyColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: BotanlyColors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: BotanlyColors.sage,
          disabledBackgroundColor: const Color(0xFFCDD5CB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: BotanlyColors.sage.withOpacity(.4),
          elevation: 4,
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
      ),
    );
  }
}
